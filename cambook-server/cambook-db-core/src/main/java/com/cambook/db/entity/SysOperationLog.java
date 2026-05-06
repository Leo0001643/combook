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
 * 后台操作日志：记录管理员所有操作行为，用于安全审计
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("sys_operation_log")
public class SysOperationLog implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键，自增
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 操作管理员 ID，关联 sys_user.id
     */
    private Long userId;

    /**
     * 操作管理员账号（冗余快照，防关联查询）
     */
    private String username;

    /**
     * 所属功能模块，如 会员管理 / 订单管理
     */
    private String module;

    /**
     * 操作描述，如 封禁会员 / 审核通过技师
     */
    private String action;

    /**
     * 目标方法全限定名，如 com.cambook.app.controller.admin.MemberController.updateStatus
     */
    private String method;

    /**
     * 请求 URL，如 /admin/member/123/status
     */
    private String requestUrl;

    /**
     * 请求参数（JSON 格式，敏感字段如密码应脱敏后记录）
     */
    private String requestParam;

    /**
     * 接口响应 HTTP 状态码
     */
    private Integer responseCode;

    /**
     * 接口执行耗时（毫秒），用于性能监控
     */
    private Integer costMs;

    /**
     * 操作者 IP 地址
     */
    private String ip;

    /**
     * 操作发生时间（UTC 秒级时间戳）
     */
    private Long createTime;
}
