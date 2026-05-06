package com.cambook.app.controller.app;

import com.cambook.app.domain.dto.MemberProfileDTO;
import com.cambook.app.domain.vo.MemberVO;
import com.cambook.app.domain.vo.WalletVO;
import com.cambook.app.service.app.IAppMemberService;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.http.MediaType;

/**
 * App 端 - 会员个人中心
 *
 * @author CamBook
 */
@Tag(name = "App - 会员中心")
@RestController("appMemberController")
@RequestMapping("/app/member")
public class MemberController {

    private final IAppMemberService memberService;

    public MemberController(IAppMemberService memberService) {
        this.memberService = memberService;
    }

    @Operation(summary = "获取当前会员信息")
    @GetMapping(value = "/profile", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<MemberVO> profile() {
        return Result.success(memberService.getMyProfile());
    }

    @Operation(summary = "修改个人资料")
    @PutMapping(value = "/profile", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> updateProfile(@Valid @ModelAttribute MemberProfileDTO dto) {
        memberService.updateProfile(dto);
        return Result.success();
    }

    @Operation(summary = "获取钱包余额")
    @GetMapping(value = "/wallet", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<WalletVO> wallet() {
        return Result.success(memberService.getWallet());
    }
}
