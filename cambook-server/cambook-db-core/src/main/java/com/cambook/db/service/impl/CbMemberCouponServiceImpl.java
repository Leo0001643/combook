package com.cambook.db.service.impl;

import com.cambook.db.entity.CbMemberCoupon;
import com.cambook.db.mapper.CbMemberCouponMapper;
import com.cambook.db.service.ICbMemberCouponService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 会员持有优惠券表：记录领取和使用状态，关联模板 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class CbMemberCouponServiceImpl extends ServiceImpl<CbMemberCouponMapper, CbMemberCoupon> implements ICbMemberCouponService {

}
