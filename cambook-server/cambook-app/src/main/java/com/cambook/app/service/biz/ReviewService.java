package com.cambook.app.service.biz;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.PageResult;
import com.cambook.dao.entity.CbOrder;
import com.cambook.dao.entity.CbReview;
import com.cambook.dao.mapper.CbOrderMapper;
import com.cambook.dao.mapper.CbReviewMapper;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * 评价管理公共服务
 *
 * <p>Admin 和 Merchant 共用同一服务，区别仅在于：
 * <ul>
 *   <li>merchantId = null → Admin：查看平台全量评价</li>
 *   <li>merchantId = X    → Merchant：仅查看该商户订单下的评价</li>
 * </ul>
 *
 * @author CamBook
 */
@Service
public class ReviewService {

    private final CbReviewMapper reviewMapper;
    private final CbOrderMapper  orderMapper;

    public ReviewService(CbReviewMapper reviewMapper, CbOrderMapper orderMapper) {
        this.reviewMapper = reviewMapper;
        this.orderMapper  = orderMapper;
    }

    /** 分页列表 */
    public PageResult<CbReview> pageList(Long merchantId,
                                         int page, int size,
                                         Long technicianId, Integer overallScore, Integer status) {
        LambdaQueryWrapper<CbReview> w = new LambdaQueryWrapper<CbReview>()
                .eq(technicianId  != null, CbReview::getTechnicianId, technicianId)
                .eq(overallScore  != null, CbReview::getOverallScore, overallScore)
                .eq(status        != null, CbReview::getStatus,       status)
                .orderByDesc(CbReview::getCreateTime);

        // 商户范围隔离：通过订单关联商户
        if (merchantId != null) {
            Set<Long> orderIds = getOrderIdsByMerchant(merchantId);
            if (orderIds.isEmpty()) {
                return PageResult.of(Collections.emptyList(), 0L, page, size);
            }
            w.in(CbReview::getOrderId, orderIds);
        }

        Page<CbReview> p = reviewMapper.selectPage(new Page<>(page, size), w);
        return PageResult.of(p.getRecords(), p.getTotal(), page, size);
    }

    /** 评价统计（商户用） */
    public Map<String, Object> stats(Long merchantId) {
        LambdaQueryWrapper<CbReview> w = new LambdaQueryWrapper<>();
        if (merchantId != null) {
            Set<Long> orderIds = getOrderIdsByMerchant(merchantId);
            if (orderIds.isEmpty()) {
                return Map.of("total", 0, "avgScore", 0, "pendingReply", 0, "fiveStars", 0);
            }
            w.in(CbReview::getOrderId, orderIds);
        }

        List<CbReview> all = reviewMapper.selectList(w);
        double avg = all.stream().mapToInt(r -> r.getOverallScore() != null ? r.getOverallScore() : 0).average().orElse(0);
        long pending = all.stream().filter(r -> r.getReply() == null || r.getReply().isBlank()).count();

        return Map.of(
                "total",        all.size(),
                "avgScore",     Math.round(avg * 10) / 10.0,
                "pendingReply", pending,
                "fiveStars",    all.stream().filter(r -> r.getOverallScore() != null && r.getOverallScore() >= 5).count()
        );
    }

    /** 回复评价 */
    public void reply(Long merchantId, Long id, String reply) {
        CbReview review = reviewMapper.selectById(id);
        if (review == null) throw new BusinessException("评价不存在");

        if (merchantId != null) {
            Set<Long> orderIds = getOrderIdsByMerchant(merchantId);
            if (!orderIds.contains(review.getOrderId())) {
                throw new BusinessException("无权操作该评价");
            }
        }

        review.setReply(reply);
        review.setReplyTime(LocalDateTime.now());
        reviewMapper.updateById(review);
    }

    /** 修改状态（Admin Only）*/
    public void updateStatus(Long id, Integer status) {
        CbReview r = reviewMapper.selectById(id);
        if (r == null) throw new BusinessException("评价不存在");
        r.setStatus(status);
        reviewMapper.updateById(r);
    }

    /** 删除（Admin Only）*/
    public void delete(Long id) {
        reviewMapper.deleteById(id);
    }

    // ── private ──────────────────────────────────────────────────────────────

    private Set<Long> getOrderIdsByMerchant(Long merchantId) {
        return orderMapper.selectList(
                Wrappers.<CbOrder>lambdaQuery()
                        .eq(CbOrder::getMerchantId, merchantId)
                        .select(CbOrder::getId))
                .stream().map(CbOrder::getId).collect(Collectors.toSet());
    }
}
