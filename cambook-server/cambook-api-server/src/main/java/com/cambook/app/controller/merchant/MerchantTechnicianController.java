package com.cambook.app.controller.merchant;

import com.cambook.app.common.annotation.RequireMerchant;
import com.cambook.app.common.security.MerchantOwnershipGuard;
import com.cambook.app.domain.dto.TechnicianCreateDTO;
import com.cambook.app.domain.dto.TechnicianQueryDTO;
import com.cambook.app.domain.dto.TechnicianUpdateDTO;
import com.cambook.app.domain.vo.TechnicianVO;
import com.cambook.app.service.admin.IAdminTechnicianService;
import com.cambook.common.result.PageResult;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;
import org.springframework.http.MediaType;

/**
 * 商户端 - 技师管理（薄包装层）
 *
 * <p>复用 {@link IAdminTechnicianService}，所有写操作强制注入当前商户 ID 并执行
 * 行级安全（IDOR 防护），查询操作通过 merchantId 范围隔离数据。
 * {@code @RequireMerchant} 切面自动完成身份 + URI 双重安全校验。
 *
 * @author CamBook
 */
@RequireMerchant
@Tag(name = "商户端 - 技师管理")
@RestController
@RequestMapping("/merchant/technician")
public class MerchantTechnicianController {

    private final IAdminTechnicianService technicianService;

    public MerchantTechnicianController(IAdminTechnicianService technicianService) {
        this.technicianService = technicianService;
    }

    @Operation(summary = "技师列表")
    @GetMapping(value = "/list", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<PageResult<TechnicianVO>> list(TechnicianQueryDTO query) {
        query.setMerchantId(MerchantOwnershipGuard.requireMerchantId());
        return Result.success(technicianService.pageList(query));
    }

    @Operation(summary = "技师详情")
    @GetMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<TechnicianVO> detail(@PathVariable Long id) {
        TechnicianVO vo = technicianService.getDetail(id);
        MerchantOwnershipGuard.assertOwnership(vo.getMerchantId(), "技师", id);
        return Result.success(vo);
    }

    @Operation(summary = "新增技师")
    @PostMapping(value = "/create", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<TechnicianVO> create(@Valid @ModelAttribute TechnicianCreateDTO dto) {
        // merchantId 强制来自 JWT，忽略客户端传入值
        dto.setMerchantId(MerchantOwnershipGuard.requireMerchantId());
        return Result.success(technicianService.create(dto));
    }

    @Operation(summary = "编辑技师信息")
    @PutMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> update(@Valid @ModelAttribute TechnicianUpdateDTO dto) {
        TechnicianVO vo = technicianService.getDetail(dto.getId());
        MerchantOwnershipGuard.assertOwnership(vo.getMerchantId(), "技师", dto.getId());
        technicianService.update(dto);
        return Result.success();
    }

    @Operation(summary = "启用 / 停用技师")
    @PostMapping(value = "/{id}/status", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> updateStatus(
            @PathVariable Long id,
            @RequestParam @Min(0) @Max(1) int status) {
        TechnicianVO vo = technicianService.getDetail(id);
        MerchantOwnershipGuard.assertOwnership(vo.getMerchantId(), "技师", id);
        technicianService.updateStatus(id, status);
        return Result.success();
    }

    @Operation(summary = "设置在线状态（0离线 1在线）")
    @PostMapping(value = "/{id}/online-status", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> updateOnlineStatus(
            @PathVariable Long id,
            @RequestParam @Min(0) @Max(2) int onlineStatus) {
        TechnicianVO vo = technicianService.getDetail(id);
        MerchantOwnershipGuard.assertOwnership(vo.getMerchantId(), "技师", id);
        technicianService.updateOnlineStatus(id, onlineStatus);
        return Result.success();
    }

    @Operation(summary = "设置 / 取消推荐技师")
    @PostMapping(value = "/{id}/featured", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> setFeatured(
            @PathVariable Long id,
            @RequestParam @Min(0) @Max(1) int featured) {
        TechnicianVO vo = technicianService.getDetail(id);
        MerchantOwnershipGuard.assertOwnership(vo.getMerchantId(), "技师", id);
        technicianService.setFeatured(id, featured);
        return Result.success();
    }

    @Operation(summary = "删除技师")
    @PostMapping(value = "/{id}/delete", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> delete(@PathVariable Long id) {
        TechnicianVO vo = technicianService.getDetail(id);
        MerchantOwnershipGuard.assertOwnership(vo.getMerchantId(), "技师", id);
        technicianService.delete(id);
        return Result.success();
    }
}
