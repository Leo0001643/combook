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
 * 图标资源表：统一管理 URL/Base64/字体图标，按 key 引用
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("cb_icon")
public class CbIcon implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键，自增
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 图标唯一标识键（全局唯一，英文小写+下划线，如 icon_home / icon_order）
     */
    private String iconKey;

    /**
     * 图标类型：1=图片 URL 2=Base64 内嵌 3=字体图标类名（如 iconfont icon-home）
     */
    private Byte iconType;

    /**
     * 图标图片 URL（icon_type=1 时填写）
     */
    private String iconUrl;

    /**
     * 字体图标类名（icon_type=3 时填写）
     */
    private String iconFont;

    /**
     * 图标用途说明
     */
    private String remark;

    /**
     * 创建时间（UTC 秒级时间戳）
     */
    private Long createTime;

    /**
     * 最后修改时间（UTC 秒级时间戳）
     */
    private Long updateTime;
}
