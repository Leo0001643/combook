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
 * 操作日志记录
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("sys_oper_log")
public class SysOperLog implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 模块标题
     */
    private String title;

    /**
     * 方法名称
     */
    private String method;

    /**
     * 请求URL
     */
    private String requestUrl;

    /**
     * HTTP请求方式
     */
    private String requestMethod;

    /**
     * 操作人员
     */
    private String operName;

    /**
     * 主机地址
     */
    private String operIp;

    /**
     * 请求参数
     */
    private String operParam;

    /**
     * 返回结果
     */
    private String jsonResult;

    /**
     * 操作状态：0正常 1异常
     */
    private Byte status;

    /**
     * 错误消息
     */
    private String errorMsg;

    /**
     * 操作时间（UTC 秒级时间戳）
     */
    private Long operTime;
}
