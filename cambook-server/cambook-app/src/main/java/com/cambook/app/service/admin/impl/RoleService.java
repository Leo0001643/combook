package com.cambook.app.service.admin.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.cambook.app.constant.CacheKey;
import com.cambook.app.domain.dto.RoleDTO;
import com.cambook.app.domain.vo.RoleVO;
import com.cambook.app.service.admin.IRoleService;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.dao.entity.SysRole;
import com.cambook.dao.entity.SysRolePermission;
import com.cambook.dao.entity.SysUserRole;
import com.cambook.dao.mapper.SysRoleMapper;
import com.cambook.dao.mapper.SysRolePermissionMapper;
import com.cambook.dao.mapper.SysUserRoleMapper;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * 角色管理服务实现
 *
 * @author CamBook
 */
@Service
public class RoleService implements IRoleService {

    private final SysRoleMapper           roleMapper;
    private final SysRolePermissionMapper rolePermissionMapper;
    private final SysUserRoleMapper       userRoleMapper;
    private final StringRedisTemplate     redisTemplate;

    public RoleService(SysRoleMapper roleMapper,
                       SysRolePermissionMapper rolePermissionMapper,
                       SysUserRoleMapper userRoleMapper,
                       StringRedisTemplate redisTemplate) {
        this.roleMapper           = roleMapper;
        this.rolePermissionMapper = rolePermissionMapper;
        this.userRoleMapper       = userRoleMapper;
        this.redisTemplate        = redisTemplate;
    }

    @Override
    public List<RoleVO> list() {
        List<SysRole> roles = roleMapper.selectList(
                new LambdaQueryWrapper<SysRole>().orderByAsc(SysRole::getSort)
        );
        return roles.stream().map(this::toVO).collect(Collectors.toList());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void add(RoleDTO dto) {
        long exists = roleMapper.selectCount(
                new LambdaQueryWrapper<SysRole>().eq(SysRole::getRoleCode, dto.getRoleCode())
        );
        if (exists > 0) throw new BusinessException(CbCodeEnum.PARAM_ERROR);

        SysRole role = new SysRole();
        role.setRoleCode(dto.getRoleCode());
        role.setRoleName(dto.getRoleName());
        role.setRemark(dto.getRemark());
        role.setSort(dto.getSort() != null ? dto.getSort() : 0);
        role.setStatus(1);
        roleMapper.insert(role);

        assignPermissions(role.getId(), dto.getPermissionIds());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void edit(RoleDTO dto) {
        SysRole role = roleMapper.selectById(dto.getId());
        if (role == null) throw new BusinessException(CbCodeEnum.DATA_NOT_FOUND);

        roleMapper.update(null,
                new LambdaUpdateWrapper<SysRole>()
                        .set(SysRole::getRoleName, dto.getRoleName())
                        .set(SysRole::getRemark, dto.getRemark())
                        .set(SysRole::getSort, dto.getSort())
                        .eq(SysRole::getId, dto.getId())
        );

        // 重新分配权限：先全删再插入
        rolePermissionMapper.delete(
                new LambdaQueryWrapper<SysRolePermission>().eq(SysRolePermission::getRoleId, dto.getId())
        );
        assignPermissions(dto.getId(), dto.getPermissionIds());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void delete(Long id) {
        roleMapper.deleteById(id);
        rolePermissionMapper.delete(
                new LambdaQueryWrapper<SysRolePermission>().eq(SysRolePermission::getRoleId, id)
        );
    }

    @Override
    public List<Long> getPermissionIds(Long roleId) {
        return rolePermissionMapper.selectList(
                        new LambdaQueryWrapper<SysRolePermission>()
                                .eq(SysRolePermission::getRoleId, roleId))
                .stream()
                .map(SysRolePermission::getPermissionId)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void savePermissions(Long roleId, List<Long> permissionIds) {
        // 全量替换
        rolePermissionMapper.delete(
                new LambdaQueryWrapper<SysRolePermission>()
                        .eq(SysRolePermission::getRoleId, roleId));
        assignPermissions(roleId, permissionIds);

        // 清理该角色下所有用户的权限缓存，强制重载
        Set<Long> userIds = userRoleMapper.selectList(
                        new LambdaQueryWrapper<SysUserRole>()
                                .eq(SysUserRole::getRoleId, roleId))
                .stream()
                .map(SysUserRole::getUserId)
                .collect(Collectors.toSet());
        userIds.forEach(uid -> redisTemplate.delete(CacheKey.ADMIN_PERMS + uid));
    }

    // ── 私有 ─────────────────────────────────────────────────────────────────

    private void assignPermissions(Long roleId, List<Long> permissionIds) {
        if (permissionIds == null || permissionIds.isEmpty()) return;
        permissionIds.forEach(permId -> {
            SysRolePermission rp = new SysRolePermission();
            rp.setRoleId(roleId);
            rp.setPermissionId(permId);
            rolePermissionMapper.insert(rp);
        });
    }

    private RoleVO toVO(SysRole r) {
        RoleVO vo = new RoleVO();
        vo.setId(r.getId());
        vo.setRoleCode(r.getRoleCode());
        vo.setRoleName(r.getRoleName());
        vo.setRemark(r.getRemark());
        vo.setSort(r.getSort());
        vo.setStatus(r.getStatus());

        List<Long> permIds = rolePermissionMapper.selectList(
                        new LambdaQueryWrapper<SysRolePermission>().eq(SysRolePermission::getRoleId, r.getId()))
                .stream().map(SysRolePermission::getPermissionId).collect(Collectors.toList());
        vo.setPermissionIds(permIds);
        return vo;
    }
}
