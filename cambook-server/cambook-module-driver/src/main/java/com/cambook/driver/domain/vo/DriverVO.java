package com.cambook.driver.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

/**
 * 司机视图
 *
 * @author CamBook
 */
@Data
@Schema(description = "司机信息")
public class DriverVO {

    @Schema(description = "司机 ID")
    private Long id;

    @Schema(description = "关联会员 ID")
    private Long memberId;

    @Schema(description = "真实姓名")
    private String realName;

    @Schema(description = "头像")
    private String avatar;

    @Schema(description = "驾照类型：KH / INT")
    private String licenseType;

    @Schema(description = "绑定车辆 ID")
    private Long vehicleId;

    @Schema(description = "绑定车辆信息（内嵌）")
    private VehicleVO vehicle;

    @Schema(description = "在线状态：0离线 1待命 2执行中")
    private Integer onlineStatus;

    @Schema(description = "审核状态：0待审 1在职 2停职")
    private Integer status;

    @Schema(description = "当前纬度")
    private Double currentLat;

    @Schema(description = "当前经度")
    private Double currentLng;

    @Schema(description = "累计完成派单数")
    private Integer totalDispatch;

    @Schema(description = "综合评分")
    private Double rating;
}
