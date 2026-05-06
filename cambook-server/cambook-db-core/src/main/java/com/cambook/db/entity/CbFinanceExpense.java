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
 * 支出记录：覆盖店租、车辆、水电、工资、采购、营销等全类目
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("cb_finance_expense")
public class CbFinanceExpense implements Serializable {

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
     * 支出单号
     */
    private String expenseNo;

    /**
     * 支出类型：1=店租/场地 2=车辆费用 3=水电费 4=员工工资 5=采购进货 6=营销推广 7=设备维修 8=其它
     */
    private Byte category;

    /**
     * 支出金额（USD）
     */
    private BigDecimal amount;

    /**
     * 原始货币
     */
    private String currency;

    /**
     * 汇率
     */
    private BigDecimal exchangeRate;

    /**
     * 折算 USD 金额
     */
    private BigDecimal usdAmount;

    /**
     * 支付方式：1=现金 2=微信 3=支付宝 4=银行 5=USDT 8=其它
     */
    private Byte payMethod;

    /**
     * 支出标题/摘要
     */
    private String title;

    /**
     * 详细说明
     */
    private String description;

    /**
     * 凭证图片 URL（JSON 数组）
     */
    private String voucherImages;

    /**
     * 支出日期
     */
    private LocalDate expenseDate;

    /**
     * 经办人员工 ID
     */
    private Long operatorId;

    /**
     * 审核人 ID
     */
    private Long approverId;

    /**
     * 状态：0=草稿 1=已确认 2=已作废
     */
    private Byte status;

    /**
     * 创建时间（UTC 秒级时间戳）
     */
    private Long createTime;

    /**
     * 更新时间（UTC 秒级时间戳）
     */
    private Long updateTime;
}
