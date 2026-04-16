package com.cambook.app.domain.vo;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;

import java.io.Serializable;

/**
 * 在线用户信息（存储于 Redis，TTL = Token 有效期）
 */
@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class OnlineUserVO implements Serializable {

    /** 会话唯一标识（token 前 36 位 UUID 部分） */
    private String sessionId;

    /** 管理员 ID */
    private Long userId;

    /** 登录账号 */
    private String username;

    /** 真实姓名 */
    private String realName;

    /** 所属部门名称 */
    private String deptName;

    /** 客户端 IP */
    private String ipAddr;

    /** 登录城市（简化：仅存 IP，前端显示） */
    private String loginLocation;

    /** 浏览器 */
    private String browser;

    /** 操作系统 */
    private String os;

    /** 会话状态：online / timeout */
    private String status;

    /** 登录时间（毫秒时间戳） */
    private Long loginTime;

    /** 最后访问时间（毫秒时间戳） */
    private Long lastAccessTime;

    /** Token（用于强退时放入黑名单） */
    private String token;
}
