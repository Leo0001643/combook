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
 * 提成规则配置：商户可设置不同技师群体的提成模板
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("cb_commission_rule")
public class CbCommissionRule implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 商户 ID（0=平台默认）
     */
    private Long merchantId;

    /**
     * 规则名称
     */
    private String ruleName;

    /**
     * 默认结算方式
     */
    private Byte settlementMode;

    /**
     * 0=按比例 1=固定金额
     */
    private Byte commissionType;

    /**
     * 提成比例(%) 或 固定金额
     */
    private BigDecimal commissionValue;

    /**
     * 固定金额时的币种
     */
    private String currencyCode;

    /**
     * 奖励达标门槛（月营业额超过此值触发奖励）
     */
    private BigDecimal bonusThreshold;

    /**
     * 奖励金额
     */
    private BigDecimal bonusAmount;

    /**
     * 是否商户默认规则
     */
    private Byte isDefault;

    private Byte status;

    private String remark;

    /**
     * 创建时间（UTC 秒级时间戳）
     */
    private Long createTime;

    /**
     * 更新时间（UTC 秒级时间戳）
     */
    private Long updateTime;
}
