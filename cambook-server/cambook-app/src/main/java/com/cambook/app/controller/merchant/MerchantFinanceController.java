package com.cambook.app.controller.merchant;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.cambook.common.context.MerchantContext;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.Result;
import com.cambook.dao.entity.CbMerchant;
import com.cambook.dao.entity.CbOrder;
import com.cambook.dao.mapper.CbMerchantMapper;
import com.cambook.dao.mapper.CbOrderMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 商户端 - 财务管理
 *
 * @author CamBook
 */
@Tag(name = "商户端 - 财务管理")
@RestController
@RequestMapping("/merchant/finance")
public class MerchantFinanceController {

    private final CbOrderMapper   orderMapper;
    private final CbMerchantMapper merchantMapper;

    public MerchantFinanceController(CbOrderMapper orderMapper, CbMerchantMapper merchantMapper) {
        this.orderMapper    = orderMapper;
        this.merchantMapper = merchantMapper;
    }

    @Operation(summary = "财务概览")
    @GetMapping("/overview")
    public Result<Map<String, Object>> overview() {
        Long merchantId = requireMerchantId();

        CbMerchant merchant = merchantMapper.selectById(merchantId);

        List<CbOrder> completedOrders = orderMapper.selectList(
                Wrappers.<CbOrder>lambdaQuery()
                        .eq(CbOrder::getMerchantId, merchantId)
                        .eq(CbOrder::getStatus, 4)
                        .select(CbOrder::getPayAmount, CbOrder::getPlatformIncome, CbOrder::getTechIncome));

        BigDecimal totalRevenue = completedOrders.stream()
                .filter(o -> o.getPayAmount() != null)
                .map(CbOrder::getPayAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal platformFee = completedOrders.stream()
                .filter(o -> o.getPlatformIncome() != null)
                .map(CbOrder::getPlatformIncome)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal techFee = completedOrders.stream()
                .filter(o -> o.getTechIncome() != null)
                .map(CbOrder::getTechIncome)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal merchantRevenue = totalRevenue.subtract(platformFee).subtract(techFee);

        // 今日收入
        List<CbOrder> todayOrders = orderMapper.selectList(
                Wrappers.<CbOrder>lambdaQuery()
                        .eq(CbOrder::getMerchantId, merchantId)
                        .eq(CbOrder::getStatus, 4)
                        .ge(CbOrder::getCreateTime, LocalDate.now().atStartOfDay())
                        .select(CbOrder::getPayAmount, CbOrder::getPlatformIncome, CbOrder::getTechIncome));
        BigDecimal todayRevenue = todayOrders.stream()
                .filter(o -> o.getPayAmount() != null)
                .map(CbOrder::getPayAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal todayPlatform = todayOrders.stream()
                .filter(o -> o.getPlatformIncome() != null)
                .map(CbOrder::getPlatformIncome)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal todayTech = todayOrders.stream()
                .filter(o -> o.getTechIncome() != null)
                .map(CbOrder::getTechIncome)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal todayMerchant = todayRevenue.subtract(todayPlatform).subtract(todayTech);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("balance",          merchant != null ? merchant.getBalance() : BigDecimal.ZERO);
        data.put("commissionRate",   merchant != null ? merchant.getCommissionRate() : BigDecimal.ZERO);
        data.put("totalRevenue",     totalRevenue);
        data.put("platformFee",      platformFee);
        data.put("techFee",          techFee);
        data.put("merchantRevenue",  merchantRevenue);
        data.put("todayRevenue",     todayRevenue);
        data.put("todayMerchant",    todayMerchant);
        data.put("completedOrders",  completedOrders.size());

        return Result.success(data);
    }

    // ── private ──────────────────────────────────────────────────────────────

    private Long requireMerchantId() {
        Long id = MerchantContext.getMerchantId();
        if (id == null) throw new BusinessException("商户身份校验失败，请重新登录");
        return id;
    }
}
