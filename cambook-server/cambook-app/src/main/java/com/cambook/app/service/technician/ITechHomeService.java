package com.cambook.app.service.technician;

import com.cambook.app.domain.vo.HomeStatsVO;
import com.cambook.app.domain.vo.ScheduleItemVO;

import java.util.List;

/**
 * 技师首页数据服务
 *
 * <p>负责聚合今日统计与今日安排数据，供技师端首页展示。
 *
 * @author CamBook
 */
public interface ITechHomeService {

    /**
     * 获取当前技师今日统计数据（订单数、收入、评分）。
     *
     * <p>今日收入 = 今日已完成订单的 {@code tech_income} 之和，
     * 该字段已在订单完成时按佣金规则计算，无需二次扣减。
     *
     * @return 今日统计 VO，不为 null
     */
    HomeStatsVO getStats();

    /**
     * 获取当前技师今日安排列表（按预约时间升序）。
     *
     * <p>仅返回预约时间在今天的有效订单，排除待支付/已取消/已退款状态。
     * 每条安排项携带完整的服务项明细（一单多项）。
     *
     * @return 今日安排列表，无订单时返回空列表
     */
    List<ScheduleItemVO> getTodaySchedule();

    /**
     * 获取当前技师待执行的预约订单数（已接单但未完成/取消）。
     *
     * <p>用于底部导航 FAB 角标展示，状态范围：1=已支付 2=接单 3=前往 4=到达。
     *
     * @return 待执行订单数，用于角标展示
     */
    int getPendingOrderCount();
}
