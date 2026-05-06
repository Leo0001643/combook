package com.cambook.app.controller.admin;

import com.cambook.app.service.biz.CouponService;
import com.cambook.common.annotation.RequirePermission;
import com.cambook.common.result.PageResult;
import com.cambook.common.result.Result;
import com.cambook.db.entity.CbCouponTemplate;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import org.springframework.http.MediaType;

/**
 * Admin 端 - 优惠券管理
 * 委托 {@link CouponService} 统一处理，merchantId=null 表示平台级数据。
 */
@Tag(name = "Admin - 优惠券管理")
@RestController
@RequestMapping("/admin/coupon")
public class CouponController {

    private final CouponService couponService;

    public CouponController(CouponService couponService) {
        this.couponService = couponService;
    }

    @RequirePermission("coupon:list")
    @Operation(summary = "优惠券分页列表")
    @GetMapping(value = "/list", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<PageResult<CbCouponTemplate>> list(
            @RequestParam(defaultValue = "1")  int     current,
            @RequestParam(defaultValue = "10") int     size,
            @RequestParam(required = false)    String  keyword,
            @RequestParam(required = false)    Integer type,
            @RequestParam(required = false)    Integer status,
            @RequestParam(required = false)    Long    merchantId) {
        return Result.success(couponService.pageList(merchantId, current, size, keyword, type, status));
    }

    @RequirePermission("coupon:add")
    @Operation(summary = "新增优惠券")
    @PostMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> add(@RequestParam String nameZh,
                            @RequestParam(required = false) String nameEn,
                            @RequestParam Integer type,
                            @RequestParam BigDecimal value,
                            @RequestParam(defaultValue = "0") BigDecimal minAmount,
                            @RequestParam Integer totalCount,
                            @RequestParam(required = false) Integer validDays,
                            @RequestParam(required = false) Long startTime,
                            @RequestParam(required = false) Long endTime) {
        couponService.add(null, nameZh, nameEn, type, value, minAmount, totalCount, validDays,
                startTime, endTime);
        return Result.success();
    }

    @RequirePermission("coupon:edit")
    @Operation(summary = "修改优惠券")
    @PutMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> edit(@RequestParam Long id,
                             @RequestParam(required = false) String nameZh,
                             @RequestParam(required = false) String nameEn,
                             @RequestParam(required = false) Integer type,
                             @RequestParam(required = false) BigDecimal value,
                             @RequestParam(required = false) BigDecimal minAmount,
                             @RequestParam(required = false) Integer totalCount,
                             @RequestParam(required = false) Integer validDays,
                             @RequestParam(required = false) Long startTime,
                             @RequestParam(required = false) Long endTime,
                             @RequestParam(required = false) Integer status) {
        couponService.edit(null, id, nameZh, nameEn, type, value, minAmount, totalCount, validDays,
                startTime, endTime, status);
        return Result.success();
    }

    @RequirePermission("coupon:edit")
    @Operation(summary = "修改状态")
    @PatchMapping(value = "/{id}/status", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> updateStatus(@PathVariable Long id, @RequestParam Integer status) {
        couponService.updateStatus(null, id, status);
        return Result.success();
    }

    @RequirePermission("coupon:delete")
    @Operation(summary = "删除优惠券")
    @DeleteMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> delete(@PathVariable Long id) {
        couponService.delete(null, id);
        return Result.success();
    }
}
