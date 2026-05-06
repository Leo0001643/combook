package com.cambook.app.service.admin.impl;

import com.cambook.app.domain.dto.DeptSaveDTO;
import com.cambook.app.service.admin.IAdminDeptService;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.db.entity.SysDept;
import com.cambook.db.service.ISysDeptService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import com.cambook.common.enums.CommonStatus;

/**
 * Admin 部门管理实现
 */
@Service
@RequiredArgsConstructor
public class AdminDeptService implements IAdminDeptService {

    private final ISysDeptService sysDeptService;

    @Override
    public List<SysDept> list(String name, Integer status) {
        return sysDeptService.lambdaQuery()
                .like(name != null && !name.isBlank(), SysDept::getName, name)
                .eq(status != null, SysDept::getStatus, status)
                .orderByAsc(SysDept::getSort).list();
    }

    @Override
    public void add(DeptSaveDTO dto) {
        SysDept dept = new SysDept();
        dept.setName(dto.getName());
        dept.setParentId(dto.getParentId() != null ? dto.getParentId() : 0L);
        dept.setSort(dto.getSort() != null ? dto.getSort() : 0);
        dept.setLeader(dto.getLeader());
        dept.setPhone(dto.getPhone());
        dept.setEmail(dto.getEmail());
        dept.setStatus(CommonStatus.ENABLED.byteCode());
        sysDeptService.save(dept);
    }

    @Override
    public void edit(DeptSaveDTO dto) {
        SysDept dept = Optional.ofNullable(sysDeptService.getById(dto.getId())).orElseThrow(() -> new BusinessException(CbCodeEnum.DATA_NOT_FOUND));
        dept.setName(dto.getName());
        dept.setParentId(dto.getParentId() != null ? dto.getParentId() : 0L);
        dept.setSort(dto.getSort() != null ? dto.getSort() : 0);
        dept.setLeader(dto.getLeader());
        dept.setPhone(dto.getPhone());
        dept.setEmail(dto.getEmail());
        if (dto.getStatus() != null) dept.setStatus(dto.getStatus().byteValue());
        sysDeptService.updateById(dept);
    }

    @Override
    public void delete(Long id) {
        long children = sysDeptService.lambdaQuery().eq(SysDept::getParentId, id).count();
        if (children > 0) throw new BusinessException(CbCodeEnum.DEPT_HAS_CHILDREN);
        sysDeptService.removeById(id);
    }

    @Override
    public void updateStatus(Long id, Integer status) {
        SysDept dept = Optional.ofNullable(sysDeptService.getById(id)).orElseThrow(() -> new BusinessException(CbCodeEnum.DATA_NOT_FOUND));
        dept.setStatus(status != null ? status.byteValue() : null);
        sysDeptService.updateById(dept);
    }
}
