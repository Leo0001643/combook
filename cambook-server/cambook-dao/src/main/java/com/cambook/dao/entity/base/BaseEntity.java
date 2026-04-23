package com.cambook.dao.entity.base;

import lombok.Getter;
import lombok.Setter;

import com.baomidou.mybatisplus.annotation.FieldFill;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import io.swagger.v3.oas.annotations.media.Schema;

import java.io.Serializable;

/**
 * 实体基类：统一主键、审计字段、逻辑删除
 *
 * @author CamBook
 */
@Getter
@Setter
public abstract class BaseEntity implements Serializable {

    @TableId(value = "id", type = IdType.AUTO)
    @Schema(description = "主键 ID")
    private Long id;

    @TableField(fill = FieldFill.INSERT)
    @Schema(description = "创建时间")
    private Long createTime;

    @TableField(fill = FieldFill.INSERT_UPDATE)
    @Schema(description = "更新时间")
    private Long updateTime;

    @TableLogic
    @TableField(value = "deleted")
    @Schema(description = "逻辑删除：0正常 1删除", hidden = true)
    private Integer deleted;

}
