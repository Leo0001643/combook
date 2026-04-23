package com.cambook.dao.entity;

import lombok.Getter;
import lombok.Setter;

import com.baomidou.mybatisplus.annotation.*;
import io.swagger.v3.oas.annotations.media.Schema;

import java.io.Serializable;
import java.math.BigDecimal;

/**
 * 钱包主表实体
 * cb_wallet 使用 created_at / updated_at 命名，独立覆盖 BaseEntity
 */
@TableName("cb_wallet")
@Getter
@Setter
public class CbWallet implements Serializable {

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    private Long       memberId;
    /** 用户类型：1-会员  2-技师  3-商户 */
    private Integer    userType;
    private BigDecimal balance;
    private BigDecimal totalRecharge;
    private BigDecimal totalWithdraw;
    private BigDecimal totalConsume;
    private Integer    status;

    @TableField(value = "created_at", fill = FieldFill.INSERT)
    @Schema(description = "创建时间")
    private Long createdAt;

    @TableField(value = "updated_at", fill = FieldFill.INSERT_UPDATE)
    @Schema(description = "更新时间")
    private Long updatedAt;

    @TableLogic
    @TableField(value = "deleted")
    private Integer deleted;

    public Long       getId()                   { return id; }
    public void       setId(Long v)             { this.id = v; }
    public Long       getMemberId()             { return memberId; }
    public void       setMemberId(Long v)       { this.memberId = v; }
    public Integer    getUserType()             { return userType; }
    public void       setUserType(Integer v)    { this.userType = v; }
    public void       setBalance(BigDecimal v)  { this.balance = v; }
    public void       setTotalRecharge(BigDecimal v){ this.totalRecharge = v; }
    public void       setTotalWithdraw(BigDecimal v){ this.totalWithdraw = v; }
    public void       setTotalConsume(BigDecimal v){ this.totalConsume = v; }
    public Integer    getStatus()               { return status; }
    public void       setStatus(Integer v)      { this.status = v; }
    public Long       getCreatedAt()            { return createdAt; }
    public Long       getUpdatedAt()            { return updatedAt; }
    public Integer    getDeleted()              { return deleted; }
}
