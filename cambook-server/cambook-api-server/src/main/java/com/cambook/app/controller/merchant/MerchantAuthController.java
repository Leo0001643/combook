package com.cambook.app.controller.merchant;

import com.cambook.app.common.annotation.RequireMerchant;
import com.cambook.app.domain.dto.MerchantLoginDTO;
import com.cambook.app.domain.vo.LoginVO;
import com.cambook.app.domain.vo.MerchantInfoVO;
import com.cambook.app.domain.vo.PermissionVO;
import com.cambook.app.service.merchant.IMerchantAuthService;
import com.cambook.app.service.merchant.IMerchantMenuService;
import com.cambook.common.context.MerchantContext;
import com.cambook.common.result.Result;
import com.cambook.db.entity.*;
import com.cambook.db.service.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 商户端认证接口
 */
@Tag(name = "商户端 - 认证")
@RestController
@RequestMapping(value = "/merchant/auth", produces = MediaType.APPLICATION_JSON_VALUE)
@RequiredArgsConstructor
public class MerchantAuthController {

    private final IMerchantAuthService merchantAuthService;
    private final IMerchantMenuService merchantMenuService;
    private final ICbMerchantService   cbMerchantService;
    private final ISysPositionService  sysPositionService;
    private final ISysDeptService      sysDeptService;

    @Operation(summary = "商户登录（主账号或员工账号；员工须填写商户编号）")
    @PostMapping(value = "/login", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<LoginVO> login(@Valid MerchantLoginDTO dto) {
        return Result.success(merchantAuthService.login(dto));
    }

    @Operation(summary = "当前登录用户信息（含职位、部门）")
    @RequireMerchant
    @GetMapping(value = "/me", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<MerchantInfoVO> me() {
        Long   merchantId = MerchantContext.getMerchantId();
        String mobile     = MerchantContext.getMobile();
        CbMerchantStaff staff = merchantAuthService.resolveCurrentStaff(merchantId, MerchantContext.getStaffId(), mobile);
        MerchantInfoVO vo = new MerchantInfoVO();
        vo.setMobile(mobile);
        if (staff != null) {
            vo.setUsername(staff.getUsername() != null ? staff.getUsername() : mobile);
            vo.setRealName(staff.getRealName()); vo.setStaff(true);
            if (staff.getPositionId() != null) {
                SysPosition pos = sysPositionService.getById(staff.getPositionId());
                vo.setPositionName(pos != null ? pos.getName() : null);
            }
            if (staff.getDeptId() != null) {
                SysDept dept = sysDeptService.getById(staff.getDeptId());
                vo.setDeptName(dept != null ? dept.getName() : null);
            }
        } else {
            CbMerchant merchant = cbMerchantService.getById(merchantId);
            vo.setUsername(merchant != null ? merchant.getMobile() : mobile);
            vo.setRealName(merchant != null ? merchant.getMerchantNameZh() : null);
            vo.setPositionName("商户主");
            vo.setDeptName(merchant != null ? merchant.getMerchantNameZh() : null);
            vo.setStaff(false);
        }
        return Result.success(vo);
    }

    @Operation(summary = "获取当前用户商户端菜单树")
    @RequireMerchant
    @GetMapping(value = "/menus", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<PermissionVO>> menus() {
        CbMerchantStaff staff = merchantAuthService.resolveCurrentStaff(MerchantContext.getMerchantId(), MerchantContext.getStaffId(), MerchantContext.getMobile());
        return Result.success(merchantMenuService.buildMenuTree(merchantMenuService.resolveEffectivePaths(MerchantContext.getMerchantId(), staff)));
    }

    @Operation(summary = "获取当前用户操作权限码列表")
    @RequireMerchant
    @GetMapping(value = "/perm-codes", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<String>> permCodes() {
        CbMerchantStaff staff = merchantAuthService.resolveCurrentStaff(MerchantContext.getMerchantId(), MerchantContext.getStaffId(), MerchantContext.getMobile());
        return Result.success(merchantMenuService.resolveEffectiveCodes(MerchantContext.getMerchantId(), staff));
    }
}
