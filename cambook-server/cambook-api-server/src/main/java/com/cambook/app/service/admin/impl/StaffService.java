package com.cambook.app.service.admin.impl;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.app.constant.CacheKey;
import com.cambook.app.domain.dto.StaffDTO;
import com.cambook.app.domain.vo.StaffVO;
import com.cambook.app.service.admin.IStaffService;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.enums.CommonStatus;
import com.cambook.common.exception.BusinessException;
import com.cambook.db.entity.SysPosition;
import com.cambook.db.entity.SysRole;
import com.cambook.db.entity.SysUser;
import com.cambook.db.entity.SysUserRole;
import com.cambook.db.service.ISysPositionService;
import com.cambook.db.service.ISysRoleService;
import com.cambook.db.service.ISysUserRoleService;
import com.cambook.db.service.ISysUserService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.DigestUtils;
import org.springframework.util.StringUtils;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * 员工管理服务实现
 *
 * @author CamBook
 */
@Service
@RequiredArgsConstructor
public class StaffService implements IStaffService {

    private static final String DEFAULT_PASSWORD = "Cambook@2026";

    private final ISysUserService     sysUserService;
    private final ISysUserRoleService sysUserRoleService;
    private final ISysRoleService     sysRoleService;
    private final ISysPositionService sysPositionService;
    private final StringRedisTemplate redisTemplate;

    @Override
    public IPage<StaffVO> page(int current, int size, String keyword, Integer status, Long positionId) {
        IPage<SysUser> page = sysUserService.lambdaQuery()
                .eq(SysUser::getDeleted, 0)
                .eq(status      != null, SysUser::getStatus,     status)
                .eq(positionId  != null, SysUser::getPositionId, positionId)
                .and(StringUtils.hasText(keyword), w -> w
                        .like(SysUser::getUsername, keyword)
                        .or().like(SysUser::getRealName, keyword)
                        .or().like(SysUser::getMobile, keyword))
                .orderByDesc(SysUser::getCreateTime)
                .page(new Page<>(current, size));

        // 批量查询职位
        List<Long> posIds = page.getRecords().stream()
                .map(SysUser::getPositionId).filter(id -> id != null).distinct()
                .collect(Collectors.toList());
        Map<Long, String> posMap = posIds.isEmpty() ? Map.of()
                : sysPositionService.listByIds(posIds).stream()
                .collect(Collectors.toMap(SysPosition::getId, SysPosition::getName));

        return page.convert(u -> toVO(u, posMap));
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void add(StaffDTO dto) {
        long exists = sysUserService.lambdaQuery().eq(SysUser::getUsername, dto.getUsername()).count();
        if (exists > 0) throw new BusinessException(CbCodeEnum.PARAM_ERROR);

        SysUser user = new SysUser();
        user.setUsername(dto.getUsername());
        user.setPassword(StringUtils.hasText(dto.getPassword()) ? md5(dto.getPassword()) : md5(DEFAULT_PASSWORD));
        user.setRealName(dto.getRealName());
        user.setEmail(dto.getEmail());
        user.setMobile(dto.getMobile());
        user.setPositionId(dto.getPositionId());
        user.setStatus(dto.getStatus() != null ? dto.getStatus().byteValue() : CommonStatus.ENABLED.byteCode());
        sysUserService.save(user);

        assignRoles(user.getId(), dto.getRoleIds());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void edit(StaffDTO dto) {
        Optional.ofNullable(sysUserService.getById(dto.getId()))
                .orElseThrow(() -> new BusinessException(CbCodeEnum.DATA_NOT_FOUND));

        sysUserService.lambdaUpdate()
                .set(dto.getRealName()  != null, SysUser::getRealName,   dto.getRealName())
                .set(dto.getEmail()     != null, SysUser::getEmail,      dto.getEmail())
                .set(dto.getMobile()    != null, SysUser::getMobile,     dto.getMobile())
                .set(dto.getPositionId() != null, SysUser::getPositionId, dto.getPositionId())
                .set(StringUtils.hasText(dto.getPassword()), SysUser::getPassword,
                        StringUtils.hasText(dto.getPassword()) ? md5(dto.getPassword()) : null)
                .eq(SysUser::getId, dto.getId())
                .update();

        if (dto.getRoleIds() != null) {
            assignRoles(dto.getId(), dto.getRoleIds());
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void delete(Long id) {
        sysUserService.lambdaUpdate()
                .set(SysUser::getDeleted, 1)
                .eq(SysUser::getId, id)
                .update();
        clearPermCache(id);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateStatus(Long id, Integer status) {
        sysUserService.lambdaUpdate()
                .set(SysUser::getStatus, status)
                .eq(SysUser::getId, id)
                .update();
        if (status == CommonStatus.DISABLED.getCode()) clearPermCache(id);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void assignRoles(Long userId, List<Long> roleIds) {
        sysUserRoleService.lambdaUpdate()
                .eq(SysUserRole::getUserId, userId)
                .remove();
        if (roleIds != null && !roleIds.isEmpty()) {
            List<SysUserRole> records = roleIds.stream().map(rid -> {
                SysUserRole ur = new SysUserRole();
                ur.setUserId(userId);
                ur.setRoleId(rid);
                return ur;
            }).collect(Collectors.toList());
            sysUserRoleService.saveBatch(records);
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
        vo.setStatus(u.getStatus() != null ? u.getStatus().intValue() : null);
        vo.setCreateTime(u.getCreateTime());

        List<Long> roleIds = sysUserRoleService.lambdaQuery()
                .eq(SysUserRole::getUserId, u.getId())
                .list()
                .stream().map(SysUserRole::getRoleId).collect(Collectors.toList());
        vo.setRoleIds(roleIds);

        List<String> roleNames = roleIds.isEmpty() ? List.of()
                : sysRoleService.listByIds(roleIds).stream()
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
