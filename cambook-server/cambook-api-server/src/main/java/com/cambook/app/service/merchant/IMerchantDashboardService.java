package com.cambook.app.service.merchant;

import com.cambook.app.domain.vo.DashboardStatsVO;
import com.cambook.db.entity.CbMerchant;

/**
 * 商户端数据看板服务接口
 *
 * @author CamBook
 */
public interface IMerchantDashboardService {

    DashboardStatsVO getStats(Long merchantId, String period);

    CbMerchant getProfile(Long merchantId);
}
