package com.cambook.common.i18n;

import com.cambook.common.enums.CbCodeEnum;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 国际化枚举消息加载器
 *
 * <p>系统启动后执行，从 sys_i18n 表读取所有枚举消息，
 * 通过枚举名反射匹配 {@link CbCodeEnum} 并注入多语言消息 Map。
 *
 * <p>设计优势：
 * <ul>
 *   <li>消息内容存库，无需重新部署即可修改文案</li>
 *   <li>枚举保留类型安全，避免魔法字符串</li>
 *   <li>使用 JdbcTemplate 直接查询，不依赖 MyBatis，避免循环依赖</li>
 * </ul>
 *
 * @author CamBook
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class I18nMessageLoader implements ApplicationRunner {

    private final JdbcTemplate jdbcTemplate;

    /** sys_i18n 中已存在枚举名的集合（用于校验缺失配置） */
    private static final java.util.Set<String> ENUM_NAMES =
            Arrays.stream(CbCodeEnum.values())
                  .map(Enum::name)
                  .collect(Collectors.toSet());

    @Override
    public void run(ApplicationArguments args) {
        log.info("[I18n] 开始加载国际化枚举消息...");

        List<Map<String, Object>> rows = jdbcTemplate.queryForList(
                "SELECT enum_code, lang, message FROM sys_i18n"
        );

        // 按 enum_code 聚合 → Map<enumCode, Map<lang, message>>
        Map<String, Map<String, String>> msgMap = new HashMap<>();
        for (Map<String, Object> row : rows) {
            String enumCode = (String) row.get("enum_code");
            String lang     = (String) row.get("lang");
            String message  = (String) row.get("message");
            msgMap.computeIfAbsent(enumCode, k -> new HashMap<>()).put(lang, message);
        }

        // 反射注入到枚举
        int loaded = 0;
        for (CbCodeEnum e : CbCodeEnum.values()) {
            Map<String, String> messages = msgMap.get(e.name());
            if (messages != null && !messages.isEmpty()) {
                e.setMessages(messages);
                loaded++;
            } else {
                log.warn("[I18n] 枚举 {} 在 sys_i18n 中无配置，消息降级为枚举名", e.name());
            }
        }

        // 反向校验：DB 中存在但 Enum 中不存在的配置（通常是历史残留）
        msgMap.keySet().stream()
              .filter(code -> !ENUM_NAMES.contains(code))
              .forEach(code -> log.warn("[I18n] sys_i18n 中存在冗余枚举配置: {}", code));

        log.info("[I18n] 国际化消息加载完成，共注入 {} 个枚举，总记录 {} 条", loaded, rows.size());
    }
}
