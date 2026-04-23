package com.cambook.app.controller.technician;

import com.cambook.app.domain.dto.TechLoginDTO;
import com.cambook.app.domain.dto.TechRegisterDTO;
import com.cambook.app.domain.vo.TechLoginVO;
import com.cambook.app.service.technician.ITechnicianAuthService;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 技师端 - 认证（登录 / 注册 / 我的信息）
 *
 * <p>路径前缀 {@code /tech/auth}，由 AuthFilter 注入 MemberContext（userType=technician）。
 * 登录 / 注册接口无需鉴权；{@code /me} 须携带有效 Token。
 *
 * @author CamBook
 */
@Tag(name = "技师端 - 认证")
@RestController
@RequestMapping("/tech/auth")
public class TechnicianAuthController {

    private final ITechnicianAuthService authService;

    public TechnicianAuthController(ITechnicianAuthService authService) {
        this.authService = authService;
    }

    // ── 登录 ──────────────────────────────────────────────────────────────────

    @Operation(
        summary  = "技师登录",
        description = """
            支持两种方式：
            - **loginType=techId**：技师编号 + 密码
            - **loginType=phone** ：手机号（国际格式）+ 密码

            登录前置校验（任意不满足均返回对应错误码）：
            1. 账号存在（逻辑删除自动过滤）
            2. 审核状态 = 1（通过）
            3. 账号状态 = 1（正常）
            4. 密码正确（BCrypt）
            """
    )
    @PostMapping("/login")
    public Result<TechLoginVO> login(@Valid @ModelAttribute TechLoginDTO dto) {
        return Result.success(authService.login(dto));
    }

    // ── 注册 ──────────────────────────────────────────────────────────────────

    @Operation(
        summary  = "技师注册",
        description = """
            注册校验规则：
            1. 商户编号必须合法（对应商户存在且状态正常、审核通过）
            2. 手机号在技师表中唯一
            3. 注册成功后账号处于「待审核」状态，平台审核通过后方可登录
            """
    )
    @PostMapping("/register")
    public Result<Void> register(@Valid @ModelAttribute TechRegisterDTO dto) {
        authService.register(dto);
        return Result.success();
    }

    // ── 当前登录信息 ──────────────────────────────────────────────────────────

    @Operation(summary = "获取当前登录技师信息", description = "需要携带有效的技师 JWT Token")
    @GetMapping("/me")
    public Result<TechLoginVO> me() {
        com.cambook.dao.entity.CbTechnician tech = authService.me();
        // 不重新签发 Token，复用当前 Token 信息仅返回最新资料
        TechLoginVO vo = TechLoginVO.of(null, 0, tech);
        return Result.success(vo);
    }
}
