package com.cambook.app.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.List;

import static com.cambook.app.domain.vo.OrderVO.OrderItemVO;

/**
 * 今日安排列表项
 *
 * <p>用于技师首页"今日安排"时间轴展示，支持一单多项。
 * 时间字段统一使用 UTC 秒级时间戳，客户端按设备本地时区自行转换，避免多国时区歧义。
 *
 * @author CamBook
 */
@Data
@Schema(description = "今日安排列表项")
public class ScheduleItemVO {

    @Schema(description = "订单 ID（在线订单为 cb_order.id；门店订单为 cb_walkin_session.id）")
    private Long orderId;

    @Schema(description = "订单号")
    private String orderNo;

    /**
     * 订单来源类型：
     * <ul>
     *   <li>1 = 在线预约订单（cb_order, order_type=1）</li>
     *   <li>2 = 门店散客订单（cb_walkin_session）</li>
     * </ul>
     * Flutter 端可据此决定点击跳转的详情页路由。
     */
    @Schema(description = "订单来源：1=在线预约 2=门店散客")
    private int orderType = 1;

    @Schema(description = "预约服务时间（UTC 秒级时间戳，客户端按本地时区显示）")
    private Long appointTime;

    /**
     * 订单状态（原始值）：
     * 0=待支付 1=已支付 2=已派单 3=技师前往 4=服务中 5=待评价 6=已完成 7=取消中 8=已取消 9=已退款
     */
    @Schema(description = "订单状态原始值（见枚举说明）")
    private Integer status;

    @Schema(description = "实付金额（USD）")
    private BigDecimal payAmount;

    @Schema(description = "技师实际收入（USD，已扣除佣金）")
    private BigDecimal techIncome;

    @Schema(description = "客户昵称")
    private String memberNickname;

    @Schema(description = "客户头像 URL")
    private String memberAvatar;

    @Schema(description = "服务项明细列表（一单多项）")
    private List<OrderItemVO> items = Collections.emptyList();

    @Schema(description = "服务项总数")
    private int itemCount;

    @Schema(description = "合计服务总时长（分钟，所有项目 duration × qty 之和）")
    private int totalDuration;

    // ── 兼容旧字段（当 items 为空时 fallback 展示）─────────────────────────

    @Schema(description = "首个服务项名称（兼容旧版单项展示）")
    private String serviceName;

    @Schema(description = "首个服务项时长（兼容旧版单项展示）")
    private Integer serviceDuration;
}
