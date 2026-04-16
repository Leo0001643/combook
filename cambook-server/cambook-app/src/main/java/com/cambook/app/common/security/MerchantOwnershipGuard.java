package com.cambook.app.common.security;

import com.cambook.common.context.MerchantContext;
import com.cambook.common.exception.BusinessException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * 商户数据归属校验工具（行级安全）
 *
 * <p>所有商户端的单记录操作（查详情、修改、删除）在确定目标数据后
 * 必须通过此工具验证数据归属，防止 IDOR（越权访问）攻击。
 *
 * <p>设计为静态工具类，可在 Service 层和 Controller 层直接调用，
 * 不引入额外依赖。
 *
 * @author CamBook
 */
public final class MerchantOwnershipGuard {

    private static final Logger log = LoggerFactory.getLogger(MerchantOwnershipGuard.class);

    private MerchantOwnershipGuard() {}

    /**
     * 从 ThreadLocal 获取当前商户 ID，若无则抛出认证异常。
     *
     * @return 当前已认证商户 ID（永不为 null）
     */
    public static Long requireMerchantId() {
        Long id = MerchantContext.getMerchantId();
        if (id == null) {
            throw new BusinessException("商户身份校验失败，请重新登录");
        }
        return id;
    }

    /**
     * 严格校验记录是否属于当前商户（行级安全）。
     *
     * <p>此方法是防止 IDOR（Insecure Direct Object References）的核心防线。
     * 攻击者即使知道其他商户的记录 ID，也无法通过此验证。
     *
     * @param resourceMerchantId 记录所属商户 ID（从数据库读取）
     * @param resourceType       资源类型描述（用于日志）
     * @param resourceId         资源主键 ID（用于日志）
     * @throws BusinessException 若记录不存在或不属于当前商户
     */
    public static void assertOwnership(Long resourceMerchantId,
                                        String resourceType,
                                        Object resourceId) {
        Long currentMerchantId = requireMerchantId();

        if (resourceMerchantId == null || !currentMerchantId.equals(resourceMerchantId)) {
            // 记录安全告警日志（不向客户端暴露内部信息）
            log.warn("[MerchantSecurity] IDOR attempt blocked! merchantId={} tried to access {}[id={}] owned by merchantId={}",
                    currentMerchantId, resourceType, resourceId, resourceMerchantId);
            // 统一返回"不存在"，不暴露"有记录但无权限"的信息差
            throw new BusinessException(resourceType + "不存在");
        }
    }

    /**
     * 校验记录存在且属于当前商户的简化版本（resource 不为 null 时调用）。
     *
     * @param resource           从数据库查询到的实体（null 视为不存在）
     * @param resourceMerchantId 实体上的 merchantId 字段值
     * @param resourceType       资源类型描述
     * @param resourceId         资源主键 ID
     */
    public static void assertOwnershipNonNull(Object resource,
                                              Long resourceMerchantId,
                                              String resourceType,
                                              Object resourceId) {
        if (resource == null) {
            throw new BusinessException(resourceType + "不存在");
        }
        assertOwnership(resourceMerchantId, resourceType, resourceId);
    }
}
