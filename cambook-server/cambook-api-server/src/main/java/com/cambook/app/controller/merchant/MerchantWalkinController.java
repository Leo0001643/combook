package com.cambook.app.controller.merchant;

import com.cambook.app.domain.dto.WalkinAddItemDTO;
import com.cambook.app.domain.dto.WalkinCreateDTO;
import com.cambook.app.domain.dto.WalkinSettleDTO;
import com.cambook.app.domain.dto.WalkinUpdateDTO;
import com.cambook.app.domain.vo.WalkinItemVO;
import com.cambook.app.domain.vo.WalkinSessionVO;
import com.cambook.app.service.merchant.IMerchantWalkinService;
import com.cambook.common.context.MerchantContext;
import com.cambook.common.result.PageResult;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * 商户端 — 散客接待管理（Walk-in Session）
 *
 * @author CamBook
 */
@Tag(name = "商户端 - 散客接待管理")
@RestController
@RequestMapping(value = "/merchant/walkin", produces = MediaType.APPLICATION_JSON_VALUE)
@RequiredArgsConstructor
public class MerchantWalkinController {

    private final IMerchantWalkinService merchantWalkinService;

    @Operation(summary = "散客接待列表（分页）")
    @GetMapping(value = "/list", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<PageResult<WalkinSessionVO>> list(
            @RequestParam(defaultValue = "1")  int     page,
            @RequestParam(defaultValue = "20") int     size,
            @RequestParam(required = false)    String  keyword,
            @RequestParam(required = false)    Integer status,
            @RequestParam(required = false) @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate date) {
        return Result.success(merchantWalkinService.list(
                MerchantContext.getMerchantId(), page, size, keyword, status, date));
    }

    @Operation(summary = "散客接待详情（含服务项列表）")
    @GetMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<WalkinSessionVO> detail(@PathVariable Long id) {
        return Result.success(merchantWalkinService.getDetail(MerchantContext.getMerchantId(), id));
    }

    @Operation(summary = "新增散客接待")
    @PostMapping(value = "/create", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<WalkinSessionVO> create(@Valid @RequestBody WalkinCreateDTO dto) {
        return Result.success(merchantWalkinService.create(MerchantContext.getMerchantId(), dto));
    }

    @Operation(summary = "新增散客接待（含服务项，原子操作）")
    @PostMapping(value = "/createWithItems", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<WalkinSessionVO> createWithItems(@Valid @RequestBody WalkinCreateDTO dto) {
        return Result.success(merchantWalkinService.createWithItems(MerchantContext.getMerchantId(), dto));
    }

    @Operation(summary = "修改散客接待基本信息")
    @PostMapping(value = "/{id}/update", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> update(@PathVariable Long id, @RequestBody WalkinUpdateDTO dto) {
        merchantWalkinService.update(MerchantContext.getMerchantId(), id, dto);
        return Result.success();
    }

    @Operation(summary = "添加服务项（到 session）")
    @PostMapping(value = "/{id}/addItem", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<WalkinItemVO> addItem(@PathVariable Long id, @Valid @RequestBody WalkinAddItemDTO dto) {
        return Result.success(merchantWalkinService.addItem(MerchantContext.getMerchantId(), id, dto));
    }

    @Operation(summary = "删除服务项")
    @DeleteMapping(value = "/{id}/items/{orderId}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> removeItem(@PathVariable Long id, @PathVariable Long orderId) {
        merchantWalkinService.removeItem(MerchantContext.getMerchantId(), id, orderId);
        return Result.success();
    }

    @Operation(summary = "修改服务项单价")
    @PostMapping(value = "/{id}/items/{orderId}/price", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> updateItemPrice(
            @PathVariable Long id, @PathVariable Long orderId,
            @NotNull @Positive @RequestParam BigDecimal unitPrice) {
        merchantWalkinService.updateItemPrice(MerchantContext.getMerchantId(), id, orderId, unitPrice);
        return Result.success();
    }

    @Operation(summary = "开始服务（设置 start_time，更新状态为服务中）")
    @PostMapping(value = "/{id}/items/{orderId}/start", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> startService(@PathVariable Long id, @PathVariable Long orderId) {
        merchantWalkinService.startService(MerchantContext.getMerchantId(), id, orderId);
        return Result.success();
    }

    @Operation(summary = "结束服务项")
    @PostMapping(value = "/{id}/items/{orderId}/finish", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> finishService(@PathVariable Long id, @PathVariable Long orderId) {
        merchantWalkinService.finishService(MerchantContext.getMerchantId(), id, orderId);
        return Result.success();
    }

    @Operation(summary = "前台结算（收款）")
    @PostMapping(value = "/{id}/settle", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> settle(@PathVariable Long id, @Valid @RequestBody WalkinSettleDTO dto) {
        merchantWalkinService.settle(MerchantContext.getMerchantId(), id, dto);
        return Result.success();
    }

    @Operation(summary = "取消接待")
    @PostMapping(value = "/{id}/cancel", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> cancel(@PathVariable Long id,
                                @RequestParam(required = false) String reason) {
        merchantWalkinService.cancel(MerchantContext.getMerchantId(), id, reason);
        return Result.success();
    }
}
