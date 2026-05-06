package com.cambook.db.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.io.Serializable;
import java.time.LocalDate;
import java.time.LocalTime;

/**
 * <p>
 * 技师排班表：记录技师可接单时间段，用于冲突检测和前端展示
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("cb_technician_schedule")
public class CbTechnicianSchedule implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键，自增
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 技师 ID，关联 cb_technician.id
     */
    private Long technicianId;

    /**
     * 排班日期（yyyy-MM-dd）
     */
    private LocalDate scheduleDate;

    /**
     * 班次开始时间（HH:mm:ss，如 09:00:00）
     */
    private LocalTime startTime;

    /**
     * 班次结束时间（HH:mm:ss，如 21:00:00）
     */
    private LocalTime endTime;

    /**
     * 是否可接单：1=可预约 0=不可预约（如临时有事则标记为不可用）
     */
    private Byte isAvailable;

    /**
     * 创建时间（UTC 秒级时间戳）
     */
    private Long createTime;
}
