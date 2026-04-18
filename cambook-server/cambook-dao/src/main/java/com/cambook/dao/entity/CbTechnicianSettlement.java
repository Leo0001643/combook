package com.cambook.dao.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 技师结算批次
 *
 * <p>支持四种结算模式：
 * <ul>
 *   <li>0 = 每笔结算：每完成一单立即生成一条结算记录</li>
 *   <li>1 = 日结：次日批量汇总前一天的订单</li>
 *   <li>2 = 周结：每周一批量汇总上一自然周</li>
 *   <li>3 = 月结：每月 1 日批量汇总上一自然月</li>
 * </ul>
 *
 * @author CamBook
 */
@TableName("cb_technician_settlement")
public class CbTechnicianSettlement implements Serializable {

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    private Long   merchantId;
    private Long   technicianId;
    private String technicianName;

    /** 结算单号（唯一，系统自动生成） */
    private String settlementNo;

    /** 结算方式：0=每笔 1=日结 2=周结 3=月结 */
    private Integer settlementMode;

    /** 结算周期开始日期 */
    private LocalDate periodStart;

    /** 结算周期结束日期 */
    private LocalDate periodEnd;

    /** 本批次订单数量 */
    private Integer orderCount;

    /** 本批次总营业额 */
    private BigDecimal totalRevenue;

    /** 提成比例(%) 或固定金额 */
    private BigDecimal commissionRate;

    /** 提成类型：0=按比例 1=固定 */
    private Integer commissionType;

    /** 基础提成金额 */
    private BigDecimal commissionAmount;

    /** 奖励金额 */
    private BigDecimal bonusAmount;

    /** 扣款金额 */
    private BigDecimal deductionAmount;

    /** 最终应付金额 = 提成 + 奖励 - 扣款 */
    private BigDecimal finalAmount;

    /** 结算币种 */
    private String currencyCode;

    /** 货币符号（冗余） */
    private String currencySymbol;

    /** 支付方式：cash / bank / usdt / wechat / ... */
    private String paymentMethod;

    /** 转账 / 流水号 */
    private String paymentRef;

    /** 状态：0=待结算 1=已结算 2=争议/暂扣 */
    private Integer status;

    /** 实际打款时间 */
    private LocalDateTime paidTime;

    private String remark;
    private String operator;

    private LocalDateTime createTime;
    private LocalDateTime updateTime;

    // ── Getters & Setters ─────────────────────────────────────────────────────

    public Long getId()                            { return id; }
    public void setId(Long id)                     { this.id = id; }

    public Long getMerchantId()                    { return merchantId; }
    public void setMerchantId(Long v)              { this.merchantId = v; }

    public Long getTechnicianId()                  { return technicianId; }
    public void setTechnicianId(Long v)            { this.technicianId = v; }

    public String getTechnicianName()              { return technicianName; }
    public void setTechnicianName(String v)        { this.technicianName = v; }

    public String getSettlementNo()                { return settlementNo; }
    public void setSettlementNo(String v)          { this.settlementNo = v; }

    public Integer getSettlementMode()             { return settlementMode; }
    public void setSettlementMode(Integer v)       { this.settlementMode = v; }

    public LocalDate getPeriodStart()              { return periodStart; }
    public void setPeriodStart(LocalDate v)        { this.periodStart = v; }

    public LocalDate getPeriodEnd()                { return periodEnd; }
    public void setPeriodEnd(LocalDate v)          { this.periodEnd = v; }

    public Integer getOrderCount()                 { return orderCount; }
    public void setOrderCount(Integer v)           { this.orderCount = v; }

    public BigDecimal getTotalRevenue()            { return totalRevenue; }
    public void setTotalRevenue(BigDecimal v)      { this.totalRevenue = v; }

    public BigDecimal getCommissionRate()          { return commissionRate; }
    public void setCommissionRate(BigDecimal v)    { this.commissionRate = v; }

    public Integer getCommissionType()             { return commissionType; }
    public void setCommissionType(Integer v)       { this.commissionType = v; }

    public BigDecimal getCommissionAmount()        { return commissionAmount; }
    public void setCommissionAmount(BigDecimal v)  { this.commissionAmount = v; }

    public BigDecimal getBonusAmount()             { return bonusAmount; }
    public void setBonusAmount(BigDecimal v)       { this.bonusAmount = v; }

    public BigDecimal getDeductionAmount()         { return deductionAmount; }
    public void setDeductionAmount(BigDecimal v)   { this.deductionAmount = v; }

    public BigDecimal getFinalAmount()             { return finalAmount; }
    public void setFinalAmount(BigDecimal v)       { this.finalAmount = v; }

    public String getCurrencyCode()                { return currencyCode; }
    public void setCurrencyCode(String v)          { this.currencyCode = v; }

    public String getCurrencySymbol()              { return currencySymbol; }
    public void setCurrencySymbol(String v)        { this.currencySymbol = v; }

    public String getPaymentMethod()               { return paymentMethod; }
    public void setPaymentMethod(String v)         { this.paymentMethod = v; }

    public String getPaymentRef()                  { return paymentRef; }
    public void setPaymentRef(String v)            { this.paymentRef = v; }

    public Integer getStatus()                     { return status; }
    public void setStatus(Integer v)               { this.status = v; }

    public LocalDateTime getPaidTime()             { return paidTime; }
    public void setPaidTime(LocalDateTime v)       { this.paidTime = v; }

    public String getRemark()                      { return remark; }
    public void setRemark(String v)                { this.remark = v; }

    public String getOperator()                    { return operator; }
    public void setOperator(String v)              { this.operator = v; }

    public LocalDateTime getCreateTime()           { return createTime; }
    public void setCreateTime(LocalDateTime v)     { this.createTime = v; }

    public LocalDateTime getUpdateTime()           { return updateTime; }
    public void setUpdateTime(LocalDateTime v)     { this.updateTime = v; }
}
