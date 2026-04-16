package com.cambook.app.controller.admin;

import com.cambook.common.context.AdminContext;
import com.cambook.app.domain.dto.AdminLoginDTO;
import com.cambook.app.domain.vo.LoginVO;
import com.cambook.app.domain.vo.PermissionVO;
import com.cambook.app.service.admin.IAdminAuthService;
import com.cambook.app.service.admin.IPermissionService;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Admin 端 - 管理员认证
 *
 * @author CamBook
 */
@Tag(name = "Admin - 认证")
@RestController
@RequestMapping("/admin/auth")
public class AdminAuthController {

    private final IAdminAuthService  adminAuthService;
    private final IPermissionService permissionService;

    public AdminAuthController(IAdminAuthService adminAuthService,
                               IPermissionService permissionService) {
        this.adminAuthService  = adminAuthService;
        this.permissionService = permissionService;
    }

    @Operation(summary = "管理员账号密码登录")
    @PostMapping("/login")
    public Result<LoginVO> login(@Valid @ModelAttribute AdminLoginDTO dto) {
        return Result.success(adminAuthService.login(dto));
    }

    @Operation(summary = "退出登录")
    @PostMapping("/logout")
    public Result<Void> logout() {
        adminAuthService.logout();
        return Result.success();
    }

    /**
     * 获取当前登录管理员的动态菜单树
     * <p>前端侧边栏根据此接口动态渲染菜单，SUPER_ADMIN 返回全量，普通角色按权限过滤。
     */
    @Operation(summary = "获取当前用户菜单树（动态菜单）")
    @GetMapping("/menus")
    public Result<List<PermissionVO>> menus() {
        Long userId = AdminContext.getUserId();
        return Result.success(permissionService.getMenuTreeByUserId(userId));
    }
}
