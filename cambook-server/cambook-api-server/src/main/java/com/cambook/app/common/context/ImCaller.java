package com.cambook.app.common.context;

import com.cambook.common.context.AdminContext;
import com.cambook.common.context.MemberContext;
import com.cambook.common.context.MerchantContext;
import com.cambook.common.exception.BusinessException;

/**
 * IM 调用者身份值对象 — 四端统一上下文解析
 *
 * <pre>
 *   超管端  userType="admin"      userId=AdminContext.getUserId()       merchantId=0
 *   商户端  userType="merchant"   userId=MerchantContext.getMerchantId  merchantId=same
 *   员工端  userType="staff"      userId=MerchantContext.getStaffId     merchantId=MerchantContext.getMerchantId
 *   技师APP userType="technician" userId=MemberContext.getMemberId       merchantId=0
 *   会员APP userType="member"     userId=MemberContext.getMemberId       merchantId=0
 * </pre>
 *
 * <p>用法：{@code ImCaller caller = ImCaller.current();}
 */
public record ImCaller(String userType, Long userId, Long merchantId) {

    /**
     * 从当前请求线程上下文自动解析调用者身份。
     * 优先级：超管 → 商户/员工 → App（技师/会员）
     *
     * @throws BusinessException 四端均未命中（未登录 / Token 失效）
     */
    public static ImCaller current() {
        // 超管端
        Long adminId = AdminContext.getUserId();
        if (adminId != null) {
            return new ImCaller("admin", adminId, 0L);
        }

        // 商户端（含员工子账号）
        if (MerchantContext.isMerchant()) {
            Long mid = MerchantContext.getMerchantId();
            return MerchantContext.isStaff()
                    ? new ImCaller("staff",    MerchantContext.getStaffId(), mid)
                    : new ImCaller("merchant", mid,                          mid);
        }

        // App 端（技师 / 会员）
        String type = MemberContext.getUserType();
        Long   id   = MemberContext.getMemberId();
        if (type != null && id != null) {
            return new ImCaller(type, id, 0L);
        }

        throw new BusinessException("未登录或登录已过期");
    }
}
