package com.cambook.app.service.chat;

import com.cambook.app.domain.vo.chat.ImConversationVO;

import java.util.List;

/**
 * IM 会话业务服务
 */
public interface IImConversationService {

    /** 获取或创建单聊会话，返回会话 ID */
    Long getOrCreate(String userTypeA, Long userIdA, String userTypeB, Long userIdB);

    /** 获取或创建群聊会话，返回会话 ID */
    Long getOrCreateGroup(Long groupId);

    /** 更新会话最后一条消息 */
    void updateLastMsg(Long conversationId, Long lastMsgId, String preview, long now);

    /** 查询用户会话列表（按最后消息时间倒序） */
    List<ImConversationVO> listConversations(String userType, Long userId);

    /** 获取单个会话详情 */
    ImConversationVO getConversation(Long conversationId, String userType, Long userId);
}
