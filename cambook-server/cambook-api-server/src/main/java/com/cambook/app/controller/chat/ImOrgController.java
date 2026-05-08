package com.cambook.app.controller.chat;

import com.cambook.app.common.chat.ImPermissionEngine;
import com.cambook.app.domain.dto.chat.ImOrgMemberDTO;
import com.cambook.app.domain.enums.ImUserRole;
import com.cambook.app.service.chat.IImOrgMemberService;
import com.cambook.common.context.MerchantContext;
import com.cambook.common.result.Result;
import com.cambook.db.entity.ImOrgMember;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * IM 组织成员管理接口
 *
 * <p>商户户主 / 平台超管 维护 {@code im_org_member} 表，
 * 为员工分配 IM 角色（MANAGER / OPERATOR / MARKETING 等）。
 */
@Tag(name = "IM 组织架构管理")
@RestController
@RequestMapping("/chat/org")
@RequiredArgsConstructor
public class ImOrgController {

    private final IImOrgMemberService orgMemberService;
    private final ImPermissionEngine  permEngine;

    // ── 查询 ──────────────────────────────────────────────────────────────────

    @Operation(summary = "查询本商户的组织成员列表")
    @GetMapping("/members")
    public Result<List<ImOrgMember>> members() {
        Long merchantId = MerchantContext.getMerchantId();
        return Result.success(orgMemberService.listActive(merchantId));
    }

    // ── 写操作 ─────────────────────────────────────────────────────────────────

    @Operation(summary = "新增/更新组织成员 IM 角色")
    @PostMapping("/member")
    public Result<Void> setMember(@Valid @RequestBody ImOrgMemberDTO dto) {
        Long merchantId = resolveMerchantId();
        ImUserRole role = ImUserRole.fromCode(dto.getImRole());
        if (role == null) return Result.fail(400, "无效的 IM 角色: " + dto.getImRole());

        orgMemberService.upsertRole(dto.getUserType(), dto.getUserId(), merchantId,
            role, dto.getDeptId(), dto.getDisplayName());
        permEngine.evictCache(merchantId);
        return Result.success();
    }

    @Operation(summary = "批量初始化：将所有员工/技师写入组织表（幂等），返回写入/更新行数")
    @PostMapping("/init")
    public Result<Integer> initOrgMembers() {
        Long merchantId = MerchantContext.getMerchantId();
        int count = orgMemberService.syncOrgMembers(merchantId);
        permEngine.evictCache(merchantId);
        return Result.success(count);
    }

    @Operation(summary = "禁用组织成员（软删除）")
    @DeleteMapping("/member/{id}")
    public Result<Void> removeMember(@PathVariable Long id) {
        Long merchantId = resolveMerchantId();
        orgMemberService.disableById(id, merchantId);
        permEngine.evictCache(merchantId);
        return Result.success();
    }

    private Long resolveMerchantId() {
        Long mid = MerchantContext.getMerchantId();
        return mid != null ? mid : 0L;
    }
}
