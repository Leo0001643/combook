package com.cambook.app.controller.admin;

import com.cambook.app.service.biz.ReviewService;
import com.cambook.common.annotation.RequirePermission;
import com.cambook.common.result.PageResult;
import com.cambook.common.result.Result;
import com.cambook.db.entity.CbReview;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.MediaType;

/**
 * Admin 端 - 评价管理
 * 委托 {@link ReviewService} 统一处理，merchantId=null 表示平台级全量数据。
 */
@Tag(name = "Admin - 评价管理")
@RestController
@RequestMapping("/admin/review")
public class ReviewController {

    private final ReviewService reviewService;

    public ReviewController(ReviewService reviewService) {
        this.reviewService = reviewService;
    }

    @RequirePermission("review:list")
    @Operation(summary = "评价分页列表")
    @GetMapping(value = "/list", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<PageResult<CbReview>> list(
            @RequestParam(defaultValue = "1")  int     current,
            @RequestParam(defaultValue = "10") int     size,
            @RequestParam(required = false)    Long    technicianId,
            @RequestParam(required = false)    Integer overallScore,
            @RequestParam(required = false)    Integer status) {
        return Result.success(reviewService.pageList(null, current, size, technicianId, overallScore, status));
    }

    @RequirePermission("review:edit")
    @Operation(summary = "屏蔽/恢复评价")
    @PatchMapping(value = "/{id}/status", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> updateStatus(@PathVariable Long id, @RequestParam Integer status) {
        reviewService.updateStatus(id, status);
        return Result.success();
    }

    @RequirePermission("review:delete")
    @Operation(summary = "删除评价")
    @DeleteMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> delete(@PathVariable Long id) {
        reviewService.delete(id);
        return Result.success();
    }
}
