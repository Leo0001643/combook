package com.cambook.app.common.statemachine;

import lombok.Getter;

/**
 * 技师在线状态枚举
 *
 * <p>状态码与数据库 {@code cb_technician.online_status} 字段完全对齐：
 * <pre>
 *   0  离线     OFFLINE  （技师未上线/下班）
 *   1  在线     ONLINE   （已上线，可接收新订单）
 *   2  服务中   SERVING  （正在为客户提供服务，暂不接新单）
 * </pre>
 *
 * @author CamBook
 */
@Getter
public enum TechnicianOnlineStatus {

    OFFLINE(0, "离线"),
    ONLINE (1, "在线"),
    SERVING(2, "服务中");

    private final int    code;
    private final String desc;

    TechnicianOnlineStatus(int code, String desc) {
        this.code = code;
        this.desc = desc;
    }

    /** Returns the code as {@code byte} for entity fields typed {@code Byte}. */
    public byte byteCode() { return (byte) code; }
}
