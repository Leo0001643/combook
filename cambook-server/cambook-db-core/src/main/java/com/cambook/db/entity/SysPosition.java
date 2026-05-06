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
 * 后台职位表
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("sys_position")
public class SysPosition implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 职位 ID
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 归属商户ID（null=平台）
     */
    private Long merchantId;

    /**
     * 所属部门ID
     */
    private Long deptId;

    /**
     * 职位名称
     */
    private String name;

    /**
     * 职位编码（全局唯一）
     */
    private String code;

    /**
     * 备注说明
     */
    private String remark;

    /**
     * 排序（越小越前）
     */
    private Integer sort;

    /**
     * 状态：1启用 0停用
     */
    private Byte status;

    /**
     * 1=全量权限（如总裁/CEO），跳过菜单分配直接获得所有菜单
     */
    private Byte fullAccess;

    /**
     * 逻辑删除：0正常 1删除
     */
    private Byte deleted;

    /**
     * 创建时间（UTC 秒级时间戳）
     */
    private Long createTime;

    /**
     * 更新时间（UTC 秒级时间戳）
     */
    private Long updateTime;
}
