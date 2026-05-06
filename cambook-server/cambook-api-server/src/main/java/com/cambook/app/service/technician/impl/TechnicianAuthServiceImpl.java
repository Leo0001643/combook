package com.cambook.app.service.technician.impl;

import com.baomidou.mybatisplus.extension.conditions.query.LambdaQueryChainWrapper;
import com.cambook.app.common.security.LoginSessionService;
import com.cambook.app.common.security.TokenKickService;
import com.cambook.app.common.statemachine.TechnicianOnlineStatus;
import com.cambook.app.domain.dto.TechLoginDTO;
import com.cambook.app.domain.dto.TechRegisterDTO;
import com.cambook.app.domain.vo.TechLoginVO;
import com.cambook.app.service.technician.ITechnicianAuthService;
import com.cambook.common.context.MemberContext;
import com.cambook.common.enums.AuditStatusEnum;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.enums.CommonStatus;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.utils.DateUtils;
import com.cambook.common.utils.JwtUtils;
import com.cambook.db.entity.CbMerchant;
import com.cambook.db.entity.CbTechnician;
import com.cambook.db.service.ICbMerchantService;
import com.cambook.db.service.ICbTechnicianService;
import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;
import org.springframework.util.DigestUtils;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.concurrent.TimeUnit;

/**
 * 技师端认证服务实现
 */
@Service
public class TechnicianAuthServiceImpl implements ITechnicianAuthService {
    private static final String USER_TYPE = "technician";

    private final ICbTechnicianService cbTechnicianService;
    private final ICbMerchantService   cbMerchantService;
    private final JwtUtils             jwtUtils;
    private final TokenKickService     tokenKickService;
    private final LoginSessionService  loginSessionService;

    public TechnicianAuthServiceImpl(ICbTechnicianService cbTechnicianService, ICbMerchantService cbMerchantService,
                                     JwtUtils jwtUtils, TokenKickService tokenKickService,
                                     LoginSessionService loginSessionService) {
        this.cbTechnicianService = cbTechnicianService;
        this.cbMerchantService   = cbMerchantService;
        this.jwtUtils            = jwtUtils;
        this.tokenKickService    = tokenKickService;
        this.loginSessionService = loginSessionService;
    }

    // ── 登录 ──────────────────────────────────────────────────────────────────

    @Override
    public TechLoginVO login(TechLoginDTO dto, String clientIp, String userAgent) {
        CbTechnician tech = loadByAccount(dto.getLoginType(), dto.getAccount(), dto.getMerchantId());
        AuditStatusEnum.from(tech.getAuditStatus()).check();
        if (!Objects.equals(tech.getStatus(), CommonStatus.ENABLED.byteCode()))
            throw new BusinessException(CbCodeEnum.TECHNICIAN_BANNED);
        verifyPassword(dto.getPassword(), tech.getPassword());
        String token   = generateToken(tech, dto.getLang());
        long expiresAt = DateUtils.expireAt(TimeUnit.DAYS.toSeconds(7));
        // 记录登录会话信息（设备、IP、时间），供管理端展示
        loginSessionService.save(USER_TYPE, tech.getId(), clientIp, userAgent);
        return TechLoginVO.of(token, expiresAt, tech);
    }

    // ── 登出 ──────────────────────────────────────────────────────────────────

    @Override
    public void logout() {
        Long techId = Optional.ofNullable(MemberContext.getMemberId()).orElseThrow(() -> new BusinessException(CbCodeEnum.TOKEN_INVALID));
        tokenKickService.kick(USER_TYPE, techId);
        loginSessionService.remove(USER_TYPE, techId);
    }

    @Override
    public void forceLogout(Long techId) {
        Optional.ofNullable(cbTechnicianService.getById(techId)).orElseThrow(() -> new BusinessException(CbCodeEnum.TECHNICIAN_NOT_FOUND));
        tokenKickService.kick(USER_TYPE, techId);
        loginSessionService.remove(USER_TYPE, techId);
    }

    // ── 注册 ──────────────────────────────────────────────────────────────────

    @Override
    public void register(TechRegisterDTO dto) {
        CbMerchant merchant = validateMerchant(dto.getMerchantNo());
        // 同一商户内手机号唯一（多租户：不同商户允许同号注册）
        checkMobileUnique(dto.getMobile(), merchant.getId());
        CbTechnician tech = buildNewTechnician(dto, merchant.getId());
        cbTechnicianService.save(tech);
    }



    @Override
    public CbTechnician me() {
        Long techId = MemberContext.getMemberId();
        Optional.ofNullable(techId).orElseThrow(() -> new BusinessException(CbCodeEnum.TOKEN_INVALID));
        CbTechnician tech = cbTechnicianService.lambdaQuery().eq(CbTechnician::getId, techId).one();
        Optional.ofNullable(tech).orElseThrow(() -> new BusinessException(CbCodeEnum.TECHNICIAN_NOT_FOUND));
        return tech;
    }

    /**
     * 按「登录类型 + 账号 + 商户ID」联合查询技师
     * <p>多租户隔离在 SQL 层完成，一次查询同时满足：
     * <ul>
     *   <li>技师编号/手机号匹配</li>
     *   <li>必须归属于当前商户（merchant_id = ?），防止跨商户登录</li>
     * </ul>
     * @param loginType
     * @param account
     * @param merchantId
     * @return
     */
    private CbTechnician loadByAccount(String loginType, String account, Long merchantId) {
        LambdaQueryChainWrapper<CbTechnician> query = cbTechnicianService.lambdaQuery().eq(CbTechnician::getMerchantId, merchantId);
        if (StringUtils.equals("techId", loginType)) {
            query.eq(CbTechnician::getTechNo, account);
        } else {
            query.eq(CbTechnician::getMobile, account);
        }
        CbTechnician tech = query.one();
        Optional.ofNullable(tech).orElseThrow(() -> new BusinessException(CbCodeEnum.TECHNICIAN_NOT_FOUND));
        return tech;
    }


    /**
     * MD5 密码验证
     *
     * <p>密码错误与账号不存在使用同一错误码 {@code TECHNICIAN_NOT_FOUND}，
     * 防止账号枚举攻击，同时保持前端提示信息一致。
     */
    private void verifyPassword(String rawPassword, String storedPassword) {
        String md5 = DigestUtils.md5DigestAsHex(rawPassword.getBytes(StandardCharsets.UTF_8));
        if (Objects.isNull(storedPassword) || !md5.equals(storedPassword)) {
            throw new BusinessException(CbCodeEnum.TECHNICIAN_NOT_FOUND);
        }
    }

    /**
     * 校验商户编号
     *
     * <p>商户须存在（deleted=0）、状态正常（status=1）、审核通过（audit_status=1）
     */
    private CbMerchant validateMerchant(String merchantNo) {
        CbMerchant merchant = cbMerchantService.lambdaQuery().eq(CbMerchant::getMerchantNo, merchantNo).one();
        if (Objects.isNull(merchant) || !Objects.equals(merchant.getStatus(), CommonStatus.ENABLED.byteCode()) || !Objects.equals(merchant.getAuditStatus(), AuditStatusEnum.PASS.getCode())) {
            throw new BusinessException(CbCodeEnum.MERCHANT_NO_INVALID);
        }
        return merchant;
    }

    /** 同一商户内手机号唯一性校验 */
    private void checkMobileUnique(String mobile, Long merchantId) {
        Long count = cbTechnicianService.lambdaQuery().eq(CbTechnician::getMobile, mobile)
                .eq(CbTechnician::getMerchantId, merchantId).count();
        if (count > 0) throw new BusinessException(CbCodeEnum.TECHNICIAN_MOBILE_EXISTS);
    }

    /**
     * 构建新技师实体（待审核状态）
     *
     * <p>{@code techNo} 技师编号由商户后台在审核通过后手动分配，
     * 注册时留 null，未分配编号的技师无法通过「技师编号」方式登录。
     */
    private CbTechnician buildNewTechnician(TechRegisterDTO dto, Long merchantId) {
        CbTechnician tech = new CbTechnician();
        tech.setMobile(dto.getMobile());
        tech.setPassword(DigestUtils.md5DigestAsHex(dto.getPassword().getBytes(StandardCharsets.UTF_8)));
        tech.setRealName(dto.getRealName());
        tech.setNickname(dto.getNickname() != null ? dto.getNickname() : dto.getRealName());
        tech.setMerchantId(merchantId);
        tech.setLang(dto.getLang() != null ? dto.getLang() : "zh");
        tech.setStatus(Byte.valueOf(CommonStatus.ENABLED.byteCode()));    // 账号正常，等待审核
        tech.setAuditStatus(AuditStatusEnum.PENDING.byteCode());              // 待审核
        tech.setOnlineStatus(TechnicianOnlineStatus.OFFLINE.byteCode());             // 默认离线
        tech.setBalance(BigDecimal.ZERO);
        tech.setTotalIncome(BigDecimal.ZERO);
        tech.setRating(BigDecimal.ZERO);
        tech.setOrderCount(0);
        tech.setReviewCount(0);
        return tech;
    }

    /** 生成技师 JWT */
    private String generateToken(CbTechnician tech, String lang) {
        return jwtUtils.generateToken(Map.of(
                "uid",        tech.getId(),
                "userType",   USER_TYPE,
                "techNo",     tech.getTechNo() != null ? tech.getTechNo() : "",
                "merchantId", tech.getMerchantId() != null ? tech.getMerchantId() : 0L,
                "lang",       lang != null ? lang : "zh"
        ));
    }
}
