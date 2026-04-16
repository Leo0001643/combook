package com.cambook.driver.constant;

/**
 * 派车模块常量
 *
 * @author CamBook
 */
public final class DriverConst {

    private DriverConst() {}

    // ── 司机状态 ─────────────────────────────────────────────────────────────
    /** 审核中 */
    public static final int DRIVER_STATUS_PENDING  = 0;
    /** 在职 */
    public static final int DRIVER_STATUS_ACTIVE   = 1;
    /** 停职 */
    public static final int DRIVER_STATUS_INACTIVE = 2;

    // ── 在线状态 ─────────────────────────────────────────────────────────────
    /** 离线 */
    public static final int ONLINE_OFFLINE  = 0;
    /** 待命 */
    public static final int ONLINE_IDLE     = 1;
    /** 执行任务中 */
    public static final int ONLINE_BUSY     = 2;

    // ── 车辆状态 ─────────────────────────────────────────────────────────────
    /** 空闲 */
    public static final int VEHICLE_IDLE    = 0;
    /** 使用中 */
    public static final int VEHICLE_IN_USE  = 1;
    /** 维修中 */
    public static final int VEHICLE_REPAIR  = 2;

    // ── 派单状态 ─────────────────────────────────────────────────────────────
    /** 待接单 */
    public static final int DISPATCH_PENDING    = 0;
    /** 司机已接单 */
    public static final int DISPATCH_ACCEPTED   = 1;
    /** 前往接客 */
    public static final int DISPATCH_GOING      = 2;
    /** 已到达 */
    public static final int DISPATCH_ARRIVED    = 3;
    /** 服务中 */
    public static final int DISPATCH_SERVICING  = 4;
    /** 已完成 */
    public static final int DISPATCH_DONE       = 5;
    /** 已取消 */
    public static final int DISPATCH_CANCELLED  = 9;

    // ── 驾驶证类型 ───────────────────────────────────────────────────────────
    /** 柬埔寨驾照 */
    public static final String LICENSE_KH = "KH";
    /** 国际驾照 */
    public static final String LICENSE_INT = "INT";
}
