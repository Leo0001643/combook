package com.cambook.app.service.merchant;

import com.cambook.app.domain.dto.MerchantLoginDTO;
import com.cambook.app.domain.vo.LoginVO;
import com.cambook.db.entity.CbMerchantStaff;

/**
 * 商户端 认证服务
 */
public interface IMerchantAuthService {

    LoginVO login(MerchantLoginDTO dto);

    CbMerchantStaff resolveCurrentStaff(Long merchantId, Long staffId, String mobile);
}
