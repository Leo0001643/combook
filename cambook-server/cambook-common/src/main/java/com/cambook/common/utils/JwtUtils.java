package com.cambook.common.utils;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Date;
import java.util.Map;

/**
 * JWT 工具类
 *
 * <p>单 Token 模式（长期有效），退出登录时加入 Redis 黑名单。
 * Token payload 携带 userId / userType / lang，避免请求时查库。
 *
 * @author CamBook
 */
@Component
public class JwtUtils {

    private static final Logger log = LoggerFactory.getLogger(JwtUtils.class);

    @Value("${cambook.jwt.secret}")
    private String secret;

    @Value("${cambook.jwt.expire-seconds:604800}")
    private long expireSeconds;

    /**
     * 生成 Token
     *
     * @param claims 自定义载荷（userId / userType / lang 等）
     */
    public String generateToken(Map<String, Object> claims) {
        return Jwts.builder()
            .claims(claims)
            .issuedAt(new Date())
            .expiration(new Date(System.currentTimeMillis() + expireSeconds * 1000))
            .signWith(signingKey())
            .compact();
    }

    /**
     * 解析 Token，失败返回 {@code null}
     */
    public Claims parseToken(String token) {
        try {
            return Jwts.parser()
                .verifyWith(signingKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
        } catch (Exception e) {
            log.warn("[JWT] parse failed: {}", e.getMessage());
            return null;
        }
    }

    // ── private ───────────────────────────────────────────────────────────────

    private SecretKey signingKey() {
        byte[] raw = secret.getBytes(StandardCharsets.UTF_8);
        if (raw.length < 32) {
            raw = Arrays.copyOf(raw, 32);
        }
        return Keys.hmacShaKeyFor(raw);
    }
}
