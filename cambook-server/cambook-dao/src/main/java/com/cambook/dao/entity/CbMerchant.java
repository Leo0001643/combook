package com.cambook.dao.entity;

import lombok.Getter;
import lombok.Setter;

import com.baomidou.mybatisplus.annotation.TableName;
import com.cambook.dao.entity.base.BaseEntity;

import java.math.BigDecimal;

/**
 * 商户实体
 *
 * @author CamBook
 */
@TableName("cb_merchant")
@Getter
@Setter
public class CbMerchant extends BaseEntity {

    private String      merchantNo;
    private String      mobile;
    /** 登录用户名（字母数字，可选） */
    private String      username;
    private String      password;
    private String      merchantNameZh;
    private String      merchantNameEn;
    private String      merchantNameVi;
    private String      merchantNameKm;
    private String      logo;
    private String      photos;
    private String      contactPerson;
    private String      contactMobile;
    private String      province;
    private String      city;
    private String      addressZh;
    private String      addressEn;
    private String      addressVi;
    private String      addressKm;
    private BigDecimal  lat;
    private BigDecimal  lng;
    private String      businessHours;
    private Integer     techCount;
    private BigDecimal  balance;
    private BigDecimal  commissionRate;
    private Integer     businessType;
    /** 营业执照号码 */
    private String      businessLicenseNo;
    /** 营业执照照片 URL */
    private String      businessLicensePic;
    /** 营业范围 */
    private String      businessScope;
    /** 营业面积/规模 */
    private String      businessArea;
    private String      features;
    private Integer     auditStatus;
    private String      rejectReason;
    private Integer     status;

    public String     getMerchantNo()                     { return merchantNo; }
    public void       setMerchantNo(String v)             { this.merchantNo = v; }
    public String     getMobile()                         { return mobile; }
    public void       setMobile(String v)                 { this.mobile = v; }
    public String     getUsername()                       { return username; }
    public void       setUsername(String v)               { this.username = v; }
    public String     getPassword()                       { return password; }
    public void       setPassword(String v)               { this.password = v; }
    public String     getMerchantNameZh()                 { return merchantNameZh; }
    public void       setMerchantNameZh(String v)         { this.merchantNameZh = v; }
    public String     getMerchantNameEn()                 { return merchantNameEn; }
    public void       setMerchantNameEn(String v)         { this.merchantNameEn = v; }
    public String     getMerchantNameVi()                 { return merchantNameVi; }
    public void       setMerchantNameVi(String v)         { this.merchantNameVi = v; }
    public String     getMerchantNameKm()                 { return merchantNameKm; }
    public void       setMerchantNameKm(String v)         { this.merchantNameKm = v; }
    public String     getLogo()                           { return logo; }
    public void       setLogo(String v)                   { this.logo = v; }
    public String     getPhotos()                         { return photos; }
    public void       setPhotos(String v)                 { this.photos = v; }
    public String     getContactPerson()                  { return contactPerson; }
    public void       setContactPerson(String v)          { this.contactPerson = v; }
    public String     getContactMobile()                  { return contactMobile; }
    public void       setContactMobile(String v)          { this.contactMobile = v; }
    public String     getProvince()                       { return province; }
    public void       setProvince(String v)               { this.province = v; }
    public String     getCity()                           { return city; }
    public void       setCity(String v)                   { this.city = v; }
    public String     getAddressZh()                      { return addressZh; }
    public void       setAddressZh(String v)              { this.addressZh = v; }
    public String     getAddressEn()                      { return addressEn; }
    public void       setAddressEn(String v)              { this.addressEn = v; }
    public String     getAddressVi()                      { return addressVi; }
    public void       setAddressVi(String v)              { this.addressVi = v; }
    public String     getAddressKm()                      { return addressKm; }
    public void       setAddressKm(String v)              { this.addressKm = v; }
    public void       setLat(BigDecimal v)                { this.lat = v; }
    public void       setLng(BigDecimal v)                { this.lng = v; }
    public String     getBusinessHours()                  { return businessHours; }
    public void       setBusinessHours(String v)          { this.businessHours = v; }
    public Integer    getTechCount()                      { return techCount; }
    public void       setTechCount(Integer v)             { this.techCount = v; }
    public void       setBalance(BigDecimal v)            { this.balance = v; }
    public void       setCommissionRate(BigDecimal v)     { this.commissionRate = v; }
    public Integer    getBusinessType()                   { return businessType; }
    public void       setBusinessType(Integer v)          { this.businessType = v; }
    public String     getBusinessLicenseNo()              { return businessLicenseNo; }
    public void       setBusinessLicenseNo(String v)      { this.businessLicenseNo = v; }
    public String     getBusinessLicensePic()             { return businessLicensePic; }
    public void       setBusinessLicensePic(String v)     { this.businessLicensePic = v; }
    public String     getBusinessScope()                  { return businessScope; }
    public void       setBusinessScope(String v)          { this.businessScope = v; }
    public String     getBusinessArea()                   { return businessArea; }
    public void       setBusinessArea(String v)           { this.businessArea = v; }
    public String     getFeatures()                       { return features; }
    public void       setFeatures(String v)               { this.features = v; }
    public Integer    getAuditStatus()                    { return auditStatus; }
    public void       setAuditStatus(Integer v)           { this.auditStatus = v; }
    public String     getRejectReason()                   { return rejectReason; }
    public void       setRejectReason(String v)           { this.rejectReason = v; }
    public Integer    getStatus()                         { return status; }
    public void       setStatus(Integer v)                { this.status = v; }
}
