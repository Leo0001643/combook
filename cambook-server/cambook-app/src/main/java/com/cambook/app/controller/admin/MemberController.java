package com.cambook.app.controller.admin;

import com.cambook.common.annotation.RequirePermission;
import com.cambook.app.domain.dto.MemberQueryDTO;
import com.cambook.app.domain.dto.MemberStatusDTO;
import com.cambook.app.domain.dto.MemberUpdateDTO;
import com.cambook.app.domain.vo.MemberVO;
import com.cambook.app.service.admin.IAdminMemberService;
import com.cambook.common.result.PageResult;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Admin 端 - 会员管理
 *
 * @author CamBook
 */
@Tag(name = "Admin - 会员管理")
@RestController("adminMemberController")
@RequestMapping("/admin/member")
public class MemberController {

    private final IAdminMemberService memberService;

    public MemberController(IAdminMemberService memberService) {
        this.memberService = memberService;
    }

    @RequirePermission("member:list")
    @Operation(summary = "分页查询会员列表")
    @GetMapping("/list")
    public Result<PageResult<MemberVO>> pageList(@Valid @ModelAttribute MemberQueryDTO query) {
        return Result.success(memberService.pageList(query));
    }

    @RequirePermission("member:detail")
    @Operation(summary = "查看会员详情")
    @GetMapping("/{id}")
    public Result<MemberVO> detail(@PathVariable Long id) {
        return Result.success(memberService.getDetail(id));
    }

    @RequirePermission("member:edit")
    @Operation(summary = "编辑会员信息")
    @PutMapping
    public Result<Void> update(@Valid @ModelAttribute MemberUpdateDTO dto) {
        memberService.update(dto);
        return Result.success();
    }

    @RequirePermission("member:status")
    @Operation(summary = "修改会员状态")
    @PatchMapping("/{id}/status")
    public Result<Void> updateStatus(@PathVariable Long id, @Valid @ModelAttribute MemberStatusDTO dto) {
        memberService.updateStatus(id, dto);
        return Result.success();
    }
}
