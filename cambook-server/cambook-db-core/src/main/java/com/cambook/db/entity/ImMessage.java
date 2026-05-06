package com.cambook.db.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;

/**
 * IM 消息表（Snowflake ID，支持单聊/群聊）
 *
 * <p>状态流转：1(已落库) → 2(已送达) → 3(已读) / 9(重试耗尽)
 */
@Data
@TableName("im_message")
public class ImMessage implements Serializable {

    private static final long serialVersionUID = 1L;

    /** 消息 ID（雪花算法生成，全局唯一有序） */
    @TableId(value = "msg_id", type = IdType.INPUT)
    private Long msgId;

    /** 所属会话 ID */
    private Long conversationId;

    /** 客户端幂等 ID（可选，传入后相同 ID 不会重复落库） */
    private String clientMsgId;

    /** 发送方类型：member / technician / merchant / system */
    private String senderType;

    /** 发送方 ID */
    private Long senderId;

    /** 接收方类型（单聊有效） */
    private String receiverType;

    /** 接收方 ID（单聊有效；群聊填 0） */
    private Long receiverId;

    /** 是否群聊：0=单聊 1=群聊 */
    private Byte isGroup;

    /** 群组 ID（群聊时有效） */
    private Long groupId;

    /**
     * 消息类型：
     * 1=文本 2=图片 3=语音 4=视频 5=文件 6=系统通知 7=WebRTC信令
     */
    private Byte msgType;

    /**
     * 消息内容（JSON 字符串）：
     * 文本：{"text":"hello"}
     * 图片：{"url":"...","width":400,"height":300,"mediaId":1}
     * 语音：{"url":"...","duration":10,"mediaId":2}
     * 信令：{"action":"invite","sdp":"..."}
     */
    private String content;

    /** 状态：1=已落库 2=已送达 3=已读 9=发送失败 */
    private Byte status;

    /** 重试次数（ACK 超时重试计数） */
    private Byte retryCount;

    /** 发送时间戳（秒） */
    private Long createTime;

    /** 更新时间戳（秒） */
    private Long updateTime;
}
