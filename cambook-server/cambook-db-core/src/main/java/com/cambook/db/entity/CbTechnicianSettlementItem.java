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
 * 技师结算明细：本次结算包含的订单及各自提成
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("cb_technician_settlement_item")
public class CbTechnicianSettlementItem implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 关联结算批次 ID
     */
    private Long settlementId;

    /**
     * 关联订单 ID
     */
    private Long orderId;

    /**
     * 订单号（冗余）
     */
    private String orderNo;

    /**
     * 服务项目名称（冗余）
     */
    private String serviceName;

    /**
     * 订单金额
     */
    private BigDecimal orderAmount;

    /**
     * 本单适用提成比例/金额
     */
    private BigDecimal commissionRate;

    /**
     * 本单提成金额
     */
    private BigDecimal commissionAmount;

    /**
     * 服务时间（UTC 秒级时间戳）
     */
    private Long serviceTime;
}
