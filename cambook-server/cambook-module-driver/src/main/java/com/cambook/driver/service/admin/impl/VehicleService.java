package com.cambook.driver.service.admin.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.dao.entity.CbVehicle;
import com.cambook.dao.mapper.CbVehicleMapper;
import com.cambook.driver.domain.dto.VehicleDTO;
import com.cambook.driver.domain.vo.VehicleVO;
import com.cambook.driver.service.admin.IVehicleService;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

/**
 * 车辆管理服务实现
 *
 * @author CamBook
 */
@Service
public class VehicleService implements IVehicleService {

    private final CbVehicleMapper vehicleMapper;

    public VehicleService(CbVehicleMapper vehicleMapper) {
        this.vehicleMapper = vehicleMapper;
    }

    @Override
    public List<VehicleVO> listAll() {
        return vehicleMapper.selectList(null)
                .stream().map(this::toVO).collect(Collectors.toList());
    }

    @Override
    public void add(VehicleDTO dto) {
        long exists = vehicleMapper.selectCount(
                new LambdaQueryWrapper<CbVehicle>().eq(CbVehicle::getPlateNumber, dto.getPlateNumber())
        );
        if (exists > 0) throw new BusinessException(CbCodeEnum.PARAM_ERROR);

        CbVehicle vehicle = new CbVehicle();
        vehicle.setPlateNumber(dto.getPlateNumber());
        vehicle.setBrand(dto.getBrand());
        vehicle.setModel(dto.getModel());
        vehicle.setColor(dto.getColor());
        vehicle.setSeats(dto.getSeats());
        vehicle.setInspectionExpiry(dto.getInspectionExpiry());
        vehicle.setPhoto(dto.getPhoto());
        vehicle.setRemark(dto.getRemark());
        vehicle.setStatus(0);
        vehicleMapper.insert(vehicle);
    }

    @Override
    public void edit(VehicleDTO dto) {
        CbVehicle vehicle = vehicleMapper.selectById(dto.getId());
        if (vehicle == null) throw new BusinessException(CbCodeEnum.DATA_NOT_FOUND);

        vehicle.setPlateNumber(dto.getPlateNumber());
        vehicle.setBrand(dto.getBrand());
        vehicle.setModel(dto.getModel());
        vehicle.setColor(dto.getColor());
        vehicle.setSeats(dto.getSeats());
        vehicle.setInspectionExpiry(dto.getInspectionExpiry());
        vehicle.setPhoto(dto.getPhoto());
        vehicle.setRemark(dto.getRemark());
        vehicleMapper.updateById(vehicle);
    }

    @Override
    public void delete(Long id) {
        vehicleMapper.deleteById(id);
    }

    @Override
    public List<VehicleVO> listIdle() {
        return vehicleMapper.selectList(
                new LambdaQueryWrapper<CbVehicle>().eq(CbVehicle::getStatus, 0)
        ).stream().map(this::toVO).collect(Collectors.toList());
    }

    // ── 私有 ─────────────────────────────────────────────────────────────────

    private VehicleVO toVO(CbVehicle v) {
        VehicleVO vo = new VehicleVO();
        vo.setId(v.getId());
        vo.setPlateNumber(v.getPlateNumber());
        vo.setBrand(v.getBrand());
        vo.setModel(v.getModel());
        vo.setColor(v.getColor());
        vo.setSeats(v.getSeats());
        vo.setPhoto(v.getPhoto());
        vo.setInspectionExpiry(v.getInspectionExpiry());
        vo.setStatus(v.getStatus());
        return vo;
    }
}
