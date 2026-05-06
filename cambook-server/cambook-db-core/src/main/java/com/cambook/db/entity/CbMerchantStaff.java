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
 * 商户员工表
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("cb_merchant_staff")
public class CbMerchantStaff implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 所属商户ID
     */
    private Long merchantId;

    /**
     * 所属部门ID
     */
    private Long deptId;

    /**
     * 所属职位ID
     */
    private Long positionId;

    /**
     * 登录用户名
     */
    private String username;

    /**
     * MD5密码
     */
    private String password;

    /**
     * 真实姓名
     */
    private String realName;

    /**
     * 手机号
     */
    private String mobile;

    /**
     * Telegram账号
     */
    private String telegram;

    /**
     * 邮箱
     */
    private String email;

    /**
     * 头像URL
     */
    private String avatar;

    /**
     * 角色名称
     */
    private String roleName;

    /**
     * 权限码（逗号分隔）
     */
    private String perms;

    /**
     * 状态 1正常 0停用
     */
    private Byte status;

    /**
     * 备注
     */
    private String remark;

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
