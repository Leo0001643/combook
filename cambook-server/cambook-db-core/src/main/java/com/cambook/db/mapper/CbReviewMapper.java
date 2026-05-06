package com.cambook.db.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.cambook.db.entity.CbReview;
import org.apache.ibatis.annotations.Param;

import java.math.BigDecimal;

/**
 * 订单评价 Mapper
 *
 * <p>自定义聚合查询见 {@code CbReviewMapper.xml}。
 *
 * @author CamBook
 */
public interface CbReviewMapper extends BaseMapper<CbReview> {

    /**
     * 今日技师平均综合评分（overall_score，1-5 星；无评价时返回 null）
     *
     * @param techId 技师 ID
     */
    BigDecimal avgTodayRating(@Param("techId") Long techId);
}
