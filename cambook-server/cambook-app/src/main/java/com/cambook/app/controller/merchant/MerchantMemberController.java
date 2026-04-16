package com.cambook.app.controller.merchant;

import com.cambook.app.common.annotation.RequireMerchant;
import com.cambook.app.common.security.MerchantOwnershipGuard;
import com.cambook.app.domain.dto.MemberQueryDTO;
import com.cambook.app.domain.vo.MemberVO;
import com.cambook.app.service.admin.IAdminMemberService;
import com.cambook.common.result.PageResult;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

/**
 * 商户端 - 会员管理（薄包装层）
 *
 * <p>复用 {@link IAdminMemberService}，注入 merchantId 后仅返回在该商户有过订单的会员。
 * {@code @RequireMerchant} 切面自动完成身份 + URI 双重安全校验。
 *
 * @author CamBook
 */
@RequireMerchant
@Tag(name = "商户端 - 会员管理")
@RestController
@RequestMapping("/merchant/member")
public class MerchantMemberController {

    private final IAdminMemberService memberService;

    public MerchantMemberController(IAdminMemberService memberService) {
        this.memberService = memberService;
    }

    @Operation(summary = "商户会员列表")
    @GetMapping("/list")
    public Result<PageResult<MemberVO>> list(MemberQueryDTO query) {
        query.setMerchantId(MerchantOwnershipGuard.requireMerchantId());
        return Result.success(memberService.pageList(query));
    }
}
