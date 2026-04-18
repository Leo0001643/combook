package com.cambook.app.controller.admin;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.cambook.common.result.Result;
import com.cambook.dao.entity.CbMember;
import com.cambook.dao.entity.CbMerchant;
import com.cambook.dao.entity.CbOrder;
import com.cambook.dao.entity.CbTechnician;
import com.cambook.dao.mapper.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.*;
import java.time.format.DateTimeFormatter;
import java.time.temporal.WeekFields;
import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * 超级管理员 — 全平台数据看板
 *
 * <p>聚合所有商户、会员、技师、订单数据，向超级管理员展示平台整体运营概览。
 * 支持日 / 周 / 月 / 年多维度趋势查询。
 *
 * @author CamBook
 */
@Tag(name = "Admin - 平台数据看板")
@RestController
@RequestMapping("/admin/dashboard")
public class AdminDashboardController {

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

    @Operation(summary = "全平台数据看板（period: day|week|month|year）")
    @GetMapping("/stats")
    public Result<Map<String, Object>> stats(@RequestParam(defaultValue = "week") String period) {

        // ── 会员统计 ──────────────────────────────────────────────────────────
        long totalMembers  = memberMapper.selectCount(Wrappers.<CbMember>lambdaQuery().eq(CbMember::getDeleted, 0));
        long todayMembers  = memberMapper.selectCount(Wrappers.<CbMember>lambdaQuery()
                .eq(CbMember::getDeleted, 0).ge(CbMember::getCreateTime, todayStart()));
        long weekMembers   = memberMapper.selectCount(Wrappers.<CbMember>lambdaQuery()
                .eq(CbMember::getDeleted, 0).ge(CbMember::getCreateTime, weekStart()));
        long monthMembers  = memberMapper.selectCount(Wrappers.<CbMember>lambdaQuery()
                .eq(CbMember::getDeleted, 0).ge(CbMember::getCreateTime, monthStart()));
        long yestMembers   = memberMapper.selectCount(Wrappers.<CbMember>lambdaQuery()
                .eq(CbMember::getDeleted, 0)
                .ge(CbMember::getCreateTime, yesterdayStart())
                .lt(CbMember::getCreateTime, todayStart()));
        long lastMonthMembers = memberMapper.selectCount(Wrappers.<CbMember>lambdaQuery()
                .eq(CbMember::getDeleted, 0)
                .ge(CbMember::getCreateTime, monthStart().minusMonths(1))
                .lt(CbMember::getCreateTime, monthStart()));

        // ── 商户统计 ──────────────────────────────────────────────────────────
        long totalMerchants  = merchantMapper.selectCount(Wrappers.<CbMerchant>lambdaQuery().eq(CbMerchant::getDeleted, 0));
        long activeMerchants = merchantMapper.selectCount(Wrappers.<CbMerchant>lambdaQuery()
                .eq(CbMerchant::getDeleted, 0).eq(CbMerchant::getStatus, 1));

        // ── 技师统计 ──────────────────────────────────────────────────────────
        long totalTechs  = technicianMapper.selectCount(Wrappers.<CbTechnician>lambdaQuery().eq(CbTechnician::getDeleted, 0));
        long onlineTechs = technicianMapper.selectCount(Wrappers.<CbTechnician>lambdaQuery()
                .eq(CbTechnician::getDeleted, 0).eq(CbTechnician::getOnlineStatus, 1));
        long servingTechs = technicianMapper.selectCount(Wrappers.<CbTechnician>lambdaQuery()
                .eq(CbTechnician::getDeleted, 0).eq(CbTechnician::getOnlineStatus, 2));

        // ── 订单 & 营收统计 ───────────────────────────────────────────────────
        long totalOrders  = orderCount(null, null, null);
        long todayOrders  = orderCount(todayStart(), tomorrowStart(), null);
        long weekOrders   = orderCount(weekStart(),  tomorrowStart(), null);
        long monthOrders  = orderCount(monthStart(), tomorrowStart(), null);
        long yestOrders   = orderCount(yesterdayStart(), todayStart(), null);
        long lastWeekOrders  = orderCount(weekStart().minusWeeks(1), weekStart(), null);
        long lastMonthOrders = orderCount(monthStart().minusMonths(1), monthStart(), null);

        // 加载全部已完成订单（用于营收聚合）
        List<CbOrder> completedOrders = orderMapper.selectList(
                Wrappers.<CbOrder>lambdaQuery()
                        .in(CbOrder::getStatus, 5, 6)
                        .eq(CbOrder::getDeleted, 0)
                        .select(CbOrder::getPayAmount, CbOrder::getPlatformIncome,
                                CbOrder::getMerchantId, CbOrder::getTechnicianId,
                                CbOrder::getCreateTime));

        BigDecimal totalRevenue   = sumAll(completedOrders, CbOrder::getPayAmount);
        BigDecimal platformIncome = sumAll(completedOrders, CbOrder::getPlatformIncome);

        BigDecimal todayRevenue  = sumSince(completedOrders, todayStart());
        BigDecimal weekRevenue   = sumSince(completedOrders, weekStart());
        BigDecimal monthRevenue  = sumSince(completedOrders, monthStart());
        BigDecimal yestRevenue   = sumRange(completedOrders, yesterdayStart(), todayStart());
        BigDecimal lastWeekRev   = sumRange(completedOrders, weekStart().minusWeeks(1), weekStart());
        BigDecimal lastMonthRev  = sumRange(completedOrders, monthStart().minusMonths(1), monthStart());

        BigDecimal avgOrderValue = totalRevenue.compareTo(BigDecimal.ZERO) > 0 && totalOrders > 0
                ? totalRevenue.divide(BigDecimal.valueOf(totalOrders), 2, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        // ── 订单状态分布（全平台）────────────────────────────────────────────
        List<CbOrder> statusOrders = orderMapper.selectList(
                Wrappers.<CbOrder>lambdaQuery().eq(CbOrder::getDeleted, 0).select(CbOrder::getStatus));
        Map<Integer, Long> statusDist = statusOrders.stream()
                .collect(Collectors.groupingBy(
                        o -> o.getStatus() == null ? 0 : o.getStatus().intValue(),
                        Collectors.counting()));

        // ── 商户营收排行 Top 10 ────────────────────────────────────────────────
        List<Map<String, Object>> merchantRank = buildMerchantRank(completedOrders);

        // ── 趋势数据 ──────────────────────────────────────────────────────────
        List<Map<String, Object>> trend     = buildTrend(period, completedOrders);
        List<Map<String, Object>> memberTrend = buildMemberTrend(period);

        // ── 技师排行 Top 8 ────────────────────────────────────────────────────
        List<Map<String, Object>> techRank = buildTechRank(completedOrders);

        // ── 组装返回 ──────────────────────────────────────────────────────────
        Map<String, Object> data = new LinkedHashMap<>();
        // 会员
        data.put("totalMembers",    totalMembers);
        data.put("todayMembers",    todayMembers);
        data.put("weekMembers",     weekMembers);
        data.put("monthMembers",    monthMembers);
        data.put("yestMembers",     yestMembers);
        data.put("lastMonthMembers",lastMonthMembers);
        // 商户
        data.put("totalMerchants",  totalMerchants);
        data.put("activeMerchants", activeMerchants);
        // 技师
        data.put("totalTechs",      totalTechs);
        data.put("onlineTechs",     onlineTechs);
        data.put("servingTechs",    servingTechs);
        // 订单
        data.put("totalOrders",     totalOrders);
        data.put("todayOrders",     todayOrders);
        data.put("weekOrders",      weekOrders);
        data.put("monthOrders",     monthOrders);
        data.put("yestOrders",      yestOrders);
        data.put("lastWeekOrders",  lastWeekOrders);
        data.put("lastMonthOrders", lastMonthOrders);
        // 营收
        data.put("totalRevenue",    totalRevenue);
        data.put("platformIncome",  platformIncome);
        data.put("todayRevenue",    todayRevenue);
        data.put("weekRevenue",     weekRevenue);
        data.put("monthRevenue",    monthRevenue);
        data.put("yestRevenue",     yestRevenue);
        data.put("lastWeekRevenue", lastWeekRev);
        data.put("lastMonthRevenue",lastMonthRev);
        data.put("avgOrderValue",   avgOrderValue);
        // 分布 & 排行
        data.put("statusDistribution", statusDist);
        data.put("merchantRank",    merchantRank);
        data.put("techRank",        techRank);
        data.put("trend",           trend);
        data.put("memberTrend",     memberTrend);

        return Result.success(data);
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private long orderCount(LocalDateTime from, LocalDateTime to, Long merchantId) {
        return orderMapper.selectCount(
                Wrappers.<CbOrder>lambdaQuery()
                        .eq(CbOrder::getDeleted, 0)
                        .ge(from         != null, CbOrder::getCreateTime, from)
                        .lt(to           != null, CbOrder::getCreateTime, to)
                        .eq(merchantId   != null, CbOrder::getMerchantId, merchantId));
    }

    private BigDecimal sumAll(List<CbOrder> orders, Function<CbOrder, BigDecimal> getter) {
        return orders.stream().map(getter).filter(Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private BigDecimal sumSince(List<CbOrder> orders, LocalDateTime since) {
        return orders.stream()
                .filter(o -> o.getCreateTime() != null && !o.getCreateTime().isBefore(since))
                .map(CbOrder::getPayAmount).filter(Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private BigDecimal sumRange(List<CbOrder> orders, LocalDateTime from, LocalDateTime to) {
        return orders.stream()
                .filter(o -> o.getCreateTime() != null
                        && !o.getCreateTime().isBefore(from)
                        && o.getCreateTime().isBefore(to))
                .map(CbOrder::getPayAmount).filter(Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    /** 商户营收排行 Top 10 */
    private List<Map<String, Object>> buildMerchantRank(List<CbOrder> completedOrders) {
        // 按商户聚合营收和订单数
        Map<Long, BigDecimal> revenueByMerchant = new HashMap<>();
        Map<Long, Long>       ordersByMerchant  = new HashMap<>();
        for (CbOrder o : completedOrders) {
            if (o.getMerchantId() == null || o.getPayAmount() == null) continue;
            revenueByMerchant.merge(o.getMerchantId(), o.getPayAmount(), BigDecimal::add);
            ordersByMerchant.merge(o.getMerchantId(), 1L, Long::sum);
        }

        List<Long> topIds = revenueByMerchant.entrySet().stream()
                .sorted((a, b) -> b.getValue().compareTo(a.getValue()))
                .limit(10).map(Map.Entry::getKey).collect(Collectors.toList());

        if (topIds.isEmpty()) return Collections.emptyList();

        List<CbMerchant> merchants = merchantMapper.selectBatchIds(topIds);
        Map<Long, CbMerchant> merchantMap = merchants.stream()
                .collect(Collectors.toMap(CbMerchant::getId, m -> m));

        return topIds.stream().map(id -> {
            CbMerchant m = merchantMap.get(id);
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id",         id);
            item.put("name",       m != null ? m.getMerchantNameZh() : "商户#" + id);
            item.put("logo",       m != null ? m.getLogo() : null);
            item.put("revenue",    revenueByMerchant.getOrDefault(id, BigDecimal.ZERO));
            item.put("orderCount", ordersByMerchant.getOrDefault(id, 0L));
            return item;
        }).collect(Collectors.toList());
    }

    /** 技师绩效排行 Top 8（全平台） */
    private List<Map<String, Object>> buildTechRank(List<CbOrder> completedOrders) {
        Map<Long, Long>       orderCount  = new HashMap<>();
        Map<Long, BigDecimal> revenue     = new HashMap<>();
        for (CbOrder o : completedOrders) {
            if (o.getTechnicianId() == null) continue;
            orderCount.merge(o.getTechnicianId(), 1L, Long::sum);
            if (o.getPayAmount() != null)
                revenue.merge(o.getTechnicianId(), o.getPayAmount(), BigDecimal::add);
        }

        List<Long> topIds = orderCount.entrySet().stream()
                .sorted((a, b) -> Long.compare(b.getValue(), a.getValue()))
                .limit(8).map(Map.Entry::getKey).collect(Collectors.toList());

        if (topIds.isEmpty()) return Collections.emptyList();

        List<CbTechnician> techs = technicianMapper.selectBatchIds(topIds);
        Map<Long, CbTechnician> techMap = techs.stream()
                .collect(Collectors.toMap(CbTechnician::getId, t -> t));

        return topIds.stream().map(id -> {
            CbTechnician t = techMap.get(id);
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id",         id);
            item.put("name",       t != null ? (t.getNickname() != null ? t.getNickname() : t.getRealName()) : "技师#" + id);
            item.put("avatar",     t != null ? t.getAvatar() : null);
            item.put("orderCount", orderCount.getOrDefault(id, 0L));
            item.put("revenue",    revenue.getOrDefault(id, BigDecimal.ZERO));
            return item;
        }).collect(Collectors.toList());
    }

    /** 营收趋势（支持 day/week/month/year） */
    private List<Map<String, Object>> buildTrend(String period, List<CbOrder> completedOrders) {
        List<Map<String, Object>> result = new ArrayList<>();
        DateTimeFormatter fmtDay   = DateTimeFormatter.ofPattern("MM-dd");
        DateTimeFormatter fmtMonth = DateTimeFormatter.ofPattern("yyyy-MM");
        DateTimeFormatter fmtHour  = DateTimeFormatter.ofPattern("HH:mm");

        switch (period) {
            case "day" -> {
                for (int h = 23; h >= 0; h--) {
                    LocalDateTime s = LocalDateTime.now().minusHours(h).withMinute(0).withSecond(0).withNano(0);
                    LocalDateTime e = s.plusHours(1);
                    result.add(trendPoint(s.format(fmtHour), s, e, completedOrders));
                }
            }
            case "week" -> {
                for (int d = 6; d >= 0; d--) {
                    LocalDate day = LocalDate.now().minusDays(d);
                    result.add(trendPoint(day.format(fmtDay), day.atStartOfDay(), day.plusDays(1).atStartOfDay(), completedOrders));
                }
            }
            case "month" -> {
                for (int d = 29; d >= 0; d--) {
                    LocalDate day = LocalDate.now().minusDays(d);
                    result.add(trendPoint(day.format(fmtDay), day.atStartOfDay(), day.plusDays(1).atStartOfDay(), completedOrders));
                }
            }
            case "year" -> {
                for (int m = 11; m >= 0; m--) {
                    LocalDate first = LocalDate.now().minusMonths(m).withDayOfMonth(1);
                    result.add(trendPoint(first.format(fmtMonth), first.atStartOfDay(), first.plusMonths(1).atStartOfDay(), completedOrders));
                }
            }
            default -> buildTrend("week", completedOrders);
        }
        return result;
    }

    private Map<String, Object> trendPoint(String label, LocalDateTime from, LocalDateTime to,
                                            List<CbOrder> orders) {
        BigDecimal rev = sumRange(orders, from, to);
        long cnt = orders.stream()
                .filter(o -> o.getCreateTime() != null
                        && !o.getCreateTime().isBefore(from)
                        && o.getCreateTime().isBefore(to))
                .count();
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("label",   label);
        item.put("revenue", rev);
        item.put("orders",  cnt);
        return item;
    }

    /** 新会员趋势 */
    private List<Map<String, Object>> buildMemberTrend(String period) {
        List<Map<String, Object>> result = new ArrayList<>();
        DateTimeFormatter fmtDay   = DateTimeFormatter.ofPattern("MM-dd");
        DateTimeFormatter fmtMonth = DateTimeFormatter.ofPattern("yyyy-MM");
        int points = "year".equals(period) ? 12 : ("day".equals(period) ? 24 : ("month".equals(period) ? 30 : 7));

        for (int i = points - 1; i >= 0; i--) {
            LocalDateTime from, to;
            String label;
            if ("year".equals(period)) {
                LocalDate first = LocalDate.now().minusMonths(i).withDayOfMonth(1);
                from  = first.atStartOfDay();
                to    = first.plusMonths(1).atStartOfDay();
                label = first.format(fmtMonth);
            } else if ("day".equals(period)) {
                from  = LocalDateTime.now().minusHours(i).withMinute(0).withSecond(0).withNano(0);
                to    = from.plusHours(1);
                label = from.format(DateTimeFormatter.ofPattern("HH:mm"));
            } else {
                LocalDate day = LocalDate.now().minusDays(i);
                from  = day.atStartOfDay();
                to    = day.plusDays(1).atStartOfDay();
                label = day.format(fmtDay);
            }
            long cnt = memberMapper.selectCount(Wrappers.<CbMember>lambdaQuery()
                    .eq(CbMember::getDeleted, 0)
                    .ge(CbMember::getCreateTime, from)
                    .lt(CbMember::getCreateTime, to));
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("label",  label);
            item.put("newMembers", cnt);
            result.add(item);
        }
        return result;
    }

    // ── 日期工具 ──────────────────────────────────────────────────────────────
    private LocalDateTime todayStart()     { return LocalDate.now().atStartOfDay(); }
    private LocalDateTime tomorrowStart()  { return LocalDate.now().plusDays(1).atStartOfDay(); }
    private LocalDateTime yesterdayStart() { return LocalDate.now().minusDays(1).atStartOfDay(); }
    private LocalDateTime weekStart()      { return LocalDate.now().with(WeekFields.ISO.dayOfWeek(), 1).atStartOfDay(); }
    private LocalDateTime monthStart()     { return LocalDate.now().withDayOfMonth(1).atStartOfDay(); }
}
