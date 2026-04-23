package com.cambook.dao.entity;

import lombok.Getter;
import lombok.Setter;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
/** 部门菜单权限 */
@TableName("sys_dept_menu")
@Getter
@Setter
public class SysDeptMenu {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long merchantId;
    private Long deptId;
    private String menuKey;
    private Long createTime;

}
