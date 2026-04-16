package com.cambook.app.service.admin.impl;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.cambook.common.context.AdminContext;
import com.cambook.app.domain.dto.AdminLoginDTO;
import com.cambook.app.domain.vo.LoginVO;
import com.cambook.app.domain.vo.OnlineUserVO;
import com.cambook.app.service.admin.IAdminAuthService;
import com.cambook.app.service.admin.IPermissionService;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.utils.JwtUtils;
import com.cambook.dao.entity.SysUser;
import com.cambook.dao.mapper.SysUserMapper;
import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.util.DigestUtils;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Admin 端认证服务实现
 *
 * @author CamBook
 */
@Service
public class AdminAuthService implements IAdminAuthService {

    private static final Logger log = LoggerFactory.getLogger(AdminAuthService.class);

    private final SysUserMapper      sysUserMapper;
    private final JwtUtils           jwtUtils;
    private final IPermissionService permissionService;
    private final OnlineSessionService onlineSessionService;

    @Value("${cambook.jwt.expire-seconds:604800}")
    private long jwtExpireSeconds;

    public AdminAuthService(SysUserMapper sysUserMapper, JwtUtils jwtUtils,
                            IPermissionService permissionService,
                            OnlineSessionService onlineSessionService) {
        this.sysUserMapper       = sysUserMapper;
        this.jwtUtils            = jwtUtils;
        this.permissionService   = permissionService;
        this.onlineSessionService = onlineSessionService;
    }

    @Override
    public LoginVO login(AdminLoginDTO dto) {
        SysUser user = sysUserMapper.selectOne(
                Wrappers.<SysUser>lambdaQuery()
                        .eq(SysUser::getUsername, dto.getUsername())
                        .last("LIMIT 1"));

        if (user == null) throw new BusinessException(CbCodeEnum.ACCOUNT_NOT_FOUND);

        String encPwd = DigestUtils.md5DigestAsHex(dto.getPassword().getBytes(StandardCharsets.UTF_8));
        if (!encPwd.equals(user.getPassword())) throw new BusinessException(CbCodeEnum.ACCOUNT_NOT_FOUND);

        if (user.getStatus() != null && user.getStatus() == 0) throw new BusinessException(CbCodeEnum.ACCOUNT_BANNED);

        Map<String, Object> claims = new HashMap<>();
        claims.put("uid",      user.getId());
        claims.put("username", user.getUsername());
        claims.put("userType", "admin");
        String token     = jwtUtils.generateToken(claims);
        long   expiresAt = System.currentTimeMillis() / 1000 + jwtExpireSeconds;

        List<String> perms = permissionService.getPermCodesByUserId(user.getId());

        // 记录在线用户 Session
        try {
            HttpServletRequest req = ((ServletRequestAttributes) RequestContextHolder.getRequestAttributes()).getRequest();
            String ua = req.getHeader("User-Agent");
            String sessionId = UUID.randomUUID().toString().replace("-", "");
            OnlineUserVO session = new OnlineUserVO();
            session.setSessionId(sessionId);
            session.setUserId(user.getId());
            session.setUsername(user.getUsername());
            session.setRealName(user.getRealName());
            session.setIpAddr(getClientIp(req));
            session.setBrowser(parseBrowser(ua));
            session.setOs(parseOs(ua));
            session.setStatus("online");
            session.setLoginTime(System.currentTimeMillis());
            session.setLastAccessTime(System.currentTimeMillis());
            session.setToken(token);
            onlineSessionService.saveSession(session, jwtExpireSeconds);
        } catch (Exception e) {
            log.warn("[Admin] session record failed: {}", e.getMessage());
        }

        log.info("[Admin] login: username={} perms={}", dto.getUsername(), perms.size());
        return LoginVO.of(token, expiresAt, "admin", user.getId(), false, perms);
    }

    private String getClientIp(HttpServletRequest req) {
        String ip = req.getHeader("X-Forwarded-For");
        if (ip == null || ip.isBlank()) ip = req.getHeader("X-Real-IP");
        if (ip == null || ip.isBlank()) ip = req.getRemoteAddr();
        if (ip != null && ip.contains(",")) ip = ip.split(",")[0].trim();
        return ip;
    }

    private String parseBrowser(String ua) {
        if (ua == null) return "Unknown";
        if (ua.contains("Edg/"))    return "Edge";
        if (ua.contains("Chrome/")) return "Chrome";
        if (ua.contains("Firefox/"))return "Firefox";
        if (ua.contains("Safari/") && !ua.contains("Chrome")) return "Safari";
        if (ua.contains("MSIE") || ua.contains("Trident")) return "IE";
        return "Other";
    }

    private String parseOs(String ua) {
        if (ua == null) return "Unknown";
        if (ua.contains("Windows NT 10.0")) return "Windows 10";
        if (ua.contains("Windows NT 6.1"))  return "Windows 7";
        if (ua.contains("Windows"))         return "Windows";
        if (ua.contains("Mac OS X"))        return "macOS";
        if (ua.contains("Android"))         return "Android";
        if (ua.contains("iPhone") || ua.contains("iPad")) return "iOS";
        if (ua.contains("Linux"))           return "Linux";
        return "Other";
    }

    @Override
    public void logout() {
        AdminContext.clear();
    }
}
