package com.cambook.dao.entity;

import lombok.Getter;
import lombok.Setter;

import com.baomidou.mybatisplus.annotation.TableName;
import com.cambook.dao.entity.base.BaseEntity;

import java.math.BigDecimal;

/**
 * 服务项目实体
 */
@TableName("cb_service_item")
@Getter
@Setter
public class CbServiceItem extends BaseEntity {

    private Long       categoryId;
    private String     nameZh;
    private String     nameEn;
    private String     nameVi;
    private String     nameKm;
    private String     nameJa;
    private String     nameKo;
    private String     descZh;
    private String     descEn;
    private Integer    duration;
    private BigDecimal basePrice;
    private BigDecimal memberPrice;
    private String     cover;
    private Integer    sort;
    private Integer    status;

    public Long       getCategoryId()             { return categoryId; }
    public void       setCategoryId(Long v)       { this.categoryId = v; }
    public String     getNameZh()                 { return nameZh; }
    public void       setNameZh(String v)         { this.nameZh = v; }
    public String     getNameEn()                 { return nameEn; }
    public void       setNameEn(String v)         { this.nameEn = v; }
    public String     getNameVi()                 { return nameVi; }
    public void       setNameVi(String v)         { this.nameVi = v; }
    public String     getNameKm()                 { return nameKm; }
    public void       setNameKm(String v)         { this.nameKm = v; }
    public String     getNameJa()                 { return nameJa; }
    public void       setNameJa(String v)         { this.nameJa = v; }
    public String     getNameKo()                 { return nameKo; }
    public void       setNameKo(String v)         { this.nameKo = v; }
    public String     getDescZh()                 { return descZh; }
    public void       setDescZh(String v)         { this.descZh = v; }
    public String     getDescEn()                 { return descEn; }
    public void       setDescEn(String v)         { this.descEn = v; }
    public Integer    getDuration()               { return duration; }
    public void       setDuration(Integer v)      { this.duration = v; }
    public void       setBasePrice(BigDecimal v)  { this.basePrice = v; }
    public void       setMemberPrice(BigDecimal v){ this.memberPrice = v; }
    public String     getCover()                  { return cover; }
    public void       setCover(String v)          { this.cover = v; }
    public Integer    getSort()                   { return sort; }
    public void       setSort(Integer v)          { this.sort = v; }
    public Integer    getStatus()                 { return status; }
    public void       setStatus(Integer v)        { this.status = v; }
}
