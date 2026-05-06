package com.cambook.db.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.io.Serializable;
import java.time.LocalDate;

/**
 * <p>
 * 车辆表：记录车辆资产信息，状态跟踪，支持派单车辆管理
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("cb_vehicle")
public class CbVehicle implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键，自增
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 所属商户ID
     */
    private Long merchantId;

    /**
     * 车牌号（全局唯一，格式按所在国家规范，如 2A-1234 柬埔寨格式）
     */
    private String plateNumber;

    /**
     * 车辆品牌，如 Toyota / Honda / Lexus
     */
    private String brand;

    /**
     * 车辆型号，如 Camry / Accord / ES300h
     */
    private String model;

    /**
     * 车辆颜色（中文描述，如 珍珠白 / 深灰）
     */
    private String color;

    /**
     * 核定座位数（含驾驶员，最少2，最多50）
     */
    private Byte seats;

    /**
     * 年检合格证编号
     */
    private String inspectionCode;

    /**
     * 年检到期日（yyyy-MM-dd，提前30天告警）
     */
    private LocalDate inspectionExpiry;

    /**
     * 车辆图片 URL（建议展示车牌清晰的正面照）
     */
    private String photo;

    /**
     * 车辆多图（JSON数组，如 ["url1","url2"]）
     */
    private String photos;

    /**
     * 车辆状态：0=空闲（可派单）1=使用中（已派出）2=维修中（暂不可派）
     */
    private Byte status;

    /**
     * 备注（如车辆特殊说明，残障设施等）
     */
    private String remark;

    /**
     * 逻辑删除：0=正常 1=已报废/删除
     */
    private Byte deleted;

    /**
     * 车辆录入时间（UTC 秒级时间戳）
     */
    private Long createTime;

    /**
     * 最后修改时间（UTC 秒级时间戳）
     */
    private Long updateTime;
}
