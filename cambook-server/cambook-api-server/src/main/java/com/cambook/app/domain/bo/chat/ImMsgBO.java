package com.cambook.app.domain.bo.chat;

import com.cambook.app.domain.dto.chat.ImGroupSendDTO;
import com.cambook.app.domain.dto.chat.ImSendDTO;
import com.cambook.db.entity.ImMessage;
import lombok.Builder;
import lombok.Getter;

/**
 * IM 消息构建 BO（Business Object）
 *
 * <p>统一封装单聊/群聊消息的构建参数，通过 {@link #toEntity()} 转为数据库实体，
 * 避免私有方法参数列表过长，也方便后续扩展字段。
 *
 * <p>推荐通过静态工厂方法创建：
 * <pre>
 *   ImMsgBO bo = ImMsgBO.forSingle(msgId, convId, senderType, senderId, dto, now);
 *   ImMsgBO bo = ImMsgBO.forGroup(msgId, convId, senderType, senderId, dto, now);
 * </pre>
 */
@Getter
@Builder
public class ImMsgBO {

    private final long   msgId;
    private final Long   convId;
    private final String clientMsgId;
    private final String senderType;
    private final Long   senderId;
    private final String receiverType;
    private final Long   receiverId;
    private final byte   isGroup;
    private final Long   groupId;
    private final byte   msgType;
    private final String content;
    private final long   now;

    // ── 静态工厂 ──────────────────────────────────────────────────────────────

    public static ImMsgBO forSingle(long msgId, Long convId, String senderType, Long senderId,
                                     ImSendDTO dto, long now) {
        return ImMsgBO.builder()
            .msgId(msgId)
            .convId(convId)
            .clientMsgId(dto.getClientMsgId())
            .senderType(senderType)
            .senderId(senderId)
            .receiverType(dto.getReceiverType())
            .receiverId(dto.getReceiverId())
            .isGroup((byte) 0)
            .msgType(dto.getMsgType().byteValue())
            .content(dto.getContent())
            .now(now)
            .build();
    }

    public static ImMsgBO forGroup(long msgId, Long convId, String senderType, Long senderId,
                                    ImGroupSendDTO dto, long now) {
        return ImMsgBO.builder()
            .msgId(msgId)
            .convId(convId)
            .clientMsgId(dto.getClientMsgId())
            .senderType(senderType)
            .senderId(senderId)
            .receiverId(0L)
            .isGroup((byte) 1)
            .groupId(dto.getGroupId())
            .msgType(dto.getMsgType().byteValue())
            .content(dto.getContent())
            .now(now)
            .build();
    }

    // ── 转换 ──────────────────────────────────────────────────────────────────

    /** 将 BO 转为 {@link ImMessage} 数据库实体（status=1 已落库，retryCount=0） */
    public ImMessage toEntity() {
        ImMessage m = new ImMessage();
        m.setMsgId(msgId);
        m.setConversationId(convId);
        m.setClientMsgId(clientMsgId);
        m.setSenderType(senderType);
        m.setSenderId(senderId);
        m.setReceiverType(receiverType);
        m.setReceiverId(receiverId);
        m.setIsGroup(isGroup);
        m.setGroupId(groupId);
        m.setMsgType(msgType);
        m.setContent(content);
        m.setStatus((byte) 1);
        m.setRetryCount((byte) 0);
        m.setCreateTime(now);
        m.setUpdateTime(now);
        return m;
    }
}
