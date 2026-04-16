package com.cambook.app.controller.merchant;

import com.cambook.app.common.annotation.RequireMerchant;
import com.cambook.app.common.security.MerchantOwnershipGuard;
import com.cambook.app.service.biz.ReviewService;
import com.cambook.common.result.PageResult;
import com.cambook.common.result.Result;
import com.cambook.dao.entity.CbReview;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * 商户端 - 评价管理（薄包装层）
 *
 * <p>复用 {@link ReviewService}，注入 merchantId 实现数据隔离。
 * {@code @RequireMerchant} 切面自动完成身份 + URI 双重安全校验。
 *
 * @author CamBook
 */
@RequireMerchant
@Tag(name = "商户端 - 评价管理")
@RestController
@RequestMapping("/merchant/review")
public class MerchantReviewController {

    private final ReviewService reviewService;

    public MerchantReviewController(ReviewService reviewService) {
        this.reviewService = reviewService;
    }

    @Operation(summary = "评价列表")
    @GetMapping("/list")
    public Result<PageResult<CbReview>> list(
            @RequestParam(defaultValue = "1")  int     page,
            @RequestParam(defaultValue = "10") int     size,
            @RequestParam(required = false)    Long    technicianId,
            @RequestParam(required = false)    Integer overallScore,
            @RequestParam(required = false)    Integer status) {
        return Result.success(reviewService.pageList(requireMerchantId(), page, size, technicianId, overallScore, status));
    }

    @Operation(summary = "评价统计")
    @GetMapping("/stats")
    public Result<Map<String, Object>> stats() {
        return Result.success(reviewService.stats(requireMerchantId()));
    }

    @Operation(summary = "回复评价")
    @PostMapping("/reply")
    public Result<Void> reply(@RequestParam Long id, @RequestParam String reply) {
        reviewService.reply(requireMerchantId(), id, reply);
        return Result.success();
    }

    private Long requireMerchantId() {
        return MerchantOwnershipGuard.requireMerchantId();
    }
}
