package com.cambook.app.common.aspect;

import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Pointcut;
import org.aspectj.lang.reflect.MethodSignature;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * 定时任务全局日志切面
 *
 * <p>拦截所有 {@code @Scheduled} 注解的方法，自动记录：
 * <ul>
 *   <li>任务名称（类名#方法名）</li>
 *   <li>开始时间、结束时间、耗时（毫秒）</li>
 *   <li>执行结果：SUCCESS / FAILED</li>
 *   <li>异常信息（ERROR 级别，含完整堆栈）</li>
 * </ul>
 *
 * <p>日志统一写入 {@code cambook-schedule.log}（logback-spring.xml 中 SCHEDULE logger 配置）。
 *
 * @author CamBook
 */
@Aspect
@Component
public class ScheduleLogAspect {

    /** 定时任务专用命名 logger，对应 logback-spring.xml 中的 SCHEDULE appender */
    private static final Logger log = LoggerFactory.getLogger("SCHEDULE");

    // ── 切点：所有 @Scheduled 注解的方法 ──────────────────────────────────────

    @Pointcut("@annotation(org.springframework.scheduling.annotation.Scheduled)")
    public void scheduledMethods() {}

    // ── 环绕通知 ───────────────────────────────────────────────────────────────

    @Around("scheduledMethods()")
    public Object around(ProceedingJoinPoint pjp) {
        MethodSignature sig    = (MethodSignature) pjp.getSignature();
        String taskName = pjp.getTarget().getClass().getSimpleName() + "#" + sig.getName();
        long start = System.currentTimeMillis();
        log.info("┌─ TASK START  [{}]", taskName);
        try {
            Object result = pjp.proceed();
            long elapsed = System.currentTimeMillis() - start;
            log.info("└─ TASK SUCCESS [{}] | elapsed={}ms", taskName, elapsed);
            return result;
        } catch (Throwable ex) {
            long elapsed = System.currentTimeMillis() - start;
            log.error("└─ TASK FAILED  [{}] | elapsed={}ms | {} : {}", taskName, elapsed, ex.getClass().getSimpleName(), ex.getMessage(),ex);
            // 定时任务异常不向上抛，防止 Spring 取消后续调度
            return null;
        }
    }
}
