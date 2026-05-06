package com.cambook.app.service.merchant.impl;

import com.cambook.app.common.security.MerchantOwnershipGuard;
import com.cambook.app.domain.dto.PositionDTO;
import com.cambook.app.domain.vo.PositionVO;
import com.cambook.app.service.merchant.IMerchantPositionService;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.db.entity.SysPosition;
import com.cambook.db.service.ISysPositionService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;
import com.cambook.common.enums.CommonStatus;

/**
 * 商户端职位服务实现
 */
@Service
@RequiredArgsConstructor
public class MerchantPositionServiceImpl implements IMerchantPositionService {

    private final ISysPositionService sysPositionService;

    @Override
    public List<PositionVO> list(Long merchantId) {
        return sysPositionService.lambdaQuery()
                .eq(SysPosition::getMerchantId, merchantId).eq(SysPosition::getDeleted, 0)
                .orderByAsc(SysPosition::getSort).list()
                .stream().map(PositionVO::from).collect(Collectors.toList());
    }

    @Override
    public void add(Long merchantId, PositionDTO dto) {
        if (sysPositionService.lambdaQuery().eq(SysPosition::getMerchantId, merchantId).eq(SysPosition::getCode, dto.getCode()).exists())
            throw new BusinessException(CbCodeEnum.DATA_DUPLICATE);
        SysPosition p = new SysPosition();
        p.setMerchantId(merchantId); p.setDeptId(dto.getDeptId()); p.setName(dto.getName()); p.setCode(dto.getCode());
        p.setRemark(dto.getRemark()); p.setSort(dto.getSort() != null ? dto.getSort() : 0);
        p.setStatus(dto.getStatus() != null ? dto.getStatus().byteValue() : CommonStatus.ENABLED.byteCode());
        p.setFullAccess(dto.getFullAccess() != null ? dto.getFullAccess().byteValue() : (byte) 0);
        sysPositionService.save(p);
    }

    @Override
    public void edit(Long merchantId, PositionDTO dto) {
        SysPosition p = Optional.ofNullable(sysPositionService.getById(dto.getId())).orElseThrow(() -> new BusinessException("职位不存在"));
        MerchantOwnershipGuard.assertOwnership(p.getMerchantId(), "职位", dto.getId());
        if (dto.getDeptId()     != null) p.setDeptId(dto.getDeptId());
        p.setName(dto.getName()); p.setRemark(dto.getRemark()); p.setSort(dto.getSort());
        if (dto.getStatus()     != null) p.setStatus(dto.getStatus().byteValue());
        if (dto.getFullAccess() != null) p.setFullAccess(dto.getFullAccess().byteValue());
        sysPositionService.updateById(p);
    }

    @Override
    public void delete(Long merchantId, Long id) {
        SysPosition p = Optional.ofNullable(sysPositionService.getById(id)).orElseThrow(() -> new BusinessException("职位不存在"));
        MerchantOwnershipGuard.assertOwnership(p.getMerchantId(), "职位", id);
        sysPositionService.lambdaUpdate().set(SysPosition::getDeleted, 1).eq(SysPosition::getId, id).update();
    }

    @Override
    public void updateStatus(Long merchantId, Long id, Integer status) {
        SysPosition p = Optional.ofNullable(sysPositionService.getById(id)).orElseThrow(() -> new BusinessException("职位不存在"));
        MerchantOwnershipGuard.assertOwnership(p.getMerchantId(), "职位", id);
        sysPositionService.lambdaUpdate().set(SysPosition::getStatus, status).eq(SysPosition::getId, id).update();
    }
}
