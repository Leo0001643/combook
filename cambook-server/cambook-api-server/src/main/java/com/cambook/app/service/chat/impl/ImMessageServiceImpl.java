package com.cambook.app.service.chat.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.cambook.app.domain.bo.chat.ImMsgBO;
import com.cambook.app.domain.dto.chat.ImGroupSendDTO;
import com.cambook.app.domain.dto.chat.ImSendDTO;
import com.cambook.app.domain.vo.chat.ImMessageVO;
import com.cambook.app.service.chat.IImConvMemberService;
import com.cambook.app.service.chat.IImConversationService;
import com.cambook.app.service.chat.IImGroupMemberService;
import com.cambook.app.service.chat.IImMessageService;
import com.cambook.app.service.chat.IImMsgAckService;
import com.cambook.chat.protocol.ImCmd;
import com.cambook.chat.protocol.ImPacket;
import com.cambook.chat.routing.UserRouter;
import com.cambook.common.utils.DateUtils;
import com.cambook.common.utils.SnowflakeGenerator;
import com.cambook.db.entity.*;
import com.cambook.db.mapper.ImMessageMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * IM 消息业务服务实现
 *
 * <p><b>消息可靠三层保障：</b>
 * <ol>
 *   <li><b>先落库</b>：status=1 写入 DB，进程崩溃也不丢</li>
 *   <li><b>实时推送</b>：Redis 路由（本节点直推 / 跨节点 Pub/Sub）</li>
 *   <li><b>ACK 重试</b>：{@link com.cambook.app.common.chat.ImAckRetryScheduler} 定期补发</li>
 * </ol>
 *
 * <p><b>幂等保证</b>：客户端携带 {@code clientMsgId} 时，服务端通过唯一索引防止重复落库。
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ImMessageServiceImpl extends ServiceImpl<ImMessageMapper, ImMessage>
    implements IImMessageService {

    private final SnowflakeGenerator snowflake;
    private final IImConversationService convService;
    private final IImConvMemberService convMemberService;
    private final IImGroupMemberService groupMemberService;
    private final IImMsgAckService ackService;
    private final UserRouter router;

    // ── 单聊 ──────────────────────────────────────────────────────────────────

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long sendMessage(String senderType, Long senderId, ImSendDTO dto) {
        long now = DateUtils.nowSecond();
        long msgId = snowflake.nextId();
        Long convId = convService.getOrCreate(senderType, senderId, dto.getReceiverType(), dto.getReceiverId());

        ImMsgBO bo = ImMsgBO.forSingle(msgId, convId, senderType, senderId, dto, now);
        save(bo.toEntity());

        convService.updateLastMsg(convId, msgId, preview(dto.getMsgType(), dto.getContent()), now);
        incrUnread(convId, dto.getReceiverType(), dto.getReceiverId(), now);

        ImPacket notify = notifyPacket(bo);
        boolean delivered = router.route(dto.getReceiverType(), dto.getReceiverId(), notify);
        if (delivered) updateStatus(msgId, (byte) 2, now);

        router.route(senderType, senderId, ImPacket.of(ImCmd.MSG_DELIVERED, String.valueOf(msgId),
            Map.of("msgId", msgId, "status", delivered ? 2 : 1)));

        log.info("[Chat] 单聊 msgId={} {}:{} -> {}:{} delivered={}",
            msgId, senderType, senderId, dto.getReceiverType(), dto.getReceiverId(), delivered);
        return msgId;
    }

    // ── 群聊（扩散读：写一次，在线成员推，离线成员上线自拉）──────────────────

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long sendGroupMessage(String senderType, Long senderId, ImGroupSendDTO dto) {
        long now = DateUtils.nowSecond();
        long msgId = snowflake.nextId();
        Long convId = convService.getOrCreateGroup(dto.getGroupId());

        ImMsgBO bo = ImMsgBO.forGroup(msgId, convId, senderType, senderId, dto, now);
        save(bo.toEntity());

        convService.updateLastMsg(convId, msgId, preview(dto.getMsgType(), dto.getContent()), now);

        List<ImGroupMember> members = groupMemberService.list(
            new LambdaQueryWrapper<ImGroupMember>()
                .eq(ImGroupMember::getGroupId, dto.getGroupId())
                .eq(ImGroupMember::getStatus, 0)
                .ne(ImGroupMember::getUserId, senderId)
                .select(ImGroupMember::getUserType, ImGroupMember::getUserId));

        ImPacket notify = groupNotifyPacket(bo);
        long pushed = members.stream()
            .filter(m -> router.route(m.getUserType(), m.getUserId(), notify))
            .count();

        log.info("[Chat] 群消息 msgId={} groupId={} pushed={}/{}",
            msgId, dto.getGroupId(), pushed, members.size());
        return msgId;
    }

    // ── ACK ──────────────────────────────────────────────────────────────────

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void handleAck(Long msgId, String userType, Long userId) {
        long now = DateUtils.nowSecond();
        ImMsgAck ack = new ImMsgAck();
        ack.setMsgId(msgId);
        ack.setUserType(userType);
        ack.setUserId(userId);
        ack.setAckType((byte) 1);
        ack.setAckTime(now);
        ackService.insertOrIgnore(ack);
        updateStatus(msgId, (byte) 2, now);
    }

    // ── 已读 ──────────────────────────────────────────────────────────────────

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void markRead(Long conversationId, String userType, Long userId, Long lastReadMsgId) {
        long now = DateUtils.nowSecond();
        convMemberService.update(null, new LambdaUpdateWrapper<ImConvMember>()
            .eq(ImConvMember::getConversationId, conversationId)
            .eq(ImConvMember::getUserType, userType)
            .eq(ImConvMember::getUserId, userId)
            .set(ImConvMember::getUnreadCount, 0)
            .set(ImConvMember::getLastReadMsgId, lastReadMsgId)
            .set(ImConvMember::getUpdateTime, now));

        ackService.update(null, new LambdaUpdateWrapper<ImMsgAck>()
            .eq(ImMsgAck::getUserType, userType)
            .eq(ImMsgAck::getUserId, userId)
            .le(ImMsgAck::getMsgId, lastReadMsgId)
            .eq(ImMsgAck::getAckType, 1)
            .set(ImMsgAck::getAckType, 2)
            .set(ImMsgAck::getAckTime, now));
    }

    // ── 离线消息（上线拉取） ──────────────────────────────────────────────────

    @Override
    public List<ImMessageVO> pullOffline(String userType, Long userId, Long lastMsgId, int limit) {
        return lambdaQuery()
            .eq(ImMessage::getReceiverType, userType)
            .eq(ImMessage::getReceiverId, userId)
            .eq(ImMessage::getIsGroup, 0)
            .lt(ImMessage::getStatus, 2)
            .gt(lastMsgId > 0, ImMessage::getMsgId, lastMsgId)
            .orderByAsc(ImMessage::getMsgId)
            .last("LIMIT " + Math.min(limit, 50))
            .list().stream().map(this::toVO).collect(Collectors.toList());
    }

    // ── 历史消息（倒序分页） ──────────────────────────────────────────────────

    @Override
    public List<ImMessageVO> history(Long conversationId, Long beforeMsgId, int limit) {
        return lambdaQuery()
            .eq(ImMessage::getConversationId, conversationId)
            .lt(beforeMsgId != null && beforeMsgId > 0, ImMessage::getMsgId, beforeMsgId)
            .orderByDesc(ImMessage::getMsgId)
            .last("LIMIT " + Math.min(limit, 50))
            .list().stream().map(this::toVO).collect(Collectors.toList());
    }

    // ── 私有方法 ──────────────────────────────────────────────────────────────

    private ImPacket notifyPacket(ImMsgBO bo) {
        return ImPacket.of(ImCmd.MSG_NOTIFY, String.valueOf(bo.getMsgId()), Map.of(
            "msgId", bo.getMsgId(),
            "conversationId", bo.getConvId(),
            "senderType", bo.getSenderType(),
            "senderId", bo.getSenderId(),
            "msgType", bo.getMsgType(),
            "content", bo.getContent(),
            "createTime", bo.getNow()));
    }

    private ImPacket groupNotifyPacket(ImMsgBO bo) {
        return ImPacket.of(ImCmd.GROUP_NOTIFY, String.valueOf(bo.getMsgId()), Map.of(
            "msgId", bo.getMsgId(),
            "conversationId", bo.getConvId(),
            "groupId", bo.getGroupId(),
            "senderType", bo.getSenderType(),
            "senderId", bo.getSenderId(),
            "msgType", bo.getMsgType(),
            "content", bo.getContent(),
            "createTime", bo.getNow()));
    }

    private void updateStatus(long msgId, byte status, long now) {
        lambdaUpdate()
            .eq(ImMessage::getMsgId, msgId)
            .set(ImMessage::getStatus, status)
            .set(ImMessage::getUpdateTime, now)
            .update();
    }

    private void incrUnread(Long convId, String userType, Long userId, long now) {
        convMemberService.update(null, new LambdaUpdateWrapper<ImConvMember>()
            .eq(ImConvMember::getConversationId, convId)
            .eq(ImConvMember::getUserType, userType)
            .eq(ImConvMember::getUserId, userId)
            .setSql("unread_count = unread_count + 1")
            .set(ImConvMember::getUpdateTime, now));
    }

    private String preview(Integer msgType, String content) {
        return switch (msgType != null ? msgType : 0) {
            case 1 -> content != null && content.length() > 100 ? content.substring(0, 100) : content;
            case 2 -> "[图片]";
            case 3 -> "[语音]";
            case 4 -> "[视频]";
            case 5 -> "[文件]";
            case 6 -> "[系统通知]";
            case 7 -> "[通话]";
            default -> "[消息]";
        };
    }

    private ImMessageVO toVO(ImMessage m) {
        ImMessageVO vo = new ImMessageVO();
        vo.setMsgId(m.getMsgId());
        vo.setConversationId(m.getConversationId());
        vo.setSenderType(m.getSenderType());
        vo.setSenderId(m.getSenderId());
        vo.setIsGroup(m.getIsGroup());
        vo.setGroupId(m.getGroupId());
        vo.setMsgType(m.getMsgType());
        vo.setContent(m.getContent());
        vo.setStatus(m.getStatus());
        vo.setCreateTime(m.getCreateTime());
        return vo;
    }
}
