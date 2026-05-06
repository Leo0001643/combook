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
 * 国际化枚举消息表：存储接口响应消息的多语言内容，启动时加载入内存
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("sys_i18n")
public class SysI18n implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键，自增
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 枚举常量名，与 CbCodeEnum 枚举值一一对应，如 SUCCESS / PARAM_ERROR
     */
    private String enumCode;

    /**
     * 语言标识：zh=中文 en=英文 vi=越南文 km=柬埔寨文 ja=日文 ko=韩文
     */
    private String lang;

    /**
     * 对应语言的消息文本
     */
    private String message;

    /**
     * 创建时间（UTC 秒级时间戳）
     */
    private Long createTime;

    /**
     * 最后修改时间（UTC 秒级时间戳）
     */
    private Long updateTime;
}
