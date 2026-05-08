package com.cambook.app.controller.chat;

import com.cambook.app.common.chat.ImPermissionEngine;
import com.cambook.app.domain.dto.chat.ImChatRuleDTO;
import com.cambook.app.domain.enums.ImUserRole;
import com.cambook.app.domain.vo.chat.ImPermMatrixVO;
import com.cambook.app.service.chat.IImChatRuleService;
import com.cambook.common.context.MerchantContext;
import com.cambook.common.result.Result;
import com.cambook.db.entity.ImChatRule;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Arrays;
import java.util.List;
import java.util.Map;

/**
 * IM 通信权限规则管理接口
 *
 * <p>商户管理员可在此覆盖平台默认的角色通信权限矩阵。
 * 决策优先级：商户自定义 → 平台默认。
 */
@Tag(name = "IM 通信权限规则管理")
@RestController
@RequestMapping("/chat/rules")
@RequiredArgsConstructor
public class ImChatRuleController {

    private final IImChatRuleService ruleService;
    private final ImPermissionEngine permEngine;

    // ── 查询 ──────────────────────────────────────────────────────────────────

    @Operation(summary = "当前商户的自定义规则列表")
    @GetMapping
    public Result<List<ImChatRule>> list() {
        Long merchantId = MerchantContext.getMerchantId();
        return Result.success(ruleService.listByMerchant(merchantId));
    }

    @Operation(summary = "平台默认规则列表（merchant_id=0）")
    @GetMapping("/platform")
    public Result<List<ImChatRule>> platformDefaults() {
        return Result.success(ruleService.listPlatformDefaults());
    }

    @Operation(summary = "权限矩阵（含商户覆盖的最终生效状态，用于前端九宫格渲染）")
    @GetMapping("/matrix")
    public Result<ImPermMatrixVO> matrix() {
        Long merchantId = MerchantContext.getMerchantId();
        Map<String, Map<String, Boolean>> effectiveMatrix = ruleService.getEffectiveMatrix(merchantId);
        List<ImChatRule> customs = ruleService.listByMerchant(merchantId);
        return Result.success(new ImPermMatrixVO(effectiveMatrix, customs));
    }

    @Operation(summary = "所有可用的 IM 角色列表（供前端下拉选择）")
    @GetMapping("/roles")
    public Result<List<String>> roles() {
        List<String> roleNames = Arrays.stream(ImUserRole.values())
            .map(Enum::name)
            .toList();
        return Result.success(roleNames);
    }

    // ── 写操作 ─────────────────────────────────────────────────────────────────

    @Operation(summary = "新增或更新商户自定义权限规则（幂等）")
    @PostMapping("/rule")
    public Result<Void> saveRule(@Valid @RequestBody ImChatRuleDTO dto) {
        Long merchantId = MerchantContext.getMerchantId();
        ImUserRole sender   = ImUserRole.fromCode(dto.getSenderRole());
        ImUserRole receiver = ImUserRole.fromCode(dto.getReceiverRole());
        if (sender == null)   return Result.fail(400, "无效发送方角色: " + dto.getSenderRole());
        if (receiver == null) return Result.fail(400, "无效接收方角色: " + dto.getReceiverRole());

        ruleService.saveRule(merchantId, sender.name(), receiver.name(), dto.isAllowed());
        permEngine.evictCache(merchantId);
        return Result.success();
    }

    @Operation(summary = "删除商户自定义规则（回退为平台默认）")
    @DeleteMapping("/rule/{id}")
    public Result<Void> deleteRule(@PathVariable Long id) {
        Long merchantId = MerchantContext.getMerchantId();
        ruleService.deleteRule(id, merchantId);
        permEngine.evictCache(merchantId);
        return Result.success();
    }

    @Operation(summary = "重置商户所有自定义规则（全部回退平台默认）")
    @PostMapping("/reset")
    public Result<Void> reset() {
        Long merchantId = MerchantContext.getMerchantId();
        ruleService.resetToDefault(merchantId);
        permEngine.evictCache(merchantId);
        return Result.success();
    }
}
