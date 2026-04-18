package com.cambook.dao.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 全平台币种注册表
 *
 * @author CamBook
 */
@TableName("sys_currency")
public class SysCurrency implements Serializable {

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /** 货币代码（ISO 4217）：USD / CNY / USDT / PHP / THB / KRW / AED / MYR */
    private String currencyCode;

    /** 货币中文名 */
    private String currencyName;

    /** 货币英文名 */
    private String currencyNameEn;

    /** 货币符号：$ / ¥ / ₱ / ฿ / ₩ / د.إ / RM / ₮ */
    private String symbol;

    /** 国旗 Emoji */
    private String flag;

    /** 是否加密货币：0=法币 1=加密货币 */
    private Integer isCrypto;

    /** 对 USD 汇率（1 单位本币 = X USD） */
    private BigDecimal rateToUsd;

    /** 汇率最后更新时间 */
    private LocalDateTime rateUpdateTime;

    /** 小数位数（KRW=0, USDT=6） */
    private Integer decimalPlaces;

    /** 排序 */
    private Integer sortOrder;

    /** 状态：0=停用 1=启用 */
    private Integer status;

    /** 备注 */
    private String remark;

    private LocalDateTime createTime;
    private LocalDateTime updateTime;

    // ── Getters & Setters ─────────────────────────────────────────────────────

    public Long getId()                         { return id; }
    public void setId(Long id)                  { this.id = id; }

    public String getCurrencyCode()             { return currencyCode; }
    public void setCurrencyCode(String v)       { this.currencyCode = v; }

    public String getCurrencyName()             { return currencyName; }
    public void setCurrencyName(String v)       { this.currencyName = v; }

    public String getCurrencyNameEn()           { return currencyNameEn; }
    public void setCurrencyNameEn(String v)     { this.currencyNameEn = v; }

    public String getSymbol()                   { return symbol; }
    public void setSymbol(String v)             { this.symbol = v; }

    public String getFlag()                     { return flag; }
    public void setFlag(String v)               { this.flag = v; }

    public Integer getIsCrypto()                { return isCrypto; }
    public void setIsCrypto(Integer v)          { this.isCrypto = v; }

    public BigDecimal getRateToUsd()            { return rateToUsd; }
    public void setRateToUsd(BigDecimal v)      { this.rateToUsd = v; }

    public LocalDateTime getRateUpdateTime()    { return rateUpdateTime; }
    public void setRateUpdateTime(LocalDateTime v) { this.rateUpdateTime = v; }

    public Integer getDecimalPlaces()           { return decimalPlaces; }
    public void setDecimalPlaces(Integer v)     { this.decimalPlaces = v; }

    public Integer getSortOrder()               { return sortOrder; }
    public void setSortOrder(Integer v)         { this.sortOrder = v; }

    public Integer getStatus()                  { return status; }
    public void setStatus(Integer v)            { this.status = v; }

    public String getRemark()                   { return remark; }
    public void setRemark(String v)             { this.remark = v; }

    public LocalDateTime getCreateTime()        { return createTime; }
    public void setCreateTime(LocalDateTime v)  { this.createTime = v; }

    public LocalDateTime getUpdateTime()        { return updateTime; }
    public void setUpdateTime(LocalDateTime v)  { this.updateTime = v; }
}
