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
 * 派车记录：记录每次车辆使用情况，支持多维度查询
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("cb_vehicle_dispatch")
public class CbVehicleDispatch implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 派车单号
     */
    private String dispatchNo;

    /**
     * 所属商户 ID
     */
    private Long merchantId;

    /**
     * 车辆 ID，关联 cb_vehicle.id
     */
    private Long vehicleId;

    /**
     * 车牌号快照
     */
    private String vehiclePlate;

    /**
     * 驾驶员员工 ID
     */
    private Long driverId;

    /**
     * 驾驶员姓名快照
     */
    private String driverName;

    /**
     * 用途：1=接送客户 2=采购 3=员工通勤 4=业务出行 5=其它
     */
    private Byte purpose;

    /**
     * 目的地
     */
    private String destination;

    /**
     * 乘客/随行人员信息
     */
    private String passengerInfo;

    /**
     * 关联订单 ID（接送客户时）
     */
    private Long orderId;

    /**
     * 出发时间（UTC 秒级时间戳）
     */
    private Long departTime;

    /**
     * 返回时间（UTC 秒级时间戳）
     */
    private Long returnTime;

    /**
     * 行驶里程（km）
     */
    private BigDecimal mileage;

    /**
     * 油费（USD）
     */
    private BigDecimal fuelCost;

    /**
     * 其它费用（USD）
     */
    private BigDecimal otherCost;

    /**
     * 本次用车总费用（USD）
     */
    private BigDecimal totalCost;

    /**
     * 状态：0=待出发 1=行程中 2=已返回 3=已取消
     */
    private Byte status;

    /**
     * 备注
     */
    private String remark;

    /**
     * 派车操作人 ID
     */
    private Long operatorId;

    /**
     * 创建时间（UTC 秒级时间戳）
     */
    private Long createTime;

    /**
     * 更新时间（UTC 秒级时间戳）
     */
    private Long updateTime;
}
