package com.cambook.db.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.io.Serializable;

/**
 * <p>
 * 标签表：多语言标签，区分技师/服务/商户类型，支持彩色展示
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("cb_tag")
public class CbTag implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键，自增
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 标签类型：1=技师标签 2=服务标签 3=商户标签
     */
    private Byte tagType;

    /**
     * 标签名称（中文），必填
     */
    private String nameZh;

    /**
     * 标签名称（英文）
     */
    private String nameEn;

    /**
     * 标签名称（越南文）
     */
    private String nameVi;

    /**
     * 标签名称（柬埔寨文）
     */
    private String nameKm;

    /**
     * 标签展示颜色（十六进制，如 #FF6B6B），用于前端渲染彩色标签
     */
    private String color;

    /**
     * 排序权重，值越小越靠前
     */
    private Integer sort;

    /**
     * 状态：1=启用 0=停用
     */
    private Byte status;

    /**
     * 创建时间（UTC 秒级时间戳）
     */
    private Long createTime;
}
