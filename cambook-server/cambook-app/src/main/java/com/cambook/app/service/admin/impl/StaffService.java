package com.cambook.app.service.admin.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.app.constant.CacheKey;
import com.cambook.app.domain.dto.StaffDTO;
import com.cambook.app.domain.vo.StaffVO;
import com.cambook.app.service.admin.IStaffService;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.dao.entity.SysPosition;
import com.cambook.dao.entity.SysRole;
import com.cambook.dao.entity.SysUser;
import com.cambook.dao.entity.SysUserRole;
import com.cambook.dao.mapper.SysPositionMapper;
import com.cambook.dao.mapper.SysRoleMapper;
import com.cambook.dao.mapper.SysUserMapper;
import com.cambook.dao.mapper.SysUserRoleMapper;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.DigestUtils;
import org.springframework.util.StringUtils;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 员工管理服务实现
 *
 * @author CamBook
 */
@Service
public class StaffService implements IStaffService {

    private final SysUserMapper       userMapper;
    private final SysUserRoleMapper   userRoleMapper;
    private final SysRoleMapper       roleMapper;
    private final SysPositionMapper   positionMapper;
    private final StringRedisTemplate redisTemplate;

    public StaffService(SysUserMapper userMapper,
                        SysUserRoleMapper userRoleMapper,
                        SysRoleMapper roleMapper,
                        SysPositionMapper positionMapper,
                        StringRedisTemplate redisTemplate) {
        this.userMapper     = userMapper;
        this.userRoleMapper = userRoleMapper;
        this.roleMapper     = roleMapper;
        this.positionMapper = positionMapper;
        this.redisTemplate  = redisTemplate;
    }

    @Override
    public IPage<StaffVO> page(int current, int size, String keyword, Integer status, Long positionId) {
        LambdaQueryWrapper<SysUser> wrapper = new LambdaQueryWrapper<SysUser>()
                .eq(SysUser::getDeleted, 0)
                .eq(status != null, SysUser::getStatus, status)
                .eq(positionId != null, SysUser::getPositionId, positionId)
                .and(StringUtils.hasText(keyword), w -> w
                        .like(SysUser::getUsername, keyword)
                        .or().like(SysUser::getRealName, keyword)
                        .or().like(SysUser::getMobile, keyword))
                .orderByDesc(SysUser::getCreateTime);

        IPage<SysUser> page = userMapper.selectPage(new Page<>(current, size), wrapper);

        // 批量查询职位
        List<Long> posIds = page.getRecords().stream()
                .map(SysUser::getPositionId).filter(id -> id != null).distinct()
                .collect(Collectors.toList());
        Map<Long, String> posMap = posIds.isEmpty() ? Map.of()
                : positionMapper.selectBatchIds(posIds).stream()
                .collect(Collectors.toMap(SysPosition::getId, SysPosition::getName));

        return page.convert(u -> toVO(u, posMap));
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void add(StaffDTO dto) {
        long exists = userMapper.selectCount(
                new LambdaQueryWrapper<SysUser>().eq(SysUser::getUsername, dto.getUsername()));
        if (exists > 0) throw new BusinessException(CbCodeEnum.PARAM_ERROR);

        SysUser user = new SysUser();
        user.setUsername(dto.getUsername());
        if (StringUtils.hasText(dto.getPassword())) {
            user.setPassword(md5(dto.getPassword()));
        } else {
            user.setPassword(md5("Cambook@2026"));
        }
        user.setRealName(dto.getRealName());
        user.setEmail(dto.getEmail());
        user.setMobile(dto.getMobile());
        user.setPositionId(dto.getPositionId());
        user.setStatus(dto.getStatus() != null ? dto.getStatus() : 1);
        userMapper.insert(user);

        assignRoles(user.getId(), dto.getRoleIds());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void edit(StaffDTO dto) {
        SysUser user = userMapper.selectById(dto.getId());
        if (user == null) throw new BusinessException(CbCodeEnum.DATA_NOT_FOUND);

        userMapper.update(
                new com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper<SysUser>()
                        .set(dto.getRealName() != null, SysUser::getRealName, dto.getRealName())
                        .set(dto.getEmail() != null, SysUser::getEmail, dto.getEmail())
                        .set(dto.getMobile() != null, SysUser::getMobile, dto.getMobile())
                        .set(dto.getPositionId() != null, SysUser::getPositionId, dto.getPositionId())
                        .set(StringUtils.hasText(dto.getPassword()), SysUser::getPassword,
                                StringUtils.hasText(dto.getPassword()) ? md5(dto.getPassword()) : null)
                        .eq(SysUser::getId, dto.getId()));

        if (dto.getRoleIds() != null) {
            assignRoles(dto.getId(), dto.getRoleIds());
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void delete(Long id) {
        userMapper.update(
                new com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper<SysUser>()
                        .set(SysUser::getDeleted, 1)
                        .eq(SysUser::getId, id));
        clearPermCache(id);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateStatus(Long id, Integer status) {
        userMapper.update(
                new com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper<SysUser>()
                        .set(SysUser::getStatus, status)
                        .eq(SysUser::getId, id));
        if (status == 0) clearPermCache(id);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void assignRoles(Long userId, List<Long> roleIds) {
        userRoleMapper.delete(
                new LambdaQueryWrapper<SysUserRole>().eq(SysUserRole::getUserId, userId));
        if (roleIds != null && !roleIds.isEmpty()) {
            roleIds.forEach(rid -> {
                SysUserRole ur = new SysUserRole();
                ur.setUserId(userId);
                ur.setRoleId(rid);
                userRoleMapper.insert(ur);
            });
        }
        clearPermCache(userId);
    }

    // ── 私有 ────────────────────────────────────────────────────────────────────

    private StaffVO toVO(SysUser u, Map<Long, String> posMap) {
        StaffVO vo = new StaffVO();
        vo.setId(u.getId());
        vo.setUsername(u.getUsername());
        vo.setRealName(u.getRealName());
        vo.setAvatar(u.getAvatar());
        vo.setEmail(u.getEmail());
        vo.setMobile(u.getMobile());
        vo.setPositionId(u.getPositionId());
        vo.setPositionName(u.getPositionId() != null ? posMap.get(u.getPositionId()) : null);
        vo.setStatus(u.getStatus());
        vo.setCreateTime(u.getCreateTime());

        List<Long> roleIds = userRoleMapper.selectList(
                        new LambdaQueryWrapper<SysUserRole>().eq(SysUserRole::getUserId, u.getId()))
                .stream().map(SysUserRole::getRoleId).collect(Collectors.toList());
        vo.setRoleIds(roleIds);

        List<String> roleNames = roleIds.isEmpty() ? List.of()
                : roleMapper.selectBatchIds(roleIds).stream()
                .map(SysRole::getRoleName).collect(Collectors.toList());
        vo.setRoleNames(roleNames);
        return vo;
    }

    private void clearPermCache(Long userId) {
        redisTemplate.delete(CacheKey.ADMIN_PERMS + userId);
    }

    private static String md5(String raw) {
        return DigestUtils.md5DigestAsHex(raw.getBytes());
    }
}
