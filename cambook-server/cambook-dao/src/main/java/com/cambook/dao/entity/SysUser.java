package com.cambook.dao.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.cambook.dao.entity.base.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 后台管理员账号（对应 sys_user 表）
 *
 * @author CamBook
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("sys_user")
public class SysUser extends BaseEntity {

    /** 登录账号（全局唯一，4-32 位，字母/数字/下划线） */
    private String username;

    /** 登录密码（MD5 哈希） */
    private String password;

    /** 真实姓名，用于后台日志展示 */
    @TableField("real_name")
    private String realName;

    /** 头像图片 URL */
    private String avatar;

    /** 邮箱地址 */
    private String email;

    /** 手机号 */
    private String mobile;

    /** 所属职位 ID */
    @TableField("position_id")
    private Long positionId;

    /** 账号状态：1=正常 0=停用 */
    private Integer status;
}
