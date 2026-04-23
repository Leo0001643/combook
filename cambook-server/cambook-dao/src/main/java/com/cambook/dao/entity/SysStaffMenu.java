package com.cambook.dao.entity;

import lombok.Getter;
import lombok.Setter;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
/** 员工菜单权限（个人覆盖） */
@TableName("sys_staff_menu")
@Getter
@Setter
public class SysStaffMenu {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long merchantId;
    private Long staffId;
    private String menuKey;
    private Long createTime;

}
