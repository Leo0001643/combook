package com.cambook.app.service.chat;

import com.cambook.app.domain.vo.chat.ImContactGroupVO;
import com.cambook.app.domain.vo.chat.ImContactVO;

import java.util.List;

/**
 * IM 通讯录服务
 *
 * <p>基于角色权限矩阵自动构建「可沟通对象列表」，无需加好友。
 */
public interface IImContactService {

    /**
     * 获取当前用户的通讯录（按角色分组）。
     *
     * @param senderType 当前用户类型
     * @param senderId   当前用户 ID
     * @param merchantId 商户 ID（平台超管传 0）
     */
    List<ImContactGroupVO> contacts(String senderType, Long senderId, Long merchantId);

    /**
     * 搜索通讯录（按姓名/手机号关键词）。
     */
    List<ImContactVO> search(String senderType, Long senderId, Long merchantId, String keyword);

    /**
     * 触发自动建会话（业务事件驱动：如订单创建、技师接单）。
     *
     * @param senderType   发起方类型
     * @param senderId     发起方 ID
     * @param receiverType 接收方类型
     * @param receiverId   接收方 ID
     * @param merchantId   商户 ID
     * @param sysNote      系统通知文本（可选，不为空则推送一条系统消息）
     * @return 会话 ID
     */
    Long autoCreateConversation(String senderType, Long senderId,
                                String receiverType, Long receiverId,
                                Long merchantId, String sysNote);
}
