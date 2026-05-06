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
 * 支付流水：支持多种支付方式，一次结算可拆分多笔支付
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("cb_payment_record")
public class CbPaymentRecord implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 所属商户 ID
     */
    private Long merchantId;

    /**
     * 关联散客 session ID（散客结算时有值）
     */
    private Long sessionId;

    /**
     * 关联订单 ID（在线预约时有值）
     */
    private Long orderId;

    /**
     * 支付方式：1=现金 2=微信 3=支付宝 4=银行转账 5=USDT 6=ABA Pay 7=Wing 8=其它
     */
    private Byte payMethod;

    /**
     * 本次支付金额
     */
    private BigDecimal amount;

    /**
     * 货币类型：USD/CNY/KHR
     */
    private String currency;

    /**
     * 对 USD 汇率
     */
    private BigDecimal exchangeRate;

    /**
     * 折算 USD 金额
     */
    private BigDecimal usdAmount;

    /**
     * 支付参考号/交易流水（转账凭证号）
     */
    private String referenceNo;

    /**
     * 备注
     */
    private String remark;

    /**
     * 操作员工 ID
     */
    private Long operatorId;

    /**
     * 支付时间（UTC 秒级时间戳）
     */
    private Long payTime;

    /**
     * 创建时间（UTC 秒级时间戳）
     */
    private Long createTime;
}
