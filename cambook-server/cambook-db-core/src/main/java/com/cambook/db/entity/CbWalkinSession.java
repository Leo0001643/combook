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
 * 散客接待 Session：一次到店对应一个 session，手环是识别载体
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("cb_walkin_session")
public class CbWalkinSession implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 接待流水号（系统生成，格式 WK+yyyyMMdd+4位序号）
     */
    private String sessionNo;

    /**
     * 手环编号（前台发放，当日唯一，如 0928）
     */
    private String wristbandNo;

    /**
     * 所属商户 ID
     */
    private Long merchantId;

    /**
     * 关联会员 ID（若客户已注册则关联，散客可为空）
     */
    private Long memberId;

    /**
     * 客户姓名/称呼（散客登记名，可为空）
     */
    private String memberName;

    /**
     * 客户手机号（散客登记，可为空）
     */
    private String memberMobile;

    /**
     * 接待员工 ID
     */
    private Long staffId;

    /**
     * 主责技师 ID（接待时选定）
     */
    private Long technicianId;

    /**
     * 技师姓名快照
     */
    private String technicianName;

    /**
     * 技师编号快照
     */
    private String technicianNo;

    /**
     * 技师手机号快照
     */
    private String technicianMobile;

    /**
     * 状态：0=接待中 1=服务中 2=待结算 3=已结算 4=已取消
     */
    private Byte status;

    /**
     * 消费总金额
     */
    private BigDecimal totalAmount;

    /**
     * 已结算金额
     */
    private BigDecimal paidAmount;

    /**
     * 接待备注
     */
    private String remark;

    /**
     * 签到时间（UTC 秒级时间戳）
     */
    private Long checkInTime;

    /**
     * 技师开始服务的时间戳（Unix 秒），点击"开始服务"时写入
     */
    private Long serviceStartTime;

    /**
     * 签出时间（UTC 秒级时间戳）
     */
    private Long checkOutTime;

    /**
     * 创建时间（UTC 秒级时间戳）
     */
    private Long createTime;

    /**
     * 更新时间（UTC 秒级时间戳）
     */
    private Long updateTime;

    /**
     * 逻辑删除：0正常 1删除
     */
    private Byte deleted;
}
