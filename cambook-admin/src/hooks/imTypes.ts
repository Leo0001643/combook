/**
 * IM 协议命令码（与后端 ImCmd.java 保持一致）
 */
export const ImCmd = {
  // ── 系统 ──
  PING:          1001,
  PONG:          1002,

  // ── 单聊 ──
  MSG_NOTIFY:    2002,
  MSG_ACK:       2003,
  MSG_DELIVERED: 2004,

  // ── 群聊 ──
  GROUP_NOTIFY:  3002,
  GROUP_ACK:     3003,

  // ── 离线 ──
  PULL_OFFLINE:  4001,

  // ── WebRTC 信令 ──
  CALL_INVITE:   5001,
  CALL_ACCEPT:   5002,
  CALL_REJECT:   5003,
  CALL_ICE:      5004,
  CALL_SDP:      5005,
  CALL_END:      5006,
  CALL_BUSY:     5007,
} as const

export type ImCmdType = typeof ImCmd[keyof typeof ImCmd]

export interface ImPacket {
  cmd: number
  seq: string
  payload?: string
  body?: Record<string, unknown>
}

/** 通话信令 payload */
export interface CallSignal {
  callId:     string
  targetType: string
  targetId:   number
  fromType:   string
  fromId:     number
  fromName?:  string
  /** SDP 字符串（CALL_SDP 时使用） */
  sdp?:       string
  sdpType?:   'offer' | 'answer'
  /** ICE Candidate JSON（CALL_ICE 时使用） */
  candidate?: string
}
