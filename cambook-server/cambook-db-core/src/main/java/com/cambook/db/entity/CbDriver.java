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
 * 司机表：记录司机认证信息/实时位置/接单统计，支持派车功能
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("cb_driver")
public class CbDriver implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键，自增
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 关联会员 ID（司机同时是会员时关联），关联 cb_member.id
     */
    private Long memberId;

    /**
     * 真实姓名（与驾照一致）
     */
    private String realName;

    /**
     * 头像图片 URL
     */
    private String avatar;

    /**
     * 联系手机号（冗余快照，国际格式）
     */
    private String mobile;

    /**
     * 证件号（护照/身份证，建议加密存储）
     */
    private String idCard;

    /**
     * 驾照正面照片 URL（审核材料）
     */
    private String drivingLicenseFront;

    /**
     * 驾照背面照片 URL（审核材料）
     */
    private String drivingLicenseBack;

    /**
     * 驾照类型：KH=柬埔寨驾照 INT=国际驾照
     */
    private String licenseType;

    /**
     * 默认绑定车辆 ID，关联 cb_vehicle.id（可为空，每次派单时再指定）
     */
    private Long vehicleId;

    /**
     * 审核/状态：0=待审核 1=在职（可接单）2=停职（禁止接单）
     */
    private Byte status;

    /**
     * 在线状态：0=离线 1=待命（可接单）2=执行任务中（不可接新单）
     */
    private Byte onlineStatus;

    /**
     * 当前位置纬度（司机 APP 实时上报，用于就近分配）
     */
    private BigDecimal currentLat;

    /**
     * 当前位置经度（司机 APP 实时上报）
     */
    private BigDecimal currentLng;

    /**
     * 累计完成派单次数（只增不减）
     */
    private Integer totalDispatch;

    /**
     * 综合评分（1.00-5.00，由完成订单评价加权计算）
     */
    private BigDecimal rating;

    /**
     * 审核拒绝原因（status=停职 或 审核不通过时填写）
     */
    private String rejectReason;

    /**
     * 逻辑删除：0=正常 1=已删除
     */
    private Byte deleted;

    /**
     * 申请注册时间（UTC 秒级时间戳）
     */
    private Long createTime;

    /**
     * 最后修改时间（UTC 秒级时间戳）
     */
    private Long updateTime;
}
