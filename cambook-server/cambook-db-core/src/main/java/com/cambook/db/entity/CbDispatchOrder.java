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
 * 派车单表：记录接送服务完整生命周期，关联主订单，含司机/车辆/坐标信息
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("cb_dispatch_order")
public class CbDispatchOrder implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键，自增
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 派车单号（业务唯一，格式 DS+yyyyMMddHHmmss+6位随机，如 DS20260413154501AB3F）
     */
    private String dispatchNo;

    /**
     * 关联主订单 ID，关联 cb_order.id
     */
    private Long orderId;

    /**
     * 执行司机 ID，关联 cb_driver.id（系统自动分配后填入，创建时可为空）
     */
    private Long driverId;

    /**
     * 使用车辆 ID，关联 cb_vehicle.id（确认司机后填入）
     */
    private Long vehicleId;

    /**
     * 上车地点纬度（会员选择的接送位置）
     */
    private BigDecimal pickupLat;

    /**
     * 上车地点经度
     */
    private BigDecimal pickupLng;

    /**
     * 目的地纬度（商户/服务地点坐标）
     */
    private BigDecimal destLat;

    /**
     * 目的地经度
     */
    private BigDecimal destLng;

    /**
     * 目的地详细地址描述（供司机导航参考）
     */
    private String destAddress;

    /**
     * 预约接送时间（会员选择的上车时间）（UTC 秒级时间戳）
     */
    private Long pickupTime;

    /**
     * 实际接到乘客时间（司机操作"已接到"时记录）（UTC 秒级时间戳）
     */
    private Long actualPickupTime;

    /**
     * 行程完成时间（司机操作"已送达"时记录）（UTC 秒级时间戳）
     */
    private Long finishTime;

    /**
     * 派车单状态：0=待接单 1=司机已接单 2=前往接客 3=已到达等待 4=乘客已上车 5=已完成 9=已取消
     */
    private Byte status;

    /**
     * 取消原因（status=9 时填写）
     */
    private String cancelReason;

    /**
     * 特殊备注（如 VIP 接待要求、需准备瓶装水等）
     */
    private String remark;

    /**
     * 逻辑删除：0=正常 1=已删除
     */
    private Byte deleted;

    /**
     * 派车单创建时间（UTC 秒级时间戳）
     */
    private Long createTime;

    /**
     * 最后修改时间（UTC 秒级时间戳）
     */
    private Long updateTime;
}
