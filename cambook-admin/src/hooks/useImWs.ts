import { useEffect, useRef, useCallback, useState } from 'react'
import { useAuthStore } from '../store/authStore'
import { useImStore } from '../store/imStore'
import type { ImMessageVO } from '../api/api'
import { ImCmd } from './imTypes'
import type { ImPacket, CallSignal } from './imTypes'

export type { ImPacket }

const WS_URL = import.meta.env.VITE_IM_WS_URL ?? 'ws://localhost:9090/ws/im'
const RECONNECT_DELAY_MS    = 3000
const HEARTBEAT_INTERVAL_MS = 30000

/** 信令事件回调，由 useVoiceCall 注入 */
export type SignalHandler = (cmd: number, signal: CallSignal) => void

// 全局信令回调注册表（单例）
let _signalHandler: SignalHandler | null = null
export const registerSignalHandler  = (fn: SignalHandler) => { _signalHandler = fn }
export const unregisterSignalHandler = ()                   => { _signalHandler = null }

const SIGNALING_CMDS = new Set([
  ImCmd.CALL_INVITE, ImCmd.CALL_ACCEPT, ImCmd.CALL_REJECT,
  ImCmd.CALL_ICE, ImCmd.CALL_SDP, ImCmd.CALL_END, ImCmd.CALL_BUSY,
])

/**
 * IM WebSocket 连接 Hook（全局单例，只在 MainLayout 调用一次）
 *
 * 负责：心跳、重连、消息分发、信令透传给 useVoiceCall。
 */
export function useImWs(_unused?: unknown) {
  const { accessToken, isLoggedIn } = useAuthStore()
  const { appendMessage, updateMessageStatus } = useImStore()

  const wsRef        = useRef<WebSocket | null>(null)
  const retryRef     = useRef<ReturnType<typeof setTimeout> | null>(null)
  const heartbeatRef = useRef<ReturnType<typeof setInterval> | null>(null)
  const mountedRef   = useRef(true)
  const [connected, setConnected] = useState(false)

  // ── 发送数据包 ────────────────────────────────────────────────────────────
  const send = useCallback((packet: ImPacket) => {
    if (wsRef.current?.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify(packet))
    }
  }, [])

  // ── 心跳 ──────────────────────────────────────────────────────────────────
  const startHeartbeat = useCallback(() => {
    stopHeartbeat()
    heartbeatRef.current = setInterval(() => {
      send({ cmd: ImCmd.PING, seq: String(Date.now()) })
    }, HEARTBEAT_INTERVAL_MS)
  }, [send])

  const stopHeartbeat = useCallback(() => {
    if (heartbeatRef.current) clearInterval(heartbeatRef.current)
    heartbeatRef.current = null
  }, [])

  // ── 消息分发 ──────────────────────────────────────────────────────────────
  const handlePacket = useCallback((packet: ImPacket) => {
    if (packet.cmd === ImCmd.PONG) return

    // 信令包 → 转给 useVoiceCall
    if (SIGNALING_CMDS.has(packet.cmd)) {
      if (packet.body && _signalHandler) {
        _signalHandler(packet.cmd, packet.body as unknown as CallSignal)
      }
      return
    }

    if (packet.cmd === ImCmd.MSG_NOTIFY || packet.cmd === ImCmd.GROUP_NOTIFY) {
      if (!packet.payload) return
      try {
        const data = JSON.parse(packet.payload)
        const msg: ImMessageVO = {
          msgId:          data.msgId,
          conversationId: data.conversationId,
          senderType:     data.senderType,
          senderId:       data.senderId,
          isGroup:        packet.cmd === ImCmd.GROUP_NOTIFY ? 1 : 0,
          groupId:        data.groupId,
          msgType:        data.msgType ?? 1,
          content:        data.content ?? '',
          status:         data.status ?? 1,
          createTime:     data.createTime ?? Math.floor(Date.now() / 1000),
        }
        appendMessage(msg)
        send({
          cmd:     packet.cmd === ImCmd.GROUP_NOTIFY ? ImCmd.GROUP_ACK : ImCmd.MSG_ACK,
          seq:     packet.seq,
          payload: JSON.stringify({ msgId: msg.msgId }),
        })
      } catch (e) {
        console.warn('[IM] 消息解析失败', e)
      }
    } else if (packet.cmd === ImCmd.MSG_DELIVERED) {
      if (!packet.payload) return
      try {
        const data = JSON.parse(packet.payload)
        if (data.msgId && data.status) updateMessageStatus(data.msgId, data.status)
      } catch { /* ignore */ }
    }
  }, [appendMessage, updateMessageStatus, send])

  // ── 连接 ──────────────────────────────────────────────────────────────────
  const connect = useCallback(() => {
    if (!mountedRef.current || !accessToken) return
    try {
      const ws = new WebSocket(`${WS_URL}?token=${encodeURIComponent(accessToken)}`)
      wsRef.current = ws
      ws.onopen    = () => { setConnected(true); startHeartbeat() }
      ws.onmessage = (e) => {
        try { handlePacket(JSON.parse(e.data)) } catch { /* ignore */ }
      }
      ws.onclose = (e) => {
        setConnected(false); stopHeartbeat()
        if (mountedRef.current && isLoggedIn)
          retryRef.current = setTimeout(connect, RECONNECT_DELAY_MS)
      }
      ws.onerror = () => ws.close()
    } catch (e) {
      if (mountedRef.current) retryRef.current = setTimeout(connect, RECONNECT_DELAY_MS)
    }
  }, [accessToken, isLoggedIn, startHeartbeat, stopHeartbeat, handlePacket])

  useEffect(() => {
    mountedRef.current = true
    if (isLoggedIn && accessToken) connect()
    return () => {
      mountedRef.current = false
      stopHeartbeat()
      if (retryRef.current) clearTimeout(retryRef.current)
      wsRef.current?.close()
    }
  }, [isLoggedIn, accessToken]) // eslint-disable-line react-hooks/exhaustive-deps

  return { send, connected }
}
