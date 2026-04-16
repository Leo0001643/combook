package com.cambook.app.controller.merchant;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.cambook.common.context.MerchantContext;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.Result;
import com.cambook.dao.entity.CbMerchant;
import com.cambook.dao.entity.CbOrder;
import com.cambook.dao.entity.CbTechnician;
import com.cambook.dao.mapper.CbMerchantMapper;
import com.cambook.dao.mapper.CbOrderMapper;
import com.cambook.dao.mapper.CbTechnicianMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 商户端 - 数据看板
 *
 * @author CamBook
 */
@Tag(name = "商户端 - 数据看板")
@RestController
@RequestMapping("/merchant/dashboard")
public class MerchantDashboardController {

    private final CbMerchantMapper  merchantMapper;
    private final CbOrderMapper     orderMapper;
    private final CbTechnicianMapper technicianMapper;

    public MerchantDashboardController(CbMerchantMapper merchantMapper,
                                       CbOrderMapper orderMapper,
                                       CbTechnicianMapper technicianMapper) {
        this.merchantMapper   = merchantMapper;
        this.orderMapper      = orderMapper;
        this.technicianMapper = technicianMapper;
    }

    @Operation(summary = "数据看板统计")
    @GetMapping("/stats")
    public Result<Map<String, Object>> stats() {
        Long merchantId = requireMerchantId();

        // 订单统计
        long totalOrders = orderMapper.selectCount(
                Wrappers.<CbOrder>lambdaQuery().eq(CbOrder::getMerchantId, merchantId));
        long pendingOrders = orderMapper.selectCount(
                Wrappers.<CbOrder>lambdaQuery().eq(CbOrder::getMerchantId, merchantId).eq(CbOrder::getStatus, 0));
        long todayOrders = orderMapper.selectCount(
                Wrappers.<CbOrder>lambdaQuery().eq(CbOrder::getMerchantId, merchantId)
                        .ge(CbOrder::getCreateTime, LocalDate.now().atStartOfDay()));

        // 营收统计
        List<CbOrder> completedOrders = orderMapper.selectList(
                Wrappers.<CbOrder>lambdaQuery().eq(CbOrder::getMerchantId, merchantId)
                        .eq(CbOrder::getStatus, 4)
                        .select(CbOrder::getPayAmount, CbOrder::getPlatformIncome));
        BigDecimal totalRevenue = completedOrders.stream()
                .filter(o -> o.getPayAmount() != null)
                .map(CbOrder::getPayAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal platformFee = completedOrders.stream()
                .filter(o -> o.getPlatformIncome() != null)
                .map(CbOrder::getPlatformIncome)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal merchantRevenue = totalRevenue.subtract(platformFee);

        // 技师统计
        long technicianCount = technicianMapper.selectCount(
                Wrappers.<CbTechnician>lambdaQuery().eq(CbTechnician::getMerchantId, merchantId));
        long activeTechCount = technicianMapper.selectCount(
                Wrappers.<CbTechnician>lambdaQuery().eq(CbTechnician::getMerchantId, merchantId)
                        .eq(CbTechnician::getStatus, 1));

        // 商户信息
        CbMerchant merchant = merchantMapper.selectById(merchantId);

        // 近7天趋势（模拟）
        List<Map<String, Object>> trend = buildTrend(merchantId);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("totalOrders",    totalOrders);
        data.put("pendingOrders",  pendingOrders);
        data.put("todayOrders",    todayOrders);
        data.put("totalRevenue",   totalRevenue);
        data.put("merchantRevenue", merchantRevenue);
        data.put("technicianCount", technicianCount);
        data.put("activeTechCount", activeTechCount);
        data.put("balance",        merchant != null ? merchant.getBalance() : BigDecimal.ZERO);
        data.put("commissionRate", merchant != null ? merchant.getCommissionRate() : BigDecimal.ZERO);
        data.put("trend",          trend);

        return Result.success(data);
    }

    @Operation(summary = "获取商户自身信息")
    @GetMapping("/profile")
    public Result<CbMerchant> profile() {
        Long merchantId = requireMerchantId();
        CbMerchant merchant = merchantMapper.selectById(merchantId);
        if (merchant != null) {
            merchant.setPassword(null); // 不回传密码
        }
        return Result.success(merchant);
    }

    // ── private ──────────────────────────────────────────────────────────────

    private Long requireMerchantId() {
        Long id = MerchantContext.getMerchantId();
        if (id == null) throw new BusinessException("商户身份校验失败，请重新登录");
        return id;
    }

    private List<Map<String, Object>> buildTrend(Long merchantId) {
        List<Map<String, Object>> trend = new ArrayList<>();
        DateTimeFormatter fmt = DateTimeFormatter.ofPattern("MM-dd");
        for (int i = 6; i >= 0; i--) {
            LocalDate day = LocalDate.now().minusDays(i);
            LocalDateTime start = day.atStartOfDay();
            LocalDateTime end   = day.plusDays(1).atStartOfDay();
            long cnt = orderMapper.selectCount(
                    Wrappers.<CbOrder>lambdaQuery()
                            .eq(CbOrder::getMerchantId, merchantId)
                            .ge(CbOrder::getCreateTime, start)
                            .lt(CbOrder::getCreateTime, end)
                            .eq(CbOrder::getDeleted, 0));
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("date", day.format(fmt));
            item.put("orders", cnt);
            trend.add(item);
        }
        return trend;
    }
}
