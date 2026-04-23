package com.cambook.dao.entity;

import lombok.Getter;
import lombok.Setter;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
/** 职位菜单权限 */
@TableName("sys_position_menu")
@Getter
@Setter
public class SysPositionMenu {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long merchantId;
    private Long positionId;
    private String menuKey;
    private Long createTime;

}
