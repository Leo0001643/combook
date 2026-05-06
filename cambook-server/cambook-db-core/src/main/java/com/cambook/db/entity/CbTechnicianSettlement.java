package com.cambook.db.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * <p>
 * 技师结算批次：支持每笔/日结/周结/月结四种方式
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("cb_technician_settlement")
public class CbTechnicianSettlement implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 所属商户 ID
     */
    private Long merchantId;

    /**
     * 技师 ID
     */
    private Long technicianId;

    /**
     * 技师姓名（冗余，防止联表）
     */
    private String technicianName;

    /**
     * 结算单号（唯一）
     */
    private String settlementNo;

    /**
     * 结算方式：0=每笔 1=日结 2=周结 3=月结
     */
    private Byte settlementMode;

    /**
     * 结算周期开始日期
     */
    private LocalDate periodStart;

    /**
     * 结算周期结束日期
     */
    private LocalDate periodEnd;

    /**
     * 本批次订单数量
     */
    private Integer orderCount;

    /**
     * 本批次总营业额
     */
    private BigDecimal totalRevenue;

    /**
     * 提成比例(%) 或 固定金额
     */
    private BigDecimal commissionRate;

    /**
     * 0=按比例 1=固定
     */
    private Byte commissionType;

    /**
     * 基础提成金额
     */
    private BigDecimal commissionAmount;

    /**
     * 奖励金额（好评奖、达标奖等）
     */
    private BigDecimal bonusAmount;

    /**
     * 扣款金额（违规、损耗等）
     */
    private BigDecimal deductionAmount;

    /**
     * 最终应付金额 = 提成+奖励-扣款
     */
    private BigDecimal finalAmount;

    /**
     * 结算币种
     */
    private String currencyCode;

    /**
     * 货币符号（冗余展示）
     */
    private String currencySymbol;

    /**
     * 支付方式：cash/bank/usdt/wechat/...
     */
    private String paymentMethod;

    /**
     * 转账/流水号
     */
    private String paymentRef;

    /**
     * 状态：0=待结算 1=已结算 2=争议/暂扣
     */
    private Byte status;

    /**
     * 打款时间（UTC 秒级时间戳）
     */
    private Long paidTime;

    /**
     * 结算备注
     */
    private String remark;

    /**
     * 操作人
     */
    private String operator;

    /**
     * 创建时间（UTC 秒级时间戳）
     */
    private Long createTime;

    /**
     * 更新时间（UTC 秒级时间戳）
     */
    private Long updateTime;
}
