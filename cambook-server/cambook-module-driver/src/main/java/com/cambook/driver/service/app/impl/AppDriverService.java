package com.cambook.driver.service.app.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.cambook.common.context.MemberContext;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.db.entity.CbDispatchOrder;
import com.cambook.db.entity.CbDriver;
import com.cambook.db.mapper.CbDispatchOrderMapper;
import com.cambook.db.mapper.CbDriverMapper;
import com.cambook.driver.domain.dto.DriverApplyDTO;
import com.cambook.driver.domain.vo.DispatchVO;
import com.cambook.driver.domain.vo.DriverVO;
import com.cambook.driver.service.app.IAppDriverService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * App 端司机服务实现
 *
 * @author CamBook
 */
@Service
public class AppDriverService implements IAppDriverService {

    private final CbDriverMapper        driverMapper;
    private final CbDispatchOrderMapper dispatchMapper;

    public AppDriverService(CbDriverMapper driverMapper,
                            CbDispatchOrderMapper dispatchMapper) {
        this.driverMapper   = driverMapper;
        this.dispatchMapper = dispatchMapper;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void apply(DriverApplyDTO dto) {
        Long memberId = MemberContext.currentId();
        long exists = driverMapper.selectCount(
                new LambdaQueryWrapper<CbDriver>().eq(CbDriver::getMemberId, memberId)
        );
        if (exists > 0) throw new BusinessException(CbCodeEnum.PARAM_ERROR);

        CbDriver driver = new CbDriver();
        driver.setMemberId(memberId);
        driver.setRealName(dto.getRealName());
        driver.setMobile(dto.getMobile());
        driver.setIdCard(dto.getIdCard());
        driver.setDrivingLicenseFront(dto.getDrivingLicenseFront());
        driver.setDrivingLicenseBack(dto.getDrivingLicenseBack());
        driver.setLicenseType(dto.getLicenseType());
        driver.setStatus((byte)0);
        driver.setOnlineStatus((byte)0);
        driver.setTotalDispatch(0);
        driverMapper.insert(driver);
    }

    @Override
    public DriverVO getMyProfile() {
        Long memberId = MemberContext.currentId();
        CbDriver driver = driverMapper.selectOne(
                new LambdaQueryWrapper<CbDriver>().eq(CbDriver::getMemberId, memberId)
        );
        if (driver == null) throw new BusinessException(CbCodeEnum.DATA_NOT_FOUND);
        return toVO(driver);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateOnlineStatus(Integer status) {
        Long memberId = MemberContext.currentId();
        CbDriver driver = driverMapper.selectOne(
                new LambdaQueryWrapper<CbDriver>()
                        .eq(CbDriver::getMemberId, memberId)
                        .eq(CbDriver::getStatus, 1)
        );
        if (driver == null) throw new BusinessException(CbCodeEnum.DATA_NOT_FOUND);

        driverMapper.update(null,
                new LambdaUpdateWrapper<CbDriver>()
                        .set(CbDriver::getOnlineStatus, status)
                        .eq(CbDriver::getId, driver.getId())
        );
    }

    @Override
    public List<DispatchVO> getPendingDispatches() {
        Long memberId = MemberContext.currentId();
        CbDriver driver = driverMapper.selectOne(
                new LambdaQueryWrapper<CbDriver>().eq(CbDriver::getMemberId, memberId)
        );
        if (driver == null) return List.of();

        return dispatchMapper.selectList(
                new LambdaQueryWrapper<CbDispatchOrder>()
                        .eq(CbDispatchOrder::getDriverId, driver.getId())
                        .eq(CbDispatchOrder::getStatus, 0)
        ).stream().map(this::toDispatchVO).collect(Collectors.toList());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void acceptDispatch(Long dispatchId) {
        Long memberId = MemberContext.currentId();
        CbDriver driver = driverMapper.selectOne(
                new LambdaQueryWrapper<CbDriver>().eq(CbDriver::getMemberId, memberId)
        );
        if (driver == null) throw new BusinessException(CbCodeEnum.DATA_NOT_FOUND);

        CbDispatchOrder dispatch = dispatchMapper.selectOne(
                new LambdaQueryWrapper<CbDispatchOrder>()
                        .eq(CbDispatchOrder::getId, dispatchId)
                        .eq(CbDispatchOrder::getDriverId, driver.getId())
        );
        if (dispatch == null || dispatch.getStatus() != 0) {
            throw new BusinessException(CbCodeEnum.ORDER_STATUS_ILLEGAL);
        }

        dispatchMapper.update(null,
                new LambdaUpdateWrapper<CbDispatchOrder>()
                        .set(CbDispatchOrder::getStatus, 1)
                        .eq(CbDispatchOrder::getId, dispatchId)
        );

        // 将司机状态改为执行中
        driverMapper.update(null,
                new LambdaUpdateWrapper<CbDriver>()
                        .set(CbDriver::getOnlineStatus, 2)
                        .eq(CbDriver::getId, driver.getId())
        );
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateLocation(Double lat, Double lng) {
        Long memberId = MemberContext.currentId();
        driverMapper.update(null,
                new LambdaUpdateWrapper<CbDriver>()
                        .set(CbDriver::getCurrentLat, lat)
                        .set(CbDriver::getCurrentLng, lng)
                        .eq(CbDriver::getMemberId, memberId)
        );
    }

    // ── 私有 ─────────────────────────────────────────────────────────────────

    private DriverVO toVO(CbDriver d) {
        DriverVO vo = new DriverVO();
        vo.setId(d.getId());
        vo.setMemberId(d.getMemberId());
        vo.setRealName(d.getRealName());
        vo.setAvatar(d.getAvatar());
        vo.setLicenseType(d.getLicenseType());
        vo.setVehicleId(d.getVehicleId());
        vo.setOnlineStatus(d.getOnlineStatus());
        vo.setStatus(d.getStatus());
        vo.setCurrentLat(d.getCurrentLat());
        vo.setCurrentLng(d.getCurrentLng());
        vo.setTotalDispatch(d.getTotalDispatch());
        vo.setRating(d.getRating());
        return vo;
    }

    private DispatchVO toDispatchVO(CbDispatchOrder d) {
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
        vo.setStatus(d.getStatus());
        vo.setRemark(d.getRemark());
        vo.setCreateTime(d.getCreateTime());
        return vo;
    }
}
