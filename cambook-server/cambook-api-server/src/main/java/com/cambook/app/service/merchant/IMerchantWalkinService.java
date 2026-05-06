package com.cambook.app.service.merchant;

import com.cambook.app.domain.dto.WalkinAddItemDTO;
import com.cambook.app.domain.dto.WalkinCreateDTO;
import com.cambook.app.domain.dto.WalkinSettleDTO;
import com.cambook.app.domain.dto.WalkinUpdateDTO;
import com.cambook.app.domain.vo.WalkinItemVO;
import com.cambook.app.domain.vo.WalkinSessionVO;
import com.cambook.common.result.PageResult;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * 商户端散客接待服务接口
 *
 * @author CamBook
 */
public interface IMerchantWalkinService {

    PageResult<WalkinSessionVO> list(Long merchantId, int page, int size,
                                     String keyword, Integer status, LocalDate date);

    WalkinSessionVO getDetail(Long merchantId, Long sessionId);

    WalkinSessionVO create(Long merchantId, WalkinCreateDTO dto);

    WalkinSessionVO createWithItems(Long merchantId, WalkinCreateDTO dto);

    void update(Long merchantId, Long sessionId, WalkinUpdateDTO dto);

    WalkinItemVO addItem(Long merchantId, Long sessionId, WalkinAddItemDTO dto);

    void removeItem(Long merchantId, Long sessionId, Long orderId);

    void updateItemPrice(Long merchantId, Long sessionId, Long orderId, BigDecimal unitPrice);

    void startService(Long merchantId, Long sessionId, Long orderId);

    void finishService(Long merchantId, Long sessionId, Long orderId);

    void settle(Long merchantId, Long sessionId, WalkinSettleDTO dto);

    void cancel(Long merchantId, Long sessionId, String reason);
}
