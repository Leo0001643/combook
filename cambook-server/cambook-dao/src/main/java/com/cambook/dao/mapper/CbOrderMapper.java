package com.cambook.dao.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.cambook.dao.entity.CbOrder;
import org.apache.ibatis.annotations.Mapper;
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
@Mapper
public interface CbOrderMapper extends BaseMapper<CbOrder> {

    // ── 技师首页统计（SQL 见 CbOrderMapper.xml） ──────────────────────────────

    /** 今日有效订单数（预约时间在今天，排除待支付/取消/已退款） */
    int countTodayOrders(@Param("techId") Long techId);

    /** 今日已完成订单数（status=6） */
    int countTodayCompleted(@Param("techId") Long techId);

    /** 今日全部预约订单数（排除待支付 0，含进行中/取消/退款） */
    int countTodayAppointments(@Param("techId") Long techId);

    /** 今日取消/退款订单数（status IN (7,8,9)） */
    int countTodayCancelled(@Param("techId") Long techId);

    /** 今日已完成订单的技师实际收入总和 */
    BigDecimal sumTodayIncome(@Param("techId") Long techId);

    /** 今日安排列表（按预约时间升序，关联会员昵称与头像） */
    List<Map<String, Object>> selectTodaySchedule(@Param("techId") Long techId);

    /**
     * 批量查询门店散客订单的服务项（order_type=2，按 session_id + create_time 升序）
     *
     * <p>walkin 场景中，每条 cb_order（order_type=2）就是一个服务项，
     * 此接口供技师首页"今日安排"批量加载 walkin 服务项，避免 N+1 查询。
     *
     * @param sessionIds 需要加载服务项的 session ID 列表
     * @return CbOrder 列表（仅含 order_type=2 的服务项订单）
     */
    List<com.cambook.dao.entity.CbOrder> selectWalkinOrdersBySessionIds(
            @Param("sessionIds") List<Long> sessionIds);

    // ── 管理员看板聚合（SQL 见 CbOrderMapper.xml） ───────────────────────────

    /**
     * 统计已完成订单的 pay_amount 总和（from/to 可选）
     *
     * @param from 起始时间（UTC 秒，null 不限）
     * @param to   结束时间（UTC 秒，null 不限）
     */
    BigDecimal sumRevenue(@Param("from") Long from, @Param("to") Long to);

    /**
     * 统计已完成订单的 platform_income 总和（from/to 可选）
     */
    BigDecimal sumPlatformIncome(@Param("from") Long from, @Param("to") Long to);

    /**
     * 统计订单总数（from/to/merchantId 均可选）
     */
    long countOrders(@Param("from") Long from, @Param("to") Long to, @Param("merchantId") Long merchantId);

    /**
     * 订单状态分布：返回 [{status, cnt}]
     */
    List<Map<String, Object>> statusDistribution();

    /**
     * 商户营收排行 Top N：返回 [{merchantId, revenue, orderCount}]
     */
    List<Map<String, Object>> merchantRevenueRank(@Param("limit") int limit);

    /**
     * 技师绩效排行 Top N：返回 [{technicianId, orderCount, revenue}]
     */
    List<Map<String, Object>> techOrderRank(@Param("limit") int limit);

    /**
     * 技师端订单列表（按 status 过滤，可选）。
     * <p>返回该技师被分配的在线预约订单，按 create_time 倒序。
     * @param techId   技师 ID
     * @param statuses 状态白名单（null 则不过滤）
     */
    List<Map<String, Object>> listTechOrders(@Param("techId") Long techId,
                                              @Param("statuses") List<Integer> statuses);

    /**
     * 技师待执行预约订单数（已支付且尚未完成/取消的订单）。
     * <p>用于底部导航 FAB 角标展示，帮助技师直观感知待处理工作量。
     * 状态范围：1=已支付 2=接单 3=前往 4=到达（服务未开始）
     */
    int pendingOrderCount(@Param("techId") Long techId);

    /**
     * 按小时聚合营收趋势（适用于 day 维度）
     * 返回 [{hour, revenue, orders}]，hour 格式 "HH"（00-23）
     */
    List<Map<String, Object>> revenueTrendByHour(@Param("from") long from, @Param("to") long to);

    /**
     * 按天聚合营收趋势（适用于 week/month 维度）
     * 返回 [{label, ymd, revenue, orders}]，label 格式 "MM-dd"，ymd 格式 "yyyy-MM-dd"
     */
    List<Map<String, Object>> revenueTrendByDay(@Param("from") long from, @Param("to") long to);

    /**
     * 按月聚合营收趋势（适用于 year 维度）
     * 返回 [{month, revenue, orders}]，month 格式 "yyyy-MM"
     */
    List<Map<String, Object>> revenueTrendByMonth(@Param("from") long from, @Param("to") long to);
}
