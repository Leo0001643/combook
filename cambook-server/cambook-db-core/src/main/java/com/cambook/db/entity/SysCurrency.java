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
 * 币种注册表：平台支持的所有结算货币及实时汇率
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("sys_currency")
public class SysCurrency implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 货币代码（ISO 4217）：USD / CNY / USDT / PHP / THB / KRW / AED / MYR
     */
    private String currencyCode;

    /**
     * 货币中文名：美元 / 人民币 / USDT
     */
    private String currencyName;

    /**
     * 货币英文名：US Dollar / Chinese Yuan
     */
    private String currencyNameEn;

    /**
     * 货币符号：$ / ¥ / ₱ / ฿ / ₩ / د.إ / RM / ₮
     */
    private String symbol;

    /**
     * 国旗 Emoji：?? / ?? / ?? / ?? / ?? / ?? / ??
     */
    private String flag;

    /**
     * 是否加密货币：0=法币 1=加密货币（USDT等）
     */
    private Byte isCrypto;

    /**
     * 对 USD 汇率（1 单位本币 = X USD），USDT=1
     */
    private BigDecimal rateToUsd;

    /**
     * 汇率最后更新时间（UTC 秒级时间戳）
     */
    private Long rateUpdateTime;

    /**
     * 小数位数（KRW=0, USDT=6）
     */
    private Byte decimalPlaces;

    /**
     * 排序（越小越靠前）
     */
    private Integer sortOrder;

    /**
     * 状态：0=停用 1=启用
     */
    private Byte status;

    /**
     * 备注
     */
    private String remark;

    /**
     * 创建时间（UTC 秒级时间戳）
     */
    private Long createTime;

    /**
     * 最后修改时间（UTC 秒级时间戳）
     */
    private Long updateTime;
}
