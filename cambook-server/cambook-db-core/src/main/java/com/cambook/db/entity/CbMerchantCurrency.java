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
 * 商户币种配置：每家商户可独立启用不同结算货币，支持自定义汇率
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("cb_merchant_currency")
public class CbMerchantCurrency implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 商户 ID，关联 cb_merchant.id
     */
    private Long merchantId;

    /**
     * 货币代码，关联 sys_currency.currency_code
     */
    private String currencyCode;

    /**
     * 是否默认收款币种：0=否 1=是（每个商户只能有一个默认）
     */
    private Byte isDefault;

    /**
     * 商户自定义汇率（优先级高于 sys_currency.rate_to_usd，为空则用全局汇率）
     */
    private BigDecimal customRate;

    /**
     * 商户自定义显示名（如 空=使用全局名）
     */
    private String displayName;

    /**
     * 商户侧排序
     */
    private Integer sortOrder;

    /**
     * 状态：0=停用 1=启用
     */
    private Byte status;

    /**
     * 创建时间（UTC 秒级时间戳）
     */
    private Long createTime;

    /**
     * 最后修改时间（UTC 秒级时间戳）
     */
    private Long updateTime;
}
