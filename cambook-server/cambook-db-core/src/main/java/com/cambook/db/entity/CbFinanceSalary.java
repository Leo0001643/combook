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
 * 薪资单：覆盖员工工资和技师提成，支持按月汇总发放
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("cb_finance_salary")
public class CbFinanceSalary implements Serializable {

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
     * 薪资月份（格式 yyyy-MM）
     */
    private String salaryMonth;

    /**
     * 员工 ID（关联 sys_user 或技师）
     */
    private Long staffId;

    /**
     * 人员类型：1=员工 2=技师
     */
    private Byte staffType;

    /**
     * 姓名快照
     */
    private String staffName;

    /**
     * 基本工资（USD）
     */
    private BigDecimal baseSalary;

    /**
     * 提成金额（USD，技师按订单分成）
     */
    private BigDecimal commission;

    /**
     * 绩效奖金（USD）
     */
    private BigDecimal bonus;

    /**
     * 扣款（USD，迟到/违规等）
     */
    private BigDecimal deduction;

    /**
     * 实发工资（USD，= base_salary + commission + bonus - deduction）
     */
    private BigDecimal totalAmount;

    /**
     * 本月完成订单数（技师）
     */
    private Integer orderCount;

    /**
     * 本月服务营收（技师）
     */
    private BigDecimal orderRevenue;

    /**
     * 发薪方式：1=现金 2=银行 3=USDT
     */
    private Byte payMethod;

    /**
     * 发薪时间（UTC 秒级时间戳）
     */
    private Long payTime;

    /**
     * 状态：0=待发放 1=已发放 2=已作废
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
     * 更新时间（UTC 秒级时间戳）
     */
    private Long updateTime;
}
