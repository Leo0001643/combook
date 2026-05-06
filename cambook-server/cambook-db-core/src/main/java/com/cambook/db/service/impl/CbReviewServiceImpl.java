package com.cambook.db.service.impl;

import com.cambook.db.entity.CbReview;
import com.cambook.db.mapper.CbReviewMapper;
import com.cambook.db.service.ICbReviewService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 订单评价表：多维度评分+文字评价，每单一次，支持技师回复 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class CbReviewServiceImpl extends ServiceImpl<CbReviewMapper, CbReview> implements ICbReviewService {

}
