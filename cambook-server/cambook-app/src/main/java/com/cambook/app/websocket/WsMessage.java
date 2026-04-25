package com.cambook.app.websocket;

/**
 * WebSocket 推送消息包装体。
 *
 * <p>消息格式：
 * <pre>{@code
 * { "type": "HOME_DATA", "data": { ... } }
 * { "type": "NEW_ORDER",  "data": { "orderId": 123, "orderNo": "..." } }
 * { "type": "PONG",       "data": null }
 * }</pre>
 */
public record WsMessage(String type, Object data) {

    public static final String HOME_DATA  = "HOME_DATA";
    public static final String NEW_ORDER  = "NEW_ORDER";
    public static final String PONG       = "PONG";

    public static WsMessage homeData(Object data) { return new WsMessage(HOME_DATA, data); }
    public static WsMessage newOrder(Object data) { return new WsMessage(NEW_ORDER, data); }
    public static WsMessage pong()               { return new WsMessage(PONG, null); }
}
