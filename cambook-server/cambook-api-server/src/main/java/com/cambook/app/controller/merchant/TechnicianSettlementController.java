package com.cambook.app.controller.merchant;

import com.cambook.app.domain.dto.*;
import com.cambook.app.domain.vo.*;
import com.cambook.app.service.merchant.IMerchantSettlementService;
import com.cambook.common.context.MerchantContext;
import com.cambook.common.result.Result;
import com.cambook.db.entity.CbTechnicianSettlement;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 商户端 — 技师结算管理
 *
 * @author CamBook
 */
@Tag(name = "Merchant - 技师结算")
@RestController
@RequestMapping(value = "/merchant/settlement", produces = MediaType.APPLICATION_JSON_VALUE)
@RequiredArgsConstructor
public class TechnicianSettlementController {

    private final IMerchantSettlementService merchantSettlementService;

    @Operation(summary = "结算列表（分页）")
    @GetMapping(value = "/list", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<SettlementListVO> list(
            @RequestParam(defaultValue = "1")  int     page,
            @RequestParam(defaultValue = "20") int     size,
            @RequestParam(required = false)    Long    technicianId,
            @RequestParam(required = false)    Integer settlementMode,
            @RequestParam(required = false)    Integer status,
            @RequestParam(required = false)    String  startDate,
            @RequestParam(required = false)    String  endDate) {
        return Result.success(merchantSettlementService.list(
                MerchantContext.getMerchantId(), page, size, technicianId, settlementMode, status, startDate, endDate));
    }

    @Operation(summary = "结算单详情")
    @GetMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<SettlementDetailVO> detail(@PathVariable Long id) {
        return Result.success(merchantSettlementService.detail(MerchantContext.getMerchantId(), id));
    }

    @Operation(summary = "某技师的统计摘要（用于侧边快查）")
    @GetMapping(value = "/summary/{technicianId}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<TechnicianSummaryVO> technicianSummary(@PathVariable Long technicianId) {
        return Result.success(merchantSettlementService.technicianSummary(MerchantContext.getMerchantId(), technicianId));
    }

    @Operation(summary = "手动生成结算单")
    @PostMapping(value = "/generate", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<CbTechnicianSettlement> generate(@Valid @RequestBody SettlementGenerateDTO dto) {
        return Result.success(merchantSettlementService.generate(MerchantContext.getMerchantId(), dto));
    }

    @Operation(summary = "标记已打款（确认结算）")
    @PatchMapping(value = "/{id}/pay", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> markPaid(@PathVariable Long id, @RequestBody SettlementPayDTO dto) {
        merchantSettlementService.markPaid(MerchantContext.getMerchantId(), id, dto);
        return Result.success();
    }

    @Operation(summary = "调整结算金额（奖励 / 扣款）")
    @PatchMapping(value = "/{id}/adjust", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> adjust(@PathVariable Long id, @RequestBody SettlementAdjustDTO dto) {
        merchantSettlementService.adjust(MerchantContext.getMerchantId(), id, dto);
        return Result.success();
    }

    @Operation(summary = "撤销结算（回退为待结算）")
    @PatchMapping(value = "/{id}/revoke", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> revoke(@PathVariable Long id) {
        merchantSettlementService.revoke(MerchantContext.getMerchantId(), id);
        return Result.success();
    }

    @Operation(summary = "批量打款（按 ID 列表）")
    @PostMapping(value = "/batch-pay", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> batchPay(@Valid @RequestBody SettlementBatchPayDTO dto) {
        merchantSettlementService.batchPay(MerchantContext.getMerchantId(), dto);
        return Result.success();
    }

    @Operation(summary = "获取可生成的结算周期建议列表")
    @GetMapping(value = "/suggest-periods", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<SuggestPeriodVO>> suggestPeriods(
            @NotNull @RequestParam Long    technicianId,
            @NotNull @RequestParam Integer settlementMode) {
        return Result.success(merchantSettlementService.suggestPeriods(technicianId, settlementMode));
    }
}
