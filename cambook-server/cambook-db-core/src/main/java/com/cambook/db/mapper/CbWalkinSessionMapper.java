package com.cambook.db.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.cambook.db.entity.CbWalkinSession;
import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

/**
 * 散客接待 Session Mapper
 *
 * <p>自定义查询见 {@code CbWalkinSessionMapper.xml}。
 *
 * @author CamBook
 */
public interface CbWalkinSessionMapper extends BaseMapper<CbWalkinSession> {

    /**
     * 技师首页今日安排（walkin 部分）
     *
     * @param techId 技师 ID
     * @return [{sessionId, orderNo, appointTime, status, payAmount, techIncome, memberNickname, memberAvatar}]
     */
    List<Map<String, Object>> selectTodayByTechId(@Param("techId") Long techId);

    /**
     * 技师最近 90 天 walkin 订单列表（含状态映射）
     *
     * @param techId   技师 ID
     * @param statuses 过滤的映射状态码列表（null 不过滤）
     */
    List<Map<String, Object>> selectRecentByTechId(@Param("techId") Long techId,
                                                    @Param("statuses") List<Integer> statuses);
}
