package com.cambook.app.controller.merchant;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.cambook.app.common.annotation.RequireMerchant;
import com.cambook.app.domain.dto.MerchantLoginDTO;
import com.cambook.app.domain.vo.LoginVO;
import com.cambook.app.domain.vo.PermissionVO;
import com.cambook.app.service.merchant.IMerchantMenuService;
import com.cambook.common.context.MerchantContext;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.Result;
import com.cambook.common.utils.JwtUtils;
import com.cambook.dao.entity.*;
import com.cambook.dao.mapper.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.util.DigestUtils;
import org.springframework.web.bind.annotation.*;

import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 商户端认证接口
 *
 * @author CamBook
 */
@Tag(name = "商户端 - 认证")
@RestController
@RequestMapping("/merchant/auth")
public class MerchantAuthController {

    private final CbMerchantMapper      merchantMapper;
    private final CbMerchantStaffMapper staffMapper;
    private final SysPositionMapper     positionMapper;
    private final SysDeptMapper         deptMapper;
    private final IMerchantMenuService  merchantMenuService;
    private final JwtUtils              jwtUtils;

    public MerchantAuthController(CbMerchantMapper merchantMapper,
                                  CbMerchantStaffMapper staffMapper,
                                  SysPositionMapper positionMapper,
                                  SysDeptMapper deptMapper,
                                  IMerchantMenuService merchantMenuService,
                                  JwtUtils jwtUtils) {
        this.merchantMapper     = merchantMapper;
        this.staffMapper        = staffMapper;
        this.positionMapper     = positionMapper;
        this.deptMapper         = deptMapper;
        this.merchantMenuService = merchantMenuService;
        this.jwtUtils           = jwtUtils;
    }

    /**
     * 商户端统一登录入口（多租户安全版）
     *
     * <h3>登录路径</h3>
     * <ol>
     *   <li><b>商户主账号</b>：无需填写商户编号，直接用手机号/用户名登录。
     *       商户主手机号在 {@code cb_merchant} 表全局唯一，无歧义。</li>
     *   <li><b>员工账号</b>：<b>必须</b>填写商户编号（{@code merchantNo}），
     *       系统据此锁定所属商户后再做账号匹配，彻底杜绝跨商户身份混淆。</li>
     * </ol>
     *
     * <h3>多商户数据隔离保证</h3>
     * 员工 JWT 中 {@code uid} = 所属商户 ID（非员工自身 ID）。
     * 所有后续请求通过 {@link MerchantContext#getMerchantId()} 过滤数据，
     * A 商户员工 Token 永远无法读写 B 商户任何数据。
     */
    @Operation(summary = "商户登录", description = "商户主账号或员工账号均可登录；员工账号须填写商户编号")
    @PostMapping("/login")
    public Result<LoginVO> login(@Valid MerchantLoginDTO dto) {
        String encPwd    = DigestUtils.md5DigestAsHex(dto.getPassword().getBytes(StandardCharsets.UTF_8));
        boolean hasMerchantNo = dto.getMerchantNo() != null && !dto.getMerchantNo().isBlank();

        // ── 路径 1：提供了商户编号 → 员工账号登录 ──────────────────────────────
        if (hasMerchantNo) {
            // 第一步：通过商户编号精确定位商户，防止跨商户混淆（核心安全保证）
            CbMerchant employer = merchantMapper.selectOne(
                    Wrappers.<CbMerchant>lambdaQuery()
                            .eq(CbMerchant::getMerchantNo, dto.getMerchantNo().trim())
                            .last("LIMIT 1"));
            if (employer == null) {
                throw new BusinessException("商户编号不存在，请确认后重试");
            }
            if (employer.getAuditStatus() == null || employer.getAuditStatus() != 1) {
                throw new BusinessException("所属商户尚未审核通过，请等待平台审核");
            }
            if (employer.getStatus() != null && employer.getStatus() == 0) {
                throw new BusinessException("所属商户已被停用，请联系平台管理员");
            }

            // 第二步：在该商户范围内查找员工，杜绝跨商户用户名冲突
            CbMerchantStaff staff = staffMapper.selectOne(
                    Wrappers.<CbMerchantStaff>lambdaQuery()
                            .eq(CbMerchantStaff::getMerchantId, employer.getId())
                            .and(q -> q.eq(CbMerchantStaff::getMobile,   dto.getAccount())
                                       .or()
                                       .eq(CbMerchantStaff::getUsername, dto.getAccount()))
                            .last("LIMIT 1"));
            if (staff == null) {
                throw new BusinessException("该商户下未找到此账号，请检查商户编号或账号是否正确");
            }
            if (!encPwd.equals(staff.getPassword())) {
                throw new BusinessException("密码错误");
            }
            if (staff.getStatus() == null || staff.getStatus() != 1) {
                throw new BusinessException("账号已停用，请联系商户管理员");
            }

            // uid = 商户 ID（不是员工 ID），保证数据隔离
            Map<String, Object> claims = new HashMap<>();
            claims.put("uid",          employer.getId());
            claims.put("merchantName", employer.getMerchantNameZh());
            claims.put("mobile",       staff.getMobile() != null ? staff.getMobile() : staff.getUsername());
            claims.put("userType",     "merchant");
            claims.put("staffId",      staff.getId());

            String token      = jwtUtils.generateToken(claims);
            long   expiresAt  = System.currentTimeMillis() / 1000 + 604800L;
            String displayName = staff.getRealName() != null ? staff.getRealName() : staff.getUsername();

            LoginVO vo = LoginVO.of(token, expiresAt, "merchant", employer.getId(), false);
            vo.setMerchantName(employer.getMerchantNameZh());
            vo.setMerchantLogo(employer.getLogo());
            vo.setMerchantMobile(employer.getMobile());
            vo.setStaffName(displayName);
            vo.setStaff(true);
            return Result.success(vo);
        }

        // ── 路径 2：未提供商户编号 → 仅允许商户主账号登录 ──────────────────────
        // 商户主手机号在 cb_merchant 全局唯一，无需商户编号即可精确定位
        CbMerchant merchant = merchantMapper.selectOne(
                Wrappers.<CbMerchant>lambdaQuery()
                        .and(q -> q.eq(CbMerchant::getMobile,   dto.getAccount())
                                   .or()
                                   .eq(CbMerchant::getUsername, dto.getAccount()))
                        .last("LIMIT 1"));

        if (merchant == null) {
            throw new BusinessException("账号不存在；若您是员工账号，请同时填写商户编号");
        }
        if (!encPwd.equals(merchant.getPassword())) {
            throw new BusinessException("密码错误");
        }
        if (merchant.getAuditStatus() == null || merchant.getAuditStatus() != 1) {
            throw new BusinessException("商户账号尚未审核通过，请等待平台审核");
        }
        if (merchant.getStatus() != null && merchant.getStatus() == 0) {
            throw new BusinessException(CbCodeEnum.ACCOUNT_BANNED);
        }

        Map<String, Object> claims = new HashMap<>();
        claims.put("uid",          merchant.getId());
        claims.put("merchantName", merchant.getMerchantNameZh());
        claims.put("mobile",       merchant.getMobile());
        claims.put("userType",     "merchant");
        // staffId 不写入 → null = 商户主身份，享有全量权限

        String token    = jwtUtils.generateToken(claims);
        long   expiresAt = System.currentTimeMillis() / 1000 + 604800L;

        LoginVO vo = LoginVO.of(token, expiresAt, "merchant", merchant.getId(), false);
        vo.setMerchantName(merchant.getMerchantNameZh());
        vo.setMerchantLogo(merchant.getLogo());
        vo.setMerchantMobile(merchant.getMobile());
        return Result.success(vo);
    }

    /**
     * 获取当前登录用户信息（含职位、部门）
     * 商户主账号登录时返回商户名/商户手机；员工账号登录时返回职位和部门。
     */
    @Operation(summary = "当前登录信息")
    @RequireMerchant
    @GetMapping("/me")
    public Result<Map<String, Object>> me() {
        Long   merchantId = MerchantContext.getMerchantId();
        String mobile     = MerchantContext.getMobile();

        Map<String, Object> info = new HashMap<>();
        info.put("mobile", mobile);

        CbMerchantStaff staff = resolveCurrentStaff();

        if (staff != null) {
            info.put("username",     staff.getUsername() != null ? staff.getUsername() : mobile);
            info.put("realName",     staff.getRealName());
            info.put("isStaff",      true);
            if (staff.getPositionId() != null) {
                SysPosition pos = positionMapper.selectById(staff.getPositionId());
                info.put("positionName", pos != null ? pos.getName() : null);
            }
            if (staff.getDeptId() != null) {
                SysDept dept = deptMapper.selectById(staff.getDeptId());
                info.put("deptName", dept != null ? dept.getName() : null);
            }
        } else {
            CbMerchant merchant = merchantMapper.selectById(merchantId);
            info.put("username",     merchant != null ? merchant.getMobile() : mobile);
            info.put("realName",     merchant != null ? merchant.getMerchantNameZh() : null);
            info.put("positionName", "商户主");
            info.put("deptName",     merchant != null ? merchant.getMerchantNameZh() : null);
            info.put("isStaff",      false);
        }

        return Result.success(info);
    }

    /**
     * 获取当前登录商户/员工的有效菜单树（用于侧边栏动态渲染）
     *
     * <p>RBAC 链解析委托给 {@link IMerchantMenuService}，Controller 保持轻薄。
     */
    @Operation(summary = "获取当前用户商户端菜单树")
    @RequireMerchant
    @GetMapping("/menus")
    public Result<List<PermissionVO>> menus() {
        CbMerchantStaff staff = resolveCurrentStaff();
        return Result.success(merchantMenuService.buildMenuTree(
                merchantMenuService.resolveEffectivePaths(MerchantContext.getMerchantId(), staff)));
    }

    /**
     * 获取当前登录商户/员工的操作权限码列表（用于前端 PermGuard 按钮级权限控制）
     *
     * <p>商户主账号返回 {@code ["*"]}（全量）；员工按 RBAC 链返回已分配的操作码。
     */
    @Operation(summary = "获取当前用户操作权限码列表")
    @RequireMerchant
    @GetMapping("/perm-codes")
    public Result<List<String>> permCodes() {
        CbMerchantStaff staff = resolveCurrentStaff();
        return Result.success(merchantMenuService.resolveEffectiveCodes(MerchantContext.getMerchantId(), staff));
    }

    /**
     * 解析当前请求的员工身份。
     *
     * <p>优先用 JWT 中的 {@code staffId} 精确定位员工记录（员工账号登录时有效）；
     * 若 staffId 不存在（商户主账号）则返回 {@code null}，上层服务按全量权限处理。
     * 兼容性兜底：staffId 不存在时尝试用手机号查找，支持旧版 Token。
     */
    private CbMerchantStaff resolveCurrentStaff() {
        Long merchantId = MerchantContext.getMerchantId();
        Long staffId    = MerchantContext.getStaffId();

        // 员工 JWT：staffId 非空，直接按主键查；同时校验归属防止越权
        if (staffId != null) {
            CbMerchantStaff s = staffMapper.selectById(staffId);
            if (s != null && merchantId.equals(s.getMerchantId())) return s;
        }

        // 商户主 JWT 或旧版 Token 兼容：尝试手机号匹配
        String mobile = MerchantContext.getMobile();
        if (mobile != null) {
            CbMerchantStaff s = staffMapper.selectOne(
                    Wrappers.<CbMerchantStaff>lambdaQuery()
                            .eq(CbMerchantStaff::getMerchantId, merchantId)
                            .eq(CbMerchantStaff::getMobile,     mobile)
                            .last("LIMIT 1"));
            if (s != null) return s;
        }

        // 返回 null = 商户主身份，享有全量权限
        return null;
    }
}
