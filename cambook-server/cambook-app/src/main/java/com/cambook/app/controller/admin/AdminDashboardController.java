package com.cambook.app.controller.admin;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.cambook.common.result.Result;
import com.cambook.common.utils.MapRowUtils;
import com.cambook.dao.entity.CbMember;
import com.cambook.dao.entity.CbMerchant;
import com.cambook.dao.entity.CbTechnician;
import com.cambook.dao.mapper.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.*;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.time.temporal.WeekFields;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 超级管理员 — 全平台数据看板
 *
 * <p><b>设计原则</b>：所有聚合统计（营收求和、订单计数、排行、趋势）全部下推到 SQL，
 * 禁止将大量行加载到 JVM 内存后在应用层聚合。SQL 返回的行数 ≤ 桶数（≤ 30），
 * 应用层只做零填充（填补无数据的时间桶）。
 *
 * <p><b>trend 构建流程</b>：
 * <ol>
 *   <li>预生成期望的有序标签列表（如最近 7 天的 "MM-dd"）</li>
 *   <li>发送一条 SQL GROUP BY 查询，取回当前有数据的桶</li>
 *   <li>按标签 merge：有数据用 SQL 结果，无数据填充零值</li>
 * </ol>
 *
 * @author CamBook
 */
@Tag(name = "Admin - 平台数据看板")
@RestController
@RequestMapping("/admin/dashboard")
public class AdminDashboardController {

    /** 合法的 period 参数集合，非法值默认回退到 week */
    private static final Set<String> VALID_PERIODS = Set.of("day", "week", "month", "year");

    private final CbOrderMapper      orderMapper;
    private final CbMemberMapper     memberMapper;
    private final CbMerchantMapper   merchantMapper;
    private final CbTechnicianMapper technicianMapper;

    public AdminDashboardController(CbOrderMapper orderMapper,
                                    CbMemberMapper memberMapper,
                                    CbMerchantMapper merchantMapper,
                                    CbTechnicianMapper technicianMapper) {
        this.orderMapper      = orderMapper;
        this.memberMapper     = memberMapper;
        this.merchantMapper   = merchantMapper;
        this.technicianMapper = technicianMapper;
    }

    // ── 综合数据看板 ──────────────────────────────────────────────────────────

    @Operation(summary = "全平台数据看板（period: day|week|month|year，非法值回退到 week）")
    @GetMapping("/stats")
    public Result<Map<String, Object>> stats(
            @RequestParam(defaultValue = "week") String period) {

        // 非法 period 回退到 week（而非抛异常，保持接口宽容性）
        String p = VALID_PERIODS.contains(period) ? period : "week";

        // ── 会员统计（selectCount → SQL COUNT，已是高效聚合）────────────────────
        long totalMembers     = memberMapper.selectCount(lq(CbMember.class).eq(CbMember::getDeleted, 0));
        long todayMembers     = memberMapper.selectCount(lq(CbMember.class).eq(CbMember::getDeleted, 0).ge(CbMember::getCreateTime, todayStart()));
        long weekMembers      = memberMapper.selectCount(lq(CbMember.class).eq(CbMember::getDeleted, 0).ge(CbMember::getCreateTime, weekStart()));
        long monthMembers     = memberMapper.selectCount(lq(CbMember.class).eq(CbMember::getDeleted, 0).ge(CbMember::getCreateTime, monthStart()));
        long yestMembers      = memberMapper.selectCount(lq(CbMember.class).eq(CbMember::getDeleted, 0).ge(CbMember::getCreateTime, yesterdayStart()).lt(CbMember::getCreateTime, todayStart()));
        long lastMonthMembers = memberMapper.selectCount(lq(CbMember.class).eq(CbMember::getDeleted, 0).ge(CbMember::getCreateTime, prevMonthStart()).lt(CbMember::getCreateTime, monthStart()));

        // ── 商户 & 技师统计 ────────────────────────────────────────────────────
        long totalMerchants  = merchantMapper.selectCount(lq(CbMerchant.class).eq(CbMerchant::getDeleted, 0));
        long activeMerchants = merchantMapper.selectCount(lq(CbMerchant.class).eq(CbMerchant::getDeleted, 0).eq(CbMerchant::getStatus, 1));
        long totalTechs      = technicianMapper.selectCount(lq(CbTechnician.class).eq(CbTechnician::getDeleted, 0));
        long onlineTechs     = technicianMapper.selectCount(lq(CbTechnician.class).eq(CbTechnician::getDeleted, 0).eq(CbTechnician::getOnlineStatus, 1));
        long servingTechs    = technicianMapper.selectCount(lq(CbTechnician.class).eq(CbTechnician::getDeleted, 0).eq(CbTechnician::getOnlineStatus, 2));

        // ── 订单计数（SQL COUNT，不加载行数据）────────────────────────────────
        long totalOrders     = orderMapper.countOrders(null,              null,            null);
        long todayOrders     = orderMapper.countOrders(todayStart(),      tomorrowStart(), null);
        long weekOrders      = orderMapper.countOrders(weekStart(),        tomorrowStart(), null);
        long monthOrders     = orderMapper.countOrders(monthStart(),       tomorrowStart(), null);
        long yestOrders      = orderMapper.countOrders(yesterdayStart(),   todayStart(),    null);
        long lastWeekOrders  = orderMapper.countOrders(weekStart() - 7 * 86400L, weekStart(), null);
        long lastMonthOrders = orderMapper.countOrders(prevMonthStart(),   monthStart(),    null);

        // ── 营收（SQL SUM，不加载行数据）─────────────────────────────────────
        BigDecimal totalRevenue    = orderMapper.sumRevenue(null,              null);
        BigDecimal platformIncome  = orderMapper.sumPlatformIncome(null,       null);
        BigDecimal todayRevenue    = orderMapper.sumRevenue(todayStart(),      tomorrowStart());
        BigDecimal weekRevenue     = orderMapper.sumRevenue(weekStart(),       tomorrowStart());
        BigDecimal monthRevenue    = orderMapper.sumRevenue(monthStart(),      tomorrowStart());
        BigDecimal yestRevenue     = orderMapper.sumRevenue(yesterdayStart(),  todayStart());
        BigDecimal lastWeekRev     = orderMapper.sumRevenue(weekStart() - 7 * 86400L, weekStart());
        BigDecimal lastMonthRev    = orderMapper.sumRevenue(prevMonthStart(),  monthStart());

        BigDecimal avgOrderValue = totalRevenue.compareTo(BigDecimal.ZERO) > 0 && totalOrders > 0
                ? totalRevenue.divide(BigDecimal.valueOf(totalOrders), 2, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        // ── 状态分布（SQL GROUP BY，O(状态数) 行）────────────────────────────
        Map<Integer, Long> statusDist = orderMapper.statusDistribution().stream()
                .collect(Collectors.toMap(
                        m -> ((Number) m.get("status")).intValue(),
                        m -> ((Number) m.get("cnt")).longValue()));

        // ── 商户营收排行 Top 10（SQL GROUP BY + ORDER BY + LIMIT）────────────
        List<Map<String, Object>> merchantRank = buildMerchantRank();

        // ── 技师绩效排行 Top 8（SQL GROUP BY + ORDER BY + LIMIT）────────────
        List<Map<String, Object>> techRank = buildTechRank();

        // ── 趋势（SQL GROUP BY + 应用层零填充，行数 = 桶数）─────────────────
        List<Map<String, Object>> trend      = buildTrend(p);
        List<Map<String, Object>> memberTrend = buildMemberTrend(p);

        // ── 组装返回 ──────────────────────────────────────────────────────────
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("totalMembers",      totalMembers);
        data.put("todayMembers",      todayMembers);
        data.put("weekMembers",       weekMembers);
        data.put("monthMembers",      monthMembers);
        data.put("yestMembers",       yestMembers);
        data.put("lastMonthMembers",  lastMonthMembers);
        data.put("totalMerchants",    totalMerchants);
        data.put("activeMerchants",   activeMerchants);
        data.put("totalTechs",        totalTechs);
        data.put("onlineTechs",       onlineTechs);
        data.put("servingTechs",      servingTechs);
        data.put("totalOrders",       totalOrders);
        data.put("todayOrders",       todayOrders);
        data.put("weekOrders",        weekOrders);
        data.put("monthOrders",       monthOrders);
        data.put("yestOrders",        yestOrders);
        data.put("lastWeekOrders",    lastWeekOrders);
        data.put("lastMonthOrders",   lastMonthOrders);
        data.put("totalRevenue",      totalRevenue);
        data.put("platformIncome",    platformIncome);
        data.put("todayRevenue",      todayRevenue);
        data.put("weekRevenue",       weekRevenue);
        data.put("monthRevenue",      monthRevenue);
        data.put("yestRevenue",       yestRevenue);
        data.put("lastWeekRevenue",   lastWeekRev);
        data.put("lastMonthRevenue",  lastMonthRev);
        data.put("avgOrderValue",     avgOrderValue);
        data.put("statusDistribution", statusDist);
        data.put("merchantRank",      merchantRank);
        data.put("techRank",          techRank);
        data.put("trend",             trend);
        data.put("memberTrend",       memberTrend);

        return Result.success(data);
    }

    // ── 排行榜（SQL 聚合 + 批量主键查名称）────────────────────────────────────

    /** 商户营收排行 Top 10 */
    private List<Map<String, Object>> buildMerchantRank() {
        List<Map<String, Object>> rows = orderMapper.merchantRevenueRank(10);
        if (rows.isEmpty()) return Collections.emptyList();

        List<Long> ids = rows.stream()
                .map(r -> MapRowUtils.toLongOrNull(r.get("merchantId")))
                .collect(Collectors.toList());
        Map<Long, CbMerchant> merchantMap = merchantMapper.selectBatchIds(ids).stream()
                .collect(Collectors.toMap(CbMerchant::getId, m -> m));

        return rows.stream().map(r -> {
            Long id = MapRowUtils.toLongOrNull(r.get("merchantId"));
            CbMerchant m = merchantMap.get(id);
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id",         id);
            item.put("name",       m != null ? m.getMerchantNameZh() : "商户#" + id);
            item.put("logo",       m != null ? m.getLogo() : null);
            item.put("revenue",    r.get("revenue"));
            item.put("orderCount", r.get("orderCount"));
            return item;
        }).collect(Collectors.toList());
    }

    /** 技师绩效排行 Top 8 */
    private List<Map<String, Object>> buildTechRank() {
        List<Map<String, Object>> rows = orderMapper.techOrderRank(8);
        if (rows.isEmpty()) return Collections.emptyList();

        List<Long> ids = rows.stream()
                .map(r -> MapRowUtils.toLongOrNull(r.get("technicianId")))
                .collect(Collectors.toList());
        Map<Long, CbTechnician> techMap = technicianMapper.selectBatchIds(ids).stream()
                .collect(Collectors.toMap(CbTechnician::getId, t -> t));

        return rows.stream().map(r -> {
            Long id = MapRowUtils.toLongOrNull(r.get("technicianId"));
            CbTechnician t = techMap.get(id);
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id",         id);
            item.put("name",       t != null ? (t.getNickname() != null ? t.getNickname() : t.getRealName()) : "技师#" + id);
            item.put("avatar",     t != null ? t.getAvatar() : null);
            item.put("orderCount", r.get("orderCount"));
            item.put("revenue",    r.get("revenue"));
            return item;
        }).collect(Collectors.toList());
    }

    // ── 趋势（SQL GROUP BY + 应用层零填充）────────────────────────────────────

    /**
     * 营收趋势：发一条 SQL 取已有数据桶，应用层补齐无数据的空桶。
     *
     * <p>有效 period 由调用方保证（已在入口归一化），此处无需 default 兜底。
     */
    private List<Map<String, Object>> buildTrend(String period) {
        ZoneId zone = ZoneId.systemDefault();
        return switch (period) {
            case "day" -> {
                long from = ZonedDateTime.now(zone).truncatedTo(ChronoUnit.DAYS).toEpochSecond();
                long to   = from + 86400L;
                Map<String, long[]> sqlData = orderMapper.revenueTrendByHour(from, to)
                        .stream().collect(Collectors.toMap(
                                r -> (String) r.get("hour"),
                                r -> new long[]{MapRowUtils.toLong(r.get("orders")), 0},
                                (a, b) -> a));
                Map<String, BigDecimal> revData = orderMapper.revenueTrendByHour(from, to)
                        .stream().collect(Collectors.toMap(
                                r -> (String) r.get("hour"),
                                r -> MapRowUtils.toBigDecimal(r.get("revenue")),
                                (a, b) -> a));
                List<Map<String, Object>> result = new ArrayList<>(24);
                for (int h = 0; h < 24; h++) {
                    String hour = String.format("%02d", h);
                    Map<String, Object> item = new LinkedHashMap<>();
                    item.put("label",   hour + ":00");
                    item.put("revenue", revData.getOrDefault(hour, BigDecimal.ZERO));
                    item.put("orders",  sqlData.containsKey(hour) ? sqlData.get(hour)[0] : 0L);
                    result.add(item);
                }
                yield result;
            }
            case "week" -> buildDayTrend(7, zone);
            case "month" -> buildDayTrend(30, zone);
            case "year" -> {
                LocalDate firstOfRange = LocalDate.now(zone).minusMonths(11).withDayOfMonth(1);
                long from = firstOfRange.atStartOfDay(zone).toEpochSecond();
                long to   = LocalDate.now(zone).plusMonths(1).withDayOfMonth(1).atStartOfDay(zone).toEpochSecond();
                Map<String, BigDecimal> revData = toMonthRevMap(orderMapper.revenueTrendByMonth(from, to));
                Map<String, Long>       cntData = toMonthCntMap(orderMapper.revenueTrendByMonth(from, to));
                List<Map<String, Object>> result = new ArrayList<>(12);
                for (int m = 11; m >= 0; m--) {
                    String key = LocalDate.now(zone).minusMonths(m).withDayOfMonth(1)
                            .format(DateTimeFormatter.ofPattern("yyyy-MM"));
                    Map<String, Object> item = new LinkedHashMap<>();
                    item.put("label",   key);
                    item.put("revenue", revData.getOrDefault(key, BigDecimal.ZERO));
                    item.put("orders",  cntData.getOrDefault(key, 0L));
                    result.add(item);
                }
                yield result;
            }
            default -> throw new IllegalStateException("period 已在入口归一化，不应到达 default: " + period);
        };
    }

    /** 新增会员趋势：同样 SQL GROUP BY + 零填充 */
    private List<Map<String, Object>> buildMemberTrend(String period) {
        ZoneId zone = ZoneId.systemDefault();
        return switch (period) {
            case "day" -> {
                long from = ZonedDateTime.now(zone).truncatedTo(ChronoUnit.DAYS).toEpochSecond();
                long to   = from + 86400L;
                Map<String, Long> sqlData = memberMapper.memberTrendByHour(from, to)
                        .stream().collect(Collectors.toMap(
                                r -> (String) r.get("hour"),
                                r -> MapRowUtils.toLong(r.get("newMembers")),
                                (a, b) -> a));
                List<Map<String, Object>> result = new ArrayList<>(24);
                for (int h = 0; h < 24; h++) {
                    String hour = String.format("%02d", h);
                    Map<String, Object> item = new LinkedHashMap<>();
                    item.put("label",      hour + ":00");
                    item.put("newMembers", sqlData.getOrDefault(hour, 0L));
                    result.add(item);
                }
                yield result;
            }
            case "week"  -> buildMemberDayTrend(7, zone);
            case "month" -> buildMemberDayTrend(30, zone);
            case "year" -> {
                LocalDate firstOfRange = LocalDate.now(zone).minusMonths(11).withDayOfMonth(1);
                long from = firstOfRange.atStartOfDay(zone).toEpochSecond();
                long to   = LocalDate.now(zone).plusMonths(1).withDayOfMonth(1).atStartOfDay(zone).toEpochSecond();
                Map<String, Long> sqlData = memberMapper.memberTrendByMonth(from, to)
                        .stream().collect(Collectors.toMap(
                                r -> (String) r.get("month"),
                                r -> MapRowUtils.toLong(r.get("newMembers")),
                                (a, b) -> a));
                List<Map<String, Object>> result = new ArrayList<>(12);
                for (int m = 11; m >= 0; m--) {
                    String key = LocalDate.now(zone).minusMonths(m).withDayOfMonth(1)
                            .format(DateTimeFormatter.ofPattern("yyyy-MM"));
                    Map<String, Object> item = new LinkedHashMap<>();
                    item.put("label",      key);
                    item.put("newMembers", sqlData.getOrDefault(key, 0L));
                    result.add(item);
                }
                yield result;
            }
            default -> throw new IllegalStateException("period 已在入口归一化，不应到达 default: " + period);
        };
    }

    // ── 趋势辅助方法 ──────────────────────────────────────────────────────────

    /** 构建 days 天的营收日趋势，查一次 SQL 后按日期零填充 */
    private List<Map<String, Object>> buildDayTrend(int days, ZoneId zone) {
        LocalDate today = LocalDate.now(zone);
        LocalDate start = today.minusDays(days - 1);
        long from = start.atStartOfDay(zone).toEpochSecond();
        long to   = today.plusDays(1).atStartOfDay(zone).toEpochSecond();

        // 一次 SQL 取所有有数据的天
        List<Map<String, Object>> sqlRows = orderMapper.revenueTrendByDay(from, to);
        Map<String, BigDecimal> revByYmd = sqlRows.stream().collect(
                Collectors.toMap(r -> (String) r.get("ymd"), r -> MapRowUtils.toBigDecimal(r.get("revenue")), (a, b) -> a));
        Map<String, Long> cntByYmd = sqlRows.stream().collect(
                Collectors.toMap(r -> (String) r.get("ymd"), r -> MapRowUtils.toLong(r.get("orders")), (a, b) -> a));

        DateTimeFormatter fmtLabel = DateTimeFormatter.ofPattern("MM-dd");
        List<Map<String, Object>> result = new ArrayList<>(days);
        for (int d = days - 1; d >= 0; d--) {
            LocalDate day = today.minusDays(d);
            String ymd   = day.format(DateTimeFormatter.ISO_LOCAL_DATE);
            String label = day.format(fmtLabel);
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("label",   label);
            item.put("revenue", revByYmd.getOrDefault(ymd, BigDecimal.ZERO));
            item.put("orders",  cntByYmd.getOrDefault(ymd, 0L));
            result.add(item);
        }
        return result;
    }

    /** 构建 days 天的会员日趋势，查一次 SQL 后按日期零填充 */
    private List<Map<String, Object>> buildMemberDayTrend(int days, ZoneId zone) {
        LocalDate today = LocalDate.now(zone);
        LocalDate start = today.minusDays(days - 1);
        long from = start.atStartOfDay(zone).toEpochSecond();
        long to   = today.plusDays(1).atStartOfDay(zone).toEpochSecond();

        List<Map<String, Object>> sqlRows = memberMapper.memberTrendByDay(from, to);
        Map<String, Long> cntByYmd = sqlRows.stream().collect(
                Collectors.toMap(r -> (String) r.get("ymd"), r -> MapRowUtils.toLong(r.get("newMembers")), (a, b) -> a));

        DateTimeFormatter fmtLabel = DateTimeFormatter.ofPattern("MM-dd");
        List<Map<String, Object>> result = new ArrayList<>(days);
        for (int d = days - 1; d >= 0; d--) {
            LocalDate day = today.minusDays(d);
            String ymd   = day.format(DateTimeFormatter.ISO_LOCAL_DATE);
            String label = day.format(fmtLabel);
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("label",      label);
            item.put("newMembers", cntByYmd.getOrDefault(ymd, 0L));
            result.add(item);
        }
        return result;
    }

    // ── 月度趋势 Map 构建（使用 MapRowUtils 统一类型转换）─────────────────────

    private static Map<String, BigDecimal> toMonthRevMap(List<Map<String, Object>> rows) {
        return rows.stream().collect(Collectors.toMap(
                r -> (String) r.get("month"),
                r -> MapRowUtils.toBigDecimal(r.get("revenue")),
                (a, b) -> a));
    }

    private static Map<String, Long> toMonthCntMap(List<Map<String, Object>> rows) {
        return rows.stream().collect(Collectors.toMap(
                r -> (String) r.get("month"),
                r -> MapRowUtils.toLong(r.get("orders")),
                (a, b) -> a));
    }

    // ── 日期边界工具（UTC epoch seconds，按系统时区计算） ─────────────────────

    private static long todayStart()     { return boundary(0);  }
    private static long tomorrowStart()  { return boundary(1);  }
    private static long yesterdayStart() { return boundary(-1); }

    private static long boundary(int plusDays) {
        return LocalDate.now().plusDays(plusDays)
                .atStartOfDay(ZoneId.systemDefault()).toEpochSecond();
    }

    private static long weekStart() {
        return LocalDate.now().with(WeekFields.ISO.dayOfWeek(), 1)
                .atStartOfDay(ZoneId.systemDefault()).toEpochSecond();
    }

    private static long monthStart() {
        return LocalDate.now().withDayOfMonth(1)
                .atStartOfDay(ZoneId.systemDefault()).toEpochSecond();
    }

    private static long prevMonthStart() {
        return LocalDate.now().minusMonths(1).withDayOfMonth(1)
                .atStartOfDay(ZoneId.systemDefault()).toEpochSecond();
    }

    /** 简化 LambdaQueryWrapper 创建的泛型辅助 */
    private static <T> com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<T>
            lq(Class<T> clazz) {
        return Wrappers.<T>lambdaQuery();
    }
}
