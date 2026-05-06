package com.cambook.app.service.technician;

import com.cambook.app.domain.dto.TechLoginDTO;
import com.cambook.app.domain.dto.TechRegisterDTO;
import com.cambook.app.domain.vo.TechLoginVO;
import com.cambook.db.entity.CbTechnician;

/**
 * 技师端认证服务
 *
 * @author CamBook
 */
public interface ITechnicianAuthService {

    /**
     * 技师登录
     *
     * <p>校验顺序：
     * <ol>
     *   <li>账号是否存在（deleted=0 由 MyBatis-Plus 逻辑删除自动过滤）</li>
     *   <li>审核状态必须为通过（audit_status=1）</li>
     *   <li>账号状态必须正常（status=1）</li>
     *   <li>密码验证（MD5）</li>
     * </ol>
     *
     * @param dto       登录请求
     * @param clientIp  客户端 IP（透传自 Controller，用于记录登录设备信息）
     * @param userAgent 客户端 User-Agent（透传自 Controller）
     * @return 登录响应（含 JWT Token 及技师基本信息）
     */
    TechLoginVO login(TechLoginDTO dto, String clientIp, String userAgent);

    /**
     * 技师注册
     *
     * <p>校验规则：
     * <ol>
     *   <li>商户编号必须存在且状态正常（status=1，audit_status=1）</li>
     *   <li>手机号在技师表中必须唯一</li>
     *   <li>注册成功后账号进入待审核（audit_status=0），审核通过方可登录</li>
     * </ol>
     *
     * @param dto 注册请求
     */
    void register(TechRegisterDTO dto);

    /**
     * 获取当前登录技师信息
     *
     * @return 技师实体
     */
    CbTechnician me();

    /**
     * 技师主动登出（使当前 Token 立即失效，支持多设备同时踢出）
     */
    void logout();

    /**
     * 管理端强制技师下线（踢出指定技师 ID 的所有在线 Token）
     *
     * @param techId 技师主键 ID
     */
    void forceLogout(Long techId);
}
