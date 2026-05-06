package com.cambook.app.service.merchant.impl;

import com.cambook.app.domain.dto.DeptSaveDTO;
import com.cambook.app.service.merchant.IMerchantDeptService;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.db.entity.SysDept;
import com.cambook.db.service.ISysDeptService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import com.cambook.common.enums.CommonStatus;

/**
 * 商户端 部门管理实现
 */
@Service
@RequiredArgsConstructor
public class MerchantDeptServiceImpl implements IMerchantDeptService {

    private final ISysDeptService sysDeptService;

    @Override
    public List<SysDept> list(Long merchantId, String name, Integer status) {
        return sysDeptService.lambdaQuery()
                .eq(SysDept::getMerchantId, merchantId)
                .like(name != null && !name.isBlank(), SysDept::getName, name)
                .eq(status != null, SysDept::getStatus, status)
                .orderByAsc(SysDept::getSort).list();
    }

    @Override
    public void add(Long merchantId, DeptSaveDTO dto) {
        SysDept dept = new SysDept();
        dept.setMerchantId(merchantId); dept.setName(dto.getName());
        dept.setParentId(dto.getParentId() != null ? dto.getParentId() : 0L);
        dept.setSort(dto.getSort() != null ? dto.getSort() : 0); dept.setLeader(dto.getLeader());
        dept.setPhone(dto.getPhone()); dept.setEmail(dto.getEmail()); dept.setStatus(CommonStatus.ENABLED.byteCode());
        sysDeptService.save(dept);
    }

    @Override
    public void edit(Long merchantId, DeptSaveDTO dto) {
        SysDept dept = getAndVerify(dto.getId(), merchantId);
        dept.setName(dto.getName()); dept.setParentId(dto.getParentId() != null ? dto.getParentId() : 0L);
        dept.setSort(dto.getSort() != null ? dto.getSort() : 0); dept.setLeader(dto.getLeader());
        dept.setPhone(dto.getPhone()); dept.setEmail(dto.getEmail());
        if (dto.getStatus() != null) dept.setStatus(dto.getStatus().byteValue());
        sysDeptService.updateById(dept);
    }

    @Override
    public void delete(Long merchantId, Long id) {
        getAndVerify(id, merchantId);
        long children = sysDeptService.lambdaQuery().eq(SysDept::getParentId, id).eq(SysDept::getMerchantId, merchantId).count();
        if (children > 0) throw new BusinessException(CbCodeEnum.DEPT_HAS_CHILDREN);
        sysDeptService.removeById(id);
    }

    @Override
    public void updateStatus(Long merchantId, Long id, Integer status) {
        SysDept dept = getAndVerify(id, merchantId);
        dept.setStatus(status != null ? status.byteValue() : null);
        sysDeptService.updateById(dept);
    }

    private SysDept getAndVerify(Long id, Long merchantId) {
        SysDept dept = Optional.ofNullable(sysDeptService.getById(id)).orElseThrow(() -> new BusinessException("部门不存在"));
        if (!merchantId.equals(dept.getMerchantId())) throw new BusinessException(CbCodeEnum.NO_PERMISSION);
        return dept;
    }
}
