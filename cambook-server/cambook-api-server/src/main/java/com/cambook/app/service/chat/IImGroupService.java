package com.cambook.app.service.chat;

import com.cambook.app.domain.dto.chat.ImCreateGroupDTO;
import com.cambook.app.domain.vo.chat.ImGroupVO;

import java.util.List;

/**
 * IM 群组业务服务
 */
public interface IImGroupService {

    /** 创建群组，返回群 ID */
    Long createGroup(String ownerType, Long ownerId, ImCreateGroupDTO dto);

    /** 加入群组 */
    void joinGroup(Long groupId, String userType, Long userId);

    /** 退出群组 */
    void quitGroup(Long groupId, String userType, Long userId);

    /** 解散群组（仅群主） */
    void dismissGroup(Long groupId, String ownerType, Long ownerId);

    /** 获取群信息（含成员列表） */
    ImGroupVO getGroupInfo(Long groupId);

    /** 查询用户加入的所有群组 */
    List<ImGroupVO> listMyGroups(String userType, Long userId);
}
