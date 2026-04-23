package com.cambook.dao.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.cambook.dao.entity.CbReview;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.math.BigDecimal;

/**
 * 订单评价 Mapper
 *
 * @author CamBook
 */
@Mapper
public interface CbReviewMapper extends BaseMapper<CbReview> {

    /** 今日平均综合评分（overall_score，1-5星），无评价时返回 null，SQL 见 CbReviewMapper.xml */
    BigDecimal avgTodayRating(@Param("techId") Long techId);
}
