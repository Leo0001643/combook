package com.cambook.app.service.technician.impl;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.cambook.app.domain.dto.TechLoginDTO;
import com.cambook.app.domain.dto.TechRegisterDTO;
import com.cambook.app.domain.vo.TechLoginVO;
import com.cambook.app.service.technician.ITechnicianAuthService;
import com.cambook.common.context.MemberContext;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.utils.JwtUtils;
import com.cambook.dao.entity.CbMerchant;
import com.cambook.dao.entity.CbTechnician;
import com.cambook.dao.mapper.CbMerchantMapper;
import com.cambook.dao.mapper.CbTechnicianMapper;
import org.springframework.stereotype.Service;
import org.springframework.util.DigestUtils;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Map;

/**
 * 技师端认证服务实现
 *
 * <p>密码存储：MD5（与项目现有 Admin/Merchant 端保持一致）
 *
 * @author CamBook
 */
@Service
public class TechnicianAuthServiceImpl implements ITechnicianAuthService {

    private static final String USER_TYPE  = "technician";
    private static final int    AUDIT_PASS = 1;
    private static final int    STATUS_OK  = 1;

    private final CbTechnicianMapper technicianMapper;
    private final CbMerchantMapper   merchantMapper;
    private final JwtUtils           jwtUtils;

    public TechnicianAuthServiceImpl(CbTechnicianMapper technicianMapper,
                                     CbMerchantMapper merchantMapper,
                                     JwtUtils jwtUtils) {
        this.technicianMapper = technicianMapper;
        this.merchantMapper   = merchantMapper;
        this.jwtUtils         = jwtUtils;
    }

    // ── 登录 ──────────────────────────────────────────────────────────────────

    @Override
    public TechLoginVO login(TechLoginDTO dto) {
        CbTechnician tech = loadByAccount(dto.getLoginType(), dto.getAccount(), dto.getMerchantId());
        checkAuditStatus(tech);
        checkAccountStatus(tech);
        verifyPassword(dto.getPassword(), tech.getPassword());
        String token     = generateToken(tech, dto.getLang());
        long   expiresAt = Instant.now().getEpochSecond() + 7 * 24 * 3600L;
        return TechLoginVO.of(token, expiresAt, tech);
    }

    // ── 注册 ──────────────────────────────────────────────────────────────────

    @Override
    public void register(TechRegisterDTO dto) {
        CbMerchant merchant = validateMerchant(dto.getMerchantNo());
        // 同一商户内手机号唯一（多租户：不同商户允许同号注册）
        checkMobileUnique(dto.getMobile(), merchant.getId());

        CbTechnician tech = buildNewTechnician(dto, merchant.getId());
        technicianMapper.insert(tech);
    }

    // ── 当前登录技师信息 ───────────────────────────────────────────────────────

    @Override
    public CbTechnician me() {
        Long techId = MemberContext.getMemberId();
        if (techId == null) throw new BusinessException(CbCodeEnum.TOKEN_INVALID);
        CbTechnician tech = technicianMapper.selectById(techId);
        if (tech == null) throw new BusinessException(CbCodeEnum.TECHNICIAN_NOT_FOUND);
        return tech;
    }

    // ── private helpers ───────────────────────────────────────────────────────

    /**
     * 按「登录类型 + 账号 + 商户ID」联合查询技师
     *
     * <p>多租户隔离在 SQL 层完成，一次查询同时满足：
     * <ul>
     *   <li>技师编号/手机号匹配</li>
     *   <li>必须归属于当前商户（merchant_id = ?），防止跨商户登录</li>
     * </ul>
     */
    private CbTechnician loadByAccount(String loginType, String account, Long merchantId) {
        var query = Wrappers.<CbTechnician>lambdaQuery().eq(CbTechnician::getMerchantId, merchantId);
        if ("techId".equals(loginType)) {
            query.eq(CbTechnician::getTechNo, account);
        } else {
            query.eq(CbTechnician::getMobile, account);
        }
        CbTechnician tech = technicianMapper.selectOne(query);
        if (tech == null) throw new BusinessException(CbCodeEnum.TECHNICIAN_NOT_FOUND);
        return tech;
    }

    /**
     * 审核状态校验
     *
     * <ul>
     *   <li>0 / null = 待审核 → {@code TECHNICIAN_AUDIT_PENDING}</li>
     *   <li>2        = 拒绝   → {@code TECHNICIAN_AUDIT_REJECTED}</li>
     *   <li>1        = 通过   → 继续后续校验</li>
     * </ul>
     */
    private void checkAuditStatus(CbTechnician tech) {
        int auditStatus = tech.getAuditStatus() != null ? tech.getAuditStatus() : 0;
        switch (auditStatus) {
            case AUDIT_PASS -> { /* 通过，继续 */ }
            case 2          -> throw new BusinessException(CbCodeEnum.TECHNICIAN_AUDIT_REJECTED);
            default         -> throw new BusinessException(CbCodeEnum.TECHNICIAN_AUDIT_PENDING);
        }
    }

    /**
     * 账号启用状态校验
     *
     * <p>status=2（停用）→ {@code TECHNICIAN_BANNED}，前端展示"账号已被停用，请联系商户处理"
     */
    private void checkAccountStatus(CbTechnician tech) {
        if (tech.getStatus() == null || tech.getStatus() != STATUS_OK) {
            throw new BusinessException(CbCodeEnum.TECHNICIAN_BANNED);
        }
    }

    /**
     * MD5 密码验证
     *
     * <p>密码错误与账号不存在使用同一错误码 {@code TECHNICIAN_NOT_FOUND}，
     * 防止账号枚举攻击，同时保持前端提示信息一致。
     */
    private void verifyPassword(String rawPassword, String storedPassword) {
        String md5 = DigestUtils.md5DigestAsHex(rawPassword.getBytes(StandardCharsets.UTF_8));
        if (storedPassword == null || !md5.equals(storedPassword)) {
            throw new BusinessException(CbCodeEnum.TECHNICIAN_NOT_FOUND);
        }
    }

    /**
     * 校验商户编号
     *
     * <p>商户须存在（deleted=0）、状态正常（status=1）、审核通过（audit_status=1）
     */
    private CbMerchant validateMerchant(String merchantNo) {
        CbMerchant merchant = merchantMapper.selectOne(Wrappers.<CbMerchant>lambdaQuery()
                .eq(CbMerchant::getMerchantNo, merchantNo));

        if (merchant == null
                || !Integer.valueOf(1).equals(merchant.getStatus())
                || !Integer.valueOf(1).equals(merchant.getAuditStatus())) {
            throw new BusinessException(CbCodeEnum.MERCHANT_NO_INVALID);
        }
        return merchant;
    }

    /** 同一商户内手机号唯一性校验 */
    private void checkMobileUnique(String mobile, Long merchantId) {
        Long count = technicianMapper.selectCount(Wrappers.<CbTechnician>lambdaQuery()
                .eq(CbTechnician::getMobile, mobile)
                .eq(CbTechnician::getMerchantId, merchantId));
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
        tech.setPassword(DigestUtils.md5DigestAsHex(
                dto.getPassword().getBytes(StandardCharsets.UTF_8)));
        tech.setRealName(dto.getRealName());
        tech.setNickname(dto.getNickname() != null ? dto.getNickname() : dto.getRealName());
        tech.setMerchantId(merchantId);
        tech.setLang(dto.getLang() != null ? dto.getLang() : "zh");
        tech.setStatus(STATUS_OK);           // 账号正常，等待审核
        tech.setAuditStatus(0);              // 待审核
        tech.setOnlineStatus(0);             // 默认离线
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
