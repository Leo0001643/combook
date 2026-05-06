package com.cambook.db.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.io.Serializable;
import java.math.BigDecimal;

/**
 * <p>
 * 服务分类表：两级树形结构，支持六语言名称
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("cb_service_category")
public class CbServiceCategory implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键，自增
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 归属商户ID，NULL=平台公共类目
     */
    private Long merchantId;

    /**
     * 写时复制来源：若本条为商户私有副本，则记录平台原始类目 ID；平台类目本身为 NULL
     */
    private Long sourceCategoryId;

    /**
     * 父分类 ID；0 表示一级分类（无父节点）
     */
    private Long parentId;

    /**
     * 分类名称（中文），必填
     */
    private String nameZh;

    /**
     * 分类名称（英文）
     */
    private String nameEn;

    /**
     * 分类名称（越南文）
     */
    private String nameVi;

    /**
     * 分类名称（柬埔寨文）
     */
    private String nameKm;

    /**
     * 分类名称（日文）
     */
    private String nameJa;

    /**
     * 分类名称（韩文）
     */
    private String nameKo;

    /**
     * 分类图标 URL
     */
    private String icon;

    /**
     * 服务基础指导价
     */
    private BigDecimal price;

    /**
     * 标准服务时长（分钟）
     */
    private Integer duration;

    /**
     * 是否特殊项目(0=常规,1=特殊)
     */
    private Boolean isSpecial;

    /**
     * 同级排序权重，值越小越靠前
     */
    private Integer sort;

    /**
     * 状态：1=启用 0=停用（停用后不在 APP 展示）
     */
    private Byte status;

    /**
     * 逻辑删除：0=正常 1=已删除
     */
    private Byte deleted;

    /**
     * 创建时间（UTC 秒级时间戳）
     */
    private Long createTime;

    /**
     * 最后修改时间（UTC 秒级时间戳）
     */
    private Long updateTime;
}
