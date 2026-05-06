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
 * 系统配置表：KV 格式，支持分组，适用于动态运营参数配置
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("sys_config")
public class SysConfig implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键，自增
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 参数名称
     */
    private String configName;

    /**
     * 配置分组，用于逻辑归类，如 sms / payment / app / oss
     */
    private String configGroup;

    /**
     * 配置键名（分组内唯一），如 sms.sign / payment.aba.merchant_id
     */
    private String configKey;

    /**
     * 配置值，支持纯文本和 JSON 字符串
     */
    private String configValue;

    /**
     * 配置项说明，建议填写用途和格式说明
     */
    private String remark;

    /**
     * 创建时间（UTC 秒级时间戳）
     */
    private Long createTime;

    /**
     * 最后修改时间（UTC 秒级时间戳）
     */
    private Long updateTime;

    /**
     * 是否内置
     */
    private Byte isSystem;

    /**
     * 逻辑删除
     */
    private Byte deleted;
}
