package com.cambook.chat.protocol;

/**
 * IM 协议命令码
 *
 * <p>约定：
 * <ul>
 *   <li>1xxx = 系统/心跳</li>
 *   <li>2xxx = 单聊消息</li>
 *   <li>3xxx = 群聊消息</li>
 *   <li>4xxx = 会话/离线</li>
 *   <li>5xxx = 媒体/信令</li>
 * </ul>
 */
public final class ImCmd {

    // ── 系统 ──────────────────────────────────────────────────────────────────
    public static final int PING           = 1001;
    public static final int PONG           = 1002;
    /** 鉴权（连接建立后客户端发送 JWT） */
    public static final int AUTH           = 1003;
    /** 鉴权结果 */
    public static final int AUTH_RESULT    = 1004;
    /** 服务端主动踢下线 */
    public static final int KICK           = 1005;
    /** 错误响应 */
    public static final int ERROR          = 1099;

    // ── 单聊 ──────────────────────────────────────────────────────────────────
    /** 客户端发送消息 */
    public static final int SEND_MSG       = 2001;
    /** 服务端推送新消息给接收方 */
    public static final int MSG_NOTIFY     = 2002;
    /** 客户端 ACK（已接收） */
    public static final int MSG_ACK        = 2003;
    /** 服务端通知发送方已送达 */
    public static final int MSG_DELIVERED  = 2004;
    /** 客户端标记已读 */
    public static final int MARK_READ      = 2005;
    /** 服务端通知发送方已读 */
    public static final int MSG_READ       = 2006;

    // ── 群聊 ──────────────────────────────────────────────────────────────────
    /** 客户端发送群消息 */
    public static final int GROUP_SEND     = 3001;
    /** 服务端推送群新消息 */
    public static final int GROUP_NOTIFY   = 3002;
    /** 群消息 ACK */
    public static final int GROUP_ACK      = 3003;

    // ── 会话/离线 ─────────────────────────────────────────────────────────────
    /** 拉取离线消息 */
    public static final int PULL_OFFLINE   = 4001;
    /** 离线消息响应 */
    public static final int OFFLINE_MSGS   = 4002;

    // ── WebRTC 信令 ───────────────────────────────────────────────────────────
    /** 发起通话邀请 */
    public static final int CALL_INVITE    = 5001;
    /** 接受通话 */
    public static final int CALL_ACCEPT    = 5002;
    /** 拒绝/挂断通话 */
    public static final int CALL_REJECT    = 5003;
    /** ICE Candidate 转发 */
    public static final int CALL_ICE       = 5004;
    /** SDP Offer/Answer 转发 */
    public static final int CALL_SDP       = 5005;
    /** 主动结束通话 */
    public static final int CALL_END       = 5006;
    /** 对方忙线 */
    public static final int CALL_BUSY      = 5007;

    /** 所有信令命令码（用于 Handler 注册批量匹配） */
    public static final java.util.Set<Integer> SIGNALING_CMDS = java.util.Set.of(
        CALL_INVITE, CALL_ACCEPT, CALL_REJECT, CALL_ICE, CALL_SDP, CALL_END, CALL_BUSY);

    private ImCmd() {}
}
