package com.cambook.db.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;

/**
 * IM 会话成员表（记录每个参与方的未读数和已读游标）
 */
@Data
@TableName("im_conv_member")
public class ImConvMember implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /** 所属会话 ID */
    private Long conversationId;

    /** 用户类型：member / technician / merchant */
    private String userType;

    /** 用户 ID */
    private Long userId;

    /** 未读消息数 */
    private Integer unreadCount;

    /** 最后已读消息 ID（已读游标） */
    private Long lastReadMsgId;

    /** 是否置顶：0=否 1=是 */
    private Byte isPinned;

    /** 是否免打扰：0=否 1=是 */
    private Byte isMuted;

    /** 加入时间戳（秒） */
    private Long joinedAt;

    /** 更新时间戳（秒） */
    private Long updateTime;
}
