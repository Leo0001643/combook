package com.cambook.app.controller.technician;

import com.cambook.app.domain.vo.HomeStatsVO;
import com.cambook.app.domain.vo.OrderVO;
import com.cambook.app.domain.vo.ScheduleItemVO;
import com.cambook.app.service.technician.ITechHomeService;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import org.springframework.http.MediaType;

/**
 * 技师端首页数据接口
 *
 * <p>所有接口均需 JWT 认证（由 {@code AuthFilter} 拦截 {@code /tech/*}）。
 *
 * @author CamBook
 */
@Tag(name = "技师端 - 首页", description = "今日统计与今日安排")
@RestController
@RequestMapping("/tech/home")
@RequiredArgsConstructor
public class TechHomeController {

    private final ITechHomeService homeService;

    /**
     * 今日统计：订单数、收入（已扣佣金）、平均评分。
     *
     * <p>收入说明：技师实际收入 = 订单实付金额 × 技师分成比例，
     * 平台佣金与商户佣金已在订单完成结算时扣除，此处直接返回净收入。
     */
    @Operation(summary = "今日统计", description = "返回今日有效订单数、技师净收入（USD）、今日平均评分，无评价时 todayRating 为 null")
    @GetMapping(value = "/stats", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<HomeStatsVO> stats() {
        return Result.success(homeService.getStats());
    }

    /**
     * 今日安排列表（按预约时间升序）。
     *
     * <p>仅返回预约时间在今天的有效订单，排除待支付/已取消/已退款。
     * 每条安排项携带完整的服务项明细列表，支持一单多项展示。
     */
    @Operation(summary = "今日安排", description = "返回今日预约列表（含服务项明细），按预约时间升序排列")
    @GetMapping(value = "/schedule", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<ScheduleItemVO>> schedule() {
        return Result.success(homeService.getTodaySchedule());
    }

    /**
     * 待执行预约订单数（用于底部导航 FAB 角标）。
     *
     * <p>返回当前技师状态为"已接单但未开始服务"的订单总数（状态 1-4）。
     */
    @Operation(summary = "待执行订单数", description = "返回角标数量：已支付/接单/前往/到达的订单总数")
    @GetMapping(value = "/pending-count", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Long> pendingCount() {
        return Result.success(homeService.getPendingOrderCount());
    }

    /**
     * 技师端订单列表，支持按状态过滤。
     *
     * <p>状态码（可多选，逗号分隔）：
     * <ul>
     *   <li>1=待接单 2=已接单 3=前往中 4=已到达 5=服务中 6=已完成 7=已取消</li>
     * </ul>
     * 不传 status 则返回全部（排除待支付/退款）。
     */
    @Operation(summary = "技师订单列表", description = "返回技师被分配的在线预约订单，支持按状态过滤，按创建时间倒序")
    @GetMapping(value = "/orders", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<OrderVO>> orders(
            @RequestParam(value = "status", required = false) List<Integer> statuses) {
        return Result.success(homeService.listOrders(statuses));
    }
}
