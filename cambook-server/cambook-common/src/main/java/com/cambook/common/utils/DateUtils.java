package com.cambook.common.utils;

import java.time.*;
import java.time.format.DateTimeFormatter;
import java.time.temporal.WeekFields;
import java.util.concurrent.TimeUnit;

/**
 * 日期时间工具类（Unix 时间戳 / 边界计算 / 格式化）
 *
 * <p>统一时区为系统默认时区，所有 epoch-second 值均以此为准，与数据库字段保持一致。
 * 所有涉及日期区间的查询边界（今日/昨日/本周/本月等）都应通过本类获取，
 * 禁止在业务代码中内联计算，保证全局时区一致性。
 *
 * <h3>使用示例：</h3>
 * <pre>
 *   // 查询今日订单
 *   .ge(CbOrder::getCreateTime, DateUtils.todayStart())
 *   .lt(CbOrder::getCreateTime, DateUtils.tomorrowStart())
 *
 *   // 查询本月数据
 *   .ge(CbOrder::getCreateTime, DateUtils.monthStart())
 *
 *   // 生成业务编号日期部分
 *   "ORD" + DateUtils.todayStr("yyyyMMdd")
 * </pre>
 *
 * @author CamBook
 */
public final class DateUtils {

    /** 常用日期格式 */
    public static final DateTimeFormatter FMT_DATE       = DateTimeFormatter.ofPattern("yyyy-MM-dd");
    public static final DateTimeFormatter FMT_DATE_COMP  = DateTimeFormatter.ofPattern("yyyyMMdd");
    public static final DateTimeFormatter FMT_DATETIME   = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    public static final DateTimeFormatter FMT_YEAR_MONTH = DateTimeFormatter.ofPattern("yyyy-MM");

    private static final ZoneId ZONE = ZoneId.systemDefault();

    private DateUtils() {}

    // ── 今日边界 ─────────────────────────────────────────────────────────────

    /** 今日 00:00:00 的 Unix 秒时间戳 */
    public static long todayStart() {
        return LocalDate.now(ZONE).atStartOfDay(ZONE).toEpochSecond();
    }

    /** 今日 23:59:59 的 Unix 秒时间戳（包含今日最后一秒） */
    public static long todayEnd() {
        return LocalDate.now(ZONE).atTime(LocalTime.MAX).atZone(ZONE).toEpochSecond();
    }

    /** 明日 00:00:00 的 Unix 秒时间戳（常用于半开区间 [today, tomorrow)） */
    public static long tomorrowStart() {
        return dayStart(LocalDate.now(ZONE).plusDays(1));
    }

    // ── 昨日 / N天前 ─────────────────────────────────────────────────────────

    /** 昨日 00:00:00 的 Unix 秒时间戳 */
    public static long yesterdayStart() {
        return dayStart(LocalDate.now(ZONE).minusDays(1));
    }

    /** N 天前的 00:00:00 Unix 秒时间戳（n=1 等同 yesterdayStart） */
    public static long daysAgoStart(int n) {
        return dayStart(LocalDate.now(ZONE).minusDays(n));
    }

    // ── 本周 / 上周 ───────────────────────────────────────────────────────────

    /** 本周一 00:00:00 的 Unix 秒时间戳（ISO 周定义：周一为第一天） */
    public static long weekStart() {
        return dayStart(LocalDate.now(ZONE).with(WeekFields.ISO.dayOfWeek(), 1));
    }

    /** 上周一 00:00:00 的 Unix 秒时间戳 */
    public static long prevWeekStart() {
        return dayStart(LocalDate.now(ZONE).with(WeekFields.ISO.dayOfWeek(), 1).minusWeeks(1));
    }

    // ── 本月 / 上月 ───────────────────────────────────────────────────────────

    /** 本月 1 日 00:00:00 的 Unix 秒时间戳 */
    public static long monthStart() {
        return dayStart(LocalDate.now(ZONE).withDayOfMonth(1));
    }

    /** 下月 1 日 00:00:00 的 Unix 秒时间戳 */
    public static long nextMonthStart() {
        return dayStart(LocalDate.now(ZONE).plusMonths(1).withDayOfMonth(1));
    }

    /** 上月 1 日 00:00:00 的 Unix 秒时间戳 */
    public static long prevMonthStart() {
        return dayStart(LocalDate.now(ZONE).minusMonths(1).withDayOfMonth(1));
    }

    // ── 任意日期转时间戳 ──────────────────────────────────────────────────────

    /** 将 {@link LocalDate} 转换为该日 00:00:00 的 Unix 秒时间戳 */
    public static long dayStart(LocalDate date) {
        return date.atStartOfDay(ZONE).toEpochSecond();
    }

    /** 将 {@link LocalDate} 转换为该日 23:59:59 的 Unix 秒时间戳 */
    public static long dayEnd(LocalDate date) {
        return date.atTime(LocalTime.MAX).atZone(ZONE).toEpochSecond();
    }

    /** 将指定月份第一天转为 00:00:00 Unix 秒时间戳（monthsAgo=0 为本月，1 为上月） */
    public static long monthStartOf(int monthsAgo) {
        return dayStart(LocalDate.now(ZONE).minusMonths(monthsAgo).withDayOfMonth(1));
    }

    /** 将指定月份下一月第一天转为 00:00:00 Unix 秒时间戳 */
    public static long nextMonthStartOf(int monthsAgo) {
        LocalDate base = LocalDate.now(ZONE).minusMonths(monthsAgo).withDayOfMonth(1);
        return dayStart(base.plusMonths(1));
    }

    // ── 格式化 ────────────────────────────────────────────────────────────────

    /** 今日日期字符串，格式 {@code pattern}，如 {@code "yyyyMMdd"} */
    public static String todayStr(String pattern) {
        return LocalDate.now(ZONE).format(DateTimeFormatter.ofPattern(pattern));
    }

    /** 今日日期字符串，格式 {@code yyyy-MM-dd} */
    public static String todayStr() {
        return LocalDate.now(ZONE).format(FMT_DATE);
    }

    /** 文件路径日期目录，格式 {@code yyyy/MM/dd} */
    public static String todayPathDir() {
        return LocalDate.now(ZONE).toString().replace("-", "/");
    }

    /** 将 LocalDate 格式化为 {@code yyyy-MM-dd} 字符串 */
    public static String format(LocalDate date) {
        return date == null ? "" : date.format(FMT_DATE);
    }

    /** 将 LocalDate 格式化为指定格式字符串 */
    public static String format(LocalDate date, DateTimeFormatter formatter) {
        return date == null ? "" : date.format(formatter);
    }

    // ── 当前时间戳 ────────────────────────────────────────────────────────────

    /** 当前 Unix 秒时间戳（等价于 {@code System.currentTimeMillis() / 1000}） */
    public static long nowSeconds() { return Instant.now().getEpochSecond(); }

    /** {@link #nowSeconds()} 的简写别名，供 IM 模块使用 */
    public static long nowSecond() { return nowSeconds(); }

    /**
     * 当前时间 + 指定秒数后的 Unix 秒时间戳（常用于 JWT 过期时间计算）。
     *
     * @param seconds 有效期秒数，推荐使用 {@link TimeUnit} 换算，如
     *                {@code TimeUnit.DAYS.toSeconds(7)} 表示 7 天
     */
    public static long expireAt(long seconds) {
        return nowSeconds() + seconds;
    }

    // ── 小时级粒度（用于日趋势图） ─────────────────────────────────────────────

    /** 指定小时前的整点时间戳（{@code hoursAgo=0} 为当前整点） */
    public static long hoursAgoStart(int hoursAgo) {
        return ZonedDateTime.now(ZONE).minusHours(hoursAgo)
                .truncatedTo(java.time.temporal.ChronoUnit.HOURS)
                .toEpochSecond();
    }
}
