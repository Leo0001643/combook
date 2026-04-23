package com.cambook.app.service.biz;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.PageResult;
import com.cambook.dao.entity.CbCouponTemplate;
import com.cambook.dao.mapper.CbCouponTemplateMapper;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;

/**
 * 优惠券管理公共服务
 *
 * <p>Admin 和 Merchant 共用同一服务，区别仅在于：
 * <ul>
 *   <li>merchantId = null → Admin：查看/操作平台所有券（或平台通用券）</li>
 *   <li>merchantId = X    → Merchant：仅查看/操作该商户自己的券</li>
 * </ul>
 *
 * @author CamBook
 */
@Service
public class CouponService {

    private final CbCouponTemplateMapper couponMapper;

    public CouponService(CbCouponTemplateMapper couponMapper) {
        this.couponMapper = couponMapper;
    }

    /** 分页列表 */
    public PageResult<CbCouponTemplate> pageList(Long merchantId,
                                                 int page, int size,
                                                 String keyword, Integer type, Integer status) {
        LambdaQueryWrapper<CbCouponTemplate> w = new LambdaQueryWrapper<CbCouponTemplate>()
                .eq(merchantId != null, CbCouponTemplate::getMerchantId, merchantId)
                .like(keyword != null && !keyword.isBlank(), CbCouponTemplate::getNameZh, keyword)
                .eq(type   != null, CbCouponTemplate::getType,   type)
                .eq(status != null, CbCouponTemplate::getStatus, status)
                .orderByDesc(CbCouponTemplate::getCreateTime);

        Page<CbCouponTemplate> p = couponMapper.selectPage(new Page<>(page, size), w);
        return PageResult.of(p.getRecords(), p.getTotal(), page, size);
    }

    /** 新增 */
    public void add(Long merchantId, String nameZh, String nameEn,
                    Integer type, BigDecimal value, BigDecimal minAmount,
                    Integer totalCount, Integer validDays,
                    Long startTime, Long endTime) {
        CbCouponTemplate c = new CbCouponTemplate();
        c.setMerchantId(merchantId);
        c.setNameZh(nameZh);
        c.setNameEn(nameEn);
        c.setType(type);
        c.setValue(value);
        c.setMinAmount(minAmount != null ? minAmount : BigDecimal.ZERO);
        c.setTotalCount(totalCount);
        c.setIssuedCount(0);
        c.setValidDays(validDays);
        c.setStartTime(startTime);
        c.setEndTime(endTime);
        c.setStatus(1);
        couponMapper.insert(c);
    }

    /** 编辑 */
    public void edit(Long merchantId, Long id, String nameZh, String nameEn,
                     Integer type, BigDecimal value, BigDecimal minAmount,
                     Integer totalCount, Integer validDays,
                     Long startTime, Long endTime, Integer status) {
        CbCouponTemplate c = getAndVerify(id, merchantId);
        if (nameZh     != null) c.setNameZh(nameZh);
        if (nameEn     != null) c.setNameEn(nameEn);
        if (type       != null) c.setType(type);
        if (value      != null) c.setValue(value);
        if (minAmount  != null) c.setMinAmount(minAmount);
        if (totalCount != null) c.setTotalCount(totalCount);
        if (validDays  != null) c.setValidDays(validDays);
        if (startTime  != null) c.setStartTime(startTime);
        if (endTime    != null) c.setEndTime(endTime);
        if (status     != null) c.setStatus(status);
        couponMapper.updateById(c);
    }

    /** 更新状态 */
    public void updateStatus(Long merchantId, Long id, Integer status) {
        CbCouponTemplate c = getAndVerify(id, merchantId);
        c.setStatus(status);
        couponMapper.updateById(c);
    }

    /** 删除 */
    public void delete(Long merchantId, Long id) {
        getAndVerify(id, merchantId);
        couponMapper.deleteById(id);
    }

    // ── private ──────────────────────────────────────────────────────────────

    private CbCouponTemplate getAndVerify(Long id, Long merchantId) {
        CbCouponTemplate c = couponMapper.selectById(id);
        if (c == null) throw new BusinessException("优惠券不存在");
        // admin (merchantId=null) 不做商户归属校验
        if (merchantId != null && !merchantId.equals(c.getMerchantId())) {
            throw new BusinessException("无权操作该优惠券");
        }
        return c;
    }
}
