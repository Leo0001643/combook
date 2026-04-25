package com.cambook.dao.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.cambook.dao.entity.CbWalkinSession;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

/**
 * 散客接待 Session Mapper
 *
 * @author CamBook
 */
@Mapper
public interface CbWalkinSessionMapper extends BaseMapper<CbWalkinSession> {

    /**
     * 查询指定技师今日的散客接待列表（用于技师首页"今日安排"）
     *
     * <p>只返回未取消/未结算的进行中 session（status IN (0,1,2)），
     * 按 check_in_time 升序排列。
     *
     * @param techId 技师 ID
     * @return Map 字段见 CbWalkinSessionMapper.xml
     */
    List<Map<String, Object>> selectTodayByTechId(@Param("techId") Long techId);

    /**
     * 查询指定技师最近散客接待列表（用于订单列表页，支持 status 过滤）
     *
     * <p>返回最近 90 天的 session，供技师订单管理页面展示。
     *
     * @param techId   技师 ID
     * @param statuses session 状态列表（null / empty = 不过滤）
     * @return Map 字段见 CbWalkinSessionMapper.xml
     */
    List<Map<String, Object>> selectRecentByTechId(
            @Param("techId") Long techId,
            @Param("statuses") List<Integer> statuses);
}
