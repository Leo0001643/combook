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
 * 优惠券模板表：定义券类型/面值/门槛/有效期，支持限量发放
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("cb_coupon_template")
public class CbCouponTemplate implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键，自增
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 所属商户ID
     */
    private Long merchantId;

    /**
     * 优惠券名称（中文，如 新人专享立减$10）
     */
    private String nameZh;

    /**
     * 优惠券名称（英文）
     */
    private String nameEn;

    /**
     * 优惠券名称（越南文）
     */
    private String nameVi;

    /**
     * 优惠券名称（柬埔寨文）
     */
    private String nameKm;

    /**
     * 券类型：1=现金满减券（满 min_amount 减 value 元）2=折扣券（折扣比例 value，如 0.8=8折）3=免交通费券
     */
    private Byte type;

    /**
     * 优惠值（type=1 时为减免金额 USD，type=2 时为折扣率如 0.80，type=3 时为 0）
     */
    private BigDecimal value;

    /**
     * 使用门槛（订单实付金额需满足此金额才可使用，0=无门槛）
     */
    private BigDecimal minAmount;

    /**
     * 总发放数量（-1=不限量，>=1=有限量）
     */
    private Integer totalCount;

    /**
     * 已发放数量（每次领取时 +1，用于限量控制）
     */
    private Integer issuedCount;

    /**
     * 领取后有效天数（如 30=领取起30天内有效，与 start/end_time 二选一）
     */
    private Integer validDays;

    /**
     * 绝对有效期开始时间（与 valid_days 二选一）（UTC 秒级时间戳）
     */
    private Long startTime;

    /**
     * 绝对有效期结束时间（与 valid_days 二选一）（UTC 秒级时间戳）
     */
    private Long endTime;

    /**
     * 状态：1=启用（可领取）0=停用
     */
    private Byte status;

    /**
     * 逻辑删除：0=正常 1=已删除
     */
    private Byte deleted;

    /**
     * 创建时间（UTC 秒级时间戳）
     */
    private Long createTime;

    /**
     * 最后修改时间（UTC 秒级时间戳）
     */
    private Long updateTime;
}
