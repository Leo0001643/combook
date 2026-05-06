package com.cambook.db.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;

/**
 * IM 消息 ACK 表（追踪每条消息的送达/已读状态）
 *
 * <p>主键为 (msg_id, user_type, user_id) 复合键，避免冗余 auto_increment，
 * 直接走主键查询，无需二级索引。
 */
@Data
@TableName("im_msg_ack")
public class ImMsgAck implements Serializable {

    private static final long serialVersionUID = 1L;

    /** 消息 ID（复合主键之一，由 @TableId 标注首列） */
    @TableId(value = "msg_id", type = IdType.INPUT)
    private Long msgId;

    /** 接收方类型 */
    private String userType;

    /** 接收方 ID */
    private Long userId;

    /**
     * ACK 状态：
     * 1=已送达（Netty 推送成功）
     * 2=已读（用户主动标记已读）
     */
    private Byte ackType;

    /** ACK 时间戳（秒） */
    private Long ackTime;
}
