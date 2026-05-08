import { useEffect, useRef, useCallback, useState } from 'react'
import { useAuthStore } from '../store/authStore'
import { ImCmd } from './imTypes'
import type { CallSignal } from './imTypes'
import { registerSignalHandler, unregisterSignalHandler } from './useImWs'

// ── 类型 ──────────────────────────────────────────────────────────────────────

export type CallState =
  | 'idle'      // 无通话
  | 'calling'   // 主叫：等待对方接听
  | 'incoming'  // 被叫：收到来电
  | 'connecting'// 双方握手建立 WebRTC 连接中
  | 'active'    // 通话中（连接已建立）
  | 'ended'     // 已结束（短暂显示，1.5s 后回到 idle）

export interface CallPeer {
  userType: string
  userId:   number
  name:     string
}

export interface VoiceCallState {
  callState:  CallState
  peer:       CallPeer | null
  muted:      boolean
  duration:   number
  startCall:  (peer: CallPeer) => void
  acceptCall: () => void
  rejectCall: () => void
  hangUp:     () => void
  toggleMute: () => void
}

// ── STUN 服务器（内网测试用公共 STUN，生产替换为 TURN）────────────────────────
const ICE_SERVERS: RTCIceServer[] = [
  { urls: 'stun:stun.l.google.com:19302' },
  { urls: 'stun:stun1.l.google.com:19302' },
]

// ── Hook ──────────────────────────────────────────────────────────────────────

/**
 * 语音通话 Hook（WebRTC P2P + IM 信令）
 *
 * 设计要点：
 *  - 用 callStateRef 镜像 callState，避免异步信令回调读到过期快照
 *  - PC 生命周期与 React render 解耦，所有清理走 cleanup()
 *  - 信令全部通过现有 IM WS 透传，无需额外连接
 */
export function useVoiceCall(
  send: (p: { cmd: number; seq: string; body?: Record<string, unknown> }) => void
): VoiceCallState {
  const { user, merchant, isMerchant } = useAuthStore()
  const myType = isMerchant ? (merchant?.staffId ? 'staff' : 'merchant') : 'admin'
  const myId   = isMerchant ? (merchant?.staffId ?? merchant?.merchantId ?? 0) : (user?.userId ?? 0)
  const myName = isMerchant ? (merchant?.merchantName ?? '商户') : (user?.username ?? '管理员')

  const [callState, setCallState_] = useState<CallState>('idle')
  const [peer,      setPeer]       = useState<CallPeer | null>(null)
  const [muted,     setMuted]      = useState(false)
  const [duration,  setDuration]   = useState(0)

  // Ref 镜像：所有异步回调（信令/WebRTC 事件）均通过 ref 读取最新状态，消除竞态
  const callStateRef  = useRef<CallState>('idle')
  const peerRef       = useRef<CallPeer | null>(null)
  const mountedRef    = useRef(true)

  const pcRef          = useRef<RTCPeerConnection | null>(null)
  const localStream    = useRef<MediaStream | null>(null)
  const callIdRef      = useRef('')
  const timerRef       = useRef<ReturnType<typeof setInterval> | null>(null)
  const pendingIce     = useRef<RTCIceCandidateInit[]>([])
  const remoteDescSet  = useRef(false)

  // 同步更新 state + ref
  const setCallState = useCallback((s: CallState) => {
    callStateRef.current = s
    if (mountedRef.current) setCallState_(s)
  }, [])

  useEffect(() => {
    mountedRef.current = true
    return () => { mountedRef.current = false }
  }, [])

  // ── 计时器 ────────────────────────────────────────────────────────────────

  const startTimer = useCallback(() => {
    if (timerRef.current) return
    timerRef.current = setInterval(() => {
      if (mountedRef.current) setDuration(d => d + 1)
    }, 1000)
  }, [])

  const stopTimer = useCallback(() => {
    if (timerRef.current) { clearInterval(timerRef.current); timerRef.current = null }
    if (mountedRef.current) setDuration(0)
  }, [])

  // ── 清理（任何终止路径的统一出口）───────────────────────────────────────

  const cleanup = useCallback((next: CallState = 'idle') => {
    stopTimer()
    localStream.current?.getTracks().forEach(t => t.stop())
    localStream.current = null
    pcRef.current?.close()
    pcRef.current = null
    remoteDescSet.current = false
    pendingIce.current = []
    peerRef.current = null
    if (mountedRef.current) setPeer(null)
    if (mountedRef.current) setMuted(false)
    setCallState(next)
    if (next === 'ended') {
      setTimeout(() => { if (mountedRef.current) setCallState('idle') }, 1500)
    }
  }, [setCallState, stopTimer])

  // ── 信令发送 ──────────────────────────────────────────────────────────────

  const sendSignal = useCallback((cmd: number, extra: Partial<CallSignal> = {}) => {
    const p = peerRef.current
    if (!p && !extra.targetType) return
    const body: CallSignal = {
      callId:     callIdRef.current,
      fromType:   myType,
      fromId:     myId as number,
      fromName:   myName,
      targetType: extra.targetType ?? p!.userType,
      targetId:   extra.targetId   ?? p!.userId,
      ...extra,
    }
    send({ cmd, seq: `sig-${Date.now()}`, body: body as unknown as Record<string, unknown> })
  }, [send, myType, myId, myName])

  // ── PeerConnection 工厂 ───────────────────────────────────────────────────

  const createPc = useCallback((targetPeer: CallPeer) => {
    if (pcRef.current) { pcRef.current.close() }
    const pc = new RTCPeerConnection({ iceServers: ICE_SERVERS })
    pcRef.current = pc
    remoteDescSet.current = false
    pendingIce.current = []

    pc.onicecandidate = (e) => {
      if (e.candidate) {
        sendSignal(ImCmd.CALL_ICE, {
          candidate:  JSON.stringify(e.candidate),
          targetType: targetPeer.userType,
          targetId:   targetPeer.userId,
        })
      }
    }

    pc.ontrack = (e) => {
      const audio = new Audio()
      audio.srcObject = e.streams[0]
      audio.autoplay  = true
    }

    pc.onconnectionstatechange = () => {
      if (pc.connectionState === 'connected') {
        setCallState('active')
        startTimer()
      } else if (['disconnected', 'failed', 'closed'].includes(pc.connectionState)) {
        if (callStateRef.current !== 'idle' && callStateRef.current !== 'ended') {
          cleanup('ended')
        }
      }
    }

    return pc
  }, [sendSignal, setCallState, startTimer, cleanup])

  // ── ICE 候选缓冲 ─────────────────────────────────────────────────────────

  const applyPendingIce = useCallback(async () => {
    const pc = pcRef.current
    if (!pc) return
    for (const c of pendingIce.current) {
      try { await pc.addIceCandidate(new RTCIceCandidate(c)) } catch { /* ignore stale */ }
    }
    pendingIce.current = []
  }, [])

  // ── 信令接收处理（用 ref 读状态，永不过期）───────────────────────────────

  const onSignal = useCallback(async (cmd: number, signal: CallSignal) => {
    const state = callStateRef.current   // 始终读最新值

    switch (cmd) {

      case ImCmd.CALL_INVITE: {
        if (state !== 'idle') {
          // 忙线回绝
          send({ cmd: ImCmd.CALL_BUSY, seq: `sig-${Date.now()}`,
            body: { callId: signal.callId, targetType: signal.fromType,
                    targetId: signal.fromId, fromType: myType, fromId: myId } as unknown as Record<string, unknown> })
          return
        }
        callIdRef.current = signal.callId
        const p = { userType: signal.fromType, userId: signal.fromId, name: signal.fromName ?? '对方' }
        peerRef.current = p
        if (mountedRef.current) setPeer(p)
        setCallState('incoming')
        break
      }

      case ImCmd.CALL_ACCEPT: {
        if (state !== 'calling' || !pcRef.current) return
        setCallState('connecting')
        try {
          const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
          localStream.current = stream
          stream.getTracks().forEach(t => pcRef.current!.addTrack(t, stream))
          const offer = await pcRef.current.createOffer({ offerToReceiveAudio: true })
          await pcRef.current.setLocalDescription(offer)
          sendSignal(ImCmd.CALL_SDP, { sdp: offer.sdp, sdpType: 'offer' })
        } catch (e) {
          console.error('[Call] 获取麦克风失败', e)
          cleanup('ended')
        }
        break
      }

      case ImCmd.CALL_SDP: {
        const pc = pcRef.current
        if (!pc || !signal.sdp || !signal.sdpType) return
        try {
          await pc.setRemoteDescription(new RTCSessionDescription({ type: signal.sdpType, sdp: signal.sdp }))
          remoteDescSet.current = true
          await applyPendingIce()
          if (signal.sdpType === 'offer') {
            const answer = await pc.createAnswer()
            await pc.setLocalDescription(answer)
            sendSignal(ImCmd.CALL_SDP, { sdp: answer.sdp, sdpType: 'answer' })
          }
        } catch (e) {
          console.error('[Call] SDP 处理失败', e)
          cleanup('ended')
        }
        break
      }

      case ImCmd.CALL_ICE: {
        if (!signal.candidate) return
        try {
          const cand = JSON.parse(signal.candidate) as RTCIceCandidateInit
          if (remoteDescSet.current && pcRef.current) {
            await pcRef.current.addIceCandidate(new RTCIceCandidate(cand))
          } else {
            pendingIce.current.push(cand)
          }
        } catch { /* ignore */ }
        break
      }

      case ImCmd.CALL_REJECT:
      case ImCmd.CALL_END:
      case ImCmd.CALL_BUSY:
        cleanup('ended')
        break
    }
  }, [send, sendSignal, setCallState, applyPendingIce, cleanup, myType, myId])

  // 注册信令回调（仅在 onSignal 引用变化时重新注册）
  useEffect(() => {
    registerSignalHandler(onSignal)
    return () => unregisterSignalHandler()
  }, [onSignal])

  // ── 对外 API ──────────────────────────────────────────────────────────────

  const startCall = useCallback((targetPeer: CallPeer) => {
    if (callStateRef.current !== 'idle') return
    callIdRef.current = `call-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`
    peerRef.current = targetPeer
    setPeer(targetPeer)
    setCallState('calling')
    createPc(targetPeer)
    sendSignal(ImCmd.CALL_INVITE, { targetType: targetPeer.userType, targetId: targetPeer.userId })
  }, [createPc, sendSignal, setCallState])

  const acceptCall = useCallback(async () => {
    if (callStateRef.current !== 'incoming' || !peerRef.current) return
    setCallState('connecting')
    try {
      const pc     = createPc(peerRef.current)
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      localStream.current = stream
      stream.getTracks().forEach(t => pc.addTrack(t, stream))
      sendSignal(ImCmd.CALL_ACCEPT)
    } catch (e) {
      console.error('[Call] 获取麦克风失败', e)
      cleanup('ended')
    }
  }, [createPc, sendSignal, setCallState, cleanup])

  const rejectCall = useCallback(() => {
    if (callStateRef.current !== 'incoming') return
    sendSignal(ImCmd.CALL_REJECT)
    cleanup('idle')
  }, [sendSignal, cleanup])

  const hangUp = useCallback(() => {
    if (callStateRef.current === 'idle') return
    sendSignal(ImCmd.CALL_END)
    cleanup('ended')
  }, [sendSignal, cleanup])

  const toggleMute = useCallback(() => {
    if (!localStream.current) return
    const next = !muted
    localStream.current.getAudioTracks().forEach(t => { t.enabled = !next })
    setMuted(next)
  }, [muted])

  return { callState, peer, muted, duration, startCall, acceptCall, rejectCall, hangUp, toggleMute }
}
