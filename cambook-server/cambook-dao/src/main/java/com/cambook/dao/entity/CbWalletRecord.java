package com.cambook.dao.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 钱包流水实体
 * 注：cb_wallet_record 无逻辑删除，不继承 BaseEntity
 */
@TableName("cb_wallet_record")
public class CbWalletRecord implements Serializable {

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    private Long       memberId;
    /** 流水类型：1-充值  2-消费  3-提现  4-退款  5-奖励 */
    private Integer    recordType;
    private BigDecimal amount;
    private BigDecimal beforeBalance;
    private BigDecimal afterBalance;
    private String     bizNo;
    private String     remark;
    private LocalDateTime createTime;

    public Long       getId()                   { return id; }
    public void       setId(Long v)             { this.id = v; }
    public Long       getMemberId()             { return memberId; }
    public void       setMemberId(Long v)       { this.memberId = v; }
    public Integer    getRecordType()           { return recordType; }
    public void       setRecordType(Integer v)  { this.recordType = v; }
    public BigDecimal getAmount()               { return amount; }
    public void       setAmount(BigDecimal v)   { this.amount = v; }
    public BigDecimal getBeforeBalance()        { return beforeBalance; }
    public void       setBeforeBalance(BigDecimal v){ this.beforeBalance = v; }
    public BigDecimal getAfterBalance()         { return afterBalance; }
    public void       setAfterBalance(BigDecimal v){ this.afterBalance = v; }
    public String     getBizNo()                { return bizNo; }
    public void       setBizNo(String v)        { this.bizNo = v; }
    public String     getRemark()               { return remark; }
    public void       setRemark(String v)       { this.remark = v; }
    public LocalDateTime getCreateTime()        { return createTime; }
    public void       setCreateTime(LocalDateTime v){ this.createTime = v; }
}
