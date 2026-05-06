package com.cambook.app.controller.admin;

import com.cambook.common.annotation.RequirePermission;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import org.springframework.http.MediaType;

/**
 * Admin 端 - 缓存监控（Redis 统计信息）
 */
@Tag(name = "Admin - 系统监控 - 缓存监控")
@RestController
@RequestMapping("/admin/monitor/cache")
public class CacheMonitorController {

    private final StringRedisTemplate redis;

    public CacheMonitorController(StringRedisTemplate redis) {
        this.redis = redis;
    }

    @RequirePermission("monitor:cache:list")
    @Operation(summary = "Redis 缓存统计信息")
    @GetMapping(value = "/info", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Map<String, Object>> cacheInfo() {
        Map<String, Object> data = new LinkedHashMap<>();

        try {
            Properties info = redis.getConnectionFactory().getConnection().serverCommands().info();
            Map<String, String> serverInfo = new LinkedHashMap<>();
            if (info != null) {
                addIfPresent(serverInfo, info, "redis_version");
                addIfPresent(serverInfo, info, "redis_mode");
                addIfPresent(serverInfo, info, "os");
                addIfPresent(serverInfo, info, "uptime_in_days");
                addIfPresent(serverInfo, info, "tcp_port");
                addIfPresent(serverInfo, info, "executable");
            }
            data.put("server", serverInfo);

            Map<String, String> statsInfo = new LinkedHashMap<>();
            if (info != null) {
                addIfPresent(statsInfo, info, "connected_clients");
                addIfPresent(statsInfo, info, "blocked_clients");
                addIfPresent(statsInfo, info, "total_commands_processed");
                addIfPresent(statsInfo, info, "instantaneous_ops_per_sec");
                addIfPresent(statsInfo, info, "total_connections_received");
                addIfPresent(statsInfo, info, "keyspace_hits");
                addIfPresent(statsInfo, info, "keyspace_misses");
            }
            data.put("stats", statsInfo);

            Map<String, Object> memInfo = new LinkedHashMap<>();
            if (info != null) {
                String usedMem = info.getProperty("used_memory_human");
                String peakMem = info.getProperty("used_memory_peak_human");
                String maxMem  = info.getProperty("maxmemory_human");
                memInfo.put("usedMemory",     usedMem != null ? usedMem : "N/A");
                memInfo.put("peakMemory",     peakMem != null ? peakMem : "N/A");
                memInfo.put("maxMemory",      maxMem  != null && !"0B".equals(maxMem) ? maxMem : "无限制");
                addIfPresent(memInfo, info,   "mem_fragmentation_ratio");
            }
            data.put("memory", memInfo);

            // 各前缀 Key 数量
            List<Map<String, Object>> keyStats = new ArrayList<>();
            String[] prefixes = { "cb:online:admin:", "cb:admin:perms:", "cb:admin:roles:",
                                   "cb:token:black:", "cb:sms:", "cb:tech:location:", "cb:order:lock:", "cb:config:" };
            for (String prefix : prefixes) {
                Set<String> keys = redis.keys(prefix + "*");
                Map<String, Object> ks = new LinkedHashMap<>();
                ks.put("prefix", prefix);
                ks.put("count", keys != null ? keys.size() : 0);
                keyStats.add(ks);
            }
            data.put("keyStats", keyStats);

            // 命中率
            if (info != null) {
                long hits   = parseLong(info.getProperty("keyspace_hits"));
                long misses = parseLong(info.getProperty("keyspace_misses"));
                long total  = hits + misses;
                data.put("hitRate", total > 0 ? Math.round(hits * 100.0 / total * 10) / 10.0 : 0.0);
            }

        } catch (Exception e) {
            data.put("error", "Redis 连接失败：" + e.getMessage());
        }

        return Result.success(data);
    }

    @RequirePermission("monitor:cache:delete")
    @Operation(summary = "清除指定前缀的缓存")
    @DeleteMapping(value = "/clear", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> clearCache(@RequestParam String prefix) {
        Set<String> keys = redis.keys(prefix + "*");
        if (!keys.isEmpty()) redis.delete(keys);
        return Result.success();
    }

    private void addIfPresent(Map<String, ?> map, Properties info, String key) {
        String val = info.getProperty(key);
        if (val != null) ((Map<String, Object>) map).put(key, val);
    }

    private long parseLong(String s) {
        try { return s == null ? 0L : Long.parseLong(s.trim()); }
        catch (NumberFormatException e) { return 0L; }
    }
}
