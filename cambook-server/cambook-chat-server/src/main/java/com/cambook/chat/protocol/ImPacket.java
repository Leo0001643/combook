package com.cambook.chat.protocol;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * IM 通信协议包（JSON 编码）
 *
 * <p>WebSocket Text Frame 内容结构：
 * <pre>
 * {
 *   "cmd":    2001,            // 命令码，见 ImCmd
 *   "msgId":  "snowflake-id", // 消息唯一 ID（客户端生成或服务端生成）
 *   "seq":    12345,           // 客户端序列号（用于去重和有序）
 *   "ts":     1700000000000,   // 发送时间戳（ms）
 *   "body":   {...}            // 业务载体，不同 cmd 对应不同结构
 * }
 * </pre>
 */
@Data
@NoArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ImPacket {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    private int    cmd;
    private String msgId;
    private Long   seq;
    private long   ts;
    private Object body;

    // ── 工厂方法 ──────────────────────────────────────────────────────────────

    public static ImPacket of(int cmd, Object body) {
        ImPacket p = new ImPacket();
        p.cmd  = cmd;
        p.ts   = System.currentTimeMillis();
        p.body = body;
        return p;
    }

    public static ImPacket of(int cmd, String msgId, Object body) {
        ImPacket p = of(cmd, body);
        p.msgId = msgId;
        return p;
    }

    public static ImPacket pong() { return of(ImCmd.PONG, null); }

    public static ImPacket error(String message) { return of(ImCmd.ERROR, message); }

    public static ImPacket authOk(long userId, String userType) {
        return of(ImCmd.AUTH_RESULT, java.util.Map.of("ok", true, "userId", userId, "userType", userType));
    }

    public static ImPacket kick(String reason) { return of(ImCmd.KICK, reason); }

    // ── 序列化 ────────────────────────────────────────────────────────────────

    public String toJson() {
        try { return MAPPER.writeValueAsString(this); }
        catch (JsonProcessingException e) { throw new RuntimeException(e); }
    }

    public static ImPacket fromJson(String json) {
        try { return MAPPER.readValue(json, ImPacket.class); }
        catch (Exception e) { return null; }
    }

    public <T> T bodyAs(Class<T> type) {
        return MAPPER.convertValue(body, type);
    }
}
