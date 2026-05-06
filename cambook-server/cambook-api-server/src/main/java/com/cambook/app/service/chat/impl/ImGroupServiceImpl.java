package com.cambook.app.service.chat.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.cambook.app.domain.dto.chat.ImCreateGroupDTO;
import com.cambook.app.domain.vo.chat.ImGroupVO;
import com.cambook.app.service.chat.IImConversationService;
import com.cambook.app.service.chat.IImGroupMemberService;
import com.cambook.app.service.chat.IImGroupService;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.utils.DateUtils;
import com.cambook.db.entity.ImGroup;
import com.cambook.db.entity.ImGroupMember;
import com.cambook.db.mapper.ImGroupMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * IM 群组业务服务实现
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ImGroupServiceImpl extends ServiceImpl<ImGroupMapper, ImGroup> implements IImGroupService {

    private final IImGroupMemberService memberService;
    private final IImConversationService convService;

    @Override
    @Transactional
    public Long createGroup(String ownerType, Long ownerId, ImCreateGroupDTO dto) {
        long now = DateUtils.nowSecond();
        ImGroup group = new ImGroup();
        group.setName(dto.getName());
        group.setAvatar(dto.getAvatar());
        group.setDescription(dto.getDescription());
        group.setOwnerType(ownerType);
        group.setOwnerId(ownerId);
        group.setMemberCount(1 + dto.getMembers().size());
        group.setMaxMember(500);
        group.setStatus((byte) 0);
        group.setCreateTime(now);
        group.setUpdateTime(now);
        save(group);

        convService.getOrCreateGroup(group.getId());
        insertMember(group.getId(), ownerType, ownerId, (byte) 2, now);
        dto.getMembers().forEach(item -> insertMember(group.getId(), item.getUserType(), item.getUserId(), (byte) 0, now));
        log.info("[Group] 创建群组 groupId={} name={} members={}", group.getId(), dto.getName(), group.getMemberCount());
        return group.getId();
    }

    @Override
    @Transactional
    public void joinGroup(Long groupId, String userType, Long userId) {
        boolean exists = memberService.exists(new LambdaQueryWrapper<ImGroupMember>()
            .eq(ImGroupMember::getGroupId, groupId)
            .eq(ImGroupMember::getUserType, userType)
            .eq(ImGroupMember::getUserId, userId)
            .eq(ImGroupMember::getStatus, 0));
        if (exists) return;

        long now = DateUtils.nowSecond();
        insertMember(groupId, userType, userId, (byte) 0, now);
        lambdaUpdate().eq(ImGroup::getId, groupId).setSql("member_count = member_count + 1").set(ImGroup::getUpdateTime, now).update();
    }

    @Override
    @Transactional
    public void quitGroup(Long groupId, String userType, Long userId) {
        long now = DateUtils.nowSecond();
        memberService.update(null, new LambdaUpdateWrapper<ImGroupMember>()
            .eq(ImGroupMember::getGroupId, groupId).eq(ImGroupMember::getUserType, userType).eq(ImGroupMember::getUserId, userId)
            .set(ImGroupMember::getStatus, 1).set(ImGroupMember::getUpdateTime, now));
        lambdaUpdate().eq(ImGroup::getId, groupId)
            .setSql("member_count = GREATEST(member_count - 1, 0)")
            .set(ImGroup::getUpdateTime, now).update();
    }

    @Override
    @Transactional
    public void dismissGroup(Long groupId, String ownerType, Long ownerId) {
        ImGroup group = Optional.ofNullable(getById(groupId)).orElseThrow(() -> new BusinessException("群组不存在"));
        if (!group.getOwnerType().equals(ownerType) || !group.getOwnerId().equals(ownerId)) {
            throw new BusinessException("仅群主可解散群组");
        }
        lambdaUpdate().eq(ImGroup::getId, groupId).set(ImGroup::getStatus, 1).set(ImGroup::getUpdateTime, DateUtils.nowSecond()).update();
        log.info("[Group] 解散群组 groupId={}", groupId);
    }

    @Override
    public ImGroupVO getGroupInfo(Long groupId) {
        return Optional.ofNullable(getById(groupId)).map(group -> {
            List<ImGroupMember> members = memberService.list(new LambdaQueryWrapper<ImGroupMember>()
                .eq(ImGroupMember::getGroupId, groupId).eq(ImGroupMember::getStatus, 0));
            return toVO(group, members);
        }).orElse(null);
    }

    @Override
    public List<ImGroupVO> listMyGroups(String userType, Long userId) {
        return memberService.list(new LambdaQueryWrapper<ImGroupMember>()
            .eq(ImGroupMember::getUserType, userType).eq(ImGroupMember::getUserId, userId).eq(ImGroupMember::getStatus, 0))
            .stream()
            .map(e -> Optional.ofNullable(getById(e.getGroupId())).map(g -> toVO(g, null)).orElse(null))
            .filter(Objects::nonNull).collect(Collectors.toList());
    }


    private void insertMember(Long groupId, String userType, Long userId, byte role, long now) {
        ImGroupMember m = new ImGroupMember();
        m.setGroupId(groupId);
        m.setUserType(userType);
        m.setUserId(userId);
        m.setRole(role);
        m.setIsMuted((byte) 0);
        m.setStatus((byte) 0);
        m.setJoinedAt(now);
        m.setUpdateTime(now);
        memberService.save(m);
    }

    private ImGroupVO toVO(ImGroup group, List<ImGroupMember> members) {
        ImGroupVO vo = new ImGroupVO();
        vo.setId(group.getId());
        vo.setName(group.getName());
        vo.setAvatar(group.getAvatar());
        vo.setDescription(group.getDescription());
        vo.setOwnerType(group.getOwnerType());
        vo.setOwnerId(group.getOwnerId());
        vo.setMemberCount(group.getMemberCount());
        vo.setMaxMember(group.getMaxMember());
        vo.setCreateTime(group.getCreateTime());
        if (Objects.nonNull(members)) {
            vo.setMembers(members.stream().map(m -> {
                ImGroupVO.MemberItem i = new ImGroupVO.MemberItem();
                i.setUserType(m.getUserType());
                i.setUserId(m.getUserId());
                i.setRole(m.getRole());
                i.setGroupAlias(m.getGroupAlias());
                return i;
            }).collect(Collectors.toList()));
        }
        return vo;
    }
}
