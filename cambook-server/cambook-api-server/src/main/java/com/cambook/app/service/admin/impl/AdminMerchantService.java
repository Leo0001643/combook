package com.cambook.app.service.admin.impl;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.app.domain.dto.MerchantCreateDTO;
import com.cambook.app.service.admin.IAdminMerchantService;
import com.cambook.common.enums.AuditStatusEnum;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.enums.CommonStatus;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.PageResult;
import com.cambook.common.utils.DateUtils;
import com.cambook.db.entity.CbMerchant;
import com.cambook.db.service.ICbMerchantService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.DigestUtils;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.util.Optional;

/**
 * Admin 商户管理服务实现
 */
@Service
@RequiredArgsConstructor
public class AdminMerchantService implements IAdminMerchantService {

    private static final int BUSINESS_TYPE_DEFAULT = 1;

    private final ICbMerchantService cbMerchantService;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public CbMerchant create(MerchantCreateDTO dto) {
        if (cbMerchantService.lambdaQuery().eq(CbMerchant::getMobile, dto.getMobile()).exists())
            throw new BusinessException(CbCodeEnum.DATA_DUPLICATE);
        CbMerchant m = new CbMerchant();
        m.setMerchantNo("M" + DateUtils.todayStr("yyyyMMdd") + String.format("%06d", (int)(Math.random() * 999999)));
        m.setMobile(dto.getMobile());
        m.setUsername(dto.getUsername());
        m.setPassword(DigestUtils.md5DigestAsHex((dto.getPassword() != null ? dto.getPassword() : "123456").getBytes(StandardCharsets.UTF_8)));
        m.setMerchantNameZh(dto.getMerchantNameZh());
        m.setMerchantNameEn(dto.getMerchantNameEn());
        m.setContactPerson(dto.getContactPerson());
        m.setContactMobile(dto.getContactMobile());
        m.setCity(dto.getCity());
        m.setAddressZh(dto.getAddressZh());
        m.setBusinessScope(dto.getBusinessScope());
        m.setBusinessArea(dto.getBusinessArea());
        m.setBusinessLicenseNo(dto.getBusinessLicenseNo());
        m.setBusinessLicensePic(dto.getBusinessLicensePic());
        m.setLogo(dto.getLogo());
        m.setPhotos(dto.getPhotos());
        m.setBusinessType(dto.getBusinessType() != null ? dto.getBusinessType().byteValue() : (byte) BUSINESS_TYPE_DEFAULT);
        m.setCommissionRate(dto.getCommissionRate());
        m.setAuditStatus(AuditStatusEnum.PASS.byteCode());
        m.setStatus(CommonStatus.ENABLED.byteCode());
        cbMerchantService.save(m);
        return m;
    }

    @Override
    public PageResult<CbMerchant> page(int current, int size, String keyword, String city, Integer status, Integer auditStatus) {
        var page = cbMerchantService.lambdaQuery()
                .and(keyword != null && !keyword.isBlank(), q -> q.like(CbMerchant::getMerchantNameZh, keyword).or().like(CbMerchant::getMobile, keyword).or().like(CbMerchant::getContactPerson, keyword))
                .eq(city != null && !city.isBlank(), CbMerchant::getCity, city)
                .eq(status != null, CbMerchant::getStatus, status).eq(auditStatus != null, CbMerchant::getAuditStatus, auditStatus)
                .orderByDesc(CbMerchant::getCreateTime).page(new Page<>(current, size));
        return PageResult.of(page);
    }

    @Override
    public CbMerchant detail(Long id) {
        return Optional.ofNullable(cbMerchantService.getById(id)).orElseThrow(() -> new BusinessException(CbCodeEnum.MERCHANT_NOT_FOUND));
    }

    @Override
    public void updateStatus(Long id, Integer status) {
        if (!cbMerchantService.lambdaUpdate().set(CbMerchant::getStatus, status).eq(CbMerchant::getId, id).update())
            throw new BusinessException(CbCodeEnum.MERCHANT_NOT_FOUND);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void audit(Long id, Integer auditStatus, String rejectReason) {
        CbMerchant m = Optional.ofNullable(cbMerchantService.getById(id)).orElseThrow(() -> new BusinessException(CbCodeEnum.MERCHANT_NOT_FOUND));
        m.setAuditStatus(auditStatus != null ? auditStatus.byteValue() : null);
        if (rejectReason != null) m.setRejectReason(rejectReason);
        cbMerchantService.updateById(m);
    }

    @Override
    public void updateCommission(Long id, BigDecimal commissionRate) {
        if (!cbMerchantService.lambdaUpdate().set(CbMerchant::getCommissionRate, commissionRate).eq(CbMerchant::getId, id).update())
            throw new BusinessException(CbCodeEnum.MERCHANT_NOT_FOUND);
    }

    @Override
    public void delete(Long id) {
        cbMerchantService.removeById(id);
    }
}
