package com.cambook.common.utils;

import java.math.BigDecimal;

/**
 * MyBatis Map 行工具
 *
 * <p>MyBatis 将聚合查询（SUM/COUNT 等）或 SELECT * 的结果以 {@code Map<String,Object>} 返回时，
 * 数值字段类型不确定（可能是 Long、Integer、BigDecimal 等，随 MySQL 驱动版本而变）。
 * 本工具类提供统一的类型安全转换，消除各处重复的 instanceof 判断。
 *
 * <p>典型使用：
 * <pre>{@code
 * List<Map<String, Object>> rows = orderMapper.statusDistribution();
 * rows.forEach(r -> {
 *     int status = MapRowUtils.toInt(r.get("status"));
 *     long cnt   = MapRowUtils.toLong(r.get("cnt"));
 * });
 * }</pre>
 *
 * @author CamBook
 */
public final class MapRowUtils {

    private MapRowUtils() {}

    /**
     * 任意 Number 或字符串 → {@code long}；null 返回 0。
     */
    public static long toLong(Object v) {
        if (v == null) return 0L;
        if (v instanceof Long l) return l;
        if (v instanceof Number n) return n.longValue();
        return Long.parseLong(v.toString());
    }

    /**
     * 任意 Number 或字符串 → 装箱 {@code Long}；null 返回 null。
     */
    public static Long toLongOrNull(Object v) {
        if (v == null) return null;
        if (v instanceof Long l) return l;
        if (v instanceof Number n) return n.longValue();
        return Long.parseLong(v.toString());
    }

    /**
     * 任意 Number 或字符串 → {@code int}；null 返回 0。
     */
    public static int toInt(Object v) {
        if (v == null) return 0;
        if (v instanceof Integer i) return i;
        if (v instanceof Number n) return n.intValue();
        return Integer.parseInt(v.toString());
    }

    /**
     * 任意 Number、BigDecimal 或字符串 → {@code BigDecimal}；null 返回 {@link BigDecimal#ZERO}。
     */
    public static BigDecimal toBigDecimal(Object v) {
        if (v == null) return BigDecimal.ZERO;
        if (v instanceof BigDecimal bd) return bd;
        if (v instanceof Number n) return new BigDecimal(n.toString());
        return new BigDecimal(v.toString());
    }

    /**
     * 任意对象 → {@code String}；null 返回空字符串 {@code ""}。
     */
    public static String toStr(Object v) {
        return v == null ? "" : v.toString();
    }
}
