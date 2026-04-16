package com.cambook.dao.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.cambook.dao.entity.base.BaseEntity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 订单表
 *
 * @author CamBook
 */
@TableName("cb_order")
public class CbOrder extends BaseEntity {

    private String orderNo;
    private Long memberId;
    private Long technicianId;
    private Long merchantId;
    private Long serviceItemId;
    private String serviceName;
    private Integer serviceDuration;
    private Long addressId;
    private String addressDetail;
    private BigDecimal addressLat;
    private BigDecimal addressLng;
    private LocalDateTime appointTime;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private BigDecimal originalAmount;
    private BigDecimal discountAmount;
    private BigDecimal transportFee;
    private BigDecimal payAmount;
    private Long couponId;
    /** 支付方式：1ABA 2USDT 3余额 4现金 */
    private Integer payType;
    private LocalDateTime payTime;
    private BigDecimal techIncome;
    private BigDecimal platformIncome;
    /** 0待支付 1已支付 2接单 3前往 4到达 5服务中 6完成 7取消 8退款中 9已退款 */
    private Integer status;
    private String cancelReason;
    private String remark;
    private Integer isReviewed;

    public String getOrderNo()              { return orderNo; }
    public Long getMemberId()               { return memberId; }
    public Long getTechnicianId()           { return technicianId; }
    public Long getMerchantId()             { return merchantId; }
    public Long getServiceItemId()          { return serviceItemId; }
    public String getServiceName()          { return serviceName; }
    public Integer getServiceDuration()     { return serviceDuration; }
    public Long getAddressId()              { return addressId; }
    public String getAddressDetail()        { return addressDetail; }
    public BigDecimal getAddressLat()       { return addressLat; }
    public BigDecimal getAddressLng()       { return addressLng; }
    public LocalDateTime getAppointTime()   { return appointTime; }
    public LocalDateTime getStartTime()     { return startTime; }
    public LocalDateTime getEndTime()       { return endTime; }
    public BigDecimal getOriginalAmount()   { return originalAmount; }
    public BigDecimal getDiscountAmount()   { return discountAmount; }
    public BigDecimal getTransportFee()     { return transportFee; }
    public BigDecimal getPayAmount()        { return payAmount; }
    public Long getCouponId()               { return couponId; }
    public Integer getPayType()             { return payType; }
    public LocalDateTime getPayTime()       { return payTime; }
    public BigDecimal getTechIncome()       { return techIncome; }
    public BigDecimal getPlatformIncome()   { return platformIncome; }
    public Integer getStatus()              { return status; }
    public String getCancelReason()         { return cancelReason; }
    public String getRemark()               { return remark; }
    public Integer getIsReviewed()          { return isReviewed; }

    public void setOrderNo(String orderNo)                      { this.orderNo = orderNo; }
    public void setMemberId(Long memberId)                      { this.memberId = memberId; }
    public void setTechnicianId(Long technicianId)              { this.technicianId = technicianId; }
    public void setMerchantId(Long merchantId)                  { this.merchantId = merchantId; }
    public void setServiceItemId(Long serviceItemId)            { this.serviceItemId = serviceItemId; }
    public void setServiceName(String serviceName)              { this.serviceName = serviceName; }
    public void setServiceDuration(Integer serviceDuration)     { this.serviceDuration = serviceDuration; }
    public void setAddressId(Long addressId)                    { this.addressId = addressId; }
    public void setAddressDetail(String addressDetail)          { this.addressDetail = addressDetail; }
    public void setAddressLat(BigDecimal addressLat)            { this.addressLat = addressLat; }
    public void setAddressLng(BigDecimal addressLng)            { this.addressLng = addressLng; }
    public void setAppointTime(LocalDateTime appointTime)       { this.appointTime = appointTime; }
    public void setStartTime(LocalDateTime startTime)           { this.startTime = startTime; }
    public void setEndTime(LocalDateTime endTime)               { this.endTime = endTime; }
    public void setOriginalAmount(BigDecimal originalAmount)    { this.originalAmount = originalAmount; }
    public void setDiscountAmount(BigDecimal discountAmount)    { this.discountAmount = discountAmount; }
    public void setTransportFee(BigDecimal transportFee)        { this.transportFee = transportFee; }
    public void setPayAmount(BigDecimal payAmount)              { this.payAmount = payAmount; }
    public void setCouponId(Long couponId)                      { this.couponId = couponId; }
    public void setPayType(Integer payType)                     { this.payType = payType; }
    public void setPayTime(LocalDateTime payTime)               { this.payTime = payTime; }
    public void setTechIncome(BigDecimal techIncome)            { this.techIncome = techIncome; }
    public void setPlatformIncome(BigDecimal platformIncome)    { this.platformIncome = platformIncome; }
    public void setStatus(Integer status)                       { this.status = status; }
    public void setCancelReason(String cancelReason)            { this.cancelReason = cancelReason; }
    public void setRemark(String remark)                        { this.remark = remark; }
    public void setIsReviewed(Integer isReviewed)               { this.isReviewed = isReviewed; }
}
