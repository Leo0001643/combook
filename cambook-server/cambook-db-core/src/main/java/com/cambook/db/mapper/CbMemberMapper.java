package com.cambook.db.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.cambook.db.entity.CbMember;
import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

/**
 * 会员 Mapper
 *
 * <p>基础 CRUD 继承 {@link BaseMapper}；管理员看板会员趋势聚合查询见 {@code CbMemberMapper.xml}。
 *
 * @author CamBook
 */
public interface CbMemberMapper extends BaseMapper<CbMember> {

    /** 新增会员趋势：按小时聚合（day 维度）[{hour, newMembers}]，hour="HH" */
    List<Map<String, Object>> memberTrendByHour(@Param("from") long from, @Param("to") long to);

    /** 新增会员趋势：按天聚合（week/month 维度）[{label, ymd, newMembers}] */
    List<Map<String, Object>> memberTrendByDay(@Param("from") long from, @Param("to") long to);

    /** 新增会员趋势：按月聚合（year 维度）[{month, newMembers}] */
    List<Map<String, Object>> memberTrendByMonth(@Param("from") long from, @Param("to") long to);
}
