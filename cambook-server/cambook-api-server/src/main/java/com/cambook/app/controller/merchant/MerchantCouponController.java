package com.cambook.app.controller.merchant;

import com.cambook.app.common.annotation.RequireMerchant;
import com.cambook.app.common.security.MerchantOwnershipGuard;
import com.cambook.app.service.biz.CouponService;
import com.cambook.common.result.PageResult;
import com.cambook.common.result.Result;
import com.cambook.db.entity.CbCouponTemplate;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import org.springframework.http.MediaType;

/**
 * 商户端 - 优惠券管理（薄包装层）
 *
 * <p>复用 {@link CouponService}，注入 merchantId 实现数据隔离。
 * {@code @RequireMerchant} 切面自动完成身份 + URI 双重安全校验。
 *
 * @author CamBook
 */
@RequireMerchant
@Tag(name = "商户端 - 优惠券管理")
@RestController
@RequestMapping("/merchant/coupon")
public class MerchantCouponController {

    private final CouponService couponService;

    public MerchantCouponController(CouponService couponService) {
        this.couponService = couponService;
    }

    @Operation(summary = "优惠券列表")
    @GetMapping(value = "/list", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<PageResult<CbCouponTemplate>> list(
            @RequestParam(defaultValue = "1")  int     page,
            @RequestParam(defaultValue = "10") int     size,
            @RequestParam(required = false)    String  keyword,
            @RequestParam(required = false)    Integer type,
            @RequestParam(required = false)    Integer status) {
        return Result.success(couponService.pageList(requireMerchantId(), page, size, keyword, type, status));
    }

    @Operation(summary = "新增优惠券")
    @PostMapping(value = "/add", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> add(@RequestParam String     nameZh,
                            @RequestParam(required = false) String     nameEn,
                            @RequestParam Integer    type,
                            @RequestParam BigDecimal value,
                            @RequestParam BigDecimal minAmount,
                            @RequestParam Integer    totalCount,
                            @RequestParam(required = false) Integer    validDays,
                            @RequestParam(required = false) Long startTime,
                            @RequestParam(required = false) Long endTime) {
        couponService.add(requireMerchantId(), nameZh, nameEn, type, value, minAmount, totalCount, validDays, startTime, endTime);
        return Result.success();
    }

    @Operation(summary = "编辑优惠券")
    @PostMapping(value = "/edit", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> edit(@RequestParam Long       id,
                             @RequestParam(required = false) String     nameZh,
                             @RequestParam(required = false) String     nameEn,
                             @RequestParam(required = false) Integer    type,
                             @RequestParam(required = false) BigDecimal value,
                             @RequestParam(required = false) BigDecimal minAmount,
                             @RequestParam(required = false) Integer    totalCount,
                             @RequestParam(required = false) Integer    validDays,
                             @RequestParam(required = false) Long startTime,
                             @RequestParam(required = false) Long endTime,
                             @RequestParam(required = false) Integer    status) {
        couponService.edit(requireMerchantId(), id, nameZh, nameEn, type, value, minAmount, totalCount, validDays, startTime, endTime, status);
        return Result.success();
    }

    @Operation(summary = "上线/下线优惠券")
    @PostMapping(value = "/status", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> updateStatus(@RequestParam Long id, @RequestParam Integer status) {
        couponService.updateStatus(requireMerchantId(), id, status);
        return Result.success();
    }

    @Operation(summary = "删除优惠券")
    @PostMapping(value = "/delete", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> delete(@RequestParam Long id) {
        couponService.delete(requireMerchantId(), id);
        return Result.success();
    }

    private Long requireMerchantId() {
        return MerchantOwnershipGuard.requireMerchantId();
    }
}
