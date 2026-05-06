package com.cambook.app.service.chat.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.cambook.app.domain.vo.chat.ImConversationVO;
import com.cambook.app.service.chat.IImConversationService;
import com.cambook.common.utils.DateUtils;
import com.cambook.db.entity.ImConvMember;
import com.cambook.db.entity.ImConversation;
import com.cambook.db.entity.ImGroup;
import com.cambook.db.mapper.ImConvMemberMapper;
import com.cambook.db.mapper.ImConversationMapper;
import com.cambook.db.mapper.ImGroupMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

/**
 * IM 会话业务服务实现
 *
 * <p>会话列表采用批量查询（listByIds + groupBy）避免 N+1 问题。
 */
@Slf4j
@Service
public class ImConversationServiceImpl extends ServiceImpl<ImConversationMapper, ImConversation>
    implements IImConversationService {

    @Autowired private ImConvMemberMapper convMemberMapper;
    @Autowired private ImGroupMapper      groupMapper;

    // ── 获取/创建会话 ─────────────────────────────────────────────────────────

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long getOrCreate(String userTypeA, Long userIdA, String userTypeB, Long userIdB) {
        String key  = convKey(userTypeA, userIdA, userTypeB, userIdB);
        ImConversation conv = lambdaQuery().eq(ImConversation::getConvKey, key).one();
        if (conv != null) return conv.getId();

        long now = DateUtils.nowSecond();
        conv = new ImConversation();
        conv.setConvKey(key); conv.setConvType((byte) 1);
        conv.setLastMsgTime(now); conv.setCreateTime(now); conv.setUpdateTime(now);
        save(conv);

        insertMember(conv.getId(), userTypeA, userIdA, now);
        insertMember(conv.getId(), userTypeB, userIdB, now);
        log.info("[Conv] 创建单聊 convId={} key={}", conv.getId(), key);
        return conv.getId();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long getOrCreateGroup(Long groupId) {
        String key = "group:" + groupId;
        ImConversation conv = lambdaQuery().eq(ImConversation::getConvKey, key).one();
        if (conv != null) return conv.getId();

        long now = DateUtils.nowSecond();
        conv = new ImConversation();
        conv.setConvKey(key); conv.setConvType((byte) 2); conv.setGroupId(groupId);
        conv.setLastMsgTime(now); conv.setCreateTime(now); conv.setUpdateTime(now);
        save(conv);
        log.info("[Conv] 创建群聊 convId={} groupId={}", conv.getId(), groupId);
        return conv.getId();
    }

    @Override
    public void updateLastMsg(Long conversationId, Long lastMsgId, String preview, long now) {
        lambdaUpdate()
            .eq(ImConversation::getId, conversationId)
            .set(ImConversation::getLastMsgId, lastMsgId)
            .set(ImConversation::getLastMsgPreview, preview)
            .set(ImConversation::getLastMsgTime, now)
            .set(ImConversation::getUpdateTime, now)
            .update();
    }

    // ── 会话列表（批量查询，消除 N+1）────────────────────────────────────────

    @Override
    public List<ImConversationVO> listConversations(String userType, Long userId) {
        List<ImConvMember> members = convMemberMapper.selectList(
            new LambdaQueryWrapper<ImConvMember>()
                .eq(ImConvMember::getUserType, userType)
                .eq(ImConvMember::getUserId, userId));

        if (members.isEmpty()) return Collections.emptyList();

        // 批量查询会话（1次 IN 查询，替代原来 N 次 getById）
        List<Long> convIds = members.stream().map(ImConvMember::getConversationId).collect(Collectors.toList());
        Map<Long, ImConversation> convMap = listByIds(convIds).stream()
            .collect(Collectors.toMap(ImConversation::getId, c -> c));

        // 批量查询群信息（仅群聊，再 1 次 IN 查询）
        Set<Long> groupIds = convMap.values().stream()
            .filter(c -> c.getConvType() == 2 && c.getGroupId() != null)
            .map(ImConversation::getGroupId).collect(Collectors.toSet());
        Map<Long, ImGroup> groupMap = groupIds.isEmpty() ? Collections.emptyMap()
            : groupMapper.selectBatchIds(groupIds).stream().collect(Collectors.toMap(ImGroup::getId, g -> g));

        // 批量查询单聊对端成员（仅单聊会话，再 1 次 IN 查询）
        List<Long> singleConvIds = convMap.values().stream()
            .filter(c -> c.getConvType() == 1).map(ImConversation::getId).collect(Collectors.toList());
        Map<Long, List<ImConvMember>> peerMap = singleConvIds.isEmpty() ? Collections.emptyMap()
            : convMemberMapper.selectList(new LambdaQueryWrapper<ImConvMember>()
                .in(ImConvMember::getConversationId, singleConvIds)
                .ne(ImConvMember::getUserType, userType).or()
                .ne(ImConvMember::getUserId, userId))
              .stream().collect(Collectors.groupingBy(ImConvMember::getConversationId));

        return members.stream()
            .map(m -> buildVO(m, convMap, groupMap, peerMap, userType, userId))
            .filter(Objects::nonNull)
            .sorted(Comparator.comparingLong(
                (ImConversationVO v) -> v.getLastMsgTime() != null ? v.getLastMsgTime() : 0L).reversed())
            .collect(Collectors.toList());
    }

    @Override
    public ImConversationVO getConversation(Long conversationId, String userType, Long userId) {
        ImConvMember member = convMemberMapper.selectOne(new LambdaQueryWrapper<ImConvMember>()
            .eq(ImConvMember::getConversationId, conversationId)
            .eq(ImConvMember::getUserType, userType)
            .eq(ImConvMember::getUserId, userId));
        if (member == null) return null;

        ImConversation conv = getById(conversationId);
        if (conv == null) return null;

        Map<Long, ImGroup> groupMap = conv.getConvType() == 2 && conv.getGroupId() != null
            ? Map.of(conv.getGroupId(), groupMapper.selectById(conv.getGroupId()))
            : Collections.emptyMap();

        List<ImConvMember> peers = conv.getConvType() == 1
            ? convMemberMapper.selectList(new LambdaQueryWrapper<ImConvMember>()
                .eq(ImConvMember::getConversationId, conversationId)
                .ne(ImConvMember::getUserType, userType).or()
                .ne(ImConvMember::getUserId, userId))
            : Collections.emptyList();
        Map<Long, List<ImConvMember>> peerMap = Map.of(conversationId, peers);

        return buildVO(member, Map.of(conversationId, conv), groupMap, peerMap, userType, userId);
    }

    // ── 私有方法 ──────────────────────────────────────────────────────────────

    private ImConversationVO buildVO(ImConvMember member,
                                      Map<Long, ImConversation> convMap,
                                      Map<Long, ImGroup> groupMap,
                                      Map<Long, List<ImConvMember>> peerMap,
                                      String myType, Long myId) {
        ImConversation conv = convMap.get(member.getConversationId());
        if (conv == null) return null;

        ImConversationVO vo = new ImConversationVO();
        vo.setConversationId(conv.getId()); vo.setConvType(conv.getConvType());
        vo.setLastMsgId(conv.getLastMsgId()); vo.setLastMsgPreview(conv.getLastMsgPreview());
        vo.setLastMsgTime(conv.getLastMsgTime()); vo.setUnreadCount(member.getUnreadCount());
        vo.setIsPinned(member.getIsPinned()); vo.setIsMuted(member.getIsMuted());

        if (conv.getConvType() == 2) {
            vo.setGroupId(conv.getGroupId());
            ImGroup group = groupMap.get(conv.getGroupId());
            if (group != null) { vo.setGroupName(group.getName()); vo.setGroupAvatar(group.getAvatar()); }
        } else {
            List<ImConvMember> peers = peerMap.getOrDefault(conv.getId(), Collections.emptyList());
            peers.stream()
                .filter(m -> !(m.getUserType().equals(myType) && m.getUserId().equals(myId)))
                .findFirst()
                .ifPresent(peer -> { vo.setPeerType(peer.getUserType()); vo.setPeerId(peer.getUserId()); });
        }
        return vo;
    }

    private void insertMember(Long convId, String userType, Long userId, long now) {
        ImConvMember m = new ImConvMember();
        m.setConversationId(convId); m.setUserType(userType); m.setUserId(userId);
        m.setUnreadCount(0); m.setIsPinned((byte) 0); m.setIsMuted((byte) 0);
        m.setJoinedAt(now); m.setUpdateTime(now);
        convMemberMapper.insert(m);
    }

    /** 单聊 key：字典序排序后拼接，保证同一对话者唯一 */
    private String convKey(String typeA, Long idA, String typeB, Long idB) {
        String a = typeA + ":" + idA, b = typeB + ":" + idB;
        return a.compareTo(b) <= 0 ? a + "_" + b : b + "_" + a;
    }
}
