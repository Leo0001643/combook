package com.cambook.dao.entity;

import lombok.Getter;
import lombok.Setter;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

import java.io.Serializable;
import java.math.BigDecimal;

/**
 * 技师结算明细：本次结算批次包含的每一笔订单
 *
 * @author CamBook
 */
@TableName("cb_technician_settlement_item")
@Getter
@Setter
public class CbTechnicianSettlementItem implements Serializable {

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    private Long   settlementId;
    private Long   orderId;
    private String orderNo;
    private String serviceName;

    /** 订单金额 */
    private BigDecimal orderAmount;

    /** 本单适用提成比例(%) 或 固定金额 */
    private BigDecimal commissionRate;

    /** 本单提成金额 */
    private BigDecimal commissionAmount;

    private Long serviceTime;

    // ── Getters & Setters ─────────────────────────────────────────────────────

    public Long getId()                           { return id; }
    public void setId(Long id)                    { this.id = id; }

    public Long getSettlementId()                 { return settlementId; }
    public void setSettlementId(Long v)           { this.settlementId = v; }

    public Long getOrderId()                      { return orderId; }
    public void setOrderId(Long v)                { this.orderId = v; }

    public String getOrderNo()                    { return orderNo; }
    public void setOrderNo(String v)              { this.orderNo = v; }

    public String getServiceName()                { return serviceName; }
    public void setServiceName(String v)          { this.serviceName = v; }

    public BigDecimal getOrderAmount()            { return orderAmount; }
    public void setOrderAmount(BigDecimal v)      { this.orderAmount = v; }

    public BigDecimal getCommissionRate()         { return commissionRate; }
    public void setCommissionRate(BigDecimal v)   { this.commissionRate = v; }

    public BigDecimal getCommissionAmount()       { return commissionAmount; }

    public Long getServiceTime()         { return serviceTime; }
    public void setServiceTime(Long v)   { this.serviceTime = v; }
}
