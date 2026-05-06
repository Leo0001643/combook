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
 * 汇率变动历史：支持查看某币种汇率走势
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("sys_currency_rate_log")
public class SysCurrencyRateLog implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 货币代码
     */
    private String currencyCode;

    /**
     * 对 USD 汇率
     */
    private BigDecimal rateToUsd;

    /**
     * 汇率来源：manual=手动 / api=自动拉取
     */
    private String source;

    /**
     * 记录时间（UTC 秒级时间戳）
     */
    private Long createTime;
}
