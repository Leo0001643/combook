package com.cambook.dao.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 商户币种配置：每家商户可独立启用不同结算货币
 *
 * @author CamBook
 */
@TableName("cb_merchant_currency")
public class CbMerchantCurrency implements Serializable {

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /** 商户 ID */
    private Long merchantId;

    /** 货币代码，关联 sys_currency.currency_code */
    private String currencyCode;

    /** 是否默认收款币种：0=否 1=是 */
    private Integer isDefault;

    /** 商户自定义汇率（优先级高于全局汇率，为 null 则用全局） */
    private BigDecimal customRate;

    /** 商户自定义显示名（为空则用全局名） */
    private String displayName;

    /** 商户侧排序 */
    private Integer sortOrder;

    /** 状态：0=停用 1=启用 */
    private Integer status;

    private LocalDateTime createTime;
    private LocalDateTime updateTime;

    // ── Getters & Setters ─────────────────────────────────────────────────────

    public Long getId()                       { return id; }
    public void setId(Long id)               { this.id = id; }

    public Long getMerchantId()              { return merchantId; }
    public void setMerchantId(Long v)        { this.merchantId = v; }

    public String getCurrencyCode()          { return currencyCode; }
    public void setCurrencyCode(String v)    { this.currencyCode = v; }

    public Integer getIsDefault()            { return isDefault; }
    public void setIsDefault(Integer v)      { this.isDefault = v; }

    public BigDecimal getCustomRate()        { return customRate; }
    public void setCustomRate(BigDecimal v)  { this.customRate = v; }

    public String getDisplayName()           { return displayName; }
    public void setDisplayName(String v)     { this.displayName = v; }

    public Integer getSortOrder()            { return sortOrder; }
    public void setSortOrder(Integer v)      { this.sortOrder = v; }

    public Integer getStatus()               { return status; }
    public void setStatus(Integer v)         { this.status = v; }

    public LocalDateTime getCreateTime()     { return createTime; }
    public void setCreateTime(LocalDateTime v){ this.createTime = v; }

    public LocalDateTime getUpdateTime()     { return updateTime; }
    public void setUpdateTime(LocalDateTime v){ this.updateTime = v; }
}
