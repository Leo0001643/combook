package com.cambook.db.service.impl;

import com.cambook.db.entity.CbCouponTemplate;
import com.cambook.db.mapper.CbCouponTemplateMapper;
import com.cambook.db.service.ICbCouponTemplateService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 优惠券模板表：定义券类型/面值/门槛/有效期，支持限量发放 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class CbCouponTemplateServiceImpl extends ServiceImpl<CbCouponTemplateMapper, CbCouponTemplate> implements ICbCouponTemplateService {

}
