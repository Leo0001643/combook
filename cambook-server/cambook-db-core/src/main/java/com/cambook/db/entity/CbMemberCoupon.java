package com.cambook.db.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.io.Serializable;

/**
 * <p>
 * 会员持有优惠券表：记录领取和使用状态，关联模板
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("cb_member_coupon")
public class CbMemberCoupon implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键，自增
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 持有会员 ID，关联 cb_member.id
     */
    private Long memberId;

    /**
     * 优惠券模板 ID，关联 cb_coupon_template.id
     */
    private Long templateId;

    /**
     * 使用状态：0=未使用 1=已使用 2=已过期
     */
    private Byte status;

    /**
     * 使用时关联的订单号（status=1时填写，关联 cb_order.order_no）
     */
    private String useOrderNo;

    /**
     * 实际使用时间（status=1时填写）（UTC 秒级时间戳）
     */
    private Long useTime;

    /**
     * 过期时间（根据模板 valid_days 或 end_time 计算后写入）（UTC 秒级时间戳）
     */
    private Long expireTime;

    /**
     * 领取时间（UTC 秒级时间戳）
     */
    private Long createTime;
}
