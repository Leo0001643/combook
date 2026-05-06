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
 * Banner 轮播图：支持多位置、多语言标题、有效期和三种跳转方式
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("cb_banner")
public class CbBanner implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键，自增
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 归属商户ID，NULL=平台公共轮播图
     */
    private Long merchantId;

    /**
     * Banner 展示位置标识（小写+下划线），如 home_top=首页顶部 / tech_detail=技师详情页
     */
    private String position;

    /**
     * Banner 标题（中文，可不填）
     */
    private String titleZh;

    /**
     * Banner 标题（英文）
     */
    private String titleEn;

    /**
     * Banner 标题（越南文）
     */
    private String titleVi;

    /**
     * Banner 标题（柬埔寨文）
     */
    private String titleKm;

    /**
     * Banner 图片 URL（建议尺寸 750×300px）
     */
    private String imageUrl;

    /**
     * 点击跳转类型：0=无跳转 1=内部路由（如 /order/detail）2=外部链接（HTTP URL）
     */
    private Byte linkType;

    /**
     * 跳转目标（link_type=1时为路由路径，link_type=2时为完整 URL）
     */
    private String linkValue;

    /**
     * 同位置排序权重，值越小越靠前
     */
    private Integer sort;

    /**
     * 状态：1=启用 0=停用
     */
    private Byte status;

    /**
     * 生效开始时间（为空则立即生效）（UTC 秒级时间戳）
     */
    private Long startTime;

    /**
     * 生效结束时间（为空则永久有效）（UTC 秒级时间戳）
     */
    private Long endTime;

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
