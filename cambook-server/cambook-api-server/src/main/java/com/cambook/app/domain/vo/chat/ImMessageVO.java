package com.cambook.app.domain.vo.chat;

import lombok.Data;

/**
 * IM 消息视图对象
 */
@Data
public class ImMessageVO {
    private Long   msgId;
    private Long   conversationId;
    private String senderType;
    private Long   senderId;
    private String senderNickname;
    private String senderAvatar;
    private Byte   isGroup;
    private Long   groupId;
    private Byte   msgType;
    private String content;
    private Byte   status;
    private Long   createTime;
}
