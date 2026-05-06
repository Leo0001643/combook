package com.cambook.app.service.merchant;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * 商户端 技师服务专属定价管理
 */
public interface IMerchantTechnicianPricingService {

    List<Map<String, Object>> list(Long merchantId, Long technicianId);

    void save(Long merchantId, Long technicianId, Long serviceItemId, BigDecimal price);

    void saveAll(Long merchantId, Long technicianId, List<Map<String, Object>> items);

    void delete(Long merchantId, Long technicianId, Long serviceItemId);
}
