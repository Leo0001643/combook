package com.cambook.dao.entity;

import lombok.Getter;
import lombok.Setter;

import com.baomidou.mybatisplus.annotation.TableName;
import com.cambook.dao.entity.base.BaseEntity;

/**
 * Banner 轮播图实体
 *
 * @author CamBook
 */
@TableName("cb_banner")
@Getter
@Setter
public class CbBanner extends BaseEntity {

    /** 归属商户 ID（null = 平台公共轮播图） */
    private Long          merchantId;
    private String        position;
    private String        titleZh;
    private String        titleEn;
    private String        titleVi;
    private String        titleKm;
    private String        imageUrl;
    private Integer       linkType;
    private String        linkValue;
    private Integer       sort;
    private Integer       status;
    private Long          startTime;
    private Long          endTime;

    public Long          getMerchantId()             { return merchantId; }
    public void          setMerchantId(Long v)        { this.merchantId = v; }
    public String        getPosition()              { return position; }
    public void          setPosition(String v)       { this.position = v; }
    public String        getTitleZh()               { return titleZh; }
    public void          setTitleZh(String v)        { this.titleZh = v; }
    public String        getTitleEn()               { return titleEn; }
    public void          setTitleEn(String v)        { this.titleEn = v; }
    public String        getTitleVi()               { return titleVi; }
    public void          setTitleVi(String v)        { this.titleVi = v; }
    public String        getTitleKm()               { return titleKm; }
    public void          setTitleKm(String v)        { this.titleKm = v; }
    public String        getImageUrl()              { return imageUrl; }
    public void          setImageUrl(String v)       { this.imageUrl = v; }
    public Integer       getLinkType()              { return linkType; }
    public void          setLinkType(Integer v)      { this.linkType = v; }
    public String        getLinkValue()             { return linkValue; }
    public void          setLinkValue(String v)      { this.linkValue = v; }
    public Integer       getSort()                  { return sort; }
    public void          setSort(Integer v)          { this.sort = v; }
    public Integer       getStatus()                { return status; }
    public void          setStatus(Integer v)        { this.status = v; }
    public Long          getStartTime()             { return startTime; }
    public void          setStartTime(Long v)        { this.startTime = v; }
    public Long          getEndTime()               { return endTime; }
    public void          setEndTime(Long v)          { this.endTime = v; }
}
