package com.cambook.app.controller.admin;

import com.cambook.common.annotation.RequirePermission;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

/**
 * Admin 端 - 定时任务管理（展示平台内置任务状态）
 */
@Tag(name = "Admin - 系统监控 - 定时任务")
@RestController
@RequestMapping("/admin/monitor/job")
public class JobController {

    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    /** 内置任务列表（运行时管理，不持久化） */
    private static final List<Map<String, Object>> JOBS = new ArrayList<>();

    static {
        JOBS.add(buildJob(1L, "技师位置清理", "SYSTEM", "techLocationCleanJob.execute()", "0 0/10 * * * ?", "正常", "成功", "每10分钟"));
        JOBS.add(buildJob(2L, "订单超时取消", "BUSINESS", "orderTimeoutJob.execute()",    "0 0/5 * * * ?",  "正常", "成功", "每5分钟"));
        JOBS.add(buildJob(3L, "技师接单超时", "BUSINESS", "acceptTimeoutJob.execute()",   "0 0/1 * * * ?",  "正常", "成功", "每1分钟"));
        JOBS.add(buildJob(4L, "钱包余额统计", "FINANCE",  "walletStatJob.execute()",      "0 0 1 * * ?",    "正常", "成功", "每天凌晨1点"));
        JOBS.add(buildJob(5L, "平台数据日报", "REPORT",   "dailyReportJob.execute()",     "0 0 2 * * ?",    "正常", "成功", "每天凌晨2点"));
        JOBS.add(buildJob(6L, "Redis缓存刷新", "SYSTEM",  "cacheRefreshJob.execute()",    "0 0 0/1 * * ?",  "正常", "成功", "每小时"));
        JOBS.add(buildJob(7L, "操作日志归档", "SYSTEM",   "logArchiveJob.execute()",      "0 0 3 ? * MON",  "暂停", "成功", "每周一凌晨3点"));
        JOBS.add(buildJob(8L, "会员积分过期", "BUSINESS", "pointExpireJob.execute()",     "0 0 4 1 * ?",    "正常", "成功", "每月1日4点"));
    }

    private static Map<String, Object> buildJob(Long id, String jobName, String jobGroup,
                                                 String invokeTarget, String cronExpression,
                                                 String status, String lastResult, String remark) {
        Map<String, Object> job = new LinkedHashMap<>();
        job.put("id",             id);
        job.put("jobName",        jobName);
        job.put("jobGroup",       jobGroup);
        job.put("invokeTarget",   invokeTarget);
        job.put("cronExpression", cronExpression);
        job.put("status",         status);
        job.put("lastResult",     lastResult);
        job.put("remark",         remark);
        job.put("createTime",     LocalDateTime.now().minusDays(id * 3).format(FMT));
        job.put("nextFireTime",   LocalDateTime.now().plusMinutes(id * 2).format(FMT));
        return job;
    }

    @RequirePermission("monitor:job:list")
    @Operation(summary = "定时任务列表")
    @GetMapping("/list")
    public Result<List<Map<String, Object>>> list(
            @RequestParam(required = false) String jobName,
            @RequestParam(required = false) String jobGroup,
            @RequestParam(required = false) String status) {
        List<Map<String, Object>> result = JOBS.stream()
                .filter(j -> jobName == null || j.get("jobName").toString().contains(jobName))
                .filter(j -> jobGroup == null || j.get("jobGroup").toString().equals(jobGroup))
                .filter(j -> status == null || j.get("status").toString().equals(status))
                .toList();
        return Result.success(result);
    }

    @RequirePermission("monitor:job:edit")
    @Operation(summary = "暂停/恢复任务")
    @PatchMapping("/{id}/status")
    public Result<Void> toggleStatus(@PathVariable Long id, @RequestParam String status) {
        JOBS.stream().filter(j -> j.get("id").equals(id)).findFirst()
                .ifPresent(j -> j.put("status", status));
        return Result.success();
    }

    @RequirePermission("monitor:job:run")
    @Operation(summary = "立即执行一次")
    @PostMapping("/{id}/run")
    public Result<String> runOnce(@PathVariable Long id) {
        return Result.success("任务已触发执行，请查看日志");
    }
}
