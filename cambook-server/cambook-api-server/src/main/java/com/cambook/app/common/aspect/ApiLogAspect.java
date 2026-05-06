package com.cambook.app.common.aspect;

import com.cambook.app.common.log.LogMaskUtils;
import com.cambook.common.context.MemberContext;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Pointcut;
import org.aspectj.lang.reflect.MethodSignature;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.validation.BindingResult;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.StringJoiner;

/**
 * 全局 API 访问日志切面
 *
 * <p>拦截所有 {@code @RestController} 标注的控制器方法，自动记录：
 * <ul>
 *   <li>请求信息：方法、URL、客户端IP、设备信息（User-Agent）、请求参数（脱敏）</li>
 *   <li>响应信息：返回值（JSON，脱敏）、耗时（毫秒）</li>
 *   <li>异常信息：异常类型、消息、根因</li>
 * </ul>
 *
 * <p>日志格式（logback-spring.xml 统一配置）：
 * <pre>
 * 时间 [线程号] INFO [ApiLogAspect.java:行号] - 日志信息
 * </pre>
 *
 * @author CamBook
 */
@Aspect
@Component
public class ApiLogAspect {

    private static final Logger log = LoggerFactory.getLogger(ApiLogAspect.class);

    /** 响应体超过此长度时截断，防止大 JSON 撑爆日志 */
    private static final int RESP_MAX_LENGTH = 2000;

    /** 需要跳过序列化的参数类型（不可 JSON 化或无意义） */
    private static final List<Class<?>> SKIP_TYPES = Arrays.asList(
            HttpServletRequest.class,
            HttpServletResponse.class,
            BindingResult.class,
            MultipartFile.class
    );

    // ── 切点：所有 @RestController 的公开方法 ──────────────────────────────────

    @Pointcut("within(@org.springframework.web.bind.annotation.RestController *)")
    public void restControllerMethods() {}

    // ── 环绕通知 ───────────────────────────────────────────────────────────────

    @Around("restControllerMethods()")
    public Object around(ProceedingJoinPoint pjp) throws Throwable {
        long start = System.currentTimeMillis();

        HttpServletRequest request = currentRequest();
        String method     = request != null ? request.getMethod()     : "UNKNOWN";
        String uri        = request != null ? request.getRequestURI() : "UNKNOWN";
        String ip         = request != null ? extractIp(request)      : "UNKNOWN";
        String userAgent  = request != null ? request.getHeader("User-Agent") : "UNKNOWN";
        String queryStr   = request != null ? buildQueryString(request) : "";
        String bodyStr    = buildArgsJson(pjp);
        Long   userId     = MemberContext.currentId();

        // ── 请求日志 ────────────────────────────────────────────────────────
        log.info("┌─ REQ  {} {} | IP:{} | UID:{}\n" +
                 "│  UA    : {}\n" +
                 "│  Query : {}\n" +
                 "│  Body  : {}",
                method, uri, ip, userId,
                truncate(userAgent, 200),
                queryStr,
                bodyStr);

        try {
            Object result = pjp.proceed();
            long elapsed = System.currentTimeMillis() - start;

            // ── 响应日志 ────────────────────────────────────────────────────
            String respJson = truncate(LogMaskUtils.toMaskedJson(result), RESP_MAX_LENGTH);
            log.info("└─ RESP {} {} | {}ms\n" +
                     "   Body: {}",
                    method, uri, elapsed, respJson);

            return result;

        } catch (Throwable ex) {
            long elapsed = System.currentTimeMillis() - start;

            // ── 异常日志（ERROR 级别）──────────────────────────────────────
            log.error("└─ EX   {} {} | {}ms | {} : {}\n" +
                      "   Cause: {}",
                    method, uri, elapsed,
                    ex.getClass().getSimpleName(),
                    ex.getMessage(),
                    rootCause(ex),
                    ex);

            throw ex;
        }
    }

    // ── IP 提取（支持反代/Nginx 转发链）────────────────────────────────────────

    private String extractIp(HttpServletRequest request) {
        String[] HEADERS = {
                "X-Real-IP",
                "X-Forwarded-For",
                "Proxy-Client-IP",
                "WL-Proxy-Client-IP",
                "HTTP_CLIENT_IP",
                "HTTP_X_FORWARDED_FOR"
        };
        for (String header : HEADERS) {
            String ip = request.getHeader(header);
            if (ip != null && !ip.isBlank() && !"unknown".equalsIgnoreCase(ip)) {
                // X-Forwarded-For 可能是链式：client, proxy1, proxy2
                return ip.split(",")[0].trim();
            }
        }
        return request.getRemoteAddr();
    }

    // ── Query String 格式化 ─────────────────────────────────────────────────────

    private String buildQueryString(HttpServletRequest request) {
        Map<String, String[]> params = request.getParameterMap();
        if (params == null || params.isEmpty()) return "-";
        StringJoiner joiner = new StringJoiner("&");
        params.forEach((k, v) -> joiner.add(k + "=" + String.join(",", v)));
        return joiner.toString();
    }

    // ── 方法参数序列化（跳过不可序列化类型）──────────────────────────────────────

    private String buildArgsJson(ProceedingJoinPoint pjp) {
        Object[] args = pjp.getArgs();
        if (args == null || args.length == 0) return "-";

        MethodSignature sig = (MethodSignature) pjp.getSignature();
        String[] names = sig.getParameterNames();

        List<String> parts = new ArrayList<>();
        for (int i = 0; i < args.length; i++) {
            Object arg = args[i];
            if (arg == null || shouldSkip(arg)) continue;
            String name = (names != null && i < names.length) ? names[i] : "arg" + i;
            parts.add(name + "=" + LogMaskUtils.toMaskedJson(arg));
        }
        if (parts.isEmpty()) return "-";
        return truncate(String.join(", ", parts), RESP_MAX_LENGTH);
    }

    private boolean shouldSkip(Object arg) {
        return SKIP_TYPES.stream().anyMatch(t -> t.isAssignableFrom(arg.getClass()));
    }

    // ── 工具方法 ─────────────────────────────────────────────────────────────

    private HttpServletRequest currentRequest() {
        try {
            ServletRequestAttributes attrs =
                    (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
            return attrs != null ? attrs.getRequest() : null;
        } catch (Exception e) {
            return null;
        }
    }

    private String rootCause(Throwable ex) {
        Throwable cause = ex;
        while (cause.getCause() != null) {
            cause = cause.getCause();
        }
        if (cause == ex) return "-";
        return cause.getClass().getSimpleName() + ": " + cause.getMessage();
    }

    private String truncate(String s, int max) {
        if (s == null) return "null";
        return s.length() <= max ? s : s.substring(0, max) + "...(truncated)";
    }
}
