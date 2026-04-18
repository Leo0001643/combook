package com.cambook.app.controller.merchant;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.cambook.app.common.annotation.RequireMerchant;
import com.cambook.app.common.security.MerchantOwnershipGuard;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.Result;
import com.cambook.dao.entity.CbServiceCategory;
import com.cambook.dao.entity.CbTechnician;
import com.cambook.dao.entity.CbTechnicianServicePrice;
import com.cambook.dao.mapper.CbServiceCategoryMapper;
import com.cambook.dao.mapper.CbTechnicianMapper;
import com.cambook.dao.mapper.CbTechnicianServicePriceMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 商户端 - 技师服务专属定价管理
 *
 * <p>特殊服务项目（is_special=1）支持技师自行覆盖系统指导价。
 * 常规项目使用 cb_service_category.price 的全局价格，不允许单独设置。
 */
@RequireMerchant
@Tag(name = "商户端 - 技师服务定价")
@RestController
@RequestMapping("/merchant/technician/pricing")
public class MerchantTechnicianPricingController {

    private final CbTechnicianServicePriceMapper pricingMapper;
    private final CbTechnicianMapper             technicianMapper;
    private final CbServiceCategoryMapper        categoryMapper;

    public MerchantTechnicianPricingController(
            CbTechnicianServicePriceMapper pricingMapper,
            CbTechnicianMapper technicianMapper,
            CbServiceCategoryMapper categoryMapper) {
        this.pricingMapper   = pricingMapper;
        this.technicianMapper = technicianMapper;
        this.categoryMapper  = categoryMapper;
    }

    /**
     * 查询指定技师的专属定价列表。
     * 返回结构：serviceItemId → price（只含有覆盖价格的条目）
     */
    @Operation(summary = "查询技师专属定价")
    @GetMapping("/list")
    public Result<List<Map<String, Object>>> list(@RequestParam Long technicianId) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        assertBelongs(technicianId, merchantId);

        List<CbTechnicianServicePrice> rows = pricingMapper.selectList(
                new LambdaQueryWrapper<CbTechnicianServicePrice>()
                        .eq(CbTechnicianServicePrice::getMerchantId,   merchantId)
                        .eq(CbTechnicianServicePrice::getTechnicianId, technicianId));

        List<Map<String, Object>> result = rows.stream().map(r -> {
            Map<String, Object> m = new HashMap<>();
            m.put("serviceItemId", r.getServiceItemId());
            m.put("price",         r.getPrice());
            return m;
        }).collect(Collectors.toList());

        return Result.success(result);
    }

    /**
     * 为技师设置或更新单个特殊服务项目的专属价格。
     */
    @Operation(summary = "设置技师专属定价")
    @PostMapping("/save")
    public Result<Void> save(@RequestParam Long technicianId,
                             @RequestParam Long serviceItemId,
                             @RequestParam BigDecimal price) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        assertBelongs(technicianId, merchantId);
        assertSpecial(serviceItemId);
        if (price.compareTo(BigDecimal.ZERO) < 0) throw new BusinessException("价格不能为负数");

        CbTechnicianServicePrice existing = pricingMapper.selectOne(
                new LambdaQueryWrapper<CbTechnicianServicePrice>()
                        .eq(CbTechnicianServicePrice::getTechnicianId, technicianId)
                        .eq(CbTechnicianServicePrice::getServiceItemId, serviceItemId));

        if (existing != null) {
            existing.setPrice(price);
            pricingMapper.updateById(existing);
        } else {
            CbTechnicianServicePrice row = new CbTechnicianServicePrice();
            row.setMerchantId(merchantId);
            row.setTechnicianId(technicianId);
            row.setServiceItemId(serviceItemId);
            row.setPrice(price);
            pricingMapper.insert(row);
        }
        return Result.success();
    }

    /**
     * 批量保存（覆盖式）：传入技师所有特殊项目的定价，删除未出现的旧数据。
     */
    @Operation(summary = "批量保存技师专属定价（覆盖式）")
    @PostMapping("/saveAll")
    public Result<Void> saveAll(@RequestParam Long technicianId,
                                @RequestBody List<Map<String, Object>> items) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        assertBelongs(technicianId, merchantId);

        // 删除旧数据
        pricingMapper.delete(new LambdaQueryWrapper<CbTechnicianServicePrice>()
                .eq(CbTechnicianServicePrice::getMerchantId,   merchantId)
                .eq(CbTechnicianServicePrice::getTechnicianId, technicianId));

        // 批量插入
        for (Map<String, Object> item : items) {
            Long       svcId = Long.valueOf(item.get("serviceItemId").toString());
            BigDecimal p     = new BigDecimal(item.get("price").toString());
            assertSpecial(svcId);
            if (p.compareTo(BigDecimal.ZERO) < 0) continue;
            CbTechnicianServicePrice row = new CbTechnicianServicePrice();
            row.setMerchantId(merchantId);
            row.setTechnicianId(technicianId);
            row.setServiceItemId(svcId);
            row.setPrice(p);
            pricingMapper.insert(row);
        }
        return Result.success();
    }

    /**
     * 删除技师单个服务项目的专属价格（回退到系统指导价）。
     */
    @Operation(summary = "删除技师专属定价")
    @PostMapping("/delete")
    public Result<Void> delete(@RequestParam Long technicianId,
                               @RequestParam Long serviceItemId) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        assertBelongs(technicianId, merchantId);
        pricingMapper.delete(new LambdaQueryWrapper<CbTechnicianServicePrice>()
                .eq(CbTechnicianServicePrice::getMerchantId,    merchantId)
                .eq(CbTechnicianServicePrice::getTechnicianId,  technicianId)
                .eq(CbTechnicianServicePrice::getServiceItemId, serviceItemId));
        return Result.success();
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private void assertBelongs(Long technicianId, Long merchantId) {
        CbTechnician tech = technicianMapper.selectById(technicianId);
        if (tech == null || !merchantId.equals(tech.getMerchantId()))
            throw new BusinessException("技师不属于当前商户");
    }

    private void assertSpecial(Long serviceItemId) {
        CbServiceCategory cat = categoryMapper.selectById(serviceItemId);
        if (cat == null) throw new BusinessException("服务项目不存在");
        if (cat.getIsSpecial() == null || cat.getIsSpecial() != 1)
            throw new BusinessException("仅特殊项目支持设置技师专属价格");
    }
}
