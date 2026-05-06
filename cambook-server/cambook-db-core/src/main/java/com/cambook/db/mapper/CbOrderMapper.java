package com.cambook.db.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.cambook.db.entity.CbOrder;
import org.apache.ibatis.annotations.Param;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * 订单 Mapper
 *
 * <p>基础 CRUD 继承 {@link BaseMapper}；自定义聚合与趋势查询见 {@code CbOrderMapper.xml}。
 *
 * @author CamBook
 */
public interface CbOrderMapper extends BaseMapper<CbOrder> {

    // ── 技师首页统计 ─────────────────────────────────────────────────────────

    /** 今日有效订单数（排除 0=待支付 7=取消中 8=已取消 9=已退款） */
    int countTodayOrders(@Param("techId") Long techId);

    /** 今日已完成订单数（status=6 + walkin session status IN 2,3） */
    int countTodayCompleted(@Param("techId") Long techId);

    /** 今日全部预约订单数（排除 0=待支付，包含进行中/取消/退款） */
    int countTodayAppointments(@Param("techId") Long techId);

    /** 今日取消/退款订单数（status IN 7,8,9 + walkin session status=4） */
    int countTodayCancelled(@Param("techId") Long techId);

    /** 今日已完成订单的技师实际收入总和 */
    BigDecimal sumTodayIncome(@Param("techId") Long techId);

    /** 今日安排列表（按预约时间升序，关联会员昵称与头像） */
    List<Map<String, Object>> selectTodaySchedule(@Param("techId") Long techId);

    /**
     * 批量查询门店散客订单的服务项（order_type=2，按 session_id + create_time 升序）
     */
    List<CbOrder> selectWalkinOrdersBySessionIds(@Param("sessionIds") List<Long> sessionIds);

    // ── 管理员看板聚合 ────────────────────────────────────────────────────────

    /** 已完成订单 pay_amount 总和（status IN 5,6；from/to 可选）*/
    BigDecimal sumRevenue(@Param("from") Long from, @Param("to") Long to);

    /** 已完成订单 platform_income 总和（from/to 可选）*/
    BigDecimal sumPlatformIncome(@Param("from") Long from, @Param("to") Long to);

    /** 订单总数（from/to/merchantId 均可选）*/
    long countOrders(@Param("from") Long from, @Param("to") Long to, @Param("merchantId") Long merchantId);

    /** 订单状态分布：返回 [{status, cnt}] */
    List<Map<String, Object>> statusDistribution();

    /** 商户营收排行 Top N：返回 [{merchantId, revenue, orderCount}] */
    List<Map<String, Object>> merchantRevenueRank(@Param("limit") int limit);

    /** 技师绩效排行 Top N：返回 [{technicianId, orderCount, revenue}] */
    List<Map<String, Object>> techOrderRank(@Param("limit") int limit);

    /** 技师待接单数（status=1, order_type=1） */
    int pendingOrderCount(@Param("techId") Long techId);

    // ── 趋势聚合 ──────────────────────────────────────────────────────────────

    /** 营收趋势：按小时聚合（day 维度）[{hour, revenue, orders}]，hour="HH" */
    List<Map<String, Object>> revenueTrendByHour(@Param("from") long from, @Param("to") long to);

    /** 营收趋势：按天聚合（week/month 维度）[{label, ymd, revenue, orders}] */
    List<Map<String, Object>> revenueTrendByDay(@Param("from") long from, @Param("to") long to);

    /** 营收趋势：按月聚合（year 维度）[{month, revenue, orders}] */
    List<Map<String, Object>> revenueTrendByMonth(@Param("from") long from, @Param("to") long to);

    /** 技师端订单列表（含会员昵称，statuses 为 null 则不过滤状态） */
    List<Map<String, Object>> listTechOrders(@Param("techId") Long techId,
                                              @Param("statuses") List<Integer> statuses);
}
