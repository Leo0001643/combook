package com.cambook.app.controller.admin;

import com.cambook.common.annotation.RequirePermission;
import com.cambook.app.domain.dto.TechnicianAuditDTO;
import com.cambook.app.domain.dto.TechnicianCreateDTO;
import com.cambook.app.domain.dto.TechnicianQueryDTO;
import com.cambook.app.domain.dto.TechnicianUpdateDTO;
import com.cambook.app.domain.vo.TechnicianVO;
import com.cambook.app.service.admin.IAdminTechnicianService;
import com.cambook.common.result.PageResult;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.http.MediaType;

/**
 * Admin 端 - 技师管理
 *
 * @author CamBook
 */
@Tag(name = "Admin - 技师管理")
@RestController("adminTechnicianController")
@RequestMapping("/admin/technician")
public class TechnicianController {

    private final IAdminTechnicianService technicianService;

    public TechnicianController(IAdminTechnicianService technicianService) {
        this.technicianService = technicianService;
    }

    @RequirePermission("technician:list")
    @Operation(summary = "分页查询技师列表")
    @GetMapping(value = "/list", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<PageResult<TechnicianVO>> pageList(@Valid @ModelAttribute TechnicianQueryDTO query) {
        return Result.success(technicianService.pageList(query));
    }

    @RequirePermission("technician:detail")
    @Operation(summary = "技师详情")
    @GetMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<TechnicianVO> detail(@PathVariable Long id) {
        return Result.success(technicianService.getDetail(id));
    }

    @RequirePermission("technician:edit")
    @Operation(summary = "后台新增技师")
    @PostMapping(value = "/create", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<TechnicianVO> create(@Valid @ModelAttribute TechnicianCreateDTO dto) {
        return Result.success(technicianService.create(dto));
    }

    @RequirePermission("technician:edit")
    @Operation(summary = "编辑技师信息")
    @PutMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> update(@Valid @ModelAttribute TechnicianUpdateDTO dto) {
        technicianService.update(dto);
        return Result.success();
    }

    @RequirePermission("technician:audit")
    @Operation(summary = "技师审核（通过/拒绝）")
    @PostMapping(value = "/audit", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> audit(@Valid @ModelAttribute TechnicianAuditDTO dto) {
        technicianService.audit(dto);
        return Result.success();
    }

    @RequirePermission("technician:edit")
    @Operation(summary = "启用/停用技师账号")
    @PatchMapping(value = "/{id}/status", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> updateStatus(@PathVariable Long id, @Parameter(description = "状态：0停用 1启用") @RequestParam @Min(0) @Max(1) int status) {
        technicianService.updateStatus(id, status);
        return Result.success();
    }

    @RequirePermission("technician:edit")
    @Operation(summary = "设置在线状态")
    @PostMapping(value = "/{id}/online-status", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> updateOnlineStatus(@PathVariable Long id, @Parameter(description = "在线状态：0离线 1在线 2服务中") @RequestParam @Min(0) @Max(2) int onlineStatus) {
        technicianService.updateOnlineStatus(id, onlineStatus);
        return Result.success();
    }

    @RequirePermission("technician:edit")
    @Operation(summary = "设置/取消推荐技师")
    @PatchMapping(value = "/{id}/featured", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> setFeatured(@PathVariable Long id, @Parameter(description = "是否推荐：0否 1是") @RequestParam @Min(0) @Max(1) int featured) {
        technicianService.setFeatured(id, featured);
        return Result.success();
    }

    @RequirePermission("technician:delete")
    @Operation(summary = "删除技师（软删除）")
    @DeleteMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> delete(@PathVariable Long id) {
        technicianService.delete(id);
        return Result.success();
    }

    @RequirePermission("technician:manage")
    @Operation(summary = "强制技师下线", description = "使该技师所有在线 Token 立即失效，技师端下次请求将收到 TOKEN_INVALID 错误，须重新登录")
    @PostMapping(value = "/{id}/force-logout", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> forceLogout(@PathVariable Long id) {
        technicianService.forceLogout(id);
        return Result.success();
    }
}
