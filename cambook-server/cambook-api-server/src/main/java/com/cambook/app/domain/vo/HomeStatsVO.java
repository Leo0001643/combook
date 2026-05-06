package com.cambook.app.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 技师首页今日统计数据
 *
 * <p>收入计算说明：
 * <ul>
 *   <li>平台收取商户 {@code merchant.commission_rate}% 的平台佣金</li>
 *   <li>技师获得订单实付金额的 {@code technician.commission_rate}% 作为实际收入</li>
 *   <li>{@code todayIncome} 即为 {@code cb_order.tech_income} 之和，已扣除全部佣金</li>
 * </ul>
 *
 * @author CamBook
 */
@Data
@Schema(description = "技师首页今日统计")
public class HomeStatsVO {

    @Schema(description = "今日有效订单数（排除待支付/已取消/已退款）")
    private Long todayOrders;

    @Schema(description = "今日已完成订单数（status=6）")
    private Long todayCompleted;

    @Schema(description = "今日全部预约订单数（排除待支付，含进行中/取消）")
    private Long todayAppointments;

    @Schema(description = "今日取消/退款订单数（status 7/8/9）")
    private Long todayCancelled;

    @Schema(description = "今日技师实际收入（USD，已扣除商户佣金与平台佣金）")
    private BigDecimal todayIncome;

    @Schema(description = "今日平均综合评分（1-5，无评价时为 null）")
    private BigDecimal todayRating;
}
