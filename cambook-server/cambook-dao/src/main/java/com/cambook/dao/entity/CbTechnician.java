package com.cambook.dao.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.cambook.dao.entity.base.BaseEntity;
import io.swagger.v3.oas.annotations.media.Schema;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * 技师表
 *
 * <p>技师信息、位置、评分统计、收益数据合并在此表。
 * 多语言简介通过 intro_zh/en/vi/km 字段支持。
 * 技能项通过 skill_tags JSON 字段存 cb_service_item.id 列表，无需连表。
 *
 * @author CamBook
 */
@TableName("cb_technician")
@Schema(description = "技师信息")
public class CbTechnician extends BaseEntity {

    private String techNo;
    /** 关联会员 ID（技师通过 App 端注册后关联） */
    private Long memberId;
    private String mobile;
    private String telegram;
    private String password;
    private String realName;
    private String nickname;
    private String avatar;
    private String photos;
    /** 展示视频 URL */
    private String videoUrl;
    private Integer gender;
    /** 国籍 */
    private String nationality;
    private LocalDate birthday;
    private String idCard;
    private String idCardFront;
    private String idCardBack;
    private String lang;
    private String introZh;
    private String introEn;
    private String introVi;
    private String introKm;
    private String serviceCity;
    private BigDecimal lat;
    private BigDecimal lng;
    private BigDecimal rating;
    private Integer reviewCount;
    private Integer orderCount;
    private BigDecimal goodReviewRate;
    private BigDecimal balance;
    private BigDecimal totalIncome;
    /** 审核状态：0待审 1通过 2拒绝 */
    private Integer auditStatus;
    private String rejectReason;
    /** 在线状态：0离线 1在线 2服务中 */
    private Integer onlineStatus;
    private Long merchantId;
    /** 技师分成比例(%) */
    private BigDecimal commissionRate;
    /** 结算方式：0每笔 1日结 2周结 3月结 */
    private Integer settlementMode;
    /** 提成类型：0按比例 1固定金额 */
    private Integer commissionType;
    /** 按比例提成百分比(%) */
    private BigDecimal commissionRatePct;
    /** 固定金额结算币种 */
    private String commissionCurrency;
    /** 技能标签 ID 列表（JSON 数组） */
    private String skillTags;
    /** 可提供的服务类目 ID 列表（JSON 数组，存 cb_service_category.id） */
    private String serviceItemIds;
    private Integer height;
    private BigDecimal weight;
    private Integer age;
    private String bust;
    private String province;
    private Integer isFeatured;
    private Integer status;

    public String getTechNo()             { return techNo; }
    public Long getMemberId()             { return memberId; }
    public String getMobile()             { return mobile; }
    public String getTelegram()           { return telegram; }
    public String getPassword()           { return password; }
    public String getRealName()           { return realName; }
    public String getNickname()           { return nickname; }
    public String getAvatar()             { return avatar; }
    public String getPhotos()             { return photos; }
    public String getVideoUrl()           { return videoUrl; }
    public Integer getGender()            { return gender; }
    public String getNationality()        { return nationality; }
    public LocalDate getBirthday()        { return birthday; }
    public String getIdCard()             { return idCard; }
    public String getIdCardFront()        { return idCardFront; }
    public String getIdCardBack()         { return idCardBack; }
    public String getLang()               { return lang; }
    public String getIntroZh()            { return introZh; }
    public String getIntroEn()            { return introEn; }
    public String getIntroVi()            { return introVi; }
    public String getIntroKm()            { return introKm; }
    public String getServiceCity()        { return serviceCity; }
    public BigDecimal getLat()            { return lat; }
    public BigDecimal getLng()            { return lng; }
    public BigDecimal getRating()         { return rating; }
    public Integer getReviewCount()       { return reviewCount; }
    public Integer getOrderCount()        { return orderCount; }
    public BigDecimal getGoodReviewRate() { return goodReviewRate; }
    public BigDecimal getBalance()        { return balance; }
    public BigDecimal getTotalIncome()    { return totalIncome; }
    public Integer getAuditStatus()       { return auditStatus; }
    public String getRejectReason()       { return rejectReason; }
    public Integer getOnlineStatus()      { return onlineStatus; }
    public Long getMerchantId()           { return merchantId; }
    public BigDecimal getCommissionRate() { return commissionRate; }
    public Integer getSettlementMode()    { return settlementMode; }
    public Integer getCommissionType()    { return commissionType; }
    public BigDecimal getCommissionRatePct() { return commissionRatePct; }
    public String getCommissionCurrency() { return commissionCurrency; }
    public String getSkillTags()          { return skillTags; }
    public String getServiceItemIds()     { return serviceItemIds; }
    public Integer getHeight()            { return height; }
    public BigDecimal getWeight()         { return weight; }
    public Integer getAge()               { return age; }
    public String getBust()               { return bust; }
    public String getProvince()           { return province; }
    public Integer getIsFeatured()        { return isFeatured; }
    public Integer getStatus()            { return status; }

    public void setTechNo(String techNo)                       { this.techNo = techNo; }
    public void setMemberId(Long memberId)                     { this.memberId = memberId; }
    public void setMobile(String mobile)                       { this.mobile = mobile; }
    public void setTelegram(String telegram)                   { this.telegram = telegram; }
    public void setPassword(String password)                   { this.password = password; }
    public void setRealName(String realName)                   { this.realName = realName; }
    public void setNickname(String nickname)                   { this.nickname = nickname; }
    public void setAvatar(String avatar)                       { this.avatar = avatar; }
    public void setPhotos(String photos)                       { this.photos = photos; }
    public void setVideoUrl(String videoUrl)                   { this.videoUrl = videoUrl; }
    public void setGender(Integer gender)                      { this.gender = gender; }
    public void setNationality(String nationality)             { this.nationality = nationality; }
    public void setBirthday(LocalDate birthday)                { this.birthday = birthday; }
    public void setIdCard(String idCard)                       { this.idCard = idCard; }
    public void setIdCardFront(String idCardFront)             { this.idCardFront = idCardFront; }
    public void setIdCardBack(String idCardBack)               { this.idCardBack = idCardBack; }
    public void setLang(String lang)                           { this.lang = lang; }
    public void setIntroZh(String introZh)                     { this.introZh = introZh; }
    public void setIntroEn(String introEn)                     { this.introEn = introEn; }
    public void setIntroVi(String introVi)                     { this.introVi = introVi; }
    public void setIntroKm(String introKm)                     { this.introKm = introKm; }
    public void setServiceCity(String serviceCity)             { this.serviceCity = serviceCity; }
    public void setLat(BigDecimal lat)                         { this.lat = lat; }
    public void setLng(BigDecimal lng)                         { this.lng = lng; }
    public void setRating(BigDecimal rating)                   { this.rating = rating; }
    public void setReviewCount(Integer reviewCount)            { this.reviewCount = reviewCount; }
    public void setOrderCount(Integer orderCount)              { this.orderCount = orderCount; }
    public void setGoodReviewRate(BigDecimal goodReviewRate)   { this.goodReviewRate = goodReviewRate; }
    public void setBalance(BigDecimal balance)                 { this.balance = balance; }
    public void setTotalIncome(BigDecimal totalIncome)         { this.totalIncome = totalIncome; }
    public void setAuditStatus(Integer auditStatus)            { this.auditStatus = auditStatus; }
    public void setRejectReason(String rejectReason)           { this.rejectReason = rejectReason; }
    public void setOnlineStatus(Integer onlineStatus)          { this.onlineStatus = onlineStatus; }
    public void setMerchantId(Long merchantId)                 { this.merchantId = merchantId; }
    public void setCommissionRate(BigDecimal commissionRate)   { this.commissionRate = commissionRate; }
    public void setSettlementMode(Integer settlementMode)      { this.settlementMode = settlementMode; }
    public void setCommissionType(Integer commissionType)      { this.commissionType = commissionType; }
    public void setCommissionRatePct(BigDecimal v)             { this.commissionRatePct = v; }
    public void setCommissionCurrency(String v)                { this.commissionCurrency = v; }
    public void setSkillTags(String skillTags)                 { this.skillTags = skillTags; }
    public void setServiceItemIds(String serviceItemIds)       { this.serviceItemIds = serviceItemIds; }
    public void setHeight(Integer height)                      { this.height = height; }
    public void setWeight(BigDecimal weight)                   { this.weight = weight; }
    public void setAge(Integer age)                            { this.age = age; }
    public void setBust(String bust)                           { this.bust = bust; }
    public void setProvince(String province)                   { this.province = province; }
    public void setIsFeatured(Integer isFeatured)              { this.isFeatured = isFeatured; }
    public void setStatus(Integer status)                      { this.status = status; }
}
