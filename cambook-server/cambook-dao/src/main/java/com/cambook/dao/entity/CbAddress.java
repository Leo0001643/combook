package com.cambook.dao.entity;

import lombok.Getter;
import lombok.Setter;

import com.baomidou.mybatisplus.annotation.TableName;
import com.cambook.dao.entity.base.BaseEntity;

import java.math.BigDecimal;

/**
 * 会员收货/服务地址实体
 *
 * @author CamBook
 */
@TableName("cb_address")
@Getter
@Setter
public class CbAddress extends BaseEntity {

    private Long       memberId;
    private String     contactName;
    private String     contactMobile;
    private String     province;
    private String     city;
    private String     district;
    private String     detailAddress;
    private BigDecimal lat;
    private BigDecimal lng;
    private Integer    isDefault;
    private Integer    status;

    public Long       getMemberId()                 { return memberId; }
    public void       setMemberId(Long v)           { this.memberId = v; }
    public String     getContactName()              { return contactName; }
    public void       setContactName(String v)      { this.contactName = v; }
    public String     getContactMobile()            { return contactMobile; }
    public void       setContactMobile(String v)    { this.contactMobile = v; }
    public String     getProvince()                 { return province; }
    public void       setProvince(String v)         { this.province = v; }
    public String     getCity()                     { return city; }
    public void       setCity(String v)             { this.city = v; }
    public String     getDistrict()                 { return district; }
    public void       setDistrict(String v)         { this.district = v; }
    public String     getDetailAddress()            { return detailAddress; }
    public void       setDetailAddress(String v)    { this.detailAddress = v; }
    public void       setLat(BigDecimal v)          { this.lat = v; }
    public void       setLng(BigDecimal v)          { this.lng = v; }
    public Integer    getIsDefault()                { return isDefault; }
    public void       setIsDefault(Integer v)       { this.isDefault = v; }
    public Integer    getStatus()                   { return status; }
    public void       setStatus(Integer v)          { this.status = v; }
}
