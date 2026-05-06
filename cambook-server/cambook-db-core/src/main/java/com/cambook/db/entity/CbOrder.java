package com.cambook.db.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.io.Serializable;
import java.math.BigDecimal;

/**
 * <p>
 * 订单表：核心业务表，含金额快照/状态流转/收益分配，全生命周期记录
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("cb_order")
public class CbOrder implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键，自增
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 订单类型：1=在线预约 2=散客上门
     */
    private Byte orderType;

    /**
     * 服务方式：1=上门服务 2=到店服务
     */
    private Boolean serviceMode;

    /**
     * 散客接待 session ID（order_type=2 时有值），关联 cb_walkin_session.id
     */
    private Long sessionId;

    /**
     * 手环编号（散客上门时的识别号，如 0928）
     */
    private String wristbandNo;

    /**
     * 订单号（业务唯一标识，格式 OD+yyyyMMddHHmmss+6位随机，如 OD20260413153012AB3F21）
     */
    private String orderNo;

    /**
     * 下单会员 ID，关联 cb_member.id
     */
    private Long memberId;

    /**
     * 服务技师 ID，关联 cb_technician.id
     */
    private Long technicianId;

    /**
     * 技师编号快照（上门服务时用于识别身份）
     */
    private String technicianNo;

    /**
     * 技师手机快照
     */
    private String technicianMobile;

    /**
     * 所属商户 ID，独立技师订单为空，关联 cb_merchant.id
     */
    private Long merchantId;

    /**
     * 主服务项ID快照（多服务项订单取第一项，详见 cb_order_item）
     */
    private Long serviceItemId;

    /**
     * 下单时服务项名称快照（防止服务项改名后历史订单名称错乱）
     */
    private String serviceName;

    /**
     * 服务时长快照（分钟，防止服务项修改后历史订单时长变化）
     */
    private Integer serviceDuration;

    /**
     * 服务地址 ID，关联 cb_address.id
     */
    private Long addressId;

    /**
     * 下单时地址详情快照（防止用户后续修改地址）
     */
    private String addressDetail;

    /**
     * 下单时服务地址纬度快照
     */
    private BigDecimal addressLat;

    /**
     * 下单时服务地址经度快照
     */
    private BigDecimal addressLng;

    /**
     * 预约服务开始时间（会员选择的上门时间）（UTC 秒级时间戳）
     */
    private Long appointTime;

    /**
     * 实际开始服务时间（技师操作开始）（UTC 秒级时间戳）
     */
    private Long startTime;

    /**
     * 实际结束服务时间（技师操作完成）（UTC 秒级时间戳）
     */
    private Long endTime;

    /**
     * 原始应付金额（USD，服务单价 × 数量）
     */
    private BigDecimal originalAmount;

    /**
     * 优惠减免金额（USD，含优惠券/活动优惠）
     */
    private BigDecimal discountAmount;

    /**
     * 上门交通费（USD，距离超出一定范围时收取）
     */
    private BigDecimal transportFee;

    /**
     * 实付金额（USD，= original_amount - discount_amount + transport_fee）
     */
    private BigDecimal payAmount;

    /**
     * 使用的优惠券 ID，关联 cb_member_coupon.id，未使用为空
     */
    private Long couponId;

    /**
     * 支付方式：1=ABA Pay 2=USDT 3=钱包余额 4=现金
     */
    private Byte payType;

    /**
     * 组合支付明细 JSON（[{method,currency,amount}]）
     */
    private String payRecords;

    /**
     * 实际支付完成时间（UTC 秒级时间戳）
     */
    private Long payTime;

    /**
     * 技师实际获得收入（USD，= pay_amount × 技师分成比例）
     */
    private BigDecimal techIncome;

    /**
     * 平台实际获得收入（USD，= pay_amount - tech_income - merchant_income）
     */
    private BigDecimal platformIncome;

    /**
     * 订单状态：0=待支付 1=已支付 2=已派单 3=技师前往 4=服务中 5=待评价 6=已完成 7=取消中 8=已取消 9=已退款
     */
    private Byte status;

    /**
     * 取消原因（status=8 时填写）
     */
    private String cancelReason;

    /**
     * 会员下单备注（如有特殊要求）
     */
    private String remark;

    /**
     * 是否已评价：0=未评价 1=已评价
     */
    private Byte isReviewed;

    /**
     * 逻辑删除：0=正常 1=已删除
     */
    private Byte deleted;

    /**
     * 下单时间（UTC 秒级时间戳）
     */
    private Long createTime;

    /**
     * 最后修改时间（UTC 秒级时间戳）
     */
    private Long updateTime;
}
