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
 * 在线订单服务项明细
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("cb_order_item")
public class CbOrderItem implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 关联订单ID
     */
    private Long orderId;

    /**
     * 执行该服务项的技师ID（关联 cb_technician.id）
     */
    private Long technicianId;

    /**
     * 服务项ID
     */
    private Long serviceItemId;

    /**
     * 服务名称快照
     */
    private String serviceName;

    /**
     * 时长(分钟)
     */
    private Integer serviceDuration;

    /**
     * 单价
     */
    private BigDecimal unitPrice;

    /**
     * 数量
     */
    private Integer qty;

    /**
     * 0=待服务 1=服务中 2=已完成
     */
    private Boolean svcStatus;

    /**
     * 技师实际收入（含佣金比例，结算时写入）
     */
    private BigDecimal techIncome;

    /**
     * 服务开始时间（UTC 秒级时间戳）
     */
    private Long startTime;

    /**
     * 服务结束时间（UTC 秒级时间戳）
     */
    private Long endTime;

    private String remark;

    /**
     * 逻辑删除：0正常 1删除
     */
    private Boolean deleted;

    /**
     * 创建时间（UTC 秒级时间戳）
     */
    private Long createTime;

    /**
     * 更新时间（UTC 秒级时间戳）
     */
    private Long updateTime;
}
