package com.cambook.dao.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 技师结算明细：本次结算批次包含的每一笔订单
 *
 * @author CamBook
 */
@TableName("cb_technician_settlement_item")
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

    private LocalDateTime serviceTime;

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
    public void setCommissionAmount(BigDecimal v) { this.commissionAmount = v; }

    public LocalDateTime getServiceTime()         { return serviceTime; }
    public void setServiceTime(LocalDateTime v)   { this.serviceTime = v; }
}
