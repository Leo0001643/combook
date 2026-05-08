package com.cambook.app.service.chat.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.cambook.app.domain.enums.ImUserRole;
import com.cambook.app.service.chat.IImOrgMemberService;
import com.cambook.common.utils.DateUtils;
import com.cambook.db.entity.ImOrgMember;
import com.cambook.db.mapper.ImOrgMemberMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * IM 组织成员服务实现
 *
 * <p>所有写操作均幂等，调用方写完后应通知 {@code ImPermissionEngine.evictCache()} 使缓存失效。
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ImOrgMemberServiceImpl extends ServiceImpl<ImOrgMemberMapper, ImOrgMember>
        implements IImOrgMemberService {

    private final JdbcTemplate jdbc;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void upsertRole(String userType, Long userId, Long merchantId,
                           ImUserRole role, Long deptId, String displayName) {
        long now = DateUtils.nowSecond();
        ImOrgMember existing = lambdaQuery()
            .eq(ImOrgMember::getUserType,   userType)
            .eq(ImOrgMember::getUserId,     userId)
            .eq(ImOrgMember::getMerchantId, merchantId)
            .one();

        if (existing != null) {
            existing.setImRole(role.name());
            existing.setDeptId(deptId);
            existing.setDisplayName(displayName);
            existing.setStatus((byte) 0);  // 重新启用（可能之前被禁用）
            existing.setUpdateTime(now);
            updateById(existing);
            log.debug("[OrgMember] 更新 {} [{}.{}] → {}", merchantId, userType, userId, role);
        } else {
            ImOrgMember member = new ImOrgMember();
            member.setMerchantId(merchantId);
            member.setUserType(userType);
            member.setUserId(userId);
            member.setImRole(role.name());
            member.setDeptId(deptId);
            member.setDisplayName(displayName);
            member.setStatus((byte) 0);
            member.setCreateTime(now);
            member.setUpdateTime(now);
            save(member);
            log.debug("[OrgMember] 新增 {} [{}.{}] → {}", merchantId, userType, userId, role);
        }
    }

    @Override
    public void disableById(Long id, Long merchantId) {
        boolean updated = lambdaUpdate()
            .eq(ImOrgMember::getId,         id)
            .eq(ImOrgMember::getMerchantId, merchantId)
            .set(ImOrgMember::getStatus,     (byte) 1)
            .set(ImOrgMember::getUpdateTime, DateUtils.nowSecond())
            .update();
        if (!updated) {
            log.warn("[OrgMember] 禁用失败：id={} merchantId={} 不存在或无权限", id, merchantId);
        }
    }

    @Override
    public List<ImOrgMember> listActive(Long merchantId) {
        return lambdaQuery()
            .eq(ImOrgMember::getMerchantId, merchantId)
            .eq(ImOrgMember::getStatus,     (byte) 0)
            .orderByAsc(ImOrgMember::getImRole)
            .orderByAsc(ImOrgMember::getId)
            .list();
    }

    @Override
    public Optional<ImOrgMember> findByUser(String userType, Long userId, Long merchantId) {
        return Optional.ofNullable(
            lambdaQuery()
                .eq(ImOrgMember::getUserType,   userType)
                .eq(ImOrgMember::getUserId,     userId)
                .eq(ImOrgMember::getMerchantId, merchantId)
                .one()
        );
    }

    /**
     * 幂等同步：商户主 + 员工 + 技师 → im_org_member。
     * ON DUPLICATE KEY UPDATE 保证多次调用安全，仅在首次访问通讯录时实际写入。
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public int syncOrgMembers(Long merchantId) {
        long now = DateUtils.nowSecond();
        int count = 0;
        final String upsertSql =
            "INSERT INTO im_org_member " +
            "  (merchant_id,user_type,user_id,im_role,status,create_time,update_time) " +
            "VALUES (?,?,?,?,0,?,?) " +
            "ON DUPLICATE KEY UPDATE im_role=VALUES(im_role),update_time=VALUES(update_time)";

        // 商户主 → OWNER
        count += jdbc.update(upsertSql, merchantId, "merchant", merchantId, "OWNER", now, now);

        // 员工：roleName → IM 角色
        List<Map<String, Object>> staff = jdbc.queryForList(
            "SELECT id, role_name FROM cb_merchant_staff WHERE merchant_id=? AND deleted=0", merchantId);
        for (var row : staff) {
            Long   staffId  = ((Number) row.get("id")).longValue();
            String roleName = row.get("role_name") != null ? row.get("role_name").toString() : "STAFF";
            count += jdbc.update(upsertSql, merchantId, "staff", staffId, mapStaffRole(roleName), now, now);
        }

        // 技师 → TECHNICIAN
        List<Map<String, Object>> techs = jdbc.queryForList(
            "SELECT id FROM cb_technician WHERE merchant_id=? AND deleted=0", merchantId);
        for (var row : techs) {
            Long techId = ((Number) row.get("id")).longValue();
            count += jdbc.update(upsertSql, merchantId, "technician", techId, "TECHNICIAN", now, now);
        }

        log.info("[OrgSync] merchantId={} 同步完成，共写入/更新 {} 条", merchantId, count);
        return count;
    }

    private static String mapStaffRole(String roleName) {
        if (roleName == null) return "STAFF";
        return switch (roleName.toUpperCase()) {
            case "OWNER", "BOSS"       -> "OWNER";
            case "MANAGER", "DIRECTOR" -> "MANAGER";
            case "OPERATOR"            -> "OPERATOR";
            case "MARKETING"           -> "MARKETING";
            case "DRIVER"              -> "DRIVER";
            default                    -> "STAFF";
        };
    }
}
