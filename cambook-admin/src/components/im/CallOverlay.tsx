import React, { useState, useRef, useEffect } from 'react'
import type { VoiceCallState } from '../../hooks/useVoiceCall'

const fmt = (s: number) => `${String(Math.floor(s / 60)).padStart(2, '0')}:${String(s % 60).padStart(2, '0')}`

// ── 颜色常量 ──────────────────────────────────────────────────────────────────
const C = {
  bg:      '#1a2533',
  surface: 'rgba(255,255,255,0.06)',
  border:  'rgba(255,255,255,0.1)',
  text:    '#e9edef',
  muted:   'rgba(255,255,255,0.5)',
  green:   '#25d366',
  red:     '#ef4444',
  orange:  '#f97316',
}

// ── 圆形操作按钮 ──────────────────────────────────────────────────────────────
function RoundBtn({ icon, label, bg, onClick }: {
  icon: React.ReactNode; label: string; bg: string; onClick: () => void
}) {
  return (
    <div onClick={onClick} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6, cursor: 'pointer' }}>
      <div style={{
        width: 54, height: 54, borderRadius: '50%', background: bg,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: `0 4px 16px ${bg}55`,
        transition: 'transform 0.15s',
      }}
        onMouseDown={e => (e.currentTarget.style.transform = 'scale(0.9)')}
        onMouseUp={e => (e.currentTarget.style.transform = 'scale(1)')}
        onMouseLeave={e => (e.currentTarget.style.transform = 'scale(1)')}
      >
        {icon}
      </div>
      <span style={{ fontSize: 11, color: C.muted, whiteSpace: 'nowrap' }}>{label}</span>
    </div>
  )
}

// ── 来电波纹动画头像 ──────────────────────────────────────────────────────────
function RingAvatar({ name }: { name: string }) {
  const initial = name[0]?.toUpperCase() ?? '?'
  return (
    <div style={{ position: 'relative', width: 90, height: 90, flexShrink: 0 }}>
      {/* 波纹层 */}
      {[1, 2, 3].map(i => (
        <div key={i} style={{
          position: 'absolute', inset: -(i * 14),
          borderRadius: '50%',
          border: `1.5px solid ${C.green}`,
          opacity: 0.35 / i,
          animation: `call-ring 1.8s ease-out ${i * 0.4}s infinite`,
        }} />
      ))}
      <div style={{
        width: 90, height: 90, borderRadius: '50%',
        background: `linear-gradient(135deg, #00a884, #007a63)`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 34, fontWeight: 700, color: '#fff',
        boxShadow: `0 0 0 3px ${C.green}55`,
        position: 'relative', zIndex: 1,
      }}>
        {initial}
      </div>
    </div>
  )
}

// ── 通话中头像（静止） ────────────────────────────────────────────────────────
function ActiveAvatar({ name }: { name: string }) {
  const initial = name[0]?.toUpperCase() ?? '?'
  return (
    <div style={{
      width: 72, height: 72, borderRadius: '50%',
      background: 'linear-gradient(135deg,#00a884,#007a63)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontSize: 28, fontWeight: 700, color: '#fff',
      boxShadow: '0 4px 24px rgba(0,168,132,0.4)',
    }}>
      {initial}
    </div>
  )
}

// ── 来电弹窗 ──────────────────────────────────────────────────────────────────
function IncomingModal({ vc }: { vc: VoiceCallState }) {
  return (
    <div style={{
      position: 'fixed', inset: 0, zIndex: 9000,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      background: 'rgba(0,0,0,0.65)', backdropFilter: 'blur(8px)',
      animation: 'call-fadein 0.25s ease',
    }}>
      <div style={{
        width: 320, borderRadius: 24,
        background: C.bg, border: `1px solid ${C.border}`,
        boxShadow: '0 24px 64px rgba(0,0,0,0.6)',
        padding: '40px 32px 36px',
        display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 20,
      }}>
        {/* 头像 + 波纹 */}
        <RingAvatar name={vc.peer?.name ?? '?'} />

        {/* 信息 */}
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: 20, fontWeight: 600, color: C.text, marginBottom: 6 }}>
            {vc.peer?.name ?? '未知用户'}
          </div>
          <div style={{ fontSize: 13, color: C.muted }}>语音通话邀请</div>
        </div>

        {/* 操作 */}
        <div style={{ display: 'flex', gap: 48, marginTop: 8 }}>
          <RoundBtn
            icon={<HangupIcon />}
            label="拒绝"
            bg={C.red}
            onClick={vc.rejectCall}
          />
          <RoundBtn
            icon={<PhoneIcon />}
            label="接听"
            bg={C.green}
            onClick={vc.acceptCall}
          />
        </div>
      </div>
    </div>
  )
}

// ── 发起中（等待接听）────────────────────────────────────────────────────────
function CallingModal({ vc }: { vc: VoiceCallState }) {
  const [dots, setDots] = useState('.')
  useEffect(() => {
    const t = setInterval(() => setDots(d => d.length >= 3 ? '.' : d + '.'), 600)
    return () => clearInterval(t)
  }, [])

  return (
    <div style={{
      position: 'fixed', inset: 0, zIndex: 9000,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      background: 'rgba(0,0,0,0.65)', backdropFilter: 'blur(8px)',
    }}>
      <div style={{
        width: 300, borderRadius: 24,
        background: C.bg, border: `1px solid ${C.border}`,
        boxShadow: '0 24px 64px rgba(0,0,0,0.6)',
        padding: '40px 32px 36px',
        display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 20,
      }}>
        <RingAvatar name={vc.peer?.name ?? '?'} />
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: 20, fontWeight: 600, color: C.text, marginBottom: 6 }}>
            {vc.peer?.name ?? '未知用户'}
          </div>
          <div style={{ fontSize: 13, color: C.muted }}>
            {vc.callState === 'connecting' ? `连接中${dots}` : `等待接听${dots}`}
          </div>
        </div>
        <RoundBtn icon={<HangupIcon />} label="取消" bg={C.red} onClick={vc.hangUp} />
      </div>
    </div>
  )
}

// ── 通话中悬浮窗（可拖拽）────────────────────────────────────────────────────
function ActiveOverlay({ vc }: { vc: VoiceCallState }) {
  const [pos, setPos] = useState({ x: window.innerWidth - 280 - 24, y: 80 })
  const dragging   = useRef(false)
  const dragStart  = useRef({ mx: 0, my: 0, px: 0, py: 0 })
  // 稳定引用，避免 addEventListener / removeEventListener 引用不一致
  const onMoveRef  = useRef<(e: MouseEvent) => void>(() => {})
  const onUpRef    = useRef<() => void>(() => {})

  useEffect(() => {
    onMoveRef.current = (e: MouseEvent) => {
      if (!dragging.current) return
      const { mx, my, px, py } = dragStart.current
      setPos({ x: px + e.clientX - mx, y: py + e.clientY - my })
    }
    onUpRef.current = () => {
      dragging.current = false
      window.removeEventListener('mousemove', onMoveRef.current)
      window.removeEventListener('mouseup',   onUpRef.current)
    }
  })

  // 组件卸载时确保清理 window 监听（防止拖动过程中通话结束导致泄漏）
  useEffect(() => {
    return () => {
      window.removeEventListener('mousemove', onMoveRef.current)
      window.removeEventListener('mouseup',   onUpRef.current)
    }
  }, [])

  const onDown = (e: React.MouseEvent) => {
    dragging.current = true
    dragStart.current = { mx: e.clientX, my: e.clientY, px: pos.x, py: pos.y }
    window.addEventListener('mousemove', onMoveRef.current)
    window.addEventListener('mouseup',   onUpRef.current)
  }

  return (
    <div
      onMouseDown={onDown}
      style={{
        position: 'fixed',
        left: Math.max(0, Math.min(pos.x, window.innerWidth  - 280)),
        top:  Math.max(0, Math.min(pos.y, window.innerHeight - 160)),
        zIndex: 9001, width: 280,
        borderRadius: 18,
        background: `linear-gradient(160deg, #0d1e2c, #1a2e3e)`,
        border: `1px solid ${C.border}`,
        boxShadow: '0 16px 48px rgba(0,0,0,0.5)',
        padding: '20px 20px 18px',
        cursor: 'grab', userSelect: 'none',
        animation: 'call-fadein 0.2s ease',
      }}
    >
      {/* 顶部：头像 + 姓名 + 时长 */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginBottom: 20 }}>
        <ActiveAvatar name={vc.peer?.name ?? '?'} />
        <div>
          <div style={{ fontSize: 15, fontWeight: 600, color: C.text }}>{vc.peer?.name ?? '通话中'}</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 4 }}>
            <span style={{
              width: 7, height: 7, borderRadius: '50%', background: C.green,
              display: 'inline-block', animation: 'call-pulse 1.5s infinite',
            }} />
            <span style={{ fontSize: 13, color: C.green, fontVariantNumeric: 'tabular-nums', letterSpacing: '0.04em' }}>
              {fmt(vc.duration)}
            </span>
          </div>
        </div>
      </div>

      {/* 操作按钮 */}
      <div style={{ display: 'flex', justifyContent: 'space-around', alignItems: 'flex-start' }}>
        <RoundBtn
          icon={vc.muted ? <MicOffIcon /> : <MicIcon />}
          label={vc.muted ? '取消静音' : '静音'}
          bg={vc.muted ? C.orange : C.surface}
          onClick={vc.toggleMute}
        />
        <RoundBtn
          icon={<HangupIcon />}
          label="挂断"
          bg={C.red}
          onClick={vc.hangUp}
        />
      </div>
    </div>
  )
}

// ── 通话结束提示 ──────────────────────────────────────────────────────────────
function EndedToast() {
  return (
    <div style={{
      position: 'fixed', bottom: 90, left: '50%', transform: 'translateX(-50%)',
      zIndex: 9001, background: 'rgba(30,40,50,0.92)', borderRadius: 12,
      padding: '10px 20px', color: C.muted, fontSize: 13,
      boxShadow: '0 4px 16px rgba(0,0,0,0.4)',
      animation: 'call-fadein 0.2s ease',
    }}>
      通话已结束
    </div>
  )
}

// ── 主导出：根据 callState 显示对应 UI ────────────────────────────────────────
export default function CallOverlay({ vc }: { vc: VoiceCallState }) {
  switch (vc.callState) {
    case 'incoming':    return <IncomingModal vc={vc} />
    case 'calling':
    case 'connecting':  return <CallingModal  vc={vc} />
    case 'active':      return <ActiveOverlay vc={vc} />
    case 'ended':       return <EndedToast />
    default:            return null
  }
}

// ── SVG 图标 ──────────────────────────────────────────────────────────────────
const PhoneIcon  = () => (
  <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
    <path d="M6.6 10.8c1.4 2.8 3.8 5.1 6.6 6.6l2.2-2.2c.3-.3.7-.4 1-.2 1.1.4 2.3.6 3.6.6.6 0 1 .4 1 1V20c0 .6-.4 1-1 1C10.6 21 3 13.4 3 4c0-.6.4-1 1-1h3.5c.6 0 1 .4 1 1 0 1.3.2 2.5.6 3.6.1.3 0 .7-.2 1L6.6 10.8z"
      fill="white" />
  </svg>
)
const HangupIcon = () => (
  <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
    <path d="M12 9c-2.9 0-5.6.5-8 1.3v2.4c0 .6-.3 1.1-.8 1.4l-2.4 1.6c-.5.3-1.1.2-1.5-.2L-.6 15c-.4-.4-.4-1.1.1-1.4C3.6 11.1 7.6 9.5 12 9.5s8.4 1.6 12.5 4.1c.5.3.5 1 .1 1.4l-1.1 1.5c-.4.4-1 .5-1.5.2l-2.4-1.6c-.5-.3-.8-.8-.8-1.4v-2.4C16.5 9.5 13.9 9 12 9z"
      fill="white" />
  </svg>
)
const MicIcon    = () => (
  <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
    <rect x="9" y="2" width="6" height="12" rx="3" fill="rgba(255,255,255,0.85)" />
    <path d="M5 10v2a7 7 0 0 0 14 0v-2" stroke="rgba(255,255,255,0.85)" strokeWidth="1.8" strokeLinecap="round" />
    <line x1="12" y1="19" x2="12" y2="22" stroke="rgba(255,255,255,0.85)" strokeWidth="1.8" strokeLinecap="round" />
    <line x1="9"  y1="22" x2="15" y2="22" stroke="rgba(255,255,255,0.85)" strokeWidth="1.8" strokeLinecap="round" />
  </svg>
)
const MicOffIcon = () => (
  <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
    <line x1="2" y1="2" x2="22" y2="22" stroke="#fff" strokeWidth="1.8" strokeLinecap="round" />
    <path d="M9 9v5a3 3 0 0 0 5.13 2.13M15 9.34V4a3 3 0 0 0-5.94-.6" stroke="#fff" strokeWidth="1.8" strokeLinecap="round" />
    <path d="M17 16.95A7 7 0 0 1 5 12v-2m4 8v2m-1 2h8" stroke="#fff" strokeWidth="1.8" strokeLinecap="round" />
  </svg>
)

// ── 全局 CSS（注入一次）──────────────────────────────────────────────────────
const CALL_STYLES = `
@keyframes call-ring {
  0%   { transform: scale(1); opacity: 0.4; }
  80%  { transform: scale(1.8); opacity: 0; }
  100% { transform: scale(1.8); opacity: 0; }
}
@keyframes call-fadein {
  from { opacity: 0; transform: scale(0.96); }
  to   { opacity: 1; transform: scale(1); }
}
@keyframes call-pulse {
  0%, 100% { opacity: 1; }
  50%       { opacity: 0.3; }
}
`
if (typeof document !== 'undefined') {
  const el = document.getElementById('call-overlay-styles')
  if (!el) {
    const style = document.createElement('style')
    style.id = 'call-overlay-styles'
    style.textContent = CALL_STYLES
    document.head.appendChild(style)
  }
}
