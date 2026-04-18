package com.cambook.app.common.aspect;

import com.cambook.common.annotation.RequirePermission;
import com.cambook.common.context.AdminContext;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Before;
import org.aspectj.lang.reflect.MethodSignature;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.lang.reflect.Method;
import java.util.Arrays;
import java.util.Set;

/**
 * 权限校验切面
 *
 * <p>拦截标注 {@link RequirePermission} 的方法，从 {@link AdminContext} 读取当前管理员的权限集合进行校验。
 * 权限集合在 JWT 过滤器中从 Redis 缓存加载（或首次从 DB 加载后写入缓存）。
 *
 * @author CamBook
 */
@Aspect
@Component
public class PermissionAspect {

    private static final Logger log = LoggerFactory.getLogger(PermissionAspect.class);

    @Before("@annotation(com.cambook.common.annotation.RequirePermission) || " +
            "@within(com.cambook.common.annotation.RequirePermission)")
    public void checkPermission(JoinPoint joinPoint) {
        RequirePermission annotation = resolveAnnotation(joinPoint);
        if (annotation == null) {
            return;
        }

        // 非管理员请求（商户端 / 匿名）不受本切面约束，由 MerchantSecurityAspect 等各自切面负责
        if (AdminContext.getUserId() == null) {
            return;
        }

        Set<String> adminPerms = AdminContext.getPermissions();
        String[] required = annotation.value();

        // SUPER_ADMIN 拥有通配符权限 "*"，直接放行
        if (adminPerms.contains("*")) return;

        boolean granted = switch (annotation.mode()) {
            case AND -> Arrays.stream(required).allMatch(adminPerms::contains);
            case OR  -> Arrays.stream(required).anyMatch(adminPerms::contains);
        };

        if (!granted) {
            log.warn("[Permission] userId={} 无权限 required={} mode={}",
                    AdminContext.getUserId(), Arrays.toString(required), annotation.mode());
            throw new BusinessException(CbCodeEnum.NO_PERMISSION);
        }
    }

    /**
     * 优先取方法级注解，再取类级注解
     */
    private RequirePermission resolveAnnotation(JoinPoint joinPoint) {
        MethodSignature sig = (MethodSignature) joinPoint.getSignature();
        Method method = sig.getMethod();
        RequirePermission method0 = method.getAnnotation(RequirePermission.class);
        if (method0 != null) {
            return method0;
        }
        return joinPoint.getTarget().getClass().getAnnotation(RequirePermission.class);
    }
}
