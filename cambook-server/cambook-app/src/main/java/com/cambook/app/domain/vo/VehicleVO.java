package com.cambook.app.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 车辆信息 VO
 *
 * @author CamBook
 */
@Data
@Schema(description = "车辆信息")
public class VehicleVO {

    @Schema(description = "主键")
    private Long id;

    @Schema(description = "车牌号")
    private String plateNumber;

    @Schema(description = "品牌")
    private String brand;

    @Schema(description = "型号")
    private String model;

    @Schema(description = "车身颜色")
    private String color;

    @Schema(description = "座位数")
    private Integer seats;

    @Schema(description = "年检编号")
    private String inspectionCode;

    @Schema(description = "年检有效期")
    private String inspectionExpiry;

    @Schema(description = "车辆图片")
    private String photo;

    @Schema(description = "车辆多图（JSON 数组）")
    private String photos;

    @Schema(description = "状态：0=空闲 1=使用中 2=维修中")
    private Integer status;

    @Schema(description = "备注")
    private String remark;

    @Schema(description = "创建时间")
    private LocalDateTime createTime;

    @Schema(description = "更新时间")
    private LocalDateTime updateTime;

    public static VehicleVO from(com.cambook.dao.entity.CbVehicle v) {
        VehicleVO vo = new VehicleVO();
        vo.setId(v.getId());
        vo.setPlateNumber(v.getPlateNumber());
        vo.setBrand(v.getBrand());
        vo.setModel(v.getModel());
        vo.setColor(v.getColor());
        vo.setSeats(v.getSeats());
        vo.setInspectionCode(v.getInspectionCode());
        vo.setInspectionExpiry(v.getInspectionExpiry());
        vo.setPhoto(v.getPhoto());
        vo.setPhotos(v.getPhotos());
        vo.setStatus(v.getStatus());
        vo.setRemark(v.getRemark());
        vo.setCreateTime(v.getCreateTime());
        vo.setUpdateTime(v.getUpdateTime());
        return vo;
    }
}
