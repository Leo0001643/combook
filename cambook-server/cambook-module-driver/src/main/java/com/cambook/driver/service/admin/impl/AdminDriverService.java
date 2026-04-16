package com.cambook.driver.service.admin.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.PageResult;
import com.cambook.dao.entity.CbDriver;
import com.cambook.dao.mapper.CbDriverMapper;
import com.cambook.driver.domain.dto.DriverAuditDTO;
import com.cambook.driver.domain.dto.DriverQueryDTO;
import com.cambook.driver.domain.vo.DriverVO;
import com.cambook.driver.service.admin.IAdminDriverService;
import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Admin 端司机管理服务实现
 *
 * @author CamBook
 */
@Service
public class AdminDriverService implements IAdminDriverService {

    private final CbDriverMapper driverMapper;

    public AdminDriverService(CbDriverMapper driverMapper) {
        this.driverMapper = driverMapper;
    }

    @Override
    public PageResult<DriverVO> pageList(DriverQueryDTO query) {
        LambdaQueryWrapper<CbDriver> wrapper = new LambdaQueryWrapper<CbDriver>()
                .like(StringUtils.isNotBlank(query.getRealName()), CbDriver::getRealName, query.getRealName())
                .eq(query.getStatus() != null, CbDriver::getStatus, query.getStatus())
                .eq(query.getOnlineStatus() != null, CbDriver::getOnlineStatus, query.getOnlineStatus())
                .orderByDesc(CbDriver::getCreateTime);

        Page<CbDriver> p = driverMapper.selectPage(new Page<>(query.getPage(), query.getSize()), wrapper);
        List<DriverVO> records = p.getRecords().stream().map(this::toVO).collect(Collectors.toList());
        return PageResult.of(records, p.getTotal(), query.getPage(), query.getSize());
    }

    @Override
    public DriverVO getDetail(Long id) {
        CbDriver driver = driverMapper.selectById(id);
        if (driver == null) throw new BusinessException(CbCodeEnum.DATA_NOT_FOUND);
        return toVO(driver);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void audit(DriverAuditDTO dto) {
        CbDriver driver = driverMapper.selectById(dto.getId());
        if (driver == null) throw new BusinessException(CbCodeEnum.DATA_NOT_FOUND);

        int auditStatus = dto.getStatus() != null ? dto.getStatus() : 0;
        driverMapper.update(null,
                new LambdaUpdateWrapper<CbDriver>()
                        .set(CbDriver::getStatus, auditStatus)
                        .set(auditStatus == 2, CbDriver::getRejectReason, dto.getRejectReason())
                        .eq(CbDriver::getId, dto.getId())
        );
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void bindVehicle(Long driverId, Long vehicleId) {
        driverMapper.update(null,
                new LambdaUpdateWrapper<CbDriver>()
                        .set(CbDriver::getVehicleId, vehicleId)
                        .eq(CbDriver::getId, driverId)
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
}
