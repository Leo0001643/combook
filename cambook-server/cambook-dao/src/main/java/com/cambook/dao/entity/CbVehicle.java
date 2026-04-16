package com.cambook.dao.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.cambook.dao.entity.base.BaseEntity;

import java.time.LocalDate;

/**
 * 车辆
 *
 * @author CamBook
 */
@TableName("cb_vehicle")
public class CbVehicle extends BaseEntity {

    private Long   merchantId;
    private String plateNumber;
    private String brand;
    private String model;
    private String color;
    private Integer seats;
    private String  inspectionCode;
    private String  inspectionExpiry;
    private String  photo;
    /** 状态：0空闲 1使用中 2维修中 */
    private Integer status;
    private String  remark;

    public Long    getMerchantId()                        { return merchantId; }
    public void    setMerchantId(Long merchantId)         { this.merchantId = merchantId; }

    public String  getPlateNumber()                       { return plateNumber; }
    public void    setPlateNumber(String plateNumber)     { this.plateNumber = plateNumber; }

    public String  getBrand()                             { return brand; }
    public void    setBrand(String brand)                 { this.brand = brand; }

    public String  getModel()                             { return model; }
    public void    setModel(String model)                 { this.model = model; }

    public String  getColor()                             { return color; }
    public void    setColor(String color)                 { this.color = color; }

    public Integer getSeats()                             { return seats; }
    public void    setSeats(Integer seats)                { this.seats = seats; }

    public String  getInspectionCode()                    { return inspectionCode; }
    public void    setInspectionCode(String v)            { this.inspectionCode = v; }

    public String  getInspectionExpiry()                  { return inspectionExpiry; }
    public void    setInspectionExpiry(String v)          { this.inspectionExpiry = v; }

    public String  getPhoto()                             { return photo; }
    public void    setPhoto(String photo)                 { this.photo = photo; }

    public Integer getStatus()                            { return status; }
    public void    setStatus(Integer status)              { this.status = status; }

    public String  getRemark()                            { return remark; }
    public void    setRemark(String remark)               { this.remark = remark; }
}
