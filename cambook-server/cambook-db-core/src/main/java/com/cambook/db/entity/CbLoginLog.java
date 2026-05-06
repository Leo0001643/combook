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
 * 用户登录日志：记录所有用户登录行为，用于安全审计和异常监控
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("cb_login_log")
public class CbLoginLog implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键，自增
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 用户类型：1=会员 2=技师 3=商户
     */
    private Byte userType;

    /**
     * 用户 ID（根据 user_type 关联对应主表，登录失败时可为 0）
     */
    private Long userId;

    /**
     * 登录手机号（冗余快照，便于直接查询无需关联）
     */
    private String mobile;

    /**
     * 登录方式：1=短信验证码 2=账号密码
     */
    private Byte loginType;

    /**
     * 登录来源 IP 地址
     */
    private String loginIp;

    /**
     * 设备信息快照（JSON，含 os/device/app_version 等，用于安全分析）
     */
    private String deviceInfo;

    /**
     * 登录结果：1=成功 0=失败
     */
    private Byte status;

    /**
     * 登录时间（UTC 秒级时间戳）
     */
    private Long createTime;
}
