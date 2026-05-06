package com.cambook.app.service.admin.impl;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.app.domain.dto.VehicleDTO;
import com.cambook.app.domain.vo.VehicleVO;
import com.cambook.app.service.admin.IVehicleService;
import com.cambook.app.common.security.MerchantOwnershipGuard;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.db.entity.CbVehicle;
import com.cambook.db.service.ICbVehicleService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.util.Optional;

/**
 * 车辆管理 Service 实现
 *
 * @author CamBook
 */
@Service
@RequiredArgsConstructor
public class VehicleService implements IVehicleService {

    private final ICbVehicleService cbVehicleService;

    @Override
    public IPage<VehicleVO> page(int current, int size, String keyword, Integer status, Long merchantId) {
        IPage<CbVehicle> raw = cbVehicleService.lambdaQuery()
                .eq(merchantId != null, CbVehicle::getMerchantId, merchantId)
                .and(StringUtils.hasText(keyword), w -> w
                        .like(CbVehicle::getPlateNumber, keyword)
                        .or().like(CbVehicle::getBrand, keyword)
                        .or().like(CbVehicle::getModel, keyword))
                .eq(status != null, CbVehicle::getStatus, status)
                .orderByDesc(CbVehicle::getCreateTime)
                .page(new Page<>(current, size));

        return raw.convert(e -> {
            VehicleVO vo = new VehicleVO();
            BeanUtils.copyProperties(e, vo);
            return vo;
        });
    }

    @Override
    public void add(VehicleDTO dto) {
        if (cbVehicleService.lambdaQuery().eq(CbVehicle::getPlateNumber, dto.getPlateNumber()).exists())
            throw new BusinessException(CbCodeEnum.DATA_DUPLICATE);
        CbVehicle entity = new CbVehicle();
        BeanUtils.copyProperties(dto, entity);
        entity.setMerchantId(dto.getMerchantId());
        cbVehicleService.save(entity);
    }

    @Override
    public void edit(VehicleDTO dto) {
        CbVehicle entity = Optional.ofNullable(cbVehicleService.getById(dto.getId()))
                .orElseThrow(() -> new BusinessException(CbCodeEnum.VEHICLE_NOT_FOUND));
        BeanUtils.copyProperties(dto, entity, "id", "merchantId");
        cbVehicleService.updateById(entity);
    }

    @Override
    public void edit(VehicleDTO dto, Long merchantId) {
        CbVehicle entity = Optional.ofNullable(cbVehicleService.getById(dto.getId()))
                .orElseThrow(() -> new BusinessException(CbCodeEnum.VEHICLE_NOT_FOUND));
        MerchantOwnershipGuard.assertOwnership(entity.getMerchantId(), "车辆", dto.getId());
        BeanUtils.copyProperties(dto, entity, "id", "merchantId");
        cbVehicleService.updateById(entity);
    }

    @Override
    public void delete(Long id) {
        Optional.ofNullable(cbVehicleService.getById(id))
                .orElseThrow(() -> new BusinessException(CbCodeEnum.VEHICLE_NOT_FOUND));
        cbVehicleService.removeById(id);
    }

    @Override
    public void delete(Long id, Long merchantId) {
        CbVehicle entity = Optional.ofNullable(cbVehicleService.getById(id))
                .orElseThrow(() -> new BusinessException(CbCodeEnum.VEHICLE_NOT_FOUND));
        MerchantOwnershipGuard.assertOwnership(entity.getMerchantId(), "车辆", id);
        cbVehicleService.removeById(id);
    }

    @Override
    public void updateStatus(Long id, Integer status) {
        CbVehicle entity = Optional.ofNullable(cbVehicleService.getById(id))
                .orElseThrow(() -> new BusinessException(CbCodeEnum.VEHICLE_NOT_FOUND));
        entity.setStatus(status == null ? null : status.byteValue());
        cbVehicleService.updateById(entity);
    }

    @Override
    public void updateStatus(Long id, Integer status, Long merchantId) {
        CbVehicle entity = Optional.ofNullable(cbVehicleService.getById(id))
                .orElseThrow(() -> new BusinessException(CbCodeEnum.VEHICLE_NOT_FOUND));
        MerchantOwnershipGuard.assertOwnership(entity.getMerchantId(), "车辆", id);
        entity.setStatus(status == null ? null : status.byteValue());
        cbVehicleService.updateById(entity);
    }
}
