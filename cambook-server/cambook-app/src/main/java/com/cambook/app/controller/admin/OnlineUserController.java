package com.cambook.app.controller.admin;

import com.cambook.app.domain.vo.OnlineUserVO;
import com.cambook.app.service.admin.impl.OnlineSessionService;
import com.cambook.common.annotation.RequirePermission;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.apache.commons.lang3.StringUtils;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Admin 端 - 在线用户管理
 */
@Tag(name = "Admin - 系统监控 - 在线用户")
@RestController
@RequestMapping("/admin/monitor/online")
public class OnlineUserController {

    private final OnlineSessionService sessionService;

    public OnlineUserController(OnlineSessionService sessionService) {
        this.sessionService = sessionService;
    }

    @RequirePermission("monitor:online:list")
    @Operation(summary = "在线用户列表")
    @GetMapping("/list")
    public Result<List<OnlineUserVO>> list(
            @RequestParam(required = false) String username) {
        List<OnlineUserVO> all = sessionService.listAll();
        if (StringUtils.isNotBlank(username)) {
            all = all.stream()
                    .filter(u -> u.getUsername() != null && u.getUsername().contains(username))
                    .collect(Collectors.toList());
        }
        return Result.success(all);
    }

    @RequirePermission("monitor:online:forceLogout")
    @Operation(summary = "强制退出在线用户")
    @DeleteMapping("/{sessionId}")
    public Result<Void> forceLogout(@PathVariable String sessionId) {
        sessionService.removeSession(sessionId);
        return Result.success();
    }
}
