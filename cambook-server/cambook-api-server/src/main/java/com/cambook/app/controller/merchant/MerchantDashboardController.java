package com.cambook.app.controller.merchant;

import com.cambook.app.domain.vo.DashboardStatsVO;
import com.cambook.app.service.merchant.IMerchantDashboardService;
import com.cambook.common.context.MerchantContext;
import com.cambook.common.result.Result;
import com.cambook.db.entity.CbMerchant;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

/**
 * 商户端 - 数据看板
 *
 * @author CamBook
 */
@Tag(name = "商户端 - 数据看板")
@RestController
@RequestMapping(value = "/merchant/dashboard", produces = MediaType.APPLICATION_JSON_VALUE)
@RequiredArgsConstructor
public class MerchantDashboardController {

    private final IMerchantDashboardService merchantDashboardService;

    @Operation(summary = "综合看板数据（订单 / 营收 / 技师 / 趋势 / 排行）")
    @GetMapping(value = "/stats", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<DashboardStatsVO> stats(@RequestParam(defaultValue = "week") String period) {
        return Result.success(merchantDashboardService.getStats(MerchantContext.getMerchantId(), period));
    }

    @Operation(summary = "获取商户自身基本信息")
    @GetMapping(value = "/profile", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<CbMerchant> profile() {
        return Result.success(merchantDashboardService.getProfile(MerchantContext.getMerchantId()));
    }
}
