package com.cambook.app.service.chat.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.cambook.app.service.chat.IImChatRuleService;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.utils.DateUtils;
import com.cambook.db.entity.ImChatRule;
import com.cambook.db.mapper.ImChatRuleMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * IM 通信权限规则服务实现
 *
 * <p>有效矩阵决策：优先取商户自定义规则，缺失时回退至平台默认（merchant_id = 0）。
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ImChatRuleServiceImpl extends ServiceImpl<ImChatRuleMapper, ImChatRule> implements IImChatRuleService {

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void saveRule(Long merchantId, String senderRole, String receiverRole, boolean allowed) {
        if (merchantId == null || merchantId <= 0) {
            throw new BusinessException("不允许直接修改平台默认规则");
        }
        long now = DateUtils.nowSecond();
        byte allowedByte = allowed ? (byte) 1 : (byte) 0;

        ImChatRule existing = lambdaQuery()
        .eq(ImChatRule::getMerchantId,  merchantId).eq(ImChatRule::getSenderRole,   senderRole)
        .eq(ImChatRule::getReceiverRole, receiverRole).one();

        if (existing != null) {
            existing.setAllowed(allowedByte);
            existing.setUpdateTime(now);
            updateById(existing);
        } else {
            ImChatRule rule = new ImChatRule();
            rule.setMerchantId(merchantId);
            rule.setSenderRole(senderRole);
            rule.setReceiverRole(receiverRole);
            rule.setAllowed(allowedByte);
            rule.setCreateTime(now);
            rule.setUpdateTime(now);
            save(rule);
        }
        log.info("[ChatRule] 商户={} {}→{} allowed={}", merchantId, senderRole, receiverRole, allowed);
    }

    @Override
    public List<ImChatRule> listByMerchant(Long merchantId) {
        return lambdaQuery().eq(ImChatRule::getMerchantId, merchantId).orderByAsc(ImChatRule::getSenderRole)
            .orderByAsc(ImChatRule::getReceiverRole).list();
    }

    @Override
    public List<ImChatRule> listPlatformDefaults() {
        return lambdaQuery().eq(ImChatRule::getMerchantId, 0L).orderByAsc(ImChatRule::getSenderRole)
                .orderByAsc(ImChatRule::getReceiverRole).list();
    }

    @Override
    public Map<String, Map<String, Boolean>> getEffectiveMatrix(Long merchantId) {
        // 基础层：平台默认规则
        List<ImChatRule> defaults = listPlatformDefaults();

        // 覆盖层：商户自定义规则
        List<ImChatRule> customs = merchantId != null && merchantId > 0
        ? listByMerchant(merchantId) : List.of();

        // 合并：商户规则覆盖平台默认
        Map<String, Map<String, Boolean>> matrix = new HashMap<>();
        for (ImChatRule r : defaults) {
            matrix.computeIfAbsent(r.getSenderRole(), k -> new HashMap<>())
            .put(r.getReceiverRole(), r.getAllowed() == 1);
        }
        for (ImChatRule r : customs) {
            matrix.computeIfAbsent(r.getSenderRole(), k -> new HashMap<>())
            .put(r.getReceiverRole(), r.getAllowed() == 1);
        }
        return matrix;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteRule(Long id, Long merchantId) {
        ImChatRule rule = getById(id);
        if (rule == null) return;
        if (rule.getMerchantId() == 0L) {
            throw new BusinessException("平台默认规则不可删除");
        }
        if (!rule.getMerchantId().equals(merchantId)) {
            throw new BusinessException("无权删除其他商户规则");
        }
        removeById(id);
        log.info("[ChatRule] 删除商户={} 规则 id={}", merchantId, id);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void resetToDefault(Long merchantId) {
        if (merchantId == null || merchantId <= 0) return;
        long removed = lambdaQuery().eq(ImChatRule::getMerchantId, merchantId).count();
        lambdaUpdate().eq(ImChatRule::getMerchantId, merchantId).remove();
        log.info("[ChatRule] 商户={} 重置规则，清除 {} 条自定义规则", merchantId, removed);
    }
}
