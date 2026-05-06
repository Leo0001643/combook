package com.cambook.app.service.biz;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.PageResult;
import com.cambook.db.entity.CbOrder;
import com.cambook.db.entity.CbReview;
import com.cambook.db.service.ICbOrderService;
import com.cambook.db.service.ICbReviewService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;
import com.cambook.common.utils.DateUtils;
import com.cambook.common.enums.CbCodeEnum;

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
@RequiredArgsConstructor
public class ReviewService {

    private final ICbReviewService cbReviewService;
    private final ICbOrderService  cbOrderService;

    /** 分页列表 */
    public PageResult<CbReview> pageList(Long merchantId, int page, int size, Long technicianId, Integer overallScore, Integer status) {
        if (merchantId != null) {
            Set<Long> orderIds = getOrderIdsByMerchant(merchantId);
            if (orderIds.isEmpty()) {
                return PageResult.of(Collections.emptyList(), 0L, page, size);
            }
            var p = cbReviewService.lambdaQuery()
                    .in(CbReview::getOrderId, orderIds)
                    .eq(technicianId  != null, CbReview::getTechnicianId, technicianId)
                    .eq(overallScore  != null, CbReview::getOverallScore, overallScore)
                    .eq(status        != null, CbReview::getStatus,       status)
                    .orderByDesc(CbReview::getCreateTime)
                    .page(new Page<>(page, size));
            return PageResult.of(p.getRecords(), p.getTotal(), page, size);
        }

        var p = cbReviewService.lambdaQuery()
                .eq(technicianId  != null, CbReview::getTechnicianId, technicianId)
                .eq(overallScore  != null, CbReview::getOverallScore, overallScore)
                .eq(status        != null, CbReview::getStatus,       status)
                .orderByDesc(CbReview::getCreateTime)
                .page(new Page<>(page, size));
        return PageResult.of(p.getRecords(), p.getTotal(), page, size);
    }

    /** 评价统计（商户用） */
    public Map<String, Object> stats(Long merchantId) {
        List<CbReview> all;
        if (merchantId != null) {
            Set<Long> orderIds = getOrderIdsByMerchant(merchantId);
            if (orderIds.isEmpty()) {
                return Map.of("total", 0, "avgScore", 0, "pendingReply", 0, "fiveStars", 0);
            }
            all = cbReviewService.lambdaQuery().in(CbReview::getOrderId, orderIds).list();
        } else {
            all = cbReviewService.list();
        }

        double avg     = all.stream().mapToInt(r -> r.getOverallScore() != null ? r.getOverallScore() : 0).average().orElse(0);
        long   pending = all.stream().filter(r -> r.getReply() == null || r.getReply().isBlank()).count();

        return Map.of(
                "total",        all.size(),
                "avgScore",     Math.round(avg * 10) / 10.0,
                "pendingReply", pending,
                "fiveStars",    all.stream().filter(r -> r.getOverallScore() != null && r.getOverallScore() >= 5).count()
        );
    }

    /** 回复评价 */
    public void reply(Long merchantId, Long id, String reply) {
        CbReview review = Optional.ofNullable(cbReviewService.getById(id)).orElseThrow(() -> new BusinessException("评价不存在"));
        if (merchantId != null) {
            Set<Long> orderIds = getOrderIdsByMerchant(merchantId);
            if (!orderIds.contains(review.getOrderId())) {
                throw new BusinessException(CbCodeEnum.NO_PERMISSION);
            }
        }

        review.setReply(reply);
        review.setReplyTime(DateUtils.nowSeconds());
        cbReviewService.updateById(review);
    }

    /** 修改状态（Admin Only）*/
    public void updateStatus(Long id, Integer status) {
        CbReview r = Optional.ofNullable(cbReviewService.getById(id))
                .orElseThrow(() -> new BusinessException("评价不存在"));
        r.setStatus(status == null ? null : status.byteValue());
        cbReviewService.updateById(r);
    }

    /** 删除（Admin Only）*/
    public void delete(Long id) {
        cbReviewService.removeById(id);
    }

    // ── private ──────────────────────────────────────────────────────────────

    private Set<Long> getOrderIdsByMerchant(Long merchantId) {
        return cbOrderService.lambdaQuery()
                .eq(CbOrder::getMerchantId, merchantId)
                .select(CbOrder::getId)
                .list()
                .stream().map(CbOrder::getId).collect(Collectors.toSet());
    }
}
