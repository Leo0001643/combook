package com.cambook.app.domain.vo.chat;

import lombok.Data;

/**
 * IM 会话视图对象
 */
@Data
public class ImConversationVO {
    private Long    conversationId;
    private Byte    convType;          // 1=单聊 2=群聊
    private Long    groupId;

    /** 对方信息（单聊有效） */
    private String  peerType;
    private Long    peerId;
    private String  peerNickname;
    private String  peerAvatar;

    /** 群信息（群聊有效） */
    private String  groupName;
    private String  groupAvatar;

    private Long    lastMsgId;
    private String  lastMsgPreview;
    private Long    lastMsgTime;
    private Integer unreadCount;
    private Byte    isPinned;
    private Byte    isMuted;
}
