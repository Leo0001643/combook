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
 * 通知公告表
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("sys_notice")
public class SysNotice implements Serializable {

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
     * 公告标题
     */
    private String title;

    /**
     * 类型：1=通知 2=公告 3=警告
     */
    private Byte type;

    /**
     * 公告内容
     */
    private String content;

    /**
     * 状态：1正常 0关闭
     */
    private Byte status;

    /**
     * 创建者
     */
    private String createBy;

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
