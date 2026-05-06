package com.cambook.app.service.merchant.impl;

import com.cambook.app.common.statemachine.OrderStatus;
import com.cambook.app.common.statemachine.TechnicianOnlineStatus;
import com.cambook.app.domain.vo.DashboardStatsVO;
import com.cambook.app.domain.vo.TechRankItemVO;
import com.cambook.app.domain.vo.TrendPointVO;
import com.cambook.app.service.merchant.IMerchantDashboardService;
import com.cambook.common.enums.CommonStatus;
import com.cambook.common.utils.DateUtils;
import com.cambook.db.entity.CbMerchant;
import com.cambook.db.entity.CbOrder;
import com.cambook.db.entity.CbTechnician;
import com.cambook.db.service.ICbMerchantService;
import com.cambook.db.service.ICbOrderService;
import com.cambook.db.service.ICbTechnicianService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.*;
import java.time.format.DateTimeFormatter;
import java.time.temporal.WeekFields;
import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * 商户端数据看板服务实现
 *
 * @author CamBook
 */
@Service
@RequiredArgsConstructor
public class MerchantDashboardServiceImpl implements IMerchantDashboardService {

    /** 已完成订单状态：服务中(IN_SERVICE) + 已完成(COMPLETED) */
    private static final List<Integer> STATUS_COMPLETED = List.of(
            OrderStatus.IN_SERVICE.getCode(), OrderStatus.COMPLETED.getCode()
    );

    private final ICbMerchantService   cbMerchantService;
    private final ICbOrderService      cbOrderService;
    private final ICbTechnicianService cbTechnicianService;

    @Override
    public DashboardStatsVO getStats(Long merchantId, String period) {
        long todayStart = DateUtils.todayStart(), tomorrowStart = DateUtils.tomorrowStart();
        long weekStart  = DateUtils.weekStart();
        long monthStart = DateUtils.monthStart();
        long yestStart  = DateUtils.yesterdayStart();
        long prevWkStart = DateUtils.prevWeekStart();
        long prevMoStart = DateUtils.prevMonthStart();

        // ── 订单计数 ──
        long totalOrders     = count(merchantId, null, null);
        long todayOrders     = count(merchantId, todayStart, tomorrowStart);
        long weekOrders      = count(merchantId, weekStart, tomorrowStart);
        long monthOrders     = count(merchantId, monthStart, tomorrowStart);
        long yestOrders      = count(merchantId, yestStart, todayStart);
        long lastWeekOrders  = count(merchantId, prevWkStart, weekStart);
        long lastMonthOrders = count(merchantId, prevMoStart, monthStart);

        // ── 营收（一次 DB 查询，内存聚合）──
        List<CbOrder> completed = cbOrderService.lambdaQuery()
                .eq(CbOrder::getMerchantId, merchantId).in(CbOrder::getStatus, STATUS_COMPLETED)
                .select(CbOrder::getPayAmount, CbOrder::getPlatformIncome,
                        CbOrder::getTechIncome, CbOrder::getCreateTime).list();

        BigDecimal totalRevenue    = sum(completed, CbOrder::getPayAmount);
        BigDecimal platformFee     = sum(completed, CbOrder::getPlatformIncome);
        BigDecimal merchantRevenue = totalRevenue.subtract(platformFee);
        BigDecimal todayRevenue    = sumRange(completed, todayStart, tomorrowStart, CbOrder::getPayAmount);
        BigDecimal weekRevenue     = sumRange(completed, weekStart, tomorrowStart, CbOrder::getPayAmount);
        BigDecimal monthRevenue    = sumRange(completed, monthStart, tomorrowStart, CbOrder::getPayAmount);
        BigDecimal yestRevenue     = sumRange(completed, yestStart, todayStart, CbOrder::getPayAmount);
        BigDecimal lastWkRevenue   = sumRange(completed, prevWkStart, weekStart, CbOrder::getPayAmount);
        BigDecimal lastMoRevenue   = sumRange(completed, prevMoStart, monthStart, CbOrder::getPayAmount);
        BigDecimal avgOrderValue   = totalOrders > 0 && totalRevenue.compareTo(BigDecimal.ZERO) > 0
                ? totalRevenue.divide(BigDecimal.valueOf(totalOrders), 2, RoundingMode.HALF_UP) : BigDecimal.ZERO;

        // ── 技师状态 ──
        long techCount   = cbTechnicianService.lambdaQuery().eq(CbTechnician::getMerchantId, merchantId).count();
        long activeTech  = cbTechnicianService.lambdaQuery().eq(CbTechnician::getMerchantId, merchantId).eq(CbTechnician::getStatus, CommonStatus.ENABLED.getCode()).count();
        long onlineTech  = cbTechnicianService.lambdaQuery().eq(CbTechnician::getMerchantId, merchantId).eq(CbTechnician::getOnlineStatus, TechnicianOnlineStatus.ONLINE.getCode()).count();
        long servingTech = cbTechnicianService.lambdaQuery().eq(CbTechnician::getMerchantId, merchantId).eq(CbTechnician::getOnlineStatus, TechnicianOnlineStatus.SERVING.getCode()).count();

        // ── 状态分布 ──
        Map<Integer, Long> statusDist = cbOrderService.lambdaQuery()
                .eq(CbOrder::getMerchantId, merchantId).eq(CbOrder::getDeleted, 0)
                .select(CbOrder::getStatus).list().stream()
                .collect(Collectors.groupingBy(
                        o -> o.getStatus() == null ? 0 : o.getStatus().intValue(), Collectors.counting()));

        CbMerchant merchant = cbMerchantService.getById(merchantId);

        DashboardStatsVO vo = new DashboardStatsVO();
        vo.setTotalOrders(totalOrders);    vo.setTodayOrders(todayOrders);
        vo.setWeekOrders(weekOrders);      vo.setMonthOrders(monthOrders);
        vo.setYestOrders(yestOrders);      vo.setLastWeekOrders(lastWeekOrders);
        vo.setLastMonthOrders(lastMonthOrders);
        vo.setTotalRevenue(totalRevenue);  vo.setMerchantRevenue(merchantRevenue);
        vo.setTodayRevenue(todayRevenue);  vo.setWeekRevenue(weekRevenue);
        vo.setMonthRevenue(monthRevenue);  vo.setYestRevenue(yestRevenue);
        vo.setLastWeekRevenue(lastWkRevenue); vo.setLastMonthRevenue(lastMoRevenue);
        vo.setAvgOrderValue(avgOrderValue);
        vo.setTechnicianCount(techCount);  vo.setActiveTechCount(activeTech);
        vo.setOnlineTechCount(onlineTech); vo.setServingTechCount(servingTech);
        vo.setStatusDistribution(statusDist);
        vo.setBalance(merchant != null ? merchant.getBalance() : BigDecimal.ZERO);
        vo.setCommissionRate(merchant != null ? merchant.getCommissionRate() : BigDecimal.ZERO);
        vo.setMerchantName(merchant != null ? merchant.getMerchantNameZh() : "");
        vo.setTrend(buildTrend(merchantId, period, completed));
        vo.setTechRank(buildTechRank(merchantId));
        return vo;
    }

    @Override
    public CbMerchant getProfile(Long merchantId) {
        CbMerchant m = cbMerchantService.getById(merchantId);
        if (m != null) m.setPassword(null);
        return m;
    }

    // ── 趋势计算 ──────────────────────────────────────────────────────────────

    private List<TrendPointVO> buildTrend(Long merchantId, String period, List<CbOrder> completed) {
        DateTimeFormatter fmtDay   = DateTimeFormatter.ofPattern("MM-dd");
        DateTimeFormatter fmtHour  = DateTimeFormatter.ofPattern("HH:mm");
        DateTimeFormatter fmtMonth = DateTimeFormatter.ofPattern("yyyy-MM");
        return switch (period) {
            case "day" -> buildPoints(24, i -> {
                ZonedDateTime zs = ZonedDateTime.now(java.time.ZoneId.systemDefault()).minusHours(i).truncatedTo(java.time.temporal.ChronoUnit.HOURS);
                return point(zs.format(fmtHour), zs.toEpochSecond(), zs.toEpochSecond() + 3600, merchantId, completed);
            });
            case "month" -> buildPoints(30, i -> {
                LocalDate d = LocalDate.now().minusDays(29 - i);
                return point(d.format(fmtDay), DateUtils.dayStart(d), DateUtils.dayStart(d.plusDays(1)), merchantId, completed);
            });
            case "year" -> buildPoints(12, i -> {
                LocalDate first = LocalDate.now().minusMonths(11 - i).withDayOfMonth(1);
                return point(first.format(fmtMonth), DateUtils.dayStart(first), DateUtils.dayStart(first.plusMonths(1).withDayOfMonth(1)), merchantId, completed);
            });
            default /* week */ -> buildPoints(7, i -> {
                LocalDate d = LocalDate.now().minusDays(6 - i);
                return point(d.format(fmtDay), DateUtils.dayStart(d), DateUtils.dayStart(d.plusDays(1)), merchantId, completed);
            });
        };
    }

    private List<TrendPointVO> buildPoints(int n, Function<Integer, TrendPointVO> fn) {
        List<TrendPointVO> result = new ArrayList<>(n);
        for (int i = 0; i < n; i++) result.add(fn.apply(i));
        return result;
    }

    private TrendPointVO point(String label, long s, long e, Long merchantId, List<CbOrder> completed) {
        TrendPointVO p = new TrendPointVO();
        p.setLabel(label);
        p.setOrders(count(merchantId, s, e));
        p.setRevenue(sumRange(completed, s, e, CbOrder::getPayAmount));
        return p;
    }

    // ── 技师排行 ──────────────────────────────────────────────────────────────

    private List<TechRankItemVO> buildTechRank(Long merchantId) {
        List<CbOrder> techOrders = cbOrderService.lambdaQuery()
                .eq(CbOrder::getMerchantId, merchantId).in(CbOrder::getStatus, STATUS_COMPLETED)
                .select(CbOrder::getTechnicianId, CbOrder::getPayAmount).list();

        Map<Long, long[]>       countMap   = new LinkedHashMap<>();
        Map<Long, BigDecimal[]> revenueMap = new LinkedHashMap<>();
        for (CbOrder o : techOrders) {
            if (o.getTechnicianId() == null) continue;
            countMap.computeIfAbsent(o.getTechnicianId(), k -> new long[]{0})[0]++;
            BigDecimal[] arr = revenueMap.computeIfAbsent(o.getTechnicianId(), k -> new BigDecimal[]{BigDecimal.ZERO});
            if (o.getPayAmount() != null) arr[0] = arr[0].add(o.getPayAmount());
        }

        List<Long> topIds = countMap.entrySet().stream()
                .sorted((a, b) -> Long.compare(b.getValue()[0], a.getValue()[0]))
                .limit(8).map(Map.Entry::getKey).collect(Collectors.toList());
        if (topIds.isEmpty()) return Collections.emptyList();

        Map<Long, CbTechnician> techMap = cbTechnicianService.listByIds(topIds).stream()
                .collect(Collectors.toMap(CbTechnician::getId, t -> t));

        return topIds.stream().map(id -> {
            CbTechnician t = techMap.get(id);
            TechRankItemVO vo = new TechRankItemVO();
            vo.setId(id);
            vo.setName(t != null ? (t.getNickname() != null ? t.getNickname() : t.getRealName()) : "技师#" + id);
            vo.setAvatar(t != null ? t.getAvatar() : null);
            vo.setOrderCount(countMap.getOrDefault(id, new long[]{0})[0]);
            vo.setRevenue(revenueMap.getOrDefault(id, new BigDecimal[]{BigDecimal.ZERO})[0]);
            return vo;
        }).collect(Collectors.toList());
    }

    // ── 工具方法 ──────────────────────────────────────────────────────────────

    private long count(Long merchantId, Long start, Long end) {
        return cbOrderService.lambdaQuery()
                .eq(CbOrder::getMerchantId, merchantId).eq(CbOrder::getDeleted, 0)
                .ge(start != null, CbOrder::getCreateTime, start)
                .lt(end   != null, CbOrder::getCreateTime, end).count();
    }

    private BigDecimal sum(List<CbOrder> list, Function<CbOrder, BigDecimal> getter) {
        return list.stream().map(getter).filter(Objects::nonNull).reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private BigDecimal sumRange(List<CbOrder> list, long from, long to,
                                 Function<CbOrder, BigDecimal> getter) {
        return list.stream()
                .filter(o -> o.getCreateTime() != null && o.getCreateTime() >= from && o.getCreateTime() < to)
                .map(getter).filter(Objects::nonNull).reduce(BigDecimal.ZERO, BigDecimal::add);
    }

}
