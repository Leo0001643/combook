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
 * 后台管理员账号表：支持账号密码登录，关联角色进行 RBAC 权限控制
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("sys_user")
public class SysUser implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键，自增
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 登录账号（全局唯一，4-32位，字母/数字/下划线）
     */
    private String username;

    /**
     * 登录密码（BCrypt 哈希，禁止明文存储）
     */
    private String password;

    /**
     * 真实姓名，用于后台日志展示
     */
    private String realName;

    /**
     * 头像图片 URL
     */
    private String avatar;

    /**
     * 邮箱地址，可用于找回密码
     */
    private String email;

    /**
     * 手机号，可用于告警通知
     */
    private String mobile;

    /**
     * 所属职位ID
     */
    private Long positionId;

    /**
     * 账号状态：1=正常可用 0=已停用
     */
    private Byte status;

    /**
     * 最后一次登录时间（UTC 秒级时间戳）
     */
    private Long lastLoginTime;

    /**
     * 最后一次登录 IP 地址
     */
    private String lastLoginIp;

    /**
     * 逻辑删除标识：0=正常 1=已删除
     */
    private Byte deleted;

    /**
     * 账号创建时间（UTC 秒级时间戳）
     */
    private Long createTime;

    /**
     * 最后修改时间（UTC 秒级时间戳）
     */
    private Long updateTime;
}
