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
 * 部门菜单权限
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("sys_dept_menu")
public class SysDeptMenu implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 所属商户
     */
    private Long merchantId;

    /**
     * 部门ID
     */
    private Long deptId;

    /**
     * 菜单路由key
     */
    private String menuKey;

    /**
     * 创建时间（UTC 秒级时间戳）
     */
    private Long createTime;
}
