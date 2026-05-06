package com.cambook.app.service.merchant.impl;

import com.cambook.app.service.merchant.IMerchantTechnicianPricingService;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.db.entity.CbServiceCategory;
import com.cambook.db.entity.CbTechnician;
import com.cambook.db.entity.CbTechnicianServicePrice;
import com.cambook.db.service.ICbServiceCategoryService;
import com.cambook.db.service.ICbTechnicianService;
import com.cambook.db.service.ICbTechnicianServicePriceService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * 商户端 技师服务专属定价管理实现
 */
@Service
@RequiredArgsConstructor
public class MerchantTechnicianPricingServiceImpl implements IMerchantTechnicianPricingService {

    private final ICbTechnicianServicePriceService cbTechnicianServicePriceService;
    private final ICbTechnicianService             cbTechnicianService;
    private final ICbServiceCategoryService        cbServiceCategoryService;

    @Override
    public List<Map<String, Object>> list(Long merchantId, Long technicianId) {
        assertBelongs(technicianId, merchantId);
        return cbTechnicianServicePriceService.lambdaQuery()
                .eq(CbTechnicianServicePrice::getMerchantId, merchantId)
                .eq(CbTechnicianServicePrice::getTechnicianId, technicianId).list()
                .stream().map(r -> {
                    Map<String, Object> m = new HashMap<>();
                    m.put("serviceItemId", r.getServiceItemId());
                    m.put("price", r.getPrice());
                    return m;
                }).collect(Collectors.toList());
    }

    @Override
    public void save(Long merchantId, Long technicianId, Long serviceItemId, BigDecimal price) {
        assertBelongs(technicianId, merchantId); assertSpecial(serviceItemId);
        if (price.compareTo(BigDecimal.ZERO) < 0) throw new BusinessException(CbCodeEnum.PARAM_ERROR);
        CbTechnicianServicePrice existing = cbTechnicianServicePriceService.lambdaQuery()
                .eq(CbTechnicianServicePrice::getTechnicianId, technicianId)
                .eq(CbTechnicianServicePrice::getServiceItemId, serviceItemId).one();
        if (existing != null) { existing.setPrice(price); cbTechnicianServicePriceService.updateById(existing); }
        else {
            CbTechnicianServicePrice row = new CbTechnicianServicePrice();
            row.setMerchantId(merchantId); row.setTechnicianId(technicianId);
            row.setServiceItemId(serviceItemId); row.setPrice(price); cbTechnicianServicePriceService.save(row);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void saveAll(Long merchantId, Long technicianId, List<Map<String, Object>> items) {
        assertBelongs(technicianId, merchantId);
        cbTechnicianServicePriceService.lambdaUpdate()
                .eq(CbTechnicianServicePrice::getMerchantId, merchantId)
                .eq(CbTechnicianServicePrice::getTechnicianId, technicianId).remove();
        for (Map<String, Object> item : items) {
            Long svcId = Long.valueOf(item.get("serviceItemId").toString());
            BigDecimal p = new BigDecimal(item.get("price").toString());
            assertSpecial(svcId);
            if (p.compareTo(BigDecimal.ZERO) < 0) continue;
            CbTechnicianServicePrice row = new CbTechnicianServicePrice();
            row.setMerchantId(merchantId); row.setTechnicianId(technicianId);
            row.setServiceItemId(svcId); row.setPrice(p); cbTechnicianServicePriceService.save(row);
        }
    }

    @Override
    public void delete(Long merchantId, Long technicianId, Long serviceItemId) {
        assertBelongs(technicianId, merchantId);
        cbTechnicianServicePriceService.lambdaUpdate()
                .eq(CbTechnicianServicePrice::getMerchantId, merchantId)
                .eq(CbTechnicianServicePrice::getTechnicianId, technicianId)
                .eq(CbTechnicianServicePrice::getServiceItemId, serviceItemId).remove();
    }

    private void assertBelongs(Long technicianId, Long merchantId) {
        CbTechnician tech = cbTechnicianService.getById(technicianId);
        if (tech == null || !merchantId.equals(tech.getMerchantId())) throw new BusinessException(CbCodeEnum.NO_PERMISSION);
    }

    private void assertSpecial(Long serviceItemId) {
        CbServiceCategory cat = Optional.ofNullable(cbServiceCategoryService.getById(serviceItemId))
                .orElseThrow(() -> new BusinessException("服务项目不存在"));
        if (cat.getIsSpecial() == null || !cat.getIsSpecial()) throw new BusinessException(CbCodeEnum.PRICING_NOT_SPECIAL);
    }
}
