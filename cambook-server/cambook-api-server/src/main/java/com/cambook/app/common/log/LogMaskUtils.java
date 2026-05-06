package com.cambook.app.common.log;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.fasterxml.jackson.databind.node.TextNode;

import java.util.Set;

/**
 * 日志敏感字段脱敏工具
 *
 * <p>在 JSON 序列化结果中，将密码、验证码、Token 等敏感字段的值替换为 {@code ****}，
 * 防止明文凭据出现在日志文件中。
 *
 * @author CamBook
 */
public final class LogMaskUtils {

    /** 需要脱敏的字段名集合（全小写匹配） */
    private static final Set<String> SENSITIVE_KEYS = Set.of(
            "password", "passwd", "pwd",
            "smscode", "sms_code", "verifycode", "verify_code", "captcha",
            "token", "accesstoken", "access_token", "refreshtoken", "refresh_token",
            "secret", "privatekey", "private_key",
            "idcard", "id_card",
            "bankcard", "bank_card", "bankcardno", "bank_card_no",
            "cvv", "paymentpassword", "payment_password"
    );

    private static final String MASK = "****";
    private static final ObjectMapper MAPPER = new ObjectMapper();

    private LogMaskUtils() {}

    /**
     * 对 JSON 字符串进行脱敏处理
     *
     * @param json 原始 JSON 字符串
     * @return 脱敏后的 JSON 字符串（解析失败则原样返回）
     */
    public static String mask(String json) {
        if (json == null || json.isBlank()) return json;
        try {
            JsonNode node = MAPPER.readTree(json);
            maskNode(node);
            return MAPPER.writeValueAsString(node);
        } catch (Exception e) {
            return json;
        }
    }

    /**
     * 将任意对象序列化为 JSON 字符串并脱敏
     */
    public static String toMaskedJson(Object obj) {
        if (obj == null) return "null";
        try {
            String json = MAPPER.writeValueAsString(obj);
            return mask(json);
        } catch (Exception e) {
            return obj.toString();
        }
    }

    // ── 私有递归遍历 ──────────────────────────────────────────────────────────

    private static void maskNode(JsonNode node) {
        if (node == null || node.isNull()) return;
        if (node.isObject()) {
            ObjectNode obj = (ObjectNode) node;
            obj.fields().forEachRemaining(entry -> {
                if (SENSITIVE_KEYS.contains(entry.getKey().toLowerCase())) {
                    obj.set(entry.getKey(), TextNode.valueOf(MASK));
                } else {
                    maskNode(entry.getValue());
                }
            });
        } else if (node.isArray()) {
            node.forEach(LogMaskUtils::maskNode);
        }
    }
}
