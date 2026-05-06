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
 * 钱包主表：记录会员/技师/商户实时余额和统计数据，与流水表联合使用
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("cb_wallet")
public class CbWallet implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键，雪花ID
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 用户ID（关联 cb_member.id）
     */
    private Long memberId;

    /**
     * 用户类型：1-会员  2-技师  3-商户
     */
    private Byte userType;

    /**
     * 当前余额（USD），最小单位0.01
     */
    private BigDecimal balance;

    /**
     * 累计充值总额（USD）
     */
    private BigDecimal totalRecharge;

    /**
     * 累计提现总额（USD）
     */
    private BigDecimal totalWithdraw;

    /**
     * 累计消费总额（USD）
     */
    private BigDecimal totalConsume;

    /**
     * 钱包状态：1-正常  0-冻结
     */
    private Byte status;

    /**
     * 创建时间（UTC 秒级时间戳）
     */
    private Long createdAt;

    /**
     * 最后更新时间（用作乐观锁版本号）（UTC 秒级时间戳）
     */
    private Long updatedAt;

    /**
     * 逻辑删除：0-正常  1-已删
     */
    private Byte deleted;
}
