package com.cambook.app.service.merchant.impl;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.app.domain.dto.StaffSaveDTO;
import com.cambook.app.service.merchant.IMerchantStaffService;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.PageResult;
import com.cambook.db.entity.CbMerchantStaff;
import com.cambook.db.service.ICbMerchantStaffService;
import lombok.RequiredArgsConstructor;
import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;
import org.springframework.util.DigestUtils;

import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;
import com.cambook.common.enums.CommonStatus;
import com.cambook.common.enums.CbCodeEnum;

/**
 * 商户端 员工管理实现
 */
@Service
@RequiredArgsConstructor
public class MerchantStaffServiceImpl implements IMerchantStaffService {

    private final ICbMerchantStaffService cbMerchantStaffService;

    @Override
    public PageResult<CbMerchantStaff> list(Long merchantId, int page, int size, String keyword, Integer status, Long deptId, Long positionId) {
        Page<CbMerchantStaff> p = cbMerchantStaffService.lambdaQuery()
                .eq(CbMerchantStaff::getMerchantId, merchantId)
                .eq(status != null, CbMerchantStaff::getStatus, status)
                .eq(deptId != null, CbMerchantStaff::getDeptId, deptId)
                .eq(positionId != null, CbMerchantStaff::getPositionId, positionId)
                .and(StringUtils.isNotBlank(keyword), q -> q.like(CbMerchantStaff::getUsername, keyword).or().like(CbMerchantStaff::getRealName, keyword).or().like(CbMerchantStaff::getMobile, keyword).or().like(CbMerchantStaff::getTelegram, keyword))
                .orderByDesc(CbMerchantStaff::getCreateTime).page(new Page<>(page, size));
        List<CbMerchantStaff> records = p.getRecords().stream().peek(s -> s.setPassword(null)).collect(Collectors.toList());
        return PageResult.of(records, p.getTotal(), page, size);
    }

    @Override
    public void add(Long merchantId, StaffSaveDTO dto) {
        boolean usernameExists = cbMerchantStaffService.lambdaQuery()
                .eq(CbMerchantStaff::getMerchantId, merchantId).eq(CbMerchantStaff::getUsername, dto.getUsername()).exists();
        if (usernameExists) throw new BusinessException(CbCodeEnum.DATA_DUPLICATE);
        if (StringUtils.isNotBlank(dto.getMobile())) {
            boolean mobileExists = cbMerchantStaffService.lambdaQuery().eq(CbMerchantStaff::getMobile, dto.getMobile()).exists();
            if (mobileExists) throw new BusinessException(CbCodeEnum.DATA_DUPLICATE);
        }
        if (StringUtils.isBlank(dto.getPassword())) throw new BusinessException(CbCodeEnum.MISSING_PARAM);
        CbMerchantStaff staff = new CbMerchantStaff();
        staff.setMerchantId(merchantId);
        staff.setUsername(dto.getUsername());
        staff.setPassword(DigestUtils.md5DigestAsHex(dto.getPassword().getBytes(StandardCharsets.UTF_8)));
        staff.setRealName(dto.getRealName());
        staff.setMobile(dto.getMobile());
        staff.setTelegram(dto.getTelegram());
        staff.setEmail(dto.getEmail());
        staff.setDeptId(dto.getDeptId());
        staff.setPositionId(dto.getPositionId());
        staff.setRemark(dto.getRemark());
        staff.setStatus(CommonStatus.ENABLED.byteCode());
        cbMerchantStaffService.save(staff);
    }

    @Override
    public void edit(Long merchantId, StaffSaveDTO dto) {
        CbMerchantStaff staff = getAndVerify(dto.getId(), merchantId);
        if (StringUtils.isNotBlank(dto.getPassword())) {
            staff.setPassword(DigestUtils.md5DigestAsHex(dto.getPassword().getBytes(StandardCharsets.UTF_8)));
        }
        if (dto.getRealName() != null) staff.setRealName(dto.getRealName());
        if (StringUtils.isNotBlank(dto.getMobile())) {
            boolean mobileExists = cbMerchantStaffService.lambdaQuery()
                    .eq(CbMerchantStaff::getMobile, dto.getMobile()).ne(CbMerchantStaff::getId, dto.getId()).exists();
            if (mobileExists) throw new BusinessException(CbCodeEnum.DATA_DUPLICATE);
            staff.setMobile(dto.getMobile());
        }
        if (dto.getTelegram()   != null) staff.setTelegram(dto.getTelegram());
        if (dto.getEmail()      != null) staff.setEmail(dto.getEmail());
        staff.setDeptId(dto.getDeptId());
        staff.setPositionId(dto.getPositionId());
        if (dto.getRemark() != null) staff.setRemark(dto.getRemark());
        cbMerchantStaffService.updateById(staff);
    }

    @Override
    public void updateStatus(Long merchantId, Long id, Integer status) {
        CbMerchantStaff staff = getAndVerify(id, merchantId);
        staff.setStatus(status != null ? status.byteValue() : null);
        cbMerchantStaffService.updateById(staff);
    }

    @Override
    public void delete(Long merchantId, Long id) {
        getAndVerify(id, merchantId);
        cbMerchantStaffService.removeById(id);
    }

    private CbMerchantStaff getAndVerify(Long id, Long merchantId) {
        CbMerchantStaff staff = Optional.ofNullable(cbMerchantStaffService.getById(id))
                .orElseThrow(() -> new BusinessException("员工不存在"));
        if (!merchantId.equals(staff.getMerchantId())) throw new BusinessException(CbCodeEnum.NO_PERMISSION);
        return staff;
    }
}
