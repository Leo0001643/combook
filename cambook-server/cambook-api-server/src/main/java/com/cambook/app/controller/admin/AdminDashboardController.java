package com.cambook.app.controller.admin;

import com.cambook.app.service.admin.IAdminDashboardService;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * 超级管理员 — 全平台数据看板
 */
@Tag(name = "Admin - 平台数据看板")
@RestController
@RequestMapping(value = "/admin/dashboard", produces = MediaType.APPLICATION_JSON_VALUE)
@RequiredArgsConstructor
public class AdminDashboardController {

    private final IAdminDashboardService adminDashboardService;

    @Operation(summary = "全平台数据看板（period: day|week|month|year，非法值回退到 week）")
    @GetMapping(value = "/stats", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Map<String, Object>> stats(@RequestParam(defaultValue = "week") String period) {
        return Result.success(adminDashboardService.stats(period));
    }
}
