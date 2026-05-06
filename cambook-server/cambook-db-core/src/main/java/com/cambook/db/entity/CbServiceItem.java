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
 * 服务项目表：含多语言名称/描述、时长、分级定价
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("cb_service_item")
public class CbServiceItem implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键，自增
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 所属服务分类 ID，关联 cb_service_category.id
     */
    private Long categoryId;

    /**
     * 服务项名称（中文），必填
     */
    private String nameZh;

    /**
     * 服务项名称（英文）
     */
    private String nameEn;

    /**
     * 服务项名称（越南文）
     */
    private String nameVi;

    /**
     * 服务项名称（柬埔寨文）
     */
    private String nameKm;

    /**
     * 服务项名称（日文）
     */
    private String nameJa;

    /**
     * 服务项名称（韩文）
     */
    private String nameKo;

    /**
     * 服务详情描述（中文，富文本或纯文本）
     */
    private String descZh;

    /**
     * 服务详情描述（英文）
     */
    private String descEn;

    /**
     * 服务时长（分钟），用于排班冲突检测和展示
     */
    private Integer duration;

    /**
     * 普通用户价格（USD）
     */
    private BigDecimal basePrice;

    /**
     * 会员优惠价格（USD），为空则不区分等级
     */
    private BigDecimal memberPrice;

    /**
     * 服务封面图片 URL
     */
    private String cover;

    /**
     * 排序权重，值越小越靠前
     */
    private Integer sort;

    /**
     * 状态：1=上架 0=下架
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
