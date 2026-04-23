package com.cambook.dao.entity;

import lombok.Getter;
import lombok.Setter;

import com.baomidou.mybatisplus.annotation.TableName;
import com.cambook.dao.entity.base.BaseEntity;

import java.math.BigDecimal;

/**
 * 优惠券模板实体
 */
@TableName("cb_coupon_template")
@Getter
@Setter
public class CbCouponTemplate extends BaseEntity {

    private Long          merchantId;
    private String        nameZh;
    private String        nameEn;
    private String        nameVi;
    private String        nameKm;
    /** 1=满减 2=折扣 */
    private Integer       type;
    private BigDecimal    value;
    private BigDecimal    minAmount;
    private Integer       totalCount;
    private Integer       issuedCount;
    private Integer       validDays;
    private Long          startTime;
    private Long          endTime;
    private Integer       status;

    public Long          getMerchantId()                   { return merchantId; }
    public void          setMerchantId(Long v)              { this.merchantId = v; }
    public String        getNameZh()                      { return nameZh; }
    public void          setNameZh(String v)               { this.nameZh = v; }
    public String        getNameEn()                      { return nameEn; }
    public void          setNameEn(String v)               { this.nameEn = v; }
    public String        getNameVi()                      { return nameVi; }
    public void          setNameVi(String v)               { this.nameVi = v; }
    public String        getNameKm()                      { return nameKm; }
    public void          setNameKm(String v)               { this.nameKm = v; }
    public Integer       getType()                        { return type; }
    public void          setType(Integer v)                { this.type = v; }
    public BigDecimal    getValue()                       { return value; }
    public void          setValue(BigDecimal v)            { this.value = v; }
    public BigDecimal    getMinAmount()                   { return minAmount; }
    public void          setMinAmount(BigDecimal v)        { this.minAmount = v; }
    public Integer       getTotalCount()                  { return totalCount; }
    public void          setTotalCount(Integer v)          { this.totalCount = v; }
    public Integer       getIssuedCount()                 { return issuedCount; }
    public void          setIssuedCount(Integer v)         { this.issuedCount = v; }
    public Integer       getValidDays()                   { return validDays; }
    public void          setValidDays(Integer v)           { this.validDays = v; }
    public Long          getStartTime()                   { return startTime; }
    public void          setStartTime(Long v)             { this.startTime = v; }
    public Long          getEndTime()                     { return endTime; }
    public void          setEndTime(Long v)               { this.endTime = v; }
    public Integer       getStatus()                      { return status; }
    public void          setStatus(Integer v)              { this.status = v; }
}
