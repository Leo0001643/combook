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
 * APP/H5 底部导航配置：支持多端动态配置，无需发版调整
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("cb_nav")
public class CbNav implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键，自增
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 所属客户端：1=会员 APP 2=技师 APP 3=商户 APP 4=H5
     */
    private Byte clientType;

    /**
     * 导航项唯一标识（英文小写，如 home / order / profile）
     */
    private String navKey;

    /**
     * 导航项标签（中文），必填
     */
    private String labelZh;

    /**
     * 导航项标签（英文）
     */
    private String labelEn;

    /**
     * 导航项标签（越南文）
     */
    private String labelVi;

    /**
     * 导航项标签（柬埔寨文）
     */
    private String labelKm;

    /**
     * 未选中状态图标 URL
     */
    private String iconNormal;

    /**
     * 选中激活状态图标 URL
     */
    private String iconActive;

    /**
     * 前端路由路径（如 /home / /order/list）
     */
    private String routePath;

    /**
     * 显示排序，值越小越靠左
     */
    private Integer sort;

    /**
     * 状态：1=显示 0=隐藏
     */
    private Byte status;

    /**
     * 创建时间（UTC 秒级时间戳）
     */
    private Long createTime;

    /**
     * 最后修改时间（UTC 秒级时间戳）
     */
    private Long updateTime;
}
