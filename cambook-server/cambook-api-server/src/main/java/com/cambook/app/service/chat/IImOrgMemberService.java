package com.cambook.app.service.chat;

import com.baomidou.mybatisplus.extension.service.IService;
import com.cambook.app.domain.enums.ImUserRole;
import com.cambook.db.entity.ImOrgMember;

import java.util.List;
import java.util.Optional;

/**
 * IM 组织成员服务
 *
 * <p>维护 {@code im_org_member} 表，将各业务用户映射为 IM 角色，
 * 构建"无好友、基于角色关系"的通讯录体系。
 */
public interface IImOrgMemberService extends IService<ImOrgMember> {

    /**
     * 新增或更新用户的 IM 角色（幂等）。
     * 写入后调用方应调用 {@link com.cambook.app.common.chat.ImPermissionEngine#evictCache} 清除权限缓存。
     */
    void upsertRole(String userType, Long userId, Long merchantId,
                    ImUserRole role, Long deptId, String displayName);

    /**
     * 禁用组织成员（软删除），同时校验商户归属防止越权。
     */
    void disableById(Long id, Long merchantId);

    /**
     * 查询商户下所有启用的组织成员，按角色 + ID 排序。
     */
    List<ImOrgMember> listActive(Long merchantId);

    /**
     * 按用户 + 商户查询组织成员，不存在时返回 {@link Optional#empty()}。
     */
    Optional<ImOrgMember> findByUser(String userType, Long userId, Long merchantId);

    /**
     * 幂等批量初始化：将该商户下所有员工/技师/商户主同步至 {@code im_org_member}。
     * 首次访问通讯录时自动调用；也可由运营人员在管理台手动触发。
     *
     * @return 本次新增或更新的行数
     */
    int syncOrgMembers(Long merchantId);
}
