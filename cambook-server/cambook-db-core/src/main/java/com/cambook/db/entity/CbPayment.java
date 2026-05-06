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
 * 支付记录表：记录每次支付行为，保存三方回调原始报文，用于对账
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("cb_payment")
public class CbPayment implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键，自增
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 支付单号（平台内部唯一，格式 PAY+时间戳+随机）
     */
    private String paymentNo;

    /**
     * 关联订单号，对应 cb_order.order_no
     */
    private String orderNo;

    /**
     * 支付会员 ID，关联 cb_member.id
     */
    private Long memberId;

    /**
     * 支付方式：1=ABA Pay 2=USDT 3=钱包余额 4=现金
     */
    private Byte payType;

    /**
     * 支付渠道标识（三方渠道代码，如 ABA / BINANCE_PAY）
     */
    private String payChannel;

    /**
     * 支付金额（USD）
     */
    private BigDecimal amount;

    /**
     * 货币类型（ISO 4217，如 USD / KHR）
     */
    private String currency;

    /**
     * 三方支付平台交易流水号（用于对账，ABA/USDT 回调时写入）
     */
    private String thirdTradeNo;

    /**
     * 三方支付平台原始回调报文（JSON，保留完整用于事后对账和纠纷处理）
     */
    private String notifyData;

    /**
     * 支付状态：0=待支付 1=支付成功 2=支付失败 3=已退款
     */
    private Byte status;

    /**
     * 退款金额（USD，部分退款时填写实际退款额）
     */
    private BigDecimal refundAmount;

    /**
     * 退款完成时间（UTC 秒级时间戳）
     */
    private Long refundTime;

    /**
     * 支付记录创建时间（UTC 秒级时间戳）
     */
    private Long createTime;

    /**
     * 最后修改时间（UTC 秒级时间戳）
     */
    private Long updateTime;
}
