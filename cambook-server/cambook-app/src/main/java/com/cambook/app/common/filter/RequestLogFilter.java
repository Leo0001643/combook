package com.cambook.app.common.filter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.util.ContentCachingRequestWrapper;
import org.springframework.web.util.ContentCachingResponseWrapper;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.Set;
import java.util.StringJoiner;

/**
 * 统一请求 / 响应日志过滤器
 *
 * <p>每次请求完整输出示例：
 * <pre>
 * ▶ POST /tech/auth/login
 *   Headers: {content-type=application/x-www-form-urlencoded, accept-language=zh, ...}
 *   Params : {loginType=techId, account=T0001, password=***, merchantId=1, lang=zh}
 * ◀ POST /tech/auth/login | status=200 | 38ms
 *   Response: {"code":200,"message":"success","data":{"token":"eyJ...","techId":1}}
 * </pre>
 *
 * <p>4xx/5xx 响应体用 WARN 级别输出，方便运维过滤。
 *
 * @author CamBook
 */
public class RequestLogFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger("HTTP");

    /** 单条 Body / Response 日志最大字符数（超出截断） */
    private static final int MAX_LOG = 4096;

    /** 需要脱敏的表单参数名（全小写比较） */
    private static final Set<String> SENSITIVE_FIELDS =
            Set.of("password", "pwd", "oldpassword", "newpassword");

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain)
            throws ServletException, IOException {

        String uri = request.getRequestURI();
        if (isStaticResource(uri)) {
            chain.doFilter(request, response);
            return;
        }

        ContentCachingRequestWrapper  wrappedReq  = new ContentCachingRequestWrapper(request);
        ContentCachingResponseWrapper wrappedResp = new ContentCachingResponseWrapper(response);

        long start = System.currentTimeMillis();
        try {
            logRequest(wrappedReq);
            chain.doFilter(wrappedReq, wrappedResp);
        } finally {
            long elapsed = System.currentTimeMillis() - start;
            // 先记日志，再把响应真正写回客户端（缺少此步客户端将收不到响应体）
            logRequestBody(wrappedReq);
            logResponseLine(wrappedResp, request.getMethod(), uri, elapsed);
            wrappedResp.copyBodyToResponse();
        }
    }

    // ── 请求行 + 请求头（chain 前记录）──────────────────────────────────────────

    private void logRequest(ContentCachingRequestWrapper req) {
        String query = req.getQueryString();
        log.info("▶ {} {}{}", req.getMethod(), req.getRequestURI(),
                query != null ? "?" + query : "");

        StringJoiner headers = new StringJoiner(", ", "{", "}");
        Collections.list(req.getHeaderNames()).forEach(name ->
                headers.add(name + "=" + maskHeader(name, req.getHeader(name))));
        log.info("  Headers: {}", headers);
    }

    // ── 请求 Body / Params（chain 后记录，此时缓存已就绪）────────────────────────

    private void logRequestBody(ContentCachingRequestWrapper req) {
        String ct = req.getContentType();
        if (ct == null) return;

        if (ct.contains(MediaType.APPLICATION_FORM_URLENCODED_VALUE)) {
            // 表单参数：直接从 parameterMap 读取，密码字段脱敏
            StringJoiner params = new StringJoiner(", ", "{", "}");
            req.getParameterMap().forEach((k, vals) -> {
                String val = (vals != null && vals.length > 0) ? vals[0] : "";
                params.add(k + "=" + (SENSITIVE_FIELDS.contains(k.toLowerCase()) ? "***" : val));
            });
            log.info("  Params : {}", params);

        } else if (ct.contains(MediaType.APPLICATION_JSON_VALUE)) {
            // JSON body：ContentCachingRequestWrapper 在 chain 中懒读后已缓存
            byte[] body = req.getContentAsByteArray();
            if (body.length > 0) {
                String bodyStr = truncate(new String(body, StandardCharsets.UTF_8));
                log.info("  Body   : {}", bodyStr);
            }
        }
    }

    // ── 响应行 + 响应体（chain 后记录）──────────────────────────────────────────

    private void logResponseLine(ContentCachingResponseWrapper resp,
                                 String method, String uri, long elapsed) {
        int status = resp.getStatus();
        log.info("◀ {} {} | status={} | {}ms", method, uri, status, elapsed);

        String ct = resp.getContentType();
        if (ct != null && ct.contains(MediaType.APPLICATION_JSON_VALUE)) {
            byte[] body = resp.getContentAsByteArray();
            if (body.length > 0) {
                String bodyStr = truncate(new String(body, StandardCharsets.UTF_8));
                if (status >= 400) {
                    log.warn("  Response: {}", bodyStr);   // 4xx/5xx 用 WARN
                } else {
                    log.info("  Response: {}", bodyStr);   // 2xx/3xx 用 INFO
                }
            }
        }
    }

    // ── 工具方法 ──────────────────────────────────────────────────────────────

    private String truncate(String s) {
        return s.length() > MAX_LOG ? s.substring(0, MAX_LOG) + "... [truncated]" : s;
    }

    private String maskHeader(String name, String value) {
        if ("authorization".equalsIgnoreCase(name) && value != null) {
            return value.length() > 12 ? value.substring(0, 12) + "***" : "***";
        }
        return value;
    }

    private boolean isStaticResource(String uri) {
        return uri.startsWith("/swagger-ui")
                || uri.startsWith("/v3/api-docs")
                || uri.startsWith("/doc.html")
                || uri.startsWith("/webjars")
                || uri.startsWith("/favicon.ico");
    }
}
