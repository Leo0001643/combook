package com.cambook.dao.entity;

import lombok.Getter;
import lombok.Setter;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

import java.io.Serializable;
import java.math.BigDecimal;

/**
 * 商户币种配置：每家商户可独立启用不同结算货币
 *
 * @author CamBook
 */
@TableName("cb_merchant_currency")
@Getter
@Setter
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

    private Long createTime;
    private Long updateTime;

    // ── Getters & Setters ─────────────────────────────────────────────────────

    public void setCreateTime(Long v){ this.createTime = v; }

    public void setUpdateTime(Long v){ this.updateTime = v; }
}
