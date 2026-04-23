package com.cambook.driver.service.admin.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.PageResult;
import com.cambook.dao.entity.CbDispatchOrder;
import com.cambook.dao.entity.CbDriver;
import com.cambook.dao.entity.CbVehicle;
import com.cambook.dao.mapper.CbDispatchOrderMapper;
import com.cambook.dao.mapper.CbDriverMapper;
import com.cambook.dao.mapper.CbVehicleMapper;
import com.cambook.driver.domain.dto.DispatchDTO;
import com.cambook.driver.domain.dto.DispatchQueryDTO;
import com.cambook.driver.domain.vo.DispatchVO;
import com.cambook.driver.domain.vo.DriverVO;
import com.cambook.driver.domain.vo.VehicleVO;
import com.cambook.driver.service.admin.IDispatchService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * 派车单管理服务实现
 *
 * <p>自动分配策略：优先选择同城、状态"待命"、最近完成派单最少的司机（负载均衡）。
 *
 * @author CamBook
 */
@Service
public class DispatchService implements IDispatchService {

    private final CbDispatchOrderMapper dispatchMapper;
    private final CbDriverMapper        driverMapper;
    private final CbVehicleMapper       vehicleMapper;

    public DispatchService(CbDispatchOrderMapper dispatchMapper,
                           CbDriverMapper driverMapper,
                           CbVehicleMapper vehicleMapper) {
        this.dispatchMapper = dispatchMapper;
        this.driverMapper   = driverMapper;
        this.vehicleMapper  = vehicleMapper;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public DispatchVO create(DispatchDTO dto) {
        CbDispatchOrder dispatch = new CbDispatchOrder();
        dispatch.setDispatchNo("DP" + System.currentTimeMillis() + UUID.randomUUID().toString().substring(0, 4).toUpperCase());
        dispatch.setOrderId(dto.getOrderId());
        dispatch.setPickupLat(dto.getPickupLat());
        dispatch.setPickupLng(dto.getPickupLng());
        dispatch.setDestLat(dto.getDestLat());
        dispatch.setDestLng(dto.getDestLng());
        dispatch.setDestAddress(dto.getDestAddress());
        dispatch.setPickupTime(dto.getPickupTime());
        dispatch.setRemark(dto.getRemark());
        dispatch.setStatus(0);

        // 自动分配司机（如果未手动指定）
        Long driverId = dto.getDriverId();
        if (driverId == null) {
            driverId = autoAssignDriver();
        }
        dispatch.setDriverId(driverId);
        if (driverId != null) {
            CbDriver driver = driverMapper.selectById(driverId);
            if (driver != null) dispatch.setVehicleId(driver.getVehicleId());
        }

        dispatchMapper.insert(dispatch);
        return toVO(dispatch);
    }

    @Override
    public PageResult<DispatchVO> pageList(DispatchQueryDTO query) {
        LambdaQueryWrapper<CbDispatchOrder> wrapper = new LambdaQueryWrapper<CbDispatchOrder>()
                .eq(query.getStatus() != null, CbDispatchOrder::getStatus, query.getStatus())
                .eq(query.getDriverId() != null, CbDispatchOrder::getDriverId, query.getDriverId())
                .orderByDesc(CbDispatchOrder::getCreateTime);

        Page<CbDispatchOrder> p = dispatchMapper.selectPage(new Page<>(query.getPage(), query.getSize()), wrapper);
        List<DispatchVO> records = p.getRecords().stream().map(this::toVO).collect(Collectors.toList());
        return PageResult.of(records, p.getTotal(), query.getPage(), query.getSize());
    }

    @Override
    public DispatchVO getDetail(Long id) {
        CbDispatchOrder d = dispatchMapper.selectById(id);
        if (d == null) throw new BusinessException(CbCodeEnum.DATA_NOT_FOUND);
        return toVO(d);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void assignDriver(Long dispatchId, Long driverId) {
        CbDispatchOrder dispatch = dispatchMapper.selectById(dispatchId);
        if (dispatch == null) throw new BusinessException(CbCodeEnum.DATA_NOT_FOUND);
        if (dispatch.getStatus() != 0) throw new BusinessException(CbCodeEnum.ORDER_STATUS_ILLEGAL);

        CbDriver driver = driverMapper.selectById(driverId);
        if (driver == null) throw new BusinessException(CbCodeEnum.DATA_NOT_FOUND);

        dispatchMapper.update(null,
                new LambdaUpdateWrapper<CbDispatchOrder>()
                        .set(CbDispatchOrder::getDriverId, driverId)
                        .set(CbDispatchOrder::getVehicleId, driver.getVehicleId())
                        .eq(CbDispatchOrder::getId, dispatchId)
        );
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateStatus(Long dispatchId, Integer status) {
        CbDispatchOrder dispatch = dispatchMapper.selectById(dispatchId);
        if (dispatch == null) throw new BusinessException(CbCodeEnum.DATA_NOT_FOUND);

        LambdaUpdateWrapper<CbDispatchOrder> wrapper = new LambdaUpdateWrapper<CbDispatchOrder>()
                .set(CbDispatchOrder::getStatus, status)
                .eq(CbDispatchOrder::getId, dispatchId);

        if (status == 5) {
            wrapper.set(CbDispatchOrder::getFinishTime, System.currentTimeMillis() / 1000L);
        }
        dispatchMapper.update(null, wrapper);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void cancel(Long dispatchId, String reason) {
        dispatchMapper.update(null,
                new LambdaUpdateWrapper<CbDispatchOrder>()
                        .set(CbDispatchOrder::getStatus, 9)
                        .set(CbDispatchOrder::getCancelReason, reason)
                        .eq(CbDispatchOrder::getId, dispatchId)
        );
    }

    // ── 私有 ─────────────────────────────────────────────────────────────────

    /**
     * 自动分配司机：选取待命（onlineStatus=1）且总派单数最少的司机
     */
    private Long autoAssignDriver() {
        List<CbDriver> available = driverMapper.selectList(
                new LambdaQueryWrapper<CbDriver>()
                        .eq(CbDriver::getOnlineStatus, 1)
                        .eq(CbDriver::getStatus, 1)
                        .orderByAsc(CbDriver::getTotalDispatch)
        );
        return available.isEmpty() ? null : available.get(0).getId();
    }

    private DispatchVO toVO(CbDispatchOrder d) {
        DispatchVO vo = new DispatchVO();
        vo.setId(d.getId());
        vo.setDispatchNo(d.getDispatchNo());
        vo.setOrderId(d.getOrderId());
        vo.setPickupLat(d.getPickupLat());
        vo.setPickupLng(d.getPickupLng());
        vo.setDestLat(d.getDestLat());
        vo.setDestLng(d.getDestLng());
        vo.setDestAddress(d.getDestAddress());
        vo.setPickupTime(d.getPickupTime());
        vo.setActualPickupTime(d.getActualPickupTime());
        vo.setFinishTime(d.getFinishTime());
        vo.setStatus(d.getStatus());
        vo.setRemark(d.getRemark());
        vo.setCreateTime(d.getCreateTime());

        if (d.getDriverId() != null) {
            CbDriver driver = driverMapper.selectById(d.getDriverId());
            if (driver != null) {
                DriverVO driverVO = new DriverVO();
                driverVO.setId(driver.getId());
                driverVO.setRealName(driver.getRealName());
                driverVO.setAvatar(driver.getAvatar());
                vo.setDriver(driverVO);
            }
        }
        if (d.getVehicleId() != null) {
            CbVehicle vehicle = vehicleMapper.selectById(d.getVehicleId());
            if (vehicle != null) {
                VehicleVO vehicleVO = new VehicleVO();
                vehicleVO.setId(vehicle.getId());
                vehicleVO.setPlateNumber(vehicle.getPlateNumber());
                vehicleVO.setBrand(vehicle.getBrand());
                vehicleVO.setModel(vehicle.getModel());
                vehicleVO.setColor(vehicle.getColor());
                vo.setVehicle(vehicleVO);
            }
        }
        return vo;
    }
}
