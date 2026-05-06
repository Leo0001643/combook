package com.cambook.db.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;

/**
 * IM 会话表（单聊/群聊通用）
 */
@Data
@TableName("im_conversation")
public class ImConversation implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 会话唯一键：
     * 单聊：小key_大key（字典序，如 member:100_technician:200）
     * 群聊：group:{groupId}
     */
    private String convKey;

    /** 会话类型：1=单聊 2=群聊 */
    private Byte convType;

    /** 关联群组 ID（群聊有效） */
    private Long groupId;

    /** 最后一条消息 ID */
    private Long lastMsgId;

    /** 最后消息内容预览（≤100 字符） */
    private String lastMsgPreview;

    /** 最后消息时间戳（秒） */
    private Long lastMsgTime;

    /** 创建时间戳（秒） */
    private Long createTime;

    /** 更新时间戳（秒） */
    private Long updateTime;
}
