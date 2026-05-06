package com.cambook.app.service.admin.impl;

import com.cambook.app.service.admin.IAdminDashboardService;
import com.cambook.common.utils.DateUtils;
import com.cambook.common.utils.MapRowUtils;
import com.cambook.db.entity.CbMember;
import com.cambook.db.entity.CbMerchant;
import com.cambook.db.entity.CbTechnician;
import com.cambook.db.mapper.CbMemberMapper;
import com.cambook.db.mapper.CbOrderMapper;
import com.cambook.db.service.ICbMemberService;
import com.cambook.db.service.ICbMerchantService;
import com.cambook.db.service.ICbTechnicianService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.*;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.time.temporal.WeekFields;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Admin 平台数据看板实现
 *
 * <p>聚合统计（营收求和、订单计数、排行、趋势）全部下推到 SQL，
 * 应用层只做零填充（填补无数据的时间桶）。
 */
@Service
@RequiredArgsConstructor
public class AdminDashboardService implements IAdminDashboardService {

    private static final Set<String> VALID_PERIODS   = Set.of("day", "week", "month", "year");
    private static final int         TECH_ONLINE     = 1;
    private static final int         TECH_SERVING    = 2;
    private static final int         MERCHANT_ACTIVE = 1;

    private final ICbMemberService     cbMemberService;
    private final ICbMerchantService   cbMerchantService;
    private final ICbTechnicianService cbTechnicianService;
    private final CbOrderMapper        cbOrderMapper;
    private final CbMemberMapper       cbMemberMapper;

    @Override
    public Map<String, Object> stats(String period) {
        String p = VALID_PERIODS.contains(period) ? period : "week";

        long totalMembers     = cbMemberService.lambdaQuery().eq(CbMember::getDeleted, Boolean.FALSE).count();
        long todayMembers     = cbMemberService.lambdaQuery().eq(CbMember::getDeleted, Boolean.FALSE).ge(CbMember::getCreateTime, DateUtils.todayStart()).count();
        long weekMembers      = cbMemberService.lambdaQuery().eq(CbMember::getDeleted, Boolean.FALSE).ge(CbMember::getCreateTime, DateUtils.weekStart()).count();
        long monthMembers     = cbMemberService.lambdaQuery().eq(CbMember::getDeleted, Boolean.FALSE).ge(CbMember::getCreateTime, DateUtils.monthStart()).count();
        long yestMembers      = cbMemberService.lambdaQuery().eq(CbMember::getDeleted, Boolean.FALSE).ge(CbMember::getCreateTime, DateUtils.yesterdayStart()).lt(CbMember::getCreateTime, DateUtils.todayStart()).count();
        long lastMonthMembers = cbMemberService.lambdaQuery().eq(CbMember::getDeleted, Boolean.FALSE).ge(CbMember::getCreateTime, DateUtils.prevMonthStart()).lt(CbMember::getCreateTime, DateUtils.monthStart()).count();

        long totalMerchants  = cbMerchantService.lambdaQuery().eq(CbMerchant::getDeleted, Boolean.FALSE).count();
        long activeMerchants = cbMerchantService.lambdaQuery().eq(CbMerchant::getDeleted, Boolean.FALSE).eq(CbMerchant::getStatus, MERCHANT_ACTIVE).count();
        long totalTechs      = cbTechnicianService.lambdaQuery().eq(CbTechnician::getDeleted, Boolean.FALSE).count();
        long onlineTechs     = cbTechnicianService.lambdaQuery().eq(CbTechnician::getDeleted, Boolean.FALSE).eq(CbTechnician::getOnlineStatus, TECH_ONLINE).count();
        long servingTechs    = cbTechnicianService.lambdaQuery().eq(CbTechnician::getDeleted, Boolean.FALSE).eq(CbTechnician::getOnlineStatus, TECH_SERVING).count();

        long totalOrders     = cbOrderMapper.countOrders(null,              null,            null);
        long todayOrders     = cbOrderMapper.countOrders(DateUtils.todayStart(),      DateUtils.tomorrowStart(), null);
        long weekOrders      = cbOrderMapper.countOrders(DateUtils.weekStart(),       DateUtils.tomorrowStart(), null);
        long monthOrders     = cbOrderMapper.countOrders(DateUtils.monthStart(),      DateUtils.tomorrowStart(), null);
        long yestOrders      = cbOrderMapper.countOrders(DateUtils.yesterdayStart(),  DateUtils.todayStart(),    null);
        long lastWeekOrders  = cbOrderMapper.countOrders(DateUtils.prevWeekStart(), DateUtils.weekStart(), null);
        long lastMonthOrders = cbOrderMapper.countOrders(DateUtils.prevMonthStart(),  DateUtils.monthStart(),    null);

        BigDecimal totalRevenue   = cbOrderMapper.sumRevenue(null,              null);
        BigDecimal platformIncome = cbOrderMapper.sumPlatformIncome(null,       null);
        BigDecimal todayRevenue   = cbOrderMapper.sumRevenue(DateUtils.todayStart(),      DateUtils.tomorrowStart());
        BigDecimal weekRevenue    = cbOrderMapper.sumRevenue(DateUtils.weekStart(),       DateUtils.tomorrowStart());
        BigDecimal monthRevenue   = cbOrderMapper.sumRevenue(DateUtils.monthStart(),      DateUtils.tomorrowStart());
        BigDecimal yestRevenue    = cbOrderMapper.sumRevenue(DateUtils.yesterdayStart(),  DateUtils.todayStart());
        BigDecimal lastWeekRev    = cbOrderMapper.sumRevenue(DateUtils.prevWeekStart(), DateUtils.weekStart());
        BigDecimal lastMonthRev   = cbOrderMapper.sumRevenue(DateUtils.prevMonthStart(),  DateUtils.monthStart());

        BigDecimal avgOrderValue = (totalRevenue.compareTo(BigDecimal.ZERO) > 0 && totalOrders > 0)
                ? totalRevenue.divide(BigDecimal.valueOf(totalOrders), 2, RoundingMode.HALF_UP) : BigDecimal.ZERO;

        Map<Integer, Long> statusDist = cbOrderMapper.statusDistribution().stream()
                .collect(Collectors.toMap(m -> ((Number) m.get("status")).intValue(), m -> ((Number) m.get("cnt")).longValue()));

        List<Map<String, Object>> merchantRank = buildMerchantRank();
        List<Map<String, Object>> techRank     = buildTechRank();
        List<Map<String, Object>> trend        = buildTrend(p);
        List<Map<String, Object>> memberTrend  = buildMemberTrend(p);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("totalMembers",       totalMembers);
        data.put("todayMembers",       todayMembers);
        data.put("weekMembers",        weekMembers);
        data.put("monthMembers",       monthMembers);
        data.put("yestMembers",        yestMembers);
        data.put("lastMonthMembers",   lastMonthMembers);
        data.put("totalMerchants",     totalMerchants);
        data.put("activeMerchants",    activeMerchants);
        data.put("totalTechs",         totalTechs);
        data.put("onlineTechs",        onlineTechs);
        data.put("servingTechs",       servingTechs);
        data.put("totalOrders",        totalOrders);
        data.put("todayOrders",        todayOrders);
        data.put("weekOrders",         weekOrders);
        data.put("monthOrders",        monthOrders);
        data.put("yestOrders",         yestOrders);
        data.put("lastWeekOrders",     lastWeekOrders);
        data.put("lastMonthOrders",    lastMonthOrders);
        data.put("totalRevenue",       totalRevenue);
        data.put("platformIncome",     platformIncome);
        data.put("todayRevenue",       todayRevenue);
        data.put("weekRevenue",        weekRevenue);
        data.put("monthRevenue",       monthRevenue);
        data.put("yestRevenue",        yestRevenue);
        data.put("lastWeekRevenue",    lastWeekRev);
        data.put("lastMonthRevenue",   lastMonthRev);
        data.put("avgOrderValue",      avgOrderValue);
        data.put("statusDistribution", statusDist);
        data.put("merchantRank",       merchantRank);
        data.put("techRank",           techRank);
        data.put("trend",              trend);
        data.put("memberTrend",        memberTrend);
        return data;
    }

    // ── 排行榜 ────────────────────────────────────────────────────────────────

    private List<Map<String, Object>> buildMerchantRank() {
        List<Map<String, Object>> rows = cbOrderMapper.merchantRevenueRank(10);
        if (rows.isEmpty()) return Collections.emptyList();
        List<Long> ids = rows.stream().map(r -> MapRowUtils.toLongOrNull(r.get("merchantId"))).collect(Collectors.toList());
        Map<Long, CbMerchant> map = cbMerchantService.listByIds(ids).stream().collect(Collectors.toMap(CbMerchant::getId, m -> m));
        return rows.stream().map(r -> {
            Long       id   = MapRowUtils.toLongOrNull(r.get("merchantId"));
            CbMerchant m    = map.get(id);
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id",         id);
            item.put("name",       m != null ? m.getMerchantNameZh() : "商户#" + id);
            item.put("logo",       m != null ? m.getLogo() : null);
            item.put("revenue",    r.get("revenue"));
            item.put("orderCount", r.get("orderCount"));
            return item;
        }).collect(Collectors.toList());
    }

    private List<Map<String, Object>> buildTechRank() {
        List<Map<String, Object>> rows = cbOrderMapper.techOrderRank(8);
        if (rows.isEmpty()) return Collections.emptyList();
        List<Long> ids = rows.stream().map(r -> MapRowUtils.toLongOrNull(r.get("technicianId"))).collect(Collectors.toList());
        Map<Long, CbTechnician> map = cbTechnicianService.listByIds(ids).stream().collect(Collectors.toMap(CbTechnician::getId, t -> t));
        return rows.stream().map(r -> {
            Long         id = MapRowUtils.toLongOrNull(r.get("technicianId"));
            CbTechnician t  = map.get(id);
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id",         id);
            item.put("name",       t != null ? (t.getNickname() != null ? t.getNickname() : t.getRealName()) : "技师#" + id);
            item.put("avatar",     t != null ? t.getAvatar() : null);
            item.put("orderCount", r.get("orderCount"));
            item.put("revenue",    r.get("revenue"));
            return item;
        }).collect(Collectors.toList());
    }

    // ── 趋势 ─────────────────────────────────────────────────────────────────

    private List<Map<String, Object>> buildTrend(String period) {
        ZoneId zone = ZoneId.systemDefault();
        return switch (period) {
            case "day" -> {
                long from = DateUtils.todayStart(), to = DateUtils.tomorrowStart();
                List<Map<String,Object>> sqlRows = cbOrderMapper.revenueTrendByHour(from, to);
                Map<String, BigDecimal> revData = sqlRows.stream().collect(Collectors.toMap(r -> (String) r.get("hour"), r -> MapRowUtils.toBigDecimal(r.get("revenue")), (a, b) -> a));
                Map<String, Long>       cntData = sqlRows.stream().collect(Collectors.toMap(r -> (String) r.get("hour"), r -> MapRowUtils.toLong(r.get("orders")), (a, b) -> a));
                List<Map<String,Object>> result = new ArrayList<>(24);
                for (int h = 0; h < 24; h++) {
                    String hour = String.format("%02d", h);
                    Map<String,Object> item = new LinkedHashMap<>();
                    item.put("label",  hour + ":00");
                    item.put("revenue", revData.getOrDefault(hour, BigDecimal.ZERO));
                    item.put("orders",  cntData.getOrDefault(hour, 0L));
                    result.add(item);
                }
                yield result;
            }
            case "week"  -> buildDayTrend(7, zone);
            case "month" -> buildDayTrend(30, zone);
            case "year"  -> {
                long from = DateUtils.monthStartOf(11), to = DateUtils.nextMonthStart();
                List<Map<String,Object>> rows = cbOrderMapper.revenueTrendByMonth(from, to);
                Map<String, BigDecimal> revData = rows.stream().collect(Collectors.toMap(r -> (String) r.get("month"), r -> MapRowUtils.toBigDecimal(r.get("revenue")), (a, b) -> a));
                Map<String, Long>       cntData = rows.stream().collect(Collectors.toMap(r -> (String) r.get("month"), r -> MapRowUtils.toLong(r.get("orders")), (a, b) -> a));
                List<Map<String,Object>> result = new ArrayList<>(12);
                for (int m = 11; m >= 0; m--) {
                    String key = LocalDate.now().minusMonths(m).withDayOfMonth(1).format(DateUtils.FMT_YEAR_MONTH);
                    Map<String,Object> item = new LinkedHashMap<>();
                    item.put("label",   key);
                    item.put("revenue", revData.getOrDefault(key, BigDecimal.ZERO));
                    item.put("orders",  cntData.getOrDefault(key, 0L));
                    result.add(item);
                }
                yield result;
            }
            default -> Collections.emptyList();
        };
    }

    private List<Map<String, Object>> buildMemberTrend(String period) {
        ZoneId zone = ZoneId.systemDefault();
        return switch (period) {
            case "day" -> {
                long from = DateUtils.todayStart(), to = DateUtils.tomorrowStart();
                Map<String, Long> sqlData = cbMemberMapper.memberTrendByHour(from, to).stream()
                        .collect(Collectors.toMap(r -> (String) r.get("hour"), r -> MapRowUtils.toLong(r.get("newMembers")), (a, b) -> a));
                List<Map<String,Object>> result = new ArrayList<>(24);
                for (int h = 0; h < 24; h++) {
                    String hour = String.format("%02d", h);
                    Map<String,Object> item = new LinkedHashMap<>();
                    item.put("label",      hour + ":00");
                    item.put("newMembers", sqlData.getOrDefault(hour, 0L));
                    result.add(item);
                }
                yield result;
            }
            case "week"  -> buildMemberDayTrend(7, zone);
            case "month" -> buildMemberDayTrend(30, zone);
            case "year"  -> {
                long from = DateUtils.monthStartOf(11), to = DateUtils.nextMonthStart();
                Map<String, Long> sqlData = cbMemberMapper.memberTrendByMonth(from, to).stream()
                        .collect(Collectors.toMap(r -> (String) r.get("month"), r -> MapRowUtils.toLong(r.get("newMembers")), (a, b) -> a));
                List<Map<String,Object>> result = new ArrayList<>(12);
                for (int m = 11; m >= 0; m--) {
                    String key = LocalDate.now().minusMonths(m).withDayOfMonth(1).format(DateUtils.FMT_YEAR_MONTH);
                    Map<String,Object> item = new LinkedHashMap<>();
                    item.put("label",      key);
                    item.put("newMembers", sqlData.getOrDefault(key, 0L));
                    result.add(item);
                }
                yield result;
            }
            default -> Collections.emptyList();
        };
    }

    private List<Map<String, Object>> buildDayTrend(int days, ZoneId zone) {
        LocalDate today = LocalDate.now();
        long from = DateUtils.dayStart(today.minusDays(days - 1)),
             to   = DateUtils.tomorrowStart();
        List<Map<String,Object>> sqlRows = cbOrderMapper.revenueTrendByDay(from, to);
        Map<String, BigDecimal> revByYmd = sqlRows.stream().collect(Collectors.toMap(r -> (String) r.get("ymd"), r -> MapRowUtils.toBigDecimal(r.get("revenue")), (a, b) -> a));
        Map<String, Long>       cntByYmd = sqlRows.stream().collect(Collectors.toMap(r -> (String) r.get("ymd"), r -> MapRowUtils.toLong(r.get("orders")), (a, b) -> a));
        DateTimeFormatter fmtLabel = DateTimeFormatter.ofPattern("MM-dd");
        List<Map<String,Object>> result = new ArrayList<>(days);
        for (int d = days - 1; d >= 0; d--) {
            LocalDate day = today.minusDays(d);
            String    ymd = day.format(DateTimeFormatter.ISO_LOCAL_DATE);
            Map<String,Object> item = new LinkedHashMap<>();
            item.put("label",   day.format(fmtLabel));
            item.put("revenue", revByYmd.getOrDefault(ymd, BigDecimal.ZERO));
            item.put("orders",  cntByYmd.getOrDefault(ymd, 0L));
            result.add(item);
        }
        return result;
    }

    private List<Map<String, Object>> buildMemberDayTrend(int days, ZoneId zone) {
        LocalDate today = LocalDate.now();
        long from = DateUtils.dayStart(today.minusDays(days - 1)),
             to   = DateUtils.tomorrowStart();
        List<Map<String,Object>> sqlRows = cbMemberMapper.memberTrendByDay(from, to);
        Map<String, Long> cntByYmd = sqlRows.stream().collect(Collectors.toMap(r -> (String) r.get("ymd"), r -> MapRowUtils.toLong(r.get("newMembers")), (a, b) -> a));
        DateTimeFormatter fmtLabel = DateTimeFormatter.ofPattern("MM-dd");
        List<Map<String,Object>> result = new ArrayList<>(days);
        for (int d = days - 1; d >= 0; d--) {
            LocalDate day = today.minusDays(d);
            String    ymd = day.format(DateTimeFormatter.ISO_LOCAL_DATE);
            Map<String,Object> item = new LinkedHashMap<>();
            item.put("label",      day.format(fmtLabel));
            item.put("newMembers", cntByYmd.getOrDefault(ymd, 0L));
            result.add(item);
        }
        return result;
    }

}
