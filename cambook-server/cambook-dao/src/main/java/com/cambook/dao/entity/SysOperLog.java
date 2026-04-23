package com.cambook.dao.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;

/**
 * 操作日志记录（不含逻辑删除，保留审计完整性）
 */
@Data
@TableName("sys_oper_log")
public class SysOperLog implements Serializable {
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;
    private String title;
    private String method;
    private String requestUrl;
    private String requestMethod;
    private String operName;
    private String operIp;
    private String operParam;
    private String jsonResult;
    private Integer status;
    private String errorMsg;
    private Long operTime;
}
