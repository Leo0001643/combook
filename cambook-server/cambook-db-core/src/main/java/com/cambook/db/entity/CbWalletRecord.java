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
 * 钱包流水表：记录会员/技师/商户每笔资金变动，含余额快照
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("cb_wallet_record")
public class CbWalletRecord implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键，自增
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 用户ID
     */
    private Long memberId;

    /**
     * 流水类型:1充值2消费3提现4退款5奖励
     */
    private Byte recordType;

    /**
     * 变动金额（USD，正数=入账/收入，负数=出账/支出）
     */
    private BigDecimal amount;

    /**
     * 变动前余额
     */
    private BigDecimal beforeBalance;

    /**
     * 变动后余额
     */
    private BigDecimal afterBalance;

    /**
     * 业务单号
     */
    private String bizNo;

    /**
     * 流水备注（如 下单消费 / 充值入账 / 手动退款等）
     */
    private String remark;

    /**
     * 流水产生时间（UTC 秒级时间戳）
     */
    private Long createTime;
}
