package com.cambook.app.controller.app;

import com.cambook.app.domain.dto.LoginDTO;
import com.cambook.app.domain.dto.SmsDTO;
import com.cambook.app.domain.vo.LoginVO;
import com.cambook.app.service.app.IAuthService;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.http.MediaType;

/**
 * App 端 - 认证
 *
 * @author CamBook
 */
@Tag(name = "App - 认证")
@RestController
@RequestMapping("/app/auth")
public class AuthController {

    private final IAuthService authService;

    public AuthController(IAuthService authService) {
        this.authService = authService;
    }

    @Operation(summary = "发送短信验证码")
    @PostMapping(value = "/sms", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> sendSms(@Valid @ModelAttribute SmsDTO dto) {
        authService.sendSms(dto.getMobile());
        return Result.success();
    }

    @Operation(summary = "短信验证码登录 / 注册")
    @PostMapping(value = "/login", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<LoginVO> login(@Valid @ModelAttribute LoginDTO dto) {
        return Result.success(authService.login(dto));
    }
}
