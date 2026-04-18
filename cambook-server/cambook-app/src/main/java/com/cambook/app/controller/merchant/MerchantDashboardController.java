package com.cambook.app.controller.merchant;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.cambook.common.context.MerchantContext;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.Result;
import com.cambook.dao.entity.CbMerchant;
import com.cambook.dao.entity.CbOrder;
import com.cambook.dao.entity.CbTechnician;
import com.cambook.dao.mapper.CbMerchantMapper;
import com.cambook.dao.mapper.CbOrderMapper;
import com.cambook.dao.mapper.CbTechnicianMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.*;
import java.time.format.DateTimeFormatter;
import java.time.temporal.WeekFields;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 商户端 - 数据看板（增强版）
 *
 * <p>提供日/周/月/年多维度趋势，KPI 汇总，技师排行，订单分布等数据。
 *
 * @author CamBook
 */
@Tag(name = "商户端 - 数据看板")
@RestController
@RequestMapping("/merchant/dashboard")
public class MerchantDashboardController {

    private final CbMerchantMapper   merchantMapper;
    private final CbOrderMapper      orderMapper;
    private final CbTechnicianMapper technicianMapper;

    public MerchantDashboardController(CbMerchantMapper merchantMapper,
                                       CbOrderMapper orderMapper,
                                       CbTechnicianMapper technicianMapper) {
        this.merchantMapper   = merchantMapper;
        this.orderMapper      = orderMapper;
        this.technicianMapper = technicianMapper;
    }

    // ── 综合看板数据（所有 KPI + 趋势）────────────────────────────────────────

    @Operation(summary = "综合看板数据")
    @GetMapping("/stats")
    public Result<Map<String, Object>> stats(@RequestParam(defaultValue = "week") String period) {
        Long merchantId = requireMerchantId();

        // ── 基础计数 ──
        long totalOrders  = count(merchantId, null, null);
        long todayOrders  = count(merchantId, todayStart(), tomorrowStart());
        long weekOrders   = count(merchantId, weekStart(), tomorrowStart());
        long monthOrders  = count(merchantId, monthStart(), tomorrowStart());

        // ── 历史比较（环比）──
        long yestOrders   = count(merchantId, yesterdayStart(), todayStart());
        long lastWeekOrders  = count(merchantId, weekStart().minusWeeks(1), weekStart());
        long lastMonthOrders = count(merchantId, monthStart().minusMonths(1), monthStart());

        // ── 营收汇总 ──
        List<CbOrder> allCompleted = orderMapper.selectList(
                Wrappers.<CbOrder>lambdaQuery()
                        .eq(CbOrder::getMerchantId, merchantId)
                        .in(CbOrder::getStatus, 5, 6)   // 待评价=5 / 已完成=6
                        .select(CbOrder::getPayAmount, CbOrder::getPlatformIncome,
                                CbOrder::getTechIncome, CbOrder::getCreateTime));

        BigDecimal totalRevenue  = sum(allCompleted, CbOrder::getPayAmount);
        BigDecimal platformFee   = sum(allCompleted, CbOrder::getPlatformIncome);
        BigDecimal merchantRevenue = totalRevenue.subtract(platformFee);

        BigDecimal todayRevenue  = sumFilter(allCompleted, todayStart(),  o -> o.getPayAmount());
        BigDecimal weekRevenue   = sumFilter(allCompleted, weekStart(),   o -> o.getPayAmount());
        BigDecimal monthRevenue  = sumFilter(allCompleted, monthStart(),  o -> o.getPayAmount());
        BigDecimal yestRevenue   = sumFilterRange(allCompleted, yesterdayStart(), todayStart(),  o -> o.getPayAmount());
        BigDecimal lastWeekRevenue  = sumFilterRange(allCompleted, weekStart().minusWeeks(1), weekStart(), o -> o.getPayAmount());
        BigDecimal lastMonthRevenue = sumFilterRange(allCompleted, monthStart().minusMonths(1), monthStart(), o -> o.getPayAmount());

        // ── 技师 ──
        long techCount  = technicianMapper.selectCount(
                Wrappers.<CbTechnician>lambdaQuery().eq(CbTechnician::getMerchantId, merchantId));
        long activeTech = technicianMapper.selectCount(
                Wrappers.<CbTechnician>lambdaQuery()
                        .eq(CbTechnician::getMerchantId, merchantId)
                        .eq(CbTechnician::getStatus, 1));
        long onlineTech = technicianMapper.selectCount(
                Wrappers.<CbTechnician>lambdaQuery()
                        .eq(CbTechnician::getMerchantId, merchantId)
                        .eq(CbTechnician::getOnlineStatus, 1));
        long servingTech = technicianMapper.selectCount(
                Wrappers.<CbTechnician>lambdaQuery()
                        .eq(CbTechnician::getMerchantId, merchantId)
                        .eq(CbTechnician::getOnlineStatus, 2));

        // ── 订单状态分布 ──
        List<CbOrder> statusOrders = orderMapper.selectList(
                Wrappers.<CbOrder>lambdaQuery()
                        .eq(CbOrder::getMerchantId, merchantId)
                        .eq(CbOrder::getDeleted, 0)
                        .select(CbOrder::getStatus));
        Map<Integer, Long> statusDist = statusOrders.stream()
                .collect(Collectors.groupingBy(o -> o.getStatus() == null ? 0 : o.getStatus().intValue(), Collectors.counting()));

        // ── 商户信息 ──
        CbMerchant merchant = merchantMapper.selectById(merchantId);

        // ── 趋势数据 ──
        List<Map<String, Object>> trend = buildTrend(merchantId, period, allCompleted);

        // ── 技师排行（按完成订单数 Top 8）──
        List<Map<String, Object>> techRank = buildTechRank(merchantId);

        // ── 平均客单价 ──
        BigDecimal avgOrderValue = totalRevenue.compareTo(BigDecimal.ZERO) > 0 && totalOrders > 0
                ? totalRevenue.divide(BigDecimal.valueOf(totalOrders), 2, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        Map<String, Object> data = new LinkedHashMap<>();
        // KPI
        data.put("totalOrders",      totalOrders);
        data.put("todayOrders",      todayOrders);
        data.put("weekOrders",       weekOrders);
        data.put("monthOrders",      monthOrders);
        data.put("yestOrders",       yestOrders);
        data.put("lastWeekOrders",   lastWeekOrders);
        data.put("lastMonthOrders",  lastMonthOrders);
        // Revenue
        data.put("totalRevenue",     totalRevenue);
        data.put("merchantRevenue",  merchantRevenue);
        data.put("todayRevenue",     todayRevenue);
        data.put("weekRevenue",      weekRevenue);
        data.put("monthRevenue",     monthRevenue);
        data.put("yestRevenue",      yestRevenue);
        data.put("lastWeekRevenue",  lastWeekRevenue);
        data.put("lastMonthRevenue", lastMonthRevenue);
        data.put("avgOrderValue",    avgOrderValue);
        // Technician
        data.put("technicianCount",  techCount);
        data.put("activeTechCount",  activeTech);
        data.put("onlineTechCount",  onlineTech);
        data.put("servingTechCount", servingTech);
        // Status distribution
        data.put("statusDistribution", statusDist);
        // Merchant
        data.put("balance",         merchant != null ? merchant.getBalance()        : BigDecimal.ZERO);
        data.put("commissionRate",  merchant != null ? merchant.getCommissionRate()  : BigDecimal.ZERO);
        data.put("merchantName",    merchant != null ? merchant.getMerchantNameZh()  : "");
        // Charts
        data.put("trend",     trend);
        data.put("techRank",  techRank);

        return Result.success(data);
    }

    @Operation(summary = "获取商户自身信息")
    @GetMapping("/profile")
    public Result<CbMerchant> profile() {
        Long merchantId = requireMerchantId();
        CbMerchant merchant = merchantMapper.selectById(merchantId);
        if (merchant != null) merchant.setPassword(null);
        return Result.success(merchant);
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private Long requireMerchantId() {
        Long id = MerchantContext.getMerchantId();
        if (id == null) throw new BusinessException("商户身份校验失败，请重新登录");
        return id;
    }

    private long count(Long merchantId, LocalDateTime start, LocalDateTime end) {
        return orderMapper.selectCount(
                Wrappers.<CbOrder>lambdaQuery()
                        .eq(CbOrder::getMerchantId, merchantId)
                        .eq(CbOrder::getDeleted, 0)
                        .ge(start != null, CbOrder::getCreateTime, start)
                        .lt(end   != null, CbOrder::getCreateTime, end));
    }

    private BigDecimal sum(List<CbOrder> list,
                           java.util.function.Function<CbOrder, BigDecimal> getter) {
        return list.stream().map(getter)
                .filter(v -> v != null)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private BigDecimal sumFilter(List<CbOrder> list, LocalDateTime since,
                                  java.util.function.Function<CbOrder, BigDecimal> getter) {
        return list.stream()
                .filter(o -> o.getCreateTime() != null && !o.getCreateTime().isBefore(since))
                .map(getter).filter(v -> v != null)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private BigDecimal sumFilterRange(List<CbOrder> list,
                                       LocalDateTime from, LocalDateTime to,
                                       java.util.function.Function<CbOrder, BigDecimal> getter) {
        return list.stream()
                .filter(o -> o.getCreateTime() != null
                        && !o.getCreateTime().isBefore(from)
                        && o.getCreateTime().isBefore(to))
                .map(getter).filter(v -> v != null)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private List<Map<String, Object>> buildTrend(Long merchantId, String period,
                                                   List<CbOrder> completedOrders) {
        List<Map<String, Object>> result = new ArrayList<>();
        DateTimeFormatter fmtDay  = DateTimeFormatter.ofPattern("MM-dd");
        DateTimeFormatter fmtMonth = DateTimeFormatter.ofPattern("yyyy-MM");

        switch (period) {
            case "day" -> {
                // 近 24 小时，每小时一个点
                for (int h = 23; h >= 0; h--) {
                    LocalDateTime s = LocalDateTime.now().minusHours(h).withMinute(0).withSecond(0);
                    LocalDateTime e = s.plusHours(1);
                    long cnt = count(merchantId, s, e);
                    BigDecimal rev = sumFilterRange(completedOrders, s, e, CbOrder::getPayAmount);
                    Map<String, Object> item = new LinkedHashMap<>();
                    item.put("label", s.format(DateTimeFormatter.ofPattern("HH:mm")));
                    item.put("orders", cnt);
                    item.put("revenue", rev);
                    result.add(item);
                }
            }
            case "week" -> {
                for (int d = 6; d >= 0; d--) {
                    LocalDate day = LocalDate.now().minusDays(d);
                    LocalDateTime s = day.atStartOfDay();
                    LocalDateTime e = day.plusDays(1).atStartOfDay();
                    long cnt = count(merchantId, s, e);
                    BigDecimal rev = sumFilterRange(completedOrders, s, e, CbOrder::getPayAmount);
                    Map<String, Object> item = new LinkedHashMap<>();
                    item.put("label", day.format(fmtDay));
                    item.put("orders", cnt);
                    item.put("revenue", rev);
                    result.add(item);
                }
            }
            case "month" -> {
                // 近 30 天
                for (int d = 29; d >= 0; d--) {
                    LocalDate day = LocalDate.now().minusDays(d);
                    LocalDateTime s = day.atStartOfDay();
                    LocalDateTime e = day.plusDays(1).atStartOfDay();
                    long cnt = count(merchantId, s, e);
                    BigDecimal rev = sumFilterRange(completedOrders, s, e, CbOrder::getPayAmount);
                    Map<String, Object> item = new LinkedHashMap<>();
                    item.put("label", day.format(fmtDay));
                    item.put("orders", cnt);
                    item.put("revenue", rev);
                    result.add(item);
                }
            }
            case "year" -> {
                // 近 12 个月
                for (int m = 11; m >= 0; m--) {
                    LocalDate firstDay = LocalDate.now().minusMonths(m).withDayOfMonth(1);
                    LocalDateTime s = firstDay.atStartOfDay();
                    LocalDateTime e = firstDay.plusMonths(1).atStartOfDay();
                    long cnt = count(merchantId, s, e);
                    BigDecimal rev = sumFilterRange(completedOrders, s, e, CbOrder::getPayAmount);
                    Map<String, Object> item = new LinkedHashMap<>();
                    item.put("label", firstDay.format(fmtMonth));
                    item.put("orders", cnt);
                    item.put("revenue", rev);
                    result.add(item);
                }
            }
            default -> buildTrend(merchantId, "week", completedOrders);
        }
        return result;
    }

    private List<Map<String, Object>> buildTechRank(Long merchantId) {
        List<CbOrder> techOrders = orderMapper.selectList(
                Wrappers.<CbOrder>lambdaQuery()
                        .eq(CbOrder::getMerchantId, merchantId)
                        .in(CbOrder::getStatus, 5, 6)
                        .select(CbOrder::getTechnicianId, CbOrder::getPayAmount, CbOrder::getTechIncome));

        Map<Long, long[]> rankMap = new LinkedHashMap<>();
        Map<Long, BigDecimal[]> revenueMap = new LinkedHashMap<>();
        for (CbOrder o : techOrders) {
            if (o.getTechnicianId() == null) continue;
            rankMap.computeIfAbsent(o.getTechnicianId(), k -> new long[]{0})[0]++;
            BigDecimal[] arr = revenueMap.computeIfAbsent(o.getTechnicianId(), k -> new BigDecimal[]{BigDecimal.ZERO});
            if (o.getPayAmount() != null) arr[0] = arr[0].add(o.getPayAmount());
        }

        // 按订单数降序，取 top 8
        List<Long> topIds = rankMap.entrySet().stream()
                .sorted((a, b) -> Long.compare(b.getValue()[0], a.getValue()[0]))
                .limit(8).map(Map.Entry::getKey).collect(Collectors.toList());

        if (topIds.isEmpty()) return Collections.emptyList();

        List<CbTechnician> techs = technicianMapper.selectBatchIds(topIds);
        Map<Long, CbTechnician> techMap = techs.stream().collect(Collectors.toMap(CbTechnician::getId, t -> t));

        return topIds.stream().map(id -> {
            CbTechnician t = techMap.get(id);
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id",         id);
            item.put("name",       t != null ? (t.getNickname() != null ? t.getNickname() : t.getRealName()) : "技师#" + id);
            item.put("avatar",     t != null ? t.getAvatar() : null);
            item.put("orderCount", rankMap.getOrDefault(id, new long[]{0})[0]);
            item.put("revenue",    revenueMap.getOrDefault(id, new BigDecimal[]{BigDecimal.ZERO})[0]);
            return item;
        }).collect(Collectors.toList());
    }

    // ── 日期工具 ──────────────────────────────────────────────────────────────

    private LocalDateTime todayStart()     { return LocalDate.now().atStartOfDay(); }
    private LocalDateTime tomorrowStart()  { return LocalDate.now().plusDays(1).atStartOfDay(); }
    private LocalDateTime yesterdayStart() { return LocalDate.now().minusDays(1).atStartOfDay(); }
    private LocalDateTime weekStart() {
        return LocalDate.now().with(WeekFields.ISO.dayOfWeek(), 1).atStartOfDay();
    }
    private LocalDateTime monthStart() {
        return LocalDate.now().withDayOfMonth(1).atStartOfDay();
    }
}
