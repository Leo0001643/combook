package com.cambook.app.service.chat.impl;

import com.cambook.app.common.chat.ImPermissionEngine;
import com.cambook.app.domain.enums.ImUserRole;
import com.cambook.app.domain.vo.chat.ImContactGroupVO;
import com.cambook.app.domain.vo.chat.ImContactVO;
import com.cambook.app.service.chat.IImContactService;
import com.cambook.app.service.chat.IImConversationService;
import com.cambook.app.service.chat.IImOrgMemberService;
import com.cambook.chat.protocol.ImCmd;
import com.cambook.chat.protocol.ImPacket;
import com.cambook.chat.routing.UserRouter;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

// LinkedHashSet used explicitly in batchFindExistingConvIds

/**
 * IM 通讯录服务实现
 *
 * <p>通讯录生成逻辑：
 * <ol>
 *   <li>获取发送方 IM 角色</li>
 *   <li>查权限规则，得到可联系的角色集合</li>
 *   <li>从 {@code im_org_member} 取所有符合角色的组织成员</li>
 *   <li>MANAGER/STAFF 额外过滤同部门限制</li>
 *   <li>批量拼接各用户表的显示信息（姓名/头像/部门/职位）</li>
 *   <li>查询在线状态（Redis）</li>
 *   <li>按角色分组返回</li>
 * </ol>
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ImContactServiceImpl implements IImContactService {

    private final JdbcTemplate jdbc;
    private final ImPermissionEngine permEngine;
    private final IImConversationService convService;
    private final IImOrgMemberService orgMemberService;
    private final UserRouter router;

    // ── 通讯录 ────────────────────────────────────────────────────────────────

    @Override
    public List<ImContactGroupVO> contacts(String senderType, Long senderId, Long merchantId) {
        ImUserRole senderRole = permEngine.getRole(senderType, senderId, merchantId);
        Set<String> allowedRoles = permEngine.getAllowedReceiverRoles(senderRole, merchantId);
        if (allowedRoles.isEmpty()) return Collections.emptyList();

        // 查 im_org_member 中该商户所有允许角色的成员（排除自己）
        // SUPER_ADMIN (merchantId=0)：跨商户查询所有 OWNER 作为直联入口
        List<Map<String, Object>> members;
        if ("admin".equals(senderType)) {
            members = queryOrgMembersForAdmin(allowedRoles, senderId);
        } else {
            members = queryOrgMembers(merchantId, allowedRoles, senderType, senderId);
            // 首次为空时自动初始化当前商户组织成员
            if (members.isEmpty() && merchantId != null && merchantId > 0) {
                log.info("[Contact] merchantId={} 通讯录为空，自动同步 org members", merchantId);
                orgMemberService.syncOrgMembers(merchantId);
                permEngine.evictCache(merchantId);
                members = queryOrgMembers(merchantId, allowedRoles, senderType, senderId);
            }
        }

        // 部门限制：MANAGER/STAFF 只能看同部门
        if (senderRole == ImUserRole.MANAGER || senderRole == ImUserRole.STAFF) {
            Long senderDept = permEngine.getDeptId(senderType, senderId, merchantId);
            members = members.stream()
                .filter(m -> {
                    String role = (String) m.get("im_role");
                    ImUserRole r = ImUserRole.fromCode(role);
                    if (r == ImUserRole.MANAGER || r == ImUserRole.STAFF) {
                        Object deptId = m.get("dept_id");
                        return senderDept != null && senderDept.equals(toLong(deptId));
                    }
                    return true;
                })
                .collect(Collectors.toList());
        }

        // admin 跨商户时，用各成员自己的 merchant_id 查询显示信息
        Long enrichMid = "admin".equals(senderType) ? null : merchantId;
        List<ImContactVO> contacts = enrichDisplayInfo(members, enrichMid);

        // 批量查已有会话（不自动创建，避免为所有联系人提前建会话 N+1）
        Map<String, Long> existingConvMap = batchFindExistingConvIds(senderType, senderId, contacts);
        contacts.forEach(c -> {
            c.setOnline(router.isOnline(c.getUserType(), c.getUserId()));
            c.setConversationId(existingConvMap.get(c.getUserType() + ":" + c.getUserId()));
        });

        return groupByRole(contacts);
    }

    @Override
    public List<ImContactVO> search(String senderType, Long senderId, Long merchantId, String keyword) {
        if (keyword == null || keyword.isBlank()) return Collections.emptyList();
        String kw = keyword.trim();

        ImUserRole senderRole = permEngine.getRole(senderType, senderId, merchantId);
        Set<String> allowedRoles = permEngine.getAllowedReceiverRoles(senderRole, merchantId);
        if (allowedRoles.isEmpty()) return Collections.emptyList();

        List<Map<String, Object>> members = queryOrgMembers(merchantId, allowedRoles, senderType, senderId);
        List<ImContactVO> contacts = enrichDisplayInfo(members, merchantId);

        return contacts.stream()
            .filter(c -> (c.getName() != null && c.getName().contains(kw))
                || (c.getDeptName() != null && c.getDeptName().contains(kw)))
            .collect(Collectors.toList());
    }

    @Override
    public Long autoCreateConversation(String senderType, Long senderId,
                                       String receiverType, Long receiverId,
                                       Long merchantId, String sysNote) {
        Long convId = convService.getOrCreate(senderType, senderId, receiverType, receiverId);
        if (sysNote != null && !sysNote.isBlank()) {
            // 推送系统通知消息
            ImPacket sysMsg = ImPacket.of(ImCmd.MSG_NOTIFY, "sys-" + System.currentTimeMillis(),
                Map.of("conversationId", convId, "content", sysNote,
                       "msgType", 6, "senderType", "system", "senderId", 0L));
            router.route(receiverType, receiverId, sysMsg);
        }
        log.info("[AutoConv] 自动建会话 convId={} {}:{} ↔ {}:{}", convId,
            senderType, senderId, receiverType, receiverId);
        return convId;
    }

    // ── 私有方法 ──────────────────────────────────────────────────────────────

    /**
     * 批量查询当前用户与联系人列表之间已存在的会话 ID。
     * 一次 IN 查询，避免 N 次 findExisting 调用。
     *
     * @return key = "userType:userId" → conversationId
     */
    private Map<String, Long> batchFindExistingConvIds(String senderType, Long senderId,
                                                        List<ImContactVO> contacts) {
        if (contacts.isEmpty()) return Collections.emptyMap();

        // 计算所有可能的 conv_key（与 ImConversationServiceImpl.convKey() 逻辑一致）
        Set<String> keys = new LinkedHashSet<>();
        Map<String, String> keyToContact = new HashMap<>();  // convKey → "type:id"
        for (ImContactVO c : contacts) {
            String key = buildConvKey(senderType, senderId, c.getUserType(), c.getUserId());
            keys.add(key);
            keyToContact.put(key, c.getUserType() + ":" + c.getUserId());
        }

        if (keys.isEmpty()) return Collections.emptyMap();

        String placeholders = String.join(",", Collections.nCopies(keys.size(), "?"));
        List<Map<String, Object>> rows = jdbc.queryForList(
            "SELECT id, conv_key FROM im_conversation WHERE conv_key IN (" + placeholders + ")",
            keys.toArray());

        Map<String, Long> result = new HashMap<>();
        for (var row : rows) {
            String ck = (String) row.get("conv_key");
            Long convId = toLong(row.get("id"));
            String contactKey = keyToContact.get(ck);
            if (contactKey != null && convId != null) result.put(contactKey, convId);
        }
        return result;
    }

    /** 字典序 conv key，与 ImConversationServiceImpl.convKey() 保持一致 */
    private static String buildConvKey(String typeA, Long idA, String typeB, Long idB) {
        String a = typeA + ":" + idA;
        String b = typeB + ":" + idB;
        return a.compareTo(b) <= 0 ? a + "_" + b : b + "_" + a;
    }

    /**
     * SUPER_ADMIN 专用：跨所有商户查询 OWNER/MANAGER/TECHNICIAN，
     * 每个商户最多取前 50 人避免结果集过大。
     */
    private List<Map<String, Object>> queryOrgMembersForAdmin(Set<String> roles, Long adminId) {
        if (roles.isEmpty()) return Collections.emptyList();
        String placeholders = String.join(",", Collections.nCopies(roles.size(), "?"));
        String sql = "SELECT id,user_type,user_id,im_role,dept_id,display_name,merchant_id " +
                     "FROM im_org_member " +
                     "WHERE merchant_id > 0 AND status=0 " +
                     "  AND im_role IN (" + placeholders + ") " +
                     "ORDER BY merchant_id, id LIMIT 200";
        List<Object> params = new ArrayList<>(roles);
        return jdbc.queryForList(sql, params.toArray());
    }

    private List<Map<String, Object>> queryOrgMembers(Long merchantId,
                                                       Set<String> roles,
                                                       String excludeType, Long excludeId) {
        if (roles.isEmpty()) return Collections.emptyList();
        String placeholders = String.join(",", Collections.nCopies(roles.size(), "?"));
        String sql = "SELECT id,user_type,user_id,im_role,dept_id,display_name " +
                     "FROM im_org_member " +
                     "WHERE merchant_id=? AND status=0 " +
                     "  AND im_role IN (" + placeholders + ") " +
                     "  AND NOT (user_type=? AND user_id=?)";
        List<Object> params = new ArrayList<>();
        params.add(merchantId);
        params.addAll(roles);
        params.add(excludeType);
        params.add(excludeId);
        return jdbc.queryForList(sql, params.toArray());
    }

    /**
     * 批量拼接各用户表的显示信息。
     * 按 user_type 分组后各查一次，避免 N+1。
     */
    private List<ImContactVO> enrichDisplayInfo(List<Map<String, Object>> members, Long merchantId) {
        Map<String, List<Map<String, Object>>> byType = members.stream()
            .collect(Collectors.groupingBy(m -> (String) m.get("user_type")));

        List<ImContactVO> result = new ArrayList<>();

        byType.forEach((type, rows) -> {
            List<Long> ids = rows.stream().map(r -> toLong(r.get("user_id"))).collect(Collectors.toList());
            Map<Long, UserInfo> infoMap = fetchUserInfo(type, ids, merchantId);

            for (var row : rows) {
                Long userId = toLong(row.get("user_id"));
                UserInfo info = infoMap.getOrDefault(userId, new UserInfo());
                String role  = (String) row.get("im_role");

                ImContactVO vo = new ImContactVO();
                vo.setUserType(type);
                vo.setUserId(userId);
                vo.setName(row.get("display_name") != null
                    ? (String) row.get("display_name") : info.name);
                vo.setAvatar(info.avatar);
                vo.setRole(role);
                vo.setRoleLabel(labelOf(role));
                vo.setDeptName(info.deptName);
                vo.setPositionName(info.positionName);
                result.add(vo);
            }
        });

        return result;
    }

    /** 按 userType 从对应业务表批量查询姓名/头像 */
    private Map<Long, UserInfo> fetchUserInfo(String userType, List<Long> ids, Long merchantId) {
        if (ids.isEmpty()) return Collections.emptyMap();
        String inClause = ids.stream().map(String::valueOf).collect(Collectors.joining(","));
        Map<Long, UserInfo> map = new HashMap<>();
        try {
            switch (userType) {
                case "staff" -> {
                    String sql = "SELECT s.id, s.real_name, s.avatar, d.name dept_name, p.name position_name " +
                        "FROM cb_merchant_staff s " +
                        "LEFT JOIN cb_dept d ON d.id = s.dept_id " +
                        "LEFT JOIN cb_position p ON p.id = s.position_id " +
                        "WHERE s.id IN (" + inClause + ") AND s.deleted=0";
                    jdbc.queryForList(sql).forEach(r -> {
                        UserInfo ui = new UserInfo();
                        ui.name = str(r.get("real_name"));
                        ui.avatar = str(r.get("avatar"));
                        ui.deptName = str(r.get("dept_name"));
                        ui.positionName = str(r.get("position_name"));
                        map.put(toLong(r.get("id")), ui);
                    });
                }
                case "technician" -> {
                    String sql = "SELECT id, real_name, avatar FROM cb_technician " +
                        "WHERE id IN (" + inClause + ") AND deleted=0";
                    jdbc.queryForList(sql).forEach(r -> {
                        UserInfo ui = new UserInfo();
                        ui.name   = str(r.get("real_name"));
                        ui.avatar = str(r.get("avatar"));
                        map.put(toLong(r.get("id")), ui);
                    });
                }
                case "member" -> {
                    String sql = "SELECT id, nickname, avatar FROM cb_member " +
                        "WHERE id IN (" + inClause + ") AND deleted=0";
                    jdbc.queryForList(sql).forEach(r -> {
                        UserInfo ui = new UserInfo();
                        ui.name   = str(r.get("nickname"));
                        ui.avatar = str(r.get("avatar"));
                        map.put(toLong(r.get("id")), ui);
                    });
                }
                case "merchant" -> {
                    String sql = "SELECT id, merchant_name_zh, logo FROM cb_merchant " +
                        "WHERE id IN (" + inClause + ") AND deleted=0";
                    jdbc.queryForList(sql).forEach(r -> {
                        UserInfo ui = new UserInfo();
                        ui.name   = str(r.get("merchant_name_zh"));
                        ui.avatar = str(r.get("logo"));
                        map.put(toLong(r.get("id")), ui);
                    });
                }
                case "admin" -> {
                    String sql = "SELECT id, username, avatar FROM sys_user WHERE id IN (" + inClause + ")";
                    jdbc.queryForList(sql).forEach(r -> {
                        UserInfo ui = new UserInfo();
                        ui.name   = str(r.get("username"));
                        ui.avatar = str(r.get("avatar"));
                        map.put(toLong(r.get("id")), ui);
                    });
                }
            }
        } catch (Exception e) {
            log.warn("[Contact] 查询用户信息失败 userType={} ids={}: {}", userType, inClause, e.getMessage());
        }
        return map;
    }

    /** 按 IM 角色分组，定义分组顺序和分组名 */
    private List<ImContactGroupVO> groupByRole(List<ImContactVO> contacts) {
        Map<String, List<ImContactVO>> grouped = contacts.stream()
            .collect(Collectors.groupingBy(c -> c.getRole() != null ? c.getRole() : "MEMBER"));

        List<ImContactGroupVO> groups = new ArrayList<>();
        addGroup(groups, grouped, 1,  "领导层",   "SUPER_ADMIN", "OWNER");
        addGroup(groups, grouped, 2,  "主管/经理", "MANAGER");
        addGroup(groups, grouped, 3,  "员工",      "STAFF");
        addGroup(groups, grouped, 4,  "运营",      "OPERATOR");
        addGroup(groups, grouped, 5,  "营销",      "MARKETING");
        addGroup(groups, grouped, 6,  "技师",      "TECHNICIAN");
        addGroup(groups, grouped, 7,  "司机/车队", "DRIVER");
        addGroup(groups, grouped, 8,  "会员",      "MEMBER");
        return groups;
    }

    private void addGroup(List<ImContactGroupVO> groups, Map<String, List<ImContactVO>> grouped,
                          int sort, String name, String... roles) {
        List<ImContactVO> list = new ArrayList<>();
        for (String role : roles) list.addAll(grouped.getOrDefault(role, Collections.emptyList()));
        if (!list.isEmpty()) groups.add(new ImContactGroupVO(name, sort, list));
    }

    // ── 内部数据载体 ──────────────────────────────────────────────────────────

    private static class UserInfo {
        String name;
        String avatar;
        String deptName;
        String positionName;
    }

    // ── 工具方法 ──────────────────────────────────────────────────────────────

    private static Long toLong(Object o) {
        if (o == null) return null;
        if (o instanceof Long l) return l;
        if (o instanceof Number n) return n.longValue();
        return null;
    }

    private static String str(Object o) { return o == null ? null : o.toString(); }

    private static String labelOf(String role) {
        if (role == null) return "";
        ImUserRole r = ImUserRole.fromCode(role);
        return r != null ? r.getLabel() : role;
    }
}
