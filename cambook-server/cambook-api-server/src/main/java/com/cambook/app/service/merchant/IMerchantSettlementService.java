package com.cambook.app.service.merchant;

import com.cambook.app.domain.dto.SettlementAdjustDTO;
import com.cambook.app.domain.dto.SettlementBatchPayDTO;
import com.cambook.app.domain.dto.SettlementGenerateDTO;
import com.cambook.app.domain.dto.SettlementPayDTO;
import com.cambook.app.domain.vo.SettlementDetailVO;
import com.cambook.app.domain.vo.SettlementListVO;
import com.cambook.app.domain.vo.SuggestPeriodVO;
import com.cambook.app.domain.vo.TechnicianSummaryVO;
import com.cambook.db.entity.CbTechnicianSettlement;

import java.util.List;

/**
 * 商户端技师结算服务接口
 *
 * @author CamBook
 */
public interface IMerchantSettlementService {

    SettlementListVO list(Long merchantId, int page, int size, Long technicianId,
                          Integer settlementMode, Integer status, String startDate, String endDate);

    SettlementDetailVO detail(Long merchantId, Long id);

    TechnicianSummaryVO technicianSummary(Long merchantId, Long technicianId);

    CbTechnicianSettlement generate(Long merchantId, SettlementGenerateDTO dto);

    void markPaid(Long merchantId, Long id, SettlementPayDTO dto);

    void adjust(Long merchantId, Long id, SettlementAdjustDTO dto);

    void revoke(Long merchantId, Long id);

    void batchPay(Long merchantId, SettlementBatchPayDTO dto);

    List<SuggestPeriodVO> suggestPeriods(Long technicianId, Integer settlementMode);
}
