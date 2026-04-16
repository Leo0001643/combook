package com.cambook.common.annotation;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * 权限校验注解（方法/类级别）
 *
 * <p>使用示例：
 * <pre>
 *   // 单权限
 *   {@literal @}RequirePermission("member:add")
 *
 *   // 需要同时拥有多个权限（AND）
 *   {@literal @}RequirePermission(value = {"order:list", "order:export"}, mode = LogicMode.AND)
 *
 *   // 拥有其中一个即可（OR）
 *   {@literal @}RequirePermission(value = {"order:list", "order:audit"}, mode = LogicMode.OR)
 * </pre>
 *
 * @author CamBook
 */
@Target({ElementType.METHOD, ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface RequirePermission {

    /** 权限标识数组 */
    String[] value();

    /** 多权限逻辑：AND=全部需要 OR=其一即可，默认 AND */
    LogicMode mode() default LogicMode.AND;

    enum LogicMode {
        AND, OR
    }
}
