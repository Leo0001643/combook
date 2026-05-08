package com.cambook.app.service.chat;

import com.baomidou.mybatisplus.extension.service.IService;
import com.cambook.db.entity.ImChatRule;

import java.util.List;
import java.util.Map;

/**
 * IM 通信权限规则服务
 *
 * <p>管理 {@code im_chat_rule} 表。
 * <ul>
 *   <li>merchant_id = 0  ：平台默认规则（种子数据，不可删除）</li>
 *   <li>merchant_id = X  ：商户自定义覆盖规则（可增删改）</li>
 * </ul>
 *
 * <p>决策优先级：商户自定义 → 平台默认 → 代码内置兜底（见 {@code ImPermissionEngine}）。
 */
public interface IImChatRuleService extends IService<ImChatRule> {

    /**
     * 新增或更新商户级规则（幂等）。
     * 更新后调用方应调用 {@code ImPermissionEngine.evictCache(merchantId)}。
     *
     * @param merchantId   商户 ID（必须 &gt; 0，平台默认规则不允许由此接口修改）
     * @param senderRole   发送方角色（ImUserRole name）
     * @param receiverRole 接收方角色
     * @param allowed      true=允许 false=禁止
     */
    void saveRule(Long merchantId, String senderRole, String receiverRole, boolean allowed);

    /**
     * 查询商户自定义规则列表（merchant_id = 指定商户，不含平台默认）。
     */
    List<ImChatRule> listByMerchant(Long merchantId);

    /**
     * 查询平台默认规则（merchant_id = 0）。
     */
    List<ImChatRule> listPlatformDefaults();

    /**
     * 获取商户的完整权限矩阵（商户自定义覆盖平台默认后的最终状态）。
     *
     * <p>返回结构：{senderRole → {receiverRole → allowed(true/false)}}
     */
    Map<String, Map<String, Boolean>> getEffectiveMatrix(Long merchantId);

    /**
     * 删除商户级别的一条自定义规则（回退到平台默认）。
     * 平台默认规则（merchant_id = 0）不允许删除。
     */
    void deleteRule(Long id, Long merchantId);

    /**
     * 清空商户所有自定义规则，全部回退到平台默认。
     */
    void resetToDefault(Long merchantId);
}
