package com.cambook.app.service.chat;

import com.baomidou.mybatisplus.extension.service.IService;
import com.cambook.app.domain.dto.chat.ImGroupSendDTO;
import com.cambook.app.domain.dto.chat.ImSendDTO;
import com.cambook.app.domain.vo.chat.ImMessageVO;
import com.cambook.db.entity.ImMessage;

import java.util.List;

/**
 * IM 消息业务服务
 */
public interface IImMessageService extends IService<ImMessage> {

    /** 发送单聊消息（先落库再投递），返回消息 ID */
    Long sendMessage(String senderType, Long senderId, ImSendDTO dto);

    /** 发送群聊消息，返回消息 ID */
    Long sendGroupMessage(String senderType, Long senderId, ImGroupSendDTO dto);

    /** 处理客户端 ACK（标记已送达） */
    void handleAck(Long msgId, String userType, Long userId);

    /** 标记指定会话已读 */
    void markRead(Long conversationId, String userType, Long userId, Long lastReadMsgId);

    /** 拉取离线消息（未送达消息） */
    List<ImMessageVO> pullOffline(String userType, Long userId, Long lastMsgId, int limit);

    /** 查询会话历史消息（倒序分页） */
    List<ImMessageVO> history(Long conversationId, Long beforeMsgId, int limit);
}
