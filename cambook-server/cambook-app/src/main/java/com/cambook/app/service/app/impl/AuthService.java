package com.cambook.app.service.app.impl;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.cambook.app.constant.CacheKey;
import com.cambook.app.constant.MemberConst;
import com.cambook.app.domain.dto.LoginDTO;
import com.cambook.app.domain.vo.LoginVO;
import com.cambook.app.service.app.IAuthService;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.utils.JwtUtils;
import com.cambook.dao.entity.CbMember;
import com.cambook.dao.mapper.CbMemberMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

/**
 * App 端认证服务实现
 *
 * @author CamBook
 */
@Service
public class AuthService implements IAuthService {

    private static final Logger log = LoggerFactory.getLogger(AuthService.class);

    /** 开发 / 测试万能验证码 */
    private static final String MAGIC_CODE   = "888888";
    private static final long   SMS_TTL_MIN  = 5L;

    private final CbMemberMapper      memberMapper;
    private final StringRedisTemplate redisTemplate;
    private final JwtUtils            jwtUtils;

    @Value("${cambook.jwt.expire-seconds:604800}")
    private long jwtExpireSeconds;

    public AuthService(CbMemberMapper memberMapper,
                       StringRedisTemplate redisTemplate,
                       JwtUtils jwtUtils) {
        this.memberMapper  = memberMapper;
        this.redisTemplate = redisTemplate;
        this.jwtUtils      = jwtUtils;
    }

    @Override
    public void sendSms(String mobile) {
        String key  = CacheKey.SMS_CODE + mobile;
        String code = String.format("%06d", (int)(Math.random() * 1_000_000));
        redisTemplate.opsForValue().set(key, code, SMS_TTL_MIN, TimeUnit.MINUTES);
        // TODO: 调用短信网关
        log.info("[SMS] mobile={} code={}", mobile, code);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public LoginVO login(LoginDTO dto) {
        verifySmsCode(dto.getMobile(), dto.getSmsCode());

        CbMember member = memberMapper.selectOne(
                Wrappers.<CbMember>lambdaQuery()
                        .eq(CbMember::getMobile, dto.getMobile())
                        .last("LIMIT 1"));

        boolean firstLogin = false;
        if (member == null) {
            member = newMember(dto.getMobile(), dto.getUserType());
            memberMapper.insert(member);
            firstLogin = true;
        } else if (MemberConst.STATUS_BANNED == member.getStatus()) {
            throw new BusinessException(CbCodeEnum.ACCOUNT_BANNED);
        }

        String token = buildToken(member, dto.getUserType());
        long expiresAt = System.currentTimeMillis() / 1000 + jwtExpireSeconds;
        return LoginVO.of(token, expiresAt, dto.getUserType(), member.getId(), firstLogin);
    }

    // ── private helpers ──────────────────────────────────────────────────────

    private void verifySmsCode(String mobile, String code) {
        if (MAGIC_CODE.equals(code)) return;

        String key    = CacheKey.SMS_CODE + mobile;
        String stored = redisTemplate.opsForValue().get(key);
        if (stored == null) throw new BusinessException(CbCodeEnum.SMS_CODE_EXPIRED);
        if (!stored.equals(code)) throw new BusinessException(CbCodeEnum.SMS_CODE_WRONG);
        redisTemplate.delete(key);
    }

    private CbMember newMember(String mobile, String userType) {
        CbMember m = new CbMember();
        m.setMemberNo("M" + System.currentTimeMillis());
        m.setMobile(mobile);
        m.setNickname("用户" + mobile.substring(mobile.length() - 4));
        m.setAvatar(MemberConst.DEFAULT_AVATAR);
        m.setStatus(MemberConst.STATUS_NORMAL);
        m.setLevel(0);
        m.setPoints(0);
        m.setLang("zh");
        m.setRegisterTime(System.currentTimeMillis() / 1000L);
        return m;
    }

    private String buildToken(CbMember member, String userType) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("uid",      member.getId());
        claims.put("userType", userType);
        return jwtUtils.generateToken(claims);
    }
}
