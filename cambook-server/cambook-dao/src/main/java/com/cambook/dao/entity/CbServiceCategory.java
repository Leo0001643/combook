package com.cambook.dao.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.cambook.dao.entity.base.BaseEntity;

/**
 * 服务类目实体
 */
@TableName("cb_service_category")
public class CbServiceCategory extends BaseEntity {

    /** 归属商户 ID（null = 平台公共类目） */
    private Long    merchantId;
    private Long    parentId;
    private String  nameZh;
    private String  nameEn;
    private String  nameVi;
    private String  nameKm;
    private String  nameJa;
    private String  nameKo;
    private String  icon;
    private Integer sort;
    private Integer status;

    public Long    getMerchantId()           { return merchantId; }
    public void    setMerchantId(Long v)     { this.merchantId = v; }
    public Long    getParentId()            { return parentId; }
    public void    setParentId(Long v)      { this.parentId = v; }
    public String  getNameZh()              { return nameZh; }
    public void    setNameZh(String v)      { this.nameZh = v; }
    public String  getNameEn()              { return nameEn; }
    public void    setNameEn(String v)      { this.nameEn = v; }
    public String  getNameVi()              { return nameVi; }
    public void    setNameVi(String v)      { this.nameVi = v; }
    public String  getNameKm()              { return nameKm; }
    public void    setNameKm(String v)      { this.nameKm = v; }
    public String  getNameJa()              { return nameJa; }
    public void    setNameJa(String v)      { this.nameJa = v; }
    public String  getNameKo()              { return nameKo; }
    public void    setNameKo(String v)      { this.nameKo = v; }
    public String  getIcon()               { return icon; }
    public void    setIcon(String v)       { this.icon = v; }
    public Integer getSort()               { return sort; }
    public void    setSort(Integer v)      { this.sort = v; }
    public Integer getStatus()             { return status; }
    public void    setStatus(Integer v)    { this.status = v; }
}
