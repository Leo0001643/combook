package com.cambook.app.controller.admin;

import com.cambook.common.annotation.RequirePermission;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.io.File;
import java.lang.management.*;
import java.util.*;

/**
 * Admin 端 - 服务器监控（JVM + OS + 磁盘）
 */
@Tag(name = "Admin - 系统监控 - 服务器监控")
@RestController
@RequestMapping("/admin/monitor/server")
public class ServerMonitorController {

    @RequirePermission("monitor:server:list")
    @Operation(summary = "获取服务器状态信息")
    @GetMapping("/info")
    public Result<Map<String, Object>> serverInfo() {
        Map<String, Object> data = new LinkedHashMap<>();

        // ── JVM 信息 ──────────────────────────────────────────────────────────
        Runtime rt = Runtime.getRuntime();
        long totalMem  = rt.totalMemory();
        long freeMem   = rt.freeMemory();
        long usedMem   = totalMem - freeMem;
        long maxMem    = rt.maxMemory();

        Map<String, Object> jvm = new LinkedHashMap<>();
        jvm.put("name",            System.getProperty("java.vm.name"));
        jvm.put("version",         System.getProperty("java.version"));
        jvm.put("totalMemoryMB",   toMB(totalMem));
        jvm.put("usedMemoryMB",    toMB(usedMem));
        jvm.put("freeMemoryMB",    toMB(freeMem));
        jvm.put("maxMemoryMB",     toMB(maxMem));
        jvm.put("usedPercent",     percent(usedMem, maxMem));
        jvm.put("processors",      rt.availableProcessors());
        jvm.put("startTime",       ManagementFactory.getRuntimeMXBean().getStartTime());
        jvm.put("upTimeMs",        ManagementFactory.getRuntimeMXBean().getUptime());
        data.put("jvm", jvm);

        // ── 操作系统信息 ──────────────────────────────────────────────────────
        OperatingSystemMXBean osMx = ManagementFactory.getOperatingSystemMXBean();
        Map<String, Object> os = new LinkedHashMap<>();
        os.put("name",      osMx.getName());
        os.put("version",   osMx.getVersion());
        os.put("arch",      osMx.getArch());
        os.put("processors", osMx.getAvailableProcessors());
        os.put("cpuLoad",   formatPercent(osMx.getSystemLoadAverage()));
        if (osMx instanceof com.sun.management.OperatingSystemMXBean sunOs) {
            long totalPhys = sunOs.getTotalMemorySize();
            long freePhys  = sunOs.getFreeMemorySize();
            os.put("totalMemoryGB", toGB(totalPhys));
            os.put("freeMemoryGB",  toGB(freePhys));
            os.put("usedMemoryGB",  toGB(totalPhys - freePhys));
            os.put("memUsedPercent", percent(totalPhys - freePhys, totalPhys));
            os.put("cpuUsedPercent", formatPercent(sunOs.getCpuLoad() * 100));
        }
        data.put("os", os);

        // ── 磁盘信息 ──────────────────────────────────────────────────────────
        List<Map<String, Object>> disks = new ArrayList<>();
        for (File root : File.listRoots()) {
            Map<String, Object> disk = new LinkedHashMap<>();
            disk.put("path",        root.getAbsolutePath());
            disk.put("totalGB",     toGB(root.getTotalSpace()));
            disk.put("freeGB",      toGB(root.getFreeSpace()));
            disk.put("usedGB",      toGB(root.getTotalSpace() - root.getFreeSpace()));
            disk.put("usedPercent", percent(root.getTotalSpace() - root.getFreeSpace(), root.getTotalSpace()));
            disks.add(disk);
        }
        data.put("disks", disks);

        // ── GC 信息 ───────────────────────────────────────────────────────────
        List<Map<String, Object>> gcList = new ArrayList<>();
        for (GarbageCollectorMXBean gc : ManagementFactory.getGarbageCollectorMXBeans()) {
            Map<String, Object> gcInfo = new LinkedHashMap<>();
            gcInfo.put("name",    gc.getName());
            gcInfo.put("count",   gc.getCollectionCount());
            gcInfo.put("timeMs",  gc.getCollectionTime());
            gcList.add(gcInfo);
        }
        data.put("gc", gcList);

        // ── 线程信息 ───────────────────────────────────────────────────────────
        ThreadMXBean threadMx = ManagementFactory.getThreadMXBean();
        Map<String, Object> thread = new LinkedHashMap<>();
        thread.put("total",   threadMx.getThreadCount());
        thread.put("daemon",  threadMx.getDaemonThreadCount());
        thread.put("peak",    threadMx.getPeakThreadCount());
        data.put("thread", thread);

        return Result.success(data);
    }

    private static double toMB(long bytes) {
        return Math.round(bytes / 1024.0 / 1024.0 * 10) / 10.0;
    }

    private static double toGB(long bytes) {
        return Math.round(bytes / 1024.0 / 1024.0 / 1024.0 * 100) / 100.0;
    }

    private static double percent(long used, long total) {
        if (total == 0) return 0.0;
        return Math.round(used * 100.0 / total * 10) / 10.0;
    }

    private static double formatPercent(double v) {
        if (v < 0) return 0.0;
        return Math.round(v * 10) / 10.0;
    }
}
