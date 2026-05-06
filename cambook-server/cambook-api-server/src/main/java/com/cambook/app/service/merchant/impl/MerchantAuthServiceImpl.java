package com.cambook.app.service.merchant.impl;

import com.cambook.app.domain.dto.MerchantLoginDTO;
import com.cambook.app.domain.vo.LoginVO;
import com.cambook.app.service.merchant.IMerchantAuthService;
import com.cambook.common.enums.AuditStatusEnum;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.enums.CommonStatus;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.utils.JwtUtils;
import com.cambook.db.entity.CbMerchant;
import com.cambook.db.entity.CbMerchantStaff;
import com.cambook.db.service.ICbMerchantService;
import com.cambook.db.service.ICbMerchantStaffService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.util.DigestUtils;

import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import com.cambook.common.utils.DateUtils;

/**
 * 商户端认证服务实现
 *
 * <p>登录路径：
 * <ol>
 *   <li>商户主账号：直接用手机号/用户名登录</li>
 *   <li>员工账号：必须填写商户编号，按商户锁定后再匹配账号，避免跨商户混淆</li>
 * </ol>
 */
@Service
@RequiredArgsConstructor
public class MerchantAuthServiceImpl implements IMerchantAuthService {


    private final ICbMerchantService      cbMerchantService;
    private final ICbMerchantStaffService cbMerchantStaffService;
    private final JwtUtils                jwtUtils;

    @Override
    public LoginVO login(MerchantLoginDTO dto) {
        String  encPwd        = DigestUtils.md5DigestAsHex(dto.getPassword().getBytes(StandardCharsets.UTF_8));
        boolean hasMerchantNo = dto.getMerchantNo() != null && !dto.getMerchantNo().isBlank();
        if (hasMerchantNo) return staffLogin(dto, encPwd);
        return ownerLogin(dto, encPwd);
    }

    @Override
    public CbMerchantStaff resolveCurrentStaff(Long merchantId, Long staffId, String mobile) {
        if (staffId != null) {
            CbMerchantStaff s = cbMerchantStaffService.getById(staffId);
            if (s != null && merchantId.equals(s.getMerchantId())) return s;
        }
        if (mobile != null) {
            return cbMerchantStaffService.lambdaQuery()
                    .eq(CbMerchantStaff::getMerchantId, merchantId).eq(CbMerchantStaff::getMobile, mobile)
                    .last("LIMIT 1").one();
        }
        return null;
    }

    // ── 私有辅助 ──────────────────────────────────────────────────────────────

    private LoginVO staffLogin(MerchantLoginDTO dto, String encPwd) {
        CbMerchant employer = Optional.ofNullable(cbMerchantService.lambdaQuery().eq(CbMerchant::getMerchantNo, dto.getMerchantNo().trim()).last("LIMIT 1").one()).orElseThrow(() -> new BusinessException(CbCodeEnum.MERCHANT_NOT_FOUND));
        if (employer.getAuditStatus() == null || employer.getAuditStatus() != AuditStatusEnum.PASS.getCode()) throw new BusinessException(CbCodeEnum.MERCHANT_AUDIT_PENDING);
        if (employer.getStatus() != null && employer.getStatus() == CommonStatus.DISABLED.getCode()) throw new BusinessException(CbCodeEnum.ACCOUNT_BANNED);

        CbMerchantStaff staff = Optional.ofNullable(cbMerchantStaffService.lambdaQuery()
                .eq(CbMerchantStaff::getMerchantId, employer.getId())
                .and(q -> q.eq(CbMerchantStaff::getMobile, dto.getAccount()).or().eq(CbMerchantStaff::getUsername, dto.getAccount()))
                .last("LIMIT 1").one()).orElseThrow(() -> new BusinessException(CbCodeEnum.ACCOUNT_NOT_FOUND));
        if (!encPwd.equals(staff.getPassword())) throw new BusinessException(CbCodeEnum.SMS_CODE_WRONG);
        if (staff.getStatus() == null || staff.getStatus() != CommonStatus.ENABLED.getCode()) throw new BusinessException(CbCodeEnum.ACCOUNT_BANNED);

        Map<String, Object> claims = new HashMap<>();
        claims.put("uid",         employer.getId());
        claims.put("merchantName",employer.getMerchantNameZh());
        claims.put("mobile",      staff.getMobile() != null ? staff.getMobile() : staff.getUsername());
        claims.put("userType",    "merchant");
        claims.put("staffId",     staff.getId());

        String displayName = staff.getRealName() != null ? staff.getRealName() : staff.getUsername();
        LoginVO vo = LoginVO.of(jwtUtils.generateToken(claims), DateUtils.expireAt(java.util.concurrent.TimeUnit.DAYS.toSeconds(7)), "merchant", employer.getId(), false);
        vo.setMerchantName(employer.getMerchantNameZh());
        vo.setMerchantLogo(employer.getLogo());
        vo.setMerchantMobile(employer.getMobile());
        vo.setStaffName(displayName);
        vo.setStaff(true);
        return vo;
    }

    private LoginVO ownerLogin(MerchantLoginDTO dto, String encPwd) {
        CbMerchant merchant = Optional.ofNullable(cbMerchantService.lambdaQuery()
                .and(q -> q.eq(CbMerchant::getMobile, dto.getAccount()).or().eq(CbMerchant::getUsername, dto.getAccount()))
                .last("LIMIT 1").one()).orElseThrow(() -> new BusinessException(CbCodeEnum.MERCHANT_NOT_FOUND));
        if (!encPwd.equals(merchant.getPassword())) throw new BusinessException(CbCodeEnum.SMS_CODE_WRONG);
        if (merchant.getAuditStatus() == null || merchant.getAuditStatus() != AuditStatusEnum.PASS.getCode()) throw new BusinessException(CbCodeEnum.MERCHANT_AUDIT_PENDING);
        if (merchant.getStatus() != null && merchant.getStatus() == CommonStatus.DISABLED.getCode()) throw new BusinessException(CbCodeEnum.ACCOUNT_BANNED);

        Map<String, Object> claims = new HashMap<>();
        claims.put("uid",         merchant.getId());
        claims.put("merchantName",merchant.getMerchantNameZh());
        claims.put("mobile",      merchant.getMobile());
        claims.put("userType",    "merchant");

        LoginVO vo = LoginVO.of(jwtUtils.generateToken(claims), DateUtils.expireAt(java.util.concurrent.TimeUnit.DAYS.toSeconds(7)), "merchant", merchant.getId(), false);
        vo.setMerchantName(merchant.getMerchantNameZh());
        vo.setMerchantLogo(merchant.getLogo());
        vo.setMerchantMobile(merchant.getMobile());
        return vo;
    }
}
