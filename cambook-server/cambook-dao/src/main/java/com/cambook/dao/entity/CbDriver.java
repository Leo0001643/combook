package com.cambook.dao.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.cambook.dao.entity.base.BaseEntity;

import java.time.LocalDate;

/**
 * 司机
 *
 * @author CamBook
 */
@TableName("cb_driver")
public class CbDriver extends BaseEntity {

    /** 关联会员 ID */
    private Long   memberId;
    private String realName;
    private String avatar;
    private String mobile;
    private String idCard;
    private String drivingLicenseFront;
    private String drivingLicenseBack;
    /** 驾照类型：KH / INT */
    private String licenseType;
    /** 绑定车辆 ID */
    private Long   vehicleId;
    /** 审核状态：0待审 1在职 2停职 */
    private Integer status;
    /** 在线状态：0离线 1待命 2执行中 */
    private Integer onlineStatus;
    private Double  currentLat;
    private Double  currentLng;
    private Integer totalDispatch;
    private Double  rating;
    private String  rejectReason;

    public Long   getMemberId()                        { return memberId; }
    public void   setMemberId(Long memberId)           { this.memberId = memberId; }

    public String getRealName()                        { return realName; }
    public void   setRealName(String realName)         { this.realName = realName; }

    public String getAvatar()                          { return avatar; }
    public void   setAvatar(String avatar)             { this.avatar = avatar; }

    public String getMobile()                          { return mobile; }
    public void   setMobile(String mobile)             { this.mobile = mobile; }

    public String getIdCard()                          { return idCard; }
    public void   setIdCard(String idCard)             { this.idCard = idCard; }

    public String getDrivingLicenseFront()             { return drivingLicenseFront; }
    public void   setDrivingLicenseFront(String v)     { this.drivingLicenseFront = v; }

    public String getDrivingLicenseBack()              { return drivingLicenseBack; }
    public void   setDrivingLicenseBack(String v)      { this.drivingLicenseBack = v; }

    public String getLicenseType()                     { return licenseType; }
    public void   setLicenseType(String licenseType)   { this.licenseType = licenseType; }

    public Long   getVehicleId()                       { return vehicleId; }
    public void   setVehicleId(Long vehicleId)         { this.vehicleId = vehicleId; }

    public Integer getStatus()                         { return status; }
    public void    setStatus(Integer status)           { this.status = status; }

    public Integer getOnlineStatus()                   { return onlineStatus; }
    public void    setOnlineStatus(Integer v)          { this.onlineStatus = v; }

    public Double  getCurrentLat()                     { return currentLat; }
    public void    setCurrentLat(Double currentLat)    { this.currentLat = currentLat; }

    public Double  getCurrentLng()                     { return currentLng; }
    public void    setCurrentLng(Double currentLng)    { this.currentLng = currentLng; }

    public Integer getTotalDispatch()                  { return totalDispatch; }
    public void    setTotalDispatch(Integer v)         { this.totalDispatch = v; }

    public Double  getRating()                         { return rating; }
    public void    setRating(Double rating)            { this.rating = rating; }

    public String  getRejectReason()                   { return rejectReason; }
    public void    setRejectReason(String v)           { this.rejectReason = v; }
}
