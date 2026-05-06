package com.cambook.app.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * 商户端数据看板 VO
 *
 * @author CamBook
 */
@Data
@Schema(description = "商户端数据看板统计")
public class DashboardStatsVO {

    // ── 订单计数 ──────────────────────────────────────────────────────────────
    @Schema(description = "总订单数")                 private long totalOrders;
    @Schema(description = "今日订单数")               private long todayOrders;
    @Schema(description = "本周订单数")               private long weekOrders;
    @Schema(description = "本月订单数")               private long monthOrders;
    @Schema(description = "昨日订单数（环比）")        private long yestOrders;
    @Schema(description = "上周订单数（环比）")        private long lastWeekOrders;
    @Schema(description = "上月订单数（环比）")        private long lastMonthOrders;

    // ── 营收 ──────────────────────────────────────────────────────────────────
    @Schema(description = "总营收")                   private BigDecimal totalRevenue;
    @Schema(description = "商户净收入（扣除平台服务费）") private BigDecimal merchantRevenue;
    @Schema(description = "今日营收")                 private BigDecimal todayRevenue;
    @Schema(description = "本周营收")                 private BigDecimal weekRevenue;
    @Schema(description = "本月营收")                 private BigDecimal monthRevenue;
    @Schema(description = "昨日营收（环比）")          private BigDecimal yestRevenue;
    @Schema(description = "上周营收（环比）")          private BigDecimal lastWeekRevenue;
    @Schema(description = "上月营收（环比）")          private BigDecimal lastMonthRevenue;
    @Schema(description = "客均消费")                 private BigDecimal avgOrderValue;

    // ── 技师 ──────────────────────────────────────────────────────────────────
    @Schema(description = "技师总人数")               private long technicianCount;
    @Schema(description = "在职技师数")               private long activeTechCount;
    @Schema(description = "在线技师数")               private long onlineTechCount;
    @Schema(description = "服务中技师数")             private long servingTechCount;

    // ── 商户信息 ──────────────────────────────────────────────────────────────
    @Schema(description = "账户余额")                 private BigDecimal balance;
    @Schema(description = "平台佣金率")               private BigDecimal commissionRate;
    @Schema(description = "商户名称")                 private String merchantName;

    // ── 图表数据 ──────────────────────────────────────────────────────────────
    @Schema(description = "订单状态分布（key=状态码, value=数量）")
    private Map<Integer, Long> statusDistribution;

    @Schema(description = "趋势数据（按 period 维度）")
    private List<TrendPointVO> trend;

    @Schema(description = "技师排行 TOP8")
    private List<TechRankItemVO> techRank;
}
