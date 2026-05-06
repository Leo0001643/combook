package com.cambook.app.service.admin.impl;

import com.cambook.app.constant.CacheKey;
import com.cambook.app.domain.dto.RoleDTO;
import com.cambook.app.domain.vo.RoleVO;
import com.cambook.app.service.admin.IRoleService;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.db.entity.SysRole;
import com.cambook.db.entity.SysRolePermission;
import com.cambook.db.entity.SysUserRole;
import com.cambook.db.service.ISysRolePermissionService;
import com.cambook.db.service.ISysRoleService;
import com.cambook.db.service.ISysUserRoleService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;
import com.cambook.common.enums.CommonStatus;

/**
 * 角色管理服务实现
 *
 * @author CamBook
 */
@Service
@RequiredArgsConstructor
public class RoleService implements IRoleService {

    private final ISysRoleService           sysRoleService;
    private final ISysRolePermissionService sysRolePermissionService;
    private final ISysUserRoleService       sysUserRoleService;
    private final StringRedisTemplate       redisTemplate;

    @Override
    public List<RoleVO> list() {
        return sysRoleService.lambdaQuery()
                .orderByAsc(SysRole::getSort)
                .list()
                .stream().map(this::toVO).collect(Collectors.toList());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void add(RoleDTO dto) {
        long exists = sysRoleService.lambdaQuery().eq(SysRole::getRoleCode, dto.getRoleCode()).count();
        if (exists > 0) throw new BusinessException(CbCodeEnum.PARAM_ERROR);

        SysRole role = new SysRole();
        role.setRoleCode(dto.getRoleCode());
        role.setRoleName(dto.getRoleName());
        role.setRemark(dto.getRemark());
        role.setSort(dto.getSort() != null ? dto.getSort() : 0);
        role.setStatus(CommonStatus.ENABLED.byteCode());
        sysRoleService.save(role);

        assignPermissions(role.getId(), dto.getPermissionIds());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void edit(RoleDTO dto) {
        Optional.ofNullable(sysRoleService.getById(dto.getId()))
                .orElseThrow(() -> new BusinessException(CbCodeEnum.DATA_NOT_FOUND));

        sysRoleService.lambdaUpdate()
                .set(SysRole::getRoleName, dto.getRoleName())
                .set(SysRole::getRemark,   dto.getRemark())
                .set(SysRole::getSort,     dto.getSort())
                .eq(SysRole::getId, dto.getId())
                .update();

        sysRolePermissionService.lambdaUpdate()
                .eq(SysRolePermission::getRoleId, dto.getId())
                .remove();
        assignPermissions(dto.getId(), dto.getPermissionIds());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void delete(Long id) {
        sysRoleService.removeById(id);
        sysRolePermissionService.lambdaUpdate()
                .eq(SysRolePermission::getRoleId, id)
                .remove();
    }

    @Override
    public List<Long> getPermissionIds(Long roleId) {
        return sysRolePermissionService.lambdaQuery()
                .eq(SysRolePermission::getRoleId, roleId)
                .list()
                .stream().map(SysRolePermission::getPermissionId).collect(Collectors.toList());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void savePermissions(Long roleId, List<Long> permissionIds) {
        sysRolePermissionService.lambdaUpdate()
                .eq(SysRolePermission::getRoleId, roleId)
                .remove();
        assignPermissions(roleId, permissionIds);

        // 清理该角色下所有用户的权限缓存，强制重载
        Set<Long> userIds = sysUserRoleService.lambdaQuery()
                .eq(SysUserRole::getRoleId, roleId)
                .list()
                .stream().map(SysUserRole::getUserId).collect(Collectors.toSet());
        userIds.forEach(uid -> redisTemplate.delete(CacheKey.ADMIN_PERMS + uid));
    }

    // ── 私有 ─────────────────────────────────────────────────────────────────

    private void assignPermissions(Long roleId, List<Long> permissionIds) {
        if (permissionIds == null || permissionIds.isEmpty()) return;
        List<SysRolePermission> records = permissionIds.stream().map(permId -> {
            SysRolePermission rp = new SysRolePermission();
            rp.setRoleId(roleId);
            rp.setPermissionId(permId);
            return rp;
        }).collect(Collectors.toList());
        sysRolePermissionService.saveBatch(records);
    }

    private RoleVO toVO(SysRole r) {
        RoleVO vo = new RoleVO();
        vo.setId(r.getId());
        vo.setRoleCode(r.getRoleCode());
        vo.setRoleName(r.getRoleName());
        vo.setRemark(r.getRemark());
        vo.setSort(r.getSort());
        vo.setStatus(r.getStatus() != null ? r.getStatus().intValue() : null);

        List<Long> permIds = sysRolePermissionService.lambdaQuery()
                .eq(SysRolePermission::getRoleId, r.getId())
                .list()
                .stream().map(SysRolePermission::getPermissionId).collect(Collectors.toList());
        vo.setPermissionIds(permIds);
        return vo;
    }
}
