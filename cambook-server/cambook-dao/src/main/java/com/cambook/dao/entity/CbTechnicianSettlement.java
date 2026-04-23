package com.cambook.dao.entity;

import lombok.Getter;
import lombok.Setter;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

import java.io.Serializable;
import java.math.BigDecimal;

/**
 * 技师结算批次
 *
 * <p>支持四种结算模式：
 * <ul>
 *   <li>0 = 每笔结算：每完成一单立即生成一条结算记录</li>
 *   <li>1 = 日结：次日批量汇总前一天的订单</li>
 *   <li>2 = 周结：每周一批量汇总上一自然周</li>
 *   <li>3 = 月结：每月 1 日批量汇总上一自然月</li>
 * </ul>
 *
 * @author CamBook
 */
@TableName("cb_technician_settlement")
@Getter
@Setter
public class CbTechnicianSettlement implements Serializable {

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    private Long   merchantId;
    private Long   technicianId;
    private String technicianName;

    /** 结算单号（唯一，系统自动生成） */
    private String settlementNo;

    /** 结算方式：0=每笔 1=日结 2=周结 3=月结 */
    private Integer settlementMode;

    /** 结算周期开始日期 */
    private String periodStart;

    /** 结算周期结束日期 */
    private String periodEnd;

    /** 本批次订单数量 */
    private Integer orderCount;

    /** 本批次总营业额 */
    private BigDecimal totalRevenue;

    /** 提成比例(%) 或固定金额 */
    private BigDecimal commissionRate;

    /** 提成类型：0=按比例 1=固定 */
    private Integer commissionType;

    /** 基础提成金额 */
    private BigDecimal commissionAmount;

    /** 奖励金额 */
    private BigDecimal bonusAmount;

    /** 扣款金额 */
    private BigDecimal deductionAmount;

    /** 最终应付金额 = 提成 + 奖励 - 扣款 */
    private BigDecimal finalAmount;

    /** 结算币种 */
    private String currencyCode;

    /** 货币符号（冗余） */
    private String currencySymbol;

    /** 支付方式：cash / bank / usdt / wechat / ... */
    private String paymentMethod;

    /** 转账 / 流水号 */
    private String paymentRef;

    /** 状态：0=待结算 1=已结算 2=争议/暂扣 */
    private Integer status;

    /** 实际打款时间 */
    private Long paidTime;

    private String remark;
    private String operator;

    private Long createTime;
    private Long updateTime;

    // ── Getters & Setters ─────────────────────────────────────────────────────

}
