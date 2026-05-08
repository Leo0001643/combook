import React, {
  useState, useEffect, useRef, useCallback, useMemo,
} from 'react'
import { Avatar, Badge, Button, Input, Tooltip, Empty, Spin, Tag, message } from 'antd'
import {
  SearchOutlined, SendOutlined, TeamOutlined,
  SmileOutlined, PictureOutlined, MoreOutlined,
  WifiOutlined, DisconnectOutlined, AudioOutlined, VideoCameraOutlined,
  PauseCircleOutlined, PlayCircleOutlined,
  LoadingOutlined,
} from '@ant-design/icons'
import Picker from '@emoji-mart/react'
import emojiData from '@emoji-mart/data'
import { useImStore } from '../../store/imStore'
import { useAuthStore } from '../../store/authStore'
import { imApi } from '../../api/api'
import type { ImConversationVO, ImMessageVO, ImContactGroupVO, ImContactVO } from '../../api/api'
import dayjs from 'dayjs'

// ── 常量 ─────────────────────────────────────────────────────────────────────
const PANEL_W    = 980
const PANEL_H    = 680
const SIDEBAR_W  = 300
const TITLEBAR_H = 48
const MIN_BTN_R  = 64   // 最小化浮窗大小

const C = {
  bg:           '#0b141a',
  sidebarBg:    '#111b21',
  headerBg:     '#202c33',
  inputBg:      '#202c33',
  inputArea:    '#2a3942',
  border:       'rgba(255,255,255,0.07)',
  divider:      'rgba(255,255,255,0.05)',
  text:         'rgba(255,255,255,0.92)',
  textSub:      'rgba(255,255,255,0.60)',
  textMuted:    'rgba(255,255,255,0.42)',
  textDim:      'rgba(255,255,255,0.26)',
  accent:       '#00a884',
  online:       '#00a884',
  tickGray:     'rgba(255,255,255,0.50)',
  tickBlue:     '#53bdeb',
  bubbleMine:   '#015c4b',
  bubbleOther:  '#202c33',
  timeText:     'rgba(255,255,255,0.48)',
  danger:       '#ef4444',
} as const

const CHAT_BG = `url('/chat-bg.png')`

const roleTagColor: Record<string, string> = {
  SUPER_ADMIN: 'magenta', OWNER: 'volcano', MANAGER: 'orange',
  STAFF: 'blue', OPERATOR: 'cyan', MARKETING: 'pink',
  TECHNICIAN: 'purple', DRIVER: 'geekblue', MEMBER: 'green',
}

// ── 工具 ─────────────────────────────────────────────────────────────────────
const fmt = (ts?: number) => ts ? dayjs.unix(ts).format('HH:mm') : ''

function fmtDate(ts: number) {
  const d = dayjs.unix(ts)
  if (d.isSame(dayjs(), 'day')) return '今天'
  if (d.isSame(dayjs().subtract(1, 'day'), 'day')) return '昨天'
  return d.format('YYYY年MM月DD日')
}

const initials  = (n?: string) => n?.slice(-2) ?? '?'
const avatarClr = (id?: number) => {
  const p = ['#6366f1','#8b5cf6','#ec4899','#f59e0b','#10b981','#3b82f6','#ef4444','#06b6d4']
  return p[(id ?? 0) % p.length]
}

function fmtSec(s: number) {
  const m = Math.floor(s / 60), sec = s % 60
  return `${String(m).padStart(2,'0')}:${String(sec).padStart(2,'0')}`
}

// ── 图片预览（Lightbox）────────────────────────────────────────────────────────
function ImagePreview({ src, onClose }: { src: string; onClose: () => void }) {
  // Esc 关闭
  useEffect(() => {
    const handler = (e: KeyboardEvent) => { if (e.key === 'Escape') onClose() }
    document.addEventListener('keydown', handler)
    return () => document.removeEventListener('keydown', handler)
  }, [onClose])

  return (
    <div
      onClick={onClose}
      style={{
        position: 'fixed', inset: 0, zIndex: 10000,
        background: 'rgba(0,0,0,0.88)', backdropFilter: 'blur(12px)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        animation: 'img-preview-in 0.18s ease',
        cursor: 'zoom-out',
      }}
    >
      <img
        src={src}
        alt="预览"
        onClick={e => e.stopPropagation()}
        style={{
          maxWidth: 'min(90vw, 1200px)',
          maxHeight: '88vh',
          objectFit: 'contain',
          borderRadius: 8,
          boxShadow: '0 24px 80px rgba(0,0,0,0.7)',
          cursor: 'default',
          animation: 'img-preview-in 0.18s ease',
        }}
      />
      {/* 关闭按钮 */}
      <div
        onClick={onClose}
        style={{
          position: 'fixed', top: 20, right: 24,
          width: 38, height: 38, borderRadius: '50%',
          background: 'rgba(255,255,255,0.12)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          cursor: 'pointer', fontSize: 20, color: 'rgba(255,255,255,0.85)',
          transition: 'background 0.15s',
        }}
        onMouseEnter={e => (e.currentTarget.style.background = 'rgba(255,255,255,0.22)')}
        onMouseLeave={e => (e.currentTarget.style.background = 'rgba(255,255,255,0.12)')}
      >
        ✕
      </div>
    </div>
  )
}

// ── 拖拽 Hook ─────────────────────────────────────────────────────────────────
function useDraggable(initPos: () => { x: number; y: number }) {
  const [pos, setPos] = useState(initPos)
  const dragging = useRef(false)
  const origin   = useRef({ mx: 0, my: 0, px: 0, py: 0 })

  const onMouseDown = useCallback((e: React.MouseEvent) => {
    dragging.current = true
    origin.current   = { mx: e.clientX, my: e.clientY, px: pos.x, py: pos.y }
    e.preventDefault()
  }, [pos])

  useEffect(() => {
    const onMove = (e: MouseEvent) => {
      if (!dragging.current) return
      setPos({
        x: origin.current.px + e.clientX - origin.current.mx,
        y: origin.current.py + e.clientY - origin.current.my,
      })
    }
    const onUp = () => { dragging.current = false }
    window.addEventListener('mousemove', onMove)
    window.addEventListener('mouseup',   onUp)
    return () => { window.removeEventListener('mousemove', onMove); window.removeEventListener('mouseup', onUp) }
  }, [])

  return { pos, setPos, onMouseDown }
}

// ── Mac 红绿灯 ────────────────────────────────────────────────────────────────
function MacDots({ onClose, onMin, onMax, maximized, onDrag }: {
  onClose: () => void; onMin: () => void; onMax: () => void
  maximized: boolean; onDrag: (e: React.MouseEvent) => void
}) {
  const [hov, setHov] = useState(false)
  const dots = [
    { bg: '#ff5f57', sym: '✕', fn: onClose },
    { bg: '#febc2e', sym: '−', fn: onMin },
    { bg: '#28c840', sym: maximized ? '⤢' : '+', fn: onMax },
  ]
  return (
    <div
      style={{ display: 'flex', alignItems: 'center', gap: 7, cursor: 'grab', flex: 1 }}
      onMouseEnter={() => setHov(true)} onMouseLeave={() => setHov(false)}
      onMouseDown={onDrag}
    >
      {dots.map((d, i) => (
        <button key={i} onClick={e => { e.stopPropagation(); d.fn() }}
          onMouseDown={e => { e.stopPropagation(); e.currentTarget.style.transform = 'scale(0.82)' }}
          onMouseUp={e => (e.currentTarget.style.transform = 'scale(1)')}
          style={{
            width: 12, height: 12, borderRadius: '50%', background: d.bg,
            border: 'none', cursor: 'pointer', padding: 0, flexShrink: 0,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 7, fontWeight: 900, color: 'rgba(0,0,0,0.6)',
          }}>
          {hov ? d.sym : ''}
        </button>
      ))}
    </div>
  )
}

// ── 头像 ─────────────────────────────────────────────────────────────────────
function UserAvatar({ src, name, userId, size = 36, online = false, borderSrc = C.sidebarBg }: {
  src?: string; name?: string; userId?: number; size?: number; online?: boolean; borderSrc?: string
}) {
  return (
    <div style={{ position: 'relative', flexShrink: 0 }}>
      <Avatar size={size} src={src ?? undefined}
        style={{ background: avatarClr(userId), fontSize: size * 0.38, fontWeight: 700, border: 'none' }}>
        {!src && initials(name)}
      </Avatar>
      {online && (
        <span style={{
          position: 'absolute', bottom: 1, right: 1, width: 9, height: 9, borderRadius: '50%',
          background: C.online, border: `2px solid ${borderSrc}`,
        }} />
      )}
    </div>
  )
}

// ── SVG 双勾 ─────────────────────────────────────────────────────────────────
function Ticks({ status }: { status: number }) {
  const col = status >= 2 ? C.tickBlue : C.tickGray
  return (
    <svg width="16" height="11" viewBox="0 0 16 11" fill="none" style={{ flexShrink: 0, marginBottom: -1 }}>
      <path d="M1 5.5L4.5 9L10 2"  stroke={col} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M5 5.5L8.5 9L14 2" stroke={col} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  )
}

// ── 语音气泡播放器 ───────────────────────────────────────────────────────────
function VoiceBubble({ url, duration, isMine }: { url: string; duration?: number; isMine: boolean }) {
  const [playing, setPlaying] = useState(false)
  const [elapsed, setElapsed] = useState(0)
  const audioRef = useRef<HTMLAudioElement | null>(null)

  const toggle = () => {
    if (!audioRef.current) {
      audioRef.current = new Audio(url)
      audioRef.current.ontimeupdate = () => setElapsed(Math.floor(audioRef.current!.currentTime))
      audioRef.current.onended = () => { setPlaying(false); setElapsed(0) }
    }
    if (playing) { audioRef.current.pause(); setPlaying(false) }
    else { audioRef.current.play(); setPlaying(true) }
  }

  const total = duration ?? 0
  const prog  = total > 0 ? Math.min(elapsed / total, 1) : 0

  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 10,
      minWidth: 160, padding: '2px 0',
    }}>
      <button onClick={toggle} style={{
        width: 34, height: 34, borderRadius: '50%',
        background: isMine ? 'rgba(255,255,255,0.18)' : 'rgba(255,255,255,0.12)',
        border: 'none', cursor: 'pointer', flexShrink: 0,
        display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff',
        fontSize: 16,
      }}>
        {playing ? <PauseCircleOutlined /> : <PlayCircleOutlined />}
      </button>
      <div style={{ flex: 1 }}>
        {/* 波形进度条 */}
        <div style={{
          height: 3, background: 'rgba(255,255,255,0.20)', borderRadius: 2, overflow: 'hidden',
        }}>
          <div style={{
            height: '100%', width: `${prog * 100}%`,
            background: isMine ? 'rgba(255,255,255,0.75)' : C.accent,
            transition: 'width 0.5s linear',
            borderRadius: 2,
          }} />
        </div>
        <div style={{ fontSize: 11, color: C.timeText, marginTop: 3 }}>
          {fmtSec(playing ? elapsed : total)}
        </div>
      </div>
    </div>
  )
}

// ── 消息气泡 ─────────────────────────────────────────────────────────────────
function Bubble({ msg, isMine, isGroupEnd, showSender, senderName, onImageClick }: {
  msg: ImMessageVO; isMine: boolean; isGroupEnd: boolean
  showSender: boolean; senderName?: string
  onImageClick?: (src: string) => void
}) {
  if (msg.msgType === 6) {
    return (
      <div style={{ textAlign: 'center', margin: '8px 0' }}>
        <span style={{
          fontSize: 11.5, color: C.textMuted,
          background: 'rgba(11,20,26,0.72)', backdropFilter: 'blur(6px)',
          padding: '3px 14px', borderRadius: 10,
        }}>{msg.content}</span>
      </div>
    )
  }

  const bg     = isMine ? C.bubbleMine : C.bubbleOther
  const radius = isMine
    ? `10px 10px ${isGroupEnd ? '2px' : '10px'} 10px`
    : `10px 10px 10px ${isGroupEnd ? '2px' : '10px'}`

  const isVoice = msg.msgType === 3
  const isImage = msg.msgType === 2
  const isVideo = msg.msgType === 4

  // 解析语音消息 content: "url|duration" or just url
  let voiceUrl = msg.content, voiceDur: number | undefined
  if (isVoice && msg.content?.includes('|')) {
    const [u, d] = msg.content.split('|')
    voiceUrl = u; voiceDur = Number(d) || undefined
  }

  return (
    <div style={{
      display: 'flex', flexDirection: isMine ? 'row-reverse' : 'row',
      alignItems: 'flex-end', marginBottom: isGroupEnd ? 8 : 3,
      paddingLeft: isMine ? 0 : 0,
    }}>
      <div style={{
        maxWidth: isImage || isVideo ? 260 : '68%',
        position: 'relative',
        marginRight: isMine && isGroupEnd ? 9 : isMine ? 9 : 0,
        marginLeft:  !isMine && isGroupEnd ? 9 : !isMine ? 9 : 0,
      }}>
        <div
          className={isGroupEnd ? (isMine ? 'bbl-r' : 'bbl-l') : ''}
          style={{
            position: 'relative',
            background: (isImage || isVideo) ? 'transparent' : bg,
            padding: (isImage || isVideo) ? '0' : isVoice ? '6px 8px 6px 8px' : '5px 8px 5px 8px',
            borderRadius: (isImage || isVideo) ? (isGroupEnd ? (isMine ? '10px 10px 2px 10px' : '10px 10px 10px 2px') : '10px') : radius,
            color: C.text, fontSize: 14, lineHeight: 1.35,
            wordBreak: 'break-word',
            boxShadow: (isImage || isVideo) ? 'none' : '0 1px 2px rgba(0,0,0,0.40)',
            overflow: (isImage || isVideo) ? 'hidden' : undefined,
            ['--bbl-color' as string]: bg,
          }}
        >
          {!isMine && showSender && senderName && (
            <div style={{ fontSize: 12, fontWeight: 600, color: C.accent, marginBottom: 2, lineHeight: 1.2 }}>
              {senderName}
            </div>
          )}

          {isImage ? (
            <div style={{ position: 'relative' }}>
              <img
                src={msg.content} alt="图片"
                onClick={() => onImageClick?.(msg.content)}
                style={{
                  display: 'block', maxWidth: 260, maxHeight: 260, width: '100%',
                  objectFit: 'cover',
                  borderRadius: radius,
                  boxShadow: '0 1px 2px rgba(0,0,0,0.40)',
                  cursor: onImageClick ? 'zoom-in' : 'default',
                  transition: 'filter 0.15s',
                }}
                onMouseEnter={e => { if (onImageClick) (e.currentTarget as HTMLImageElement).style.filter = 'brightness(0.88)' }}
                onMouseLeave={e => { (e.currentTarget as HTMLImageElement).style.filter = '' }}
              />
              <div style={{
                position: 'absolute', bottom: 6, right: 8,
                display: 'flex', alignItems: 'center', gap: 3,
                background: 'rgba(0,0,0,0.45)', backdropFilter: 'blur(4px)',
                padding: '1px 5px', borderRadius: 8,
              }}>
                <span style={{ fontSize: 11, color: 'rgba(255,255,255,0.85)', whiteSpace: 'nowrap' }}>
                  {fmt(msg.createTime)}
                </span>
                {isMine && <Ticks status={msg.status} />}
              </div>
            </div>
          ) : isVideo ? (
            <div style={{ position: 'relative' }}>
              <video
                src={msg.content}
                controls
                preload="metadata"
                style={{
                  display: 'block', maxWidth: 260, maxHeight: 200, width: '100%',
                  borderRadius: radius,
                  background: '#000',
                  boxShadow: '0 1px 2px rgba(0,0,0,0.40)',
                }}
              />
              <div style={{
                position: 'absolute', bottom: 40, right: 8,
                display: 'flex', alignItems: 'center', gap: 3,
                background: 'rgba(0,0,0,0.45)', backdropFilter: 'blur(4px)',
                padding: '1px 5px', borderRadius: 8,
              }}>
                <span style={{ fontSize: 11, color: 'rgba(255,255,255,0.85)', whiteSpace: 'nowrap' }}>
                  {fmt(msg.createTime)}
                </span>
                {isMine && <Ticks status={msg.status} />}
              </div>
            </div>
          ) : isVoice ? (
            <>
              <VoiceBubble url={voiceUrl} duration={voiceDur} isMine={isMine} />
              {/* 语音：时间跟在波形后面，float 右对齐 */}
              <div style={{
                float: 'right', marginLeft: 8, marginTop: 2,
                display: 'flex', alignItems: 'center', gap: 2,
              }}>
                <span style={{ fontSize: 11, color: C.timeText, whiteSpace: 'nowrap' }}>{fmt(msg.createTime)}</span>
                {isMine && <Ticks status={msg.status} />}
              </div>
              <div style={{ clear: 'both' }} />
            </>
          ) : (
            /* 文本：时间 float 右对齐，单行时与文字同行，多行时落到最后一行 */
            <div style={{ overflow: 'hidden' }}>
              <div style={{
                float: 'right', marginLeft: 6, marginTop: 3,
                display: 'flex', alignItems: 'center', gap: 2,
                fontSize: 11, color: C.timeText, whiteSpace: 'nowrap',
                lineHeight: 1, pointerEvents: 'none',
              }}>
                {fmt(msg.createTime)}
                {isMine && <Ticks status={msg.status} />}
              </div>
              <span style={{ wordBreak: 'break-word' }}>{msg.content}</span>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

// ── 会话列表项 ────────────────────────────────────────────────────────────────
function ConvItem({ conv, active, onClick, contactMap }: {
  conv: ImConversationVO; active: boolean; onClick: () => void
  contactMap: Map<string, ImContactVO>
}) {
  const key     = `${conv.peerType ?? 'group'}_${conv.peerId ?? conv.groupId ?? ''}`
  const contact = contactMap.get(key)
  const name    = conv.groupName ?? contact?.name ?? `会话 ${conv.conversationId}`
  return (
    <div onClick={onClick} style={{
      display: 'flex', gap: 10, padding: '10px 14px', cursor: 'pointer',
      background: active ? 'rgba(255,255,255,0.07)' : 'transparent',
      borderLeft: `3px solid ${active ? C.accent : 'transparent'}`,
      transition: 'background 0.15s',
    }}
      onMouseEnter={e => { if (!active) e.currentTarget.style.background = 'rgba(255,255,255,0.04)' }}
      onMouseLeave={e => { if (!active) e.currentTarget.style.background = 'transparent' }}>
      <Badge count={conv.unreadCount} size="small" offset={[-2, 2]} style={{ background: C.accent }}>
        <UserAvatar src={conv.groupAvatar ?? contact?.avatar}
          name={name} userId={conv.peerId ?? conv.groupId} size={44} online={contact?.online} />
      </Badge>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <span style={{
            color: C.text, fontSize: 13.5, fontWeight: active ? 600 : 500,
            overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', maxWidth: 160,
          }}>{name}</span>
          <span style={{ fontSize: 11, color: C.textDim, flexShrink: 0 }}>{fmt(conv.lastMsgTime)}</span>
        </div>
        <div style={{ fontSize: 12, color: C.textMuted, marginTop: 2, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
          {conv.lastMsgPreview ?? '暂无消息'}
        </div>
      </div>
    </div>
  )
}

// ── 联系人列表项 ──────────────────────────────────────────────────────────────
function ContactItem({ contact, onClick }: { contact: ImContactVO; onClick: () => void }) {
  return (
    <div onClick={onClick} style={{
      display: 'flex', gap: 10, padding: '8px 14px',
      cursor: 'pointer', transition: 'background 0.15s', alignItems: 'center',
    }}
      onMouseEnter={e => (e.currentTarget.style.background = 'rgba(255,255,255,0.05)')}
      onMouseLeave={e => (e.currentTarget.style.background = 'transparent')}>
      <UserAvatar src={contact.avatar} name={contact.name} userId={contact.userId} size={40} online={contact.online} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <span style={{ color: C.text, fontSize: 13, fontWeight: 500, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
            {contact.name}
          </span>
          <Tag color={roleTagColor[contact.role] ?? 'default'}
            style={{ fontSize: 10, padding: '0 4px', lineHeight: '16px', margin: 0, flexShrink: 0 }}>
            {contact.roleLabel}
          </Tag>
        </div>
        {(contact.deptName || contact.positionName) && (
          <div style={{ fontSize: 11, color: C.textMuted, marginTop: 1 }}>
            {[contact.deptName, contact.positionName].filter(Boolean).join(' · ')}
          </div>
        )}
      </div>
    </div>
  )
}

// ══════════════════════════════════════════════════════════════════════════════
// 主组件
// ══════════════════════════════════════════════════════════════════════════════
interface Props { connected?: boolean; voiceCall?: import('../../hooks/useVoiceCall').VoiceCallState }

export default function ImChatPanel({ connected = false, voiceCall }: Props) {
  const {
    open, minimized, maximized, unreadTotal, convRefreshKey,
    conversations, activeConvId, messages, contactGroups,
    setOpen, setMinimized, setMaximized,
    setActiveConv, setConversations, setMessages, prependMessages, setContactGroups,
    appendMessage,
  } = useImStore()

  const { user, merchant, isMerchant } = useAuthStore()
  const currentUserId   = isMerchant ? merchant?.merchantId : user?.userId
  const currentUserType = isMerchant ? 'merchant' : 'admin'

  // ── 拖拽位置 ─────────────────────────────────────────────────────────────
  const defaultPos = () => ({
    x: window.innerWidth  - PANEL_W - 24,
    y: window.innerHeight - PANEL_H - 80,
  })
  const { pos, setPos, onMouseDown: onDragStart } = useDraggable(defaultPos)

  // 最大化时重置拖拽偏移
  const handleMaximize = () => {
    setMaximized(!maximized)
    if (!maximized) setPos({ x: 0, y: 0 })
  }

  // ── UI 状态 ───────────────────────────────────────────────────────────────
  const [sideTab,      setSideTab]      = useState<'conv' | 'contact'>('conv')
  const [searchKw,     setSearchKw]     = useState('')
  const [inputText,    setInputText]    = useState('')
  const [loading,      setLoading]      = useState(false)
  const [sending,      setSending]      = useState(false)
  const [loadingMore,  setLoadingMore]  = useState(false)
  const [showEmoji,    setShowEmoji]    = useState(false)
  const [uploadingImg,   setUploadingImg]   = useState(false)
  const [uploadingVideo, setUploadingVideo] = useState(false)
  const [previewImg,     setPreviewImg]     = useState<string | null>(null)

  // 语音录制状态
  const [recording,    setRecording]    = useState(false)
  const [recSeconds,   setRecSeconds]   = useState(0)
  const recRef       = useRef<MediaRecorder | null>(null)
  const recTimer     = useRef<ReturnType<typeof setInterval> | null>(null)
  const recChunks    = useRef<Blob[]>([])
  const recCancelled = useRef(false)
  const recSecsRef   = useRef(0)   // 镜像 recSeconds，供 mr.onstop 闭包读取最新值

  const msgEndRef  = useRef<HTMLDivElement>(null)
  const msgListRef = useRef<HTMLDivElement>(null)
  const fileRef    = useRef<HTMLInputElement>(null)
  const videoRef   = useRef<HTMLInputElement>(null)
  const emojiRef   = useRef<HTMLDivElement>(null)

  // ── 数据加载 ─────────────────────────────────────────────────────────────
  useEffect(() => {
    if (!open) return
    setLoading(true)
    Promise.all([
      imApi.conversations().then(r => setConversations((r.data as any)?.data ?? [])),
      imApi.contacts().then(r => setContactGroups((r.data as any)?.data ?? [])),
    ]).finally(() => setLoading(false))
  }, [open]) // eslint-disable-line

  const activeConv  = conversations.find(c => c.conversationId === activeConvId)
  const currentMsgs = messages[activeConvId ?? -1] ?? []

  // WS 新消息来自陌生会话时，convRefreshKey 自增，自动重新拉取会话列表
  useEffect(() => {
    if (convRefreshKey === 0) return
    imApi.conversations().then(r => setConversations((r.data as any)?.data ?? []))
  }, [convRefreshKey]) // eslint-disable-line

  useEffect(() => {
    if (activeConvId == null) return
    if (messages[activeConvId]?.length) return
    imApi.history(activeConvId).then(r => {
      setMessages(activeConvId, (((r.data as any)?.data ?? []) as ImMessageVO[]).reverse())
    })
  }, [activeConvId]) // eslint-disable-line

  useEffect(() => {
    msgEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [currentMsgs.length]) // eslint-disable-line

  // 点击外部关闭 emoji picker
  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (emojiRef.current && !emojiRef.current.contains(e.target as Node)) {
        setShowEmoji(false)
      }
    }
    if (showEmoji) document.addEventListener('mousedown', handler)
    return () => document.removeEventListener('mousedown', handler)
  }, [showEmoji])

  const loadMore = useCallback(async () => {
    if (!activeConvId || loadingMore) return
    const msgs = messages[activeConvId] ?? []
    if (!msgs.length) return
    setLoadingMore(true)
    try {
      const r = await imApi.history(activeConvId, msgs[0].msgId)
      const older = ((r.data as any)?.data ?? []) as ImMessageVO[]
      if (older.length) prependMessages(activeConvId, older.reverse())
    } finally { setLoadingMore(false) }
  }, [activeConvId, messages, loadingMore, prependMessages])

  const handleScroll = useCallback((e: React.UIEvent<HTMLDivElement>) => {
    if (e.currentTarget.scrollTop < 60) loadMore()
  }, [loadMore])

  // ── 发送文本 ─────────────────────────────────────────────────────────────
  const doSend = useCallback(async (text?: string) => {
    const content = (text ?? inputText).trim()
    if (!content || !activeConv || !activeConvId || !currentUserId || sending) return
    setSending(true)
    if (!text) setInputText('')
    try {
      const dto = {
        receiverType: activeConv.peerType ?? 'member',
        receiverId:   activeConv.peerId ?? 0,
        msgType: 1, content,
        clientMsgId: `${Date.now()}-${Math.random().toString(36).slice(2, 7)}`,
      }
      const r   = await imApi.sendMessage(dto)
      const msgId = (r.data as any)?.data as number
      appendMessage({
        msgId, conversationId: activeConvId,
        senderType: currentUserType, senderId: currentUserId,
        isGroup: 0, msgType: 1, content, status: 1,
        createTime: Math.floor(Date.now() / 1000),
      })
    } catch { if (!text) setInputText(content) }
    finally { setSending(false) }
  }, [inputText, activeConv, activeConvId, sending, currentUserId, currentUserType, appendMessage])

  // ── 发送媒体消息（通用） ─────────────────────────────────────────────────
  const doSendMedia = useCallback(async (url: string, msgType: number, extraContent?: string) => {
    if (!activeConv || !activeConvId || !currentUserId) return
    const content = extraContent ?? url
    const r = await imApi.sendMessage({
      receiverType: activeConv.peerType ?? 'member',
      receiverId:   activeConv.peerId ?? 0,
      msgType, content,
      clientMsgId: `${Date.now()}-${Math.random().toString(36).slice(2, 7)}`,
    })
    const msgId = (r.data as any)?.data as number
    appendMessage({
      msgId, conversationId: activeConvId,
      senderType: currentUserType, senderId: currentUserId,
      isGroup: 0, msgType, content, status: 1,
      createTime: Math.floor(Date.now() / 1000),
    })
  }, [activeConv, activeConvId, currentUserId, currentUserType, appendMessage])

  // ── Emoji 选择 ───────────────────────────────────────────────────────────
  const onEmojiSelect = useCallback((emoji: { native: string }) => {
    setInputText(prev => prev + emoji.native)
    setShowEmoji(false)
  }, [])

  // ── 图片上传 ─────────────────────────────────────────────────────────────
  const onFileChange = useCallback(async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return
    e.target.value = ''
    if (file.size > 250 * 1024 * 1024) { message.error('图片不能超过 250MB'); return }
    setUploadingImg(true)
    try {
      const r   = await imApi.uploadImage(file)
      const url = (r.data as any)?.data?.fileUrl as string
      if (!url) throw new Error('上传失败')
      await doSendMedia(url, 2)
    } catch { message.error('图片上传失败') }
    finally { setUploadingImg(false) }
  }, [doSendMedia])

  // ── 视频上传 ─────────────────────────────────────────────────────────────
  const onVideoChange = useCallback(async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return
    e.target.value = ''
    if (file.size > 250 * 1024 * 1024) { message.error('视频不能超过 250MB'); return }
    setUploadingVideo(true)
    try {
      const r   = await imApi.uploadVideo(file)
      const url = (r.data as any)?.data?.fileUrl as string
      if (!url) throw new Error('上传失败')
      await doSendMedia(url, 4)
    } catch { message.error('视频上传失败') }
    finally { setUploadingVideo(false) }
  }, [doSendMedia])

  // ── 语音录制 ─────────────────────────────────────────────────────────────

  /** 选择浏览器支持的最优音频格式，优先 mp4/aac（iOS 原生支持） */
  const getAudioMime = () => {
    // Prefer mp4/aac first — natively supported by iOS AVAudioPlayer.
    // Chrome 108+ on macOS supports audio/mp4; Safari always supports it.
    // Webm/ogg are Chrome-Linux / Firefox fallbacks that cannot play on iOS.
    const preferred = ['audio/mp4', 'audio/aac', 'audio/webm;codecs=opus', 'audio/webm', 'audio/ogg;codecs=opus']
    return preferred.find(t => MediaRecorder.isTypeSupported(t)) ?? ''
  }

  /** 根据 MIME 类型推断文件扩展名（iOS 兼容） */
  const mimeToExt = (mime: string): string => {
    if (mime.includes('mp4') || mime.includes('aac')) return 'm4a'
    if (mime.includes('ogg') || mime.includes('opus')) return 'ogg'
    if (mime.includes('mpeg') || mime.includes('mp3')) return 'mp3'
    return 'webm'
  }

  const startRecord = useCallback(async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      recChunks.current  = []
      recCancelled.current = false
      const mime = getAudioMime()
      const mr   = new MediaRecorder(stream, mime ? { mimeType: mime } : undefined)
      mr.ondataavailable = e => { if (e.data.size > 0) recChunks.current.push(e.data) }
      mr.onstop = async () => {
        stream.getTracks().forEach(t => t.stop())
        if (recCancelled.current) return  // 取消录制，不上传
        const blob = new Blob(recChunks.current, { type: mime || 'audio/webm' })
        if (blob.size === 0) return
        const dur  = recSecsRef.current   // 使用 ref 读取，避免 useCallback 闭包过期
        recSecsRef.current = 0
        setRecSeconds(0)
        try {
          const ext = mimeToExt(mime || 'audio/webm')
          const r   = await imApi.uploadVoice(blob, `voice.${ext}`)
          const url = (r.data as any)?.data?.fileUrl as string
          if (!url) throw new Error('上传失败')
          // content 格式: "url|duration"
          await doSendMedia(url, 3, `${url}|${dur}`)
        } catch { message.error('语音发送失败') }
      }
      recRef.current = mr
      mr.start(100)
      setRecording(true)
      setRecSeconds(0)
      recSecsRef.current = 0
      recTimer.current = setInterval(() => {
        recSecsRef.current += 1
        setRecSeconds(recSecsRef.current)
      }, 1000)
    } catch { message.error('无法访问麦克风') }
  }, [doSendMedia])

  const stopRecord = useCallback(() => {
    if (recTimer.current) { clearInterval(recTimer.current); recTimer.current = null }
    recRef.current?.stop()
    recRef.current = null
    setRecording(false)
  }, [])

  const cancelRecord = useCallback(() => {
    recCancelled.current = true
    if (recTimer.current) { clearInterval(recTimer.current); recTimer.current = null }
    recRef.current?.stream?.getTracks().forEach(t => t.stop())
    recRef.current?.stop()
    recRef.current = null
    recChunks.current = []
    recSecsRef.current = 0
    setRecording(false)
    setRecSeconds(0)
  }, [])

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); doSend() }
  }

  // ── 通讯录建会话 ─────────────────────────────────────────────────────────
  const openContactConv = useCallback(async (contact: ImContactVO) => {
    const exist = conversations.find(c => c.peerType === contact.userType && c.peerId === contact.userId)
    if (exist) { setActiveConv(exist.conversationId); setSideTab('conv'); return }
    try {
      await imApi.sendMessage({ receiverType: contact.userType, receiverId: contact.userId, msgType: 6, content: '会话已建立' })
      const r2  = await imApi.conversations()
      const list = (r2.data as any)?.data ?? []
      setConversations(list)
      const nxt = list.find((c: ImConversationVO) => c.peerType === contact.userType && c.peerId === contact.userId)
      if (nxt) { setActiveConv(nxt.conversationId); setSideTab('conv') }
    } catch { /* ignore */ }
  }, [conversations, setActiveConv, setConversations])

  // ── 联系人 Map ───────────────────────────────────────────────────────────
  const contactMap = useMemo(() => {
    const m = new Map<string, ImContactVO>()
    contactGroups.forEach(g => g.contacts.forEach(c => m.set(`${c.userType}_${c.userId}`, c)))
    return m
  }, [contactGroups])

  const filteredGroups: ImContactGroupVO[] = searchKw.trim()
    ? [{ groupName: '搜索结果', sort: 0, contacts: contactGroups.flatMap(g => g.contacts)
        .filter(c => c.name?.includes(searchKw) || c.deptName?.includes(searchKw)) }]
    : contactGroups

  if (!open) return null

  // ── 最小化：可拖拽浮动按钮 ───────────────────────────────────────────────
  if (minimized) {
    return (
      <MinimizedButton
        unread={unreadTotal}
        onRestore={() => setMinimized(false)}
        onClose={() => setOpen(false)}
      />
    )
  }

  // ── 面板样式（支持拖拽定位 or 最大化）───────────────────────────────────
  const panelStyle: React.CSSProperties = maximized ? {
    position: 'fixed', top: 16, left: 16, right: 16, bottom: 16,
    width: 'auto', height: 'auto', borderRadius: 14,
  } : {
    position: 'fixed',
    left: Math.max(0, Math.min(pos.x, window.innerWidth  - PANEL_W)),
    top:  Math.max(0, Math.min(pos.y, window.innerHeight - PANEL_H)),
    width: PANEL_W, height: PANEL_H, borderRadius: 16,
  }

  return (
    <div style={{
      ...panelStyle,
      background: C.bg,
      border: `1px solid ${C.border}`,
      boxShadow: '0 28px 100px rgba(0,0,0,0.75), 0 0 0 1px rgba(0,168,132,0.10)',
      display: 'flex', flexDirection: 'column', overflow: 'hidden', zIndex: 1000,
      animation: 'imIn 0.22s cubic-bezier(0.34,1.56,0.64,1)',
    }}>
      <style>{`
        @keyframes imIn {
          from { opacity:0; transform:scale(0.93) translateY(18px); }
          to   { opacity:1; transform:scale(1) translateY(0); }
        }
        @keyframes recPulse { 0%,100%{opacity:1} 50%{opacity:0.35} }
        @keyframes im-pulse {
          0%   { transform:scale(1);   opacity:0.8; }
          70%  { transform:scale(2.2); opacity:0; }
          100% { transform:scale(2.2); opacity:0; }
        }
        @keyframes im-badge-pop {
          0%   { transform:scale(0); opacity:0; }
          70%  { transform:scale(1.25); }
          100% { transform:scale(1); opacity:1; }
        }
        .bbl-r::after {
          content:''; position:absolute; bottom:0; right:-8px;
          width:0; height:0;
          border-left:9px solid var(--bbl-color,#015c4b);
          border-bottom:9px solid transparent;
        }
        .bbl-l::after {
          content:''; position:absolute; bottom:0; left:-8px;
          width:0; height:0;
          border-right:9px solid var(--bbl-color,#202c33);
          border-bottom:9px solid transparent;
        }
        .im-search .ant-input-affix-wrapper { background:rgba(255,255,255,0.07)!important; border-color:transparent!important; border-radius:8px!important; }
        .im-search .ant-input { background:transparent!important; color:#ebebeb!important; }
        .im-search .ant-input::placeholder { color:rgba(255,255,255,0.35)!important; }
        .im-input .ant-input { background:#2a3942!important; color:#ebebeb!important; border-color:transparent!important; }
        .im-input .ant-input::placeholder { color:rgba(255,255,255,0.32)!important; }
        .im-input .ant-input:focus { box-shadow:none!important; }
        .im-msglist::-webkit-scrollbar { width:5px; }
        .im-msglist::-webkit-scrollbar-thumb { background:rgba(255,255,255,0.10); border-radius:3px; }
        .im-sidebar::-webkit-scrollbar { width:3px; }
        .im-sidebar::-webkit-scrollbar-thumb { background:rgba(255,255,255,0.08); }
        .em-emoji-picker { --border-radius:12px!important; --font-size:14px!important; }
        @keyframes img-preview-in {
          from { opacity:0; transform:scale(0.94); }
          to   { opacity:1; transform:scale(1); }
        }
      `}</style>

      {/* ── 隐藏文件输入 */}
      <input ref={fileRef}  type="file" accept="image/*"  style={{ display: 'none' }} onChange={onFileChange} />
      <input ref={videoRef} type="file" accept="video/*"  style={{ display: 'none' }} onChange={onVideoChange} />

      {/* ── 图片预览 Lightbox */}
      {previewImg && <ImagePreview src={previewImg} onClose={() => setPreviewImg(null)} />}

      {/* ── 标题栏（可拖拽） ─────────────────────────────────────────────── */}
      <div style={{
        height: TITLEBAR_H, flexShrink: 0, padding: '0 14px',
        display: 'flex', alignItems: 'center', gap: 0,
        background: C.headerBg, borderBottom: `1px solid ${C.border}`,
        userSelect: 'none',
      }}>
        <MacDots
          onClose={() => setOpen(false)}
          onMin={() => setMinimized(true)}
          onMax={handleMaximize}
          maximized={maximized}
          onDrag={onDragStart}
        />
        <div style={{ flex: 1, textAlign: 'center' }}>
          <span style={{ color: C.text, fontWeight: 600, fontSize: 13.5, letterSpacing: 0.3 }}>
            企业通讯
          </span>
        </div>
        <Tooltip title={connected ? '已连接' : '未连接'}>
          {connected
            ? <WifiOutlined style={{ color: C.online, fontSize: 12 }} />
            : <DisconnectOutlined style={{ color: '#ef4444', fontSize: 12 }} />}
        </Tooltip>
      </div>

      <div style={{ flex: 1, display: 'flex', overflow: 'hidden' }}>

        {/* ── 左侧边栏 ──────────────────────────────────────────────────── */}
        <div style={{
          width: SIDEBAR_W, flexShrink: 0, background: C.sidebarBg,
          borderRight: `1px solid ${C.border}`, display: 'flex', flexDirection: 'column',
        }}>
          <div style={{ padding: '10px 12px 8px', borderBottom: `1px solid ${C.border}` }}>
            <Input className="im-search"
              prefix={<SearchOutlined style={{ color: C.textMuted }} />}
              placeholder="搜索联系人…" size="small" value={searchKw}
              onChange={e => setSearchKw(e.target.value)}
              style={{ borderRadius: 8 }} />
          </div>
          <div style={{ display: 'flex', borderBottom: `1px solid ${C.border}` }}>
            {(['conv', 'contact'] as const).map(tab => (
              <button key={tab} onClick={() => setSideTab(tab)} style={{
                flex: 1, padding: '9px 0', border: 'none', cursor: 'pointer',
                background: sideTab === tab ? 'rgba(0,168,132,0.10)' : 'transparent',
                borderBottom: `2px solid ${sideTab === tab ? C.accent : 'transparent'}`,
                color: sideTab === tab ? C.accent : C.textMuted,
                fontSize: 12.5, fontWeight: sideTab === tab ? 600 : 400, transition: 'all 0.15s',
              }}>
                {tab === 'conv' ? '会话' : '通讯录'}
              </button>
            ))}
          </div>
          <div className="im-sidebar" style={{ flex: 1, overflowY: 'auto' }}>
            {loading ? (
              <div style={{ display: 'flex', justifyContent: 'center', paddingTop: 48 }}>
                <Spin size="small" />
              </div>
            ) : sideTab === 'conv' ? (
              conversations.length === 0
                ? <Empty description={<span style={{ color: C.textMuted, fontSize: 12 }}>暂无会话</span>}
                    style={{ marginTop: 44 }} image={Empty.PRESENTED_IMAGE_SIMPLE} />
                : conversations
                    .sort((a, b) => (b.lastMsgTime ?? 0) - (a.lastMsgTime ?? 0))
                    .map(conv => (
                      <ConvItem key={conv.conversationId} conv={conv}
                        active={conv.conversationId === activeConvId}
                        onClick={() => setActiveConv(conv.conversationId)}
                        contactMap={contactMap} />
                    ))
            ) : (
              filteredGroups.length === 0
                ? <Empty description={<span style={{ color: C.textMuted, fontSize: 12 }}>暂无联系人</span>}
                    style={{ marginTop: 44 }} image={Empty.PRESENTED_IMAGE_SIMPLE} />
                : filteredGroups.map(group => (
                    <div key={group.groupName}>
                      <div style={{ padding: '6px 14px 4px', fontSize: 11, color: C.textDim, fontWeight: 600, letterSpacing: 0.5, textTransform: 'uppercase' }}>
                        {group.groupName}
                      </div>
                      {group.contacts.map(c => (
                        <ContactItem key={`${c.userType}_${c.userId}`}
                          contact={c} onClick={() => openContactConv(c)} />
                      ))}
                    </div>
                  ))
            )}
          </div>
        </div>

        {/* ── 右侧消息区 ────────────────────────────────────────────────── */}
        {activeConvId == null ? (
          <div style={{
            flex: 1, display: 'flex', flexDirection: 'column',
            alignItems: 'center', justifyContent: 'center', gap: 16,
            backgroundImage: CHAT_BG, backgroundSize: 'cover', backgroundPosition: 'center',
          }}>
            <div style={{
              width: 76, height: 76, borderRadius: 22,
              background: 'linear-gradient(135deg,#00a884,#008f72)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: '0 12px 40px rgba(0,168,132,0.4)',
            }}>
              <TeamOutlined style={{ fontSize: 34, color: '#fff' }} />
            </div>
            <div style={{ textAlign: 'center' }}>
              <div style={{ color: C.text, fontSize: 15, fontWeight: 600 }}>企业通讯</div>
              <div style={{ color: C.textMuted, fontSize: 12.5, marginTop: 5 }}>选择会话或联系人开始聊天</div>
            </div>
          </div>
        ) : (
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>

            {/* 会话顶栏 */}
            {(() => {
              const c    = contactMap.get(`${activeConv?.peerType}_${activeConv?.peerId}`)
              const name = activeConv?.groupName ?? c?.name ?? `会话 ${activeConvId}`
              return (
                <div style={{
                  height: 58, flexShrink: 0, padding: '0 16px',
                  display: 'flex', alignItems: 'center', gap: 12,
                  background: C.headerBg, borderBottom: `1px solid ${C.border}`,
                }}>
                  <UserAvatar src={activeConv?.groupAvatar ?? c?.avatar} name={name}
                    userId={activeConv?.peerId ?? activeConv?.groupId} size={38}
                    online={c?.online} borderSrc={C.headerBg} />
                  <div style={{ flex: 1 }}>
                    <div style={{ color: C.text, fontWeight: 600, fontSize: 14.5 }}>{name}</div>
                    <div style={{ fontSize: 11.5, color: c?.online ? C.online : C.textDim, marginTop: 1 }}>
                      {c?.online ? '在线' : (c?.roleLabel ?? '')}
                    </div>
                  </div>
                  {/* 语音通话按钮（仅单聊显示） */}
                  {activeConv?.peerType && voiceCall && (
                    <Tooltip title="语音通话">
                      <Button type="text" size="small"
                        disabled={voiceCall.callState !== 'idle'}
                        onClick={() => voiceCall.startCall({
                          userType: activeConv.peerType!,
                          userId:   activeConv.peerId!,
                          name,
                        })}
                        icon={
                          <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
                            <path d="M6.6 10.8c1.4 2.8 3.8 5.1 6.6 6.6l2.2-2.2c.3-.3.7-.4 1-.2 1.1.4 2.3.6 3.6.6.6 0 1 .4 1 1V20c0 .6-.4 1-1 1C10.6 21 3 13.4 3 4c0-.6.4-1 1-1h3.5c.6 0 1 .4 1 1 0 1.3.2 2.5.6 3.6.1.3 0 .7-.2 1L6.6 10.8z"
                              fill={voiceCall.callState !== 'idle' ? C.accent : C.textMuted} />
                          </svg>
                        }
                      />
                    </Tooltip>
                  )}
                  <Tooltip title="更多">
                    <Button type="text" size="small"
                      icon={<MoreOutlined style={{ color: C.textMuted, fontSize: 17 }} />} />
                  </Tooltip>
                </div>
              )
            })()}

            {/* 消息列表 */}
            <div ref={msgListRef} onScroll={handleScroll} className="im-msglist"
              style={{
                flex: 1, overflowY: 'auto', padding: '10px 18px 6px',
                backgroundImage: CHAT_BG, backgroundSize: 'cover',
                backgroundPosition: 'center', backgroundAttachment: 'local',
              }}>
              {loadingMore && <div style={{ textAlign: 'center', marginBottom: 8 }}><Spin size="small" /></div>}
              {currentMsgs.length === 0 ? (
                <Empty description={<span style={{ color: C.textMuted, fontSize: 12 }}>发送第一条消息</span>}
                  image={Empty.PRESENTED_IMAGE_SIMPLE} style={{ marginTop: 80 }} />
              ) : (
                currentMsgs.map((msg, idx) => {
                  const isMine       = msg.senderId === currentUserId
                  const next         = idx < currentMsgs.length - 1 ? currentMsgs[idx + 1] : null
                  const prev         = idx > 0 ? currentMsgs[idx - 1] : null
                  const isGroupEnd   = !next || next.senderId !== msg.senderId
                  const isGroupStart = !prev || prev.senderId !== msg.senderId
                  const showDate     = !prev || !dayjs.unix(msg.createTime).isSame(dayjs.unix(prev.createTime), 'day')
                  const contact      = contactMap.get(`${msg.senderType}_${msg.senderId}`)

                  return (
                    <React.Fragment key={msg.msgId}>
                      {showDate && (
                        <div style={{ textAlign: 'center', margin: '10px 0 8px' }}>
                          <span style={{
                            fontSize: 11.5, color: C.textMuted,
                            background: 'rgba(11,20,26,0.75)', backdropFilter: 'blur(6px)',
                            padding: '4px 14px', borderRadius: 10,
                          }}>{fmtDate(msg.createTime)}</span>
                        </div>
                      )}
                      <Bubble msg={msg} isMine={isMine}
                        isGroupEnd={isGroupEnd} showSender={isGroupStart}
                        senderName={contact?.name}
                        onImageClick={setPreviewImg} />
                    </React.Fragment>
                  )
                })
              )}
              <div ref={msgEndRef} />
            </div>

            {/* ── 输入区 ────────────────────────────────────────────────── */}
            <div style={{ background: C.inputBg, borderTop: `1px solid ${C.border}`, flexShrink: 0 }}>

              {/* 录音状态条 */}
              {recording && (
                <div style={{
                  display: 'flex', alignItems: 'center', gap: 12,
                  padding: '8px 16px',
                  background: 'rgba(239,68,68,0.08)', borderBottom: `1px solid ${C.divider}`,
                }}>
                  <span style={{
                    width: 10, height: 10, borderRadius: '50%', background: C.danger, flexShrink: 0,
                    animation: 'recPulse 1.2s ease-in-out infinite',
                  }} />
                  <span style={{ color: C.danger, fontSize: 13, fontWeight: 500 }}>
                    正在录音 {fmtSec(recSeconds)}
                  </span>
                  <div style={{ flex: 1 }} />
                  <Button size="small" type="text"
                    style={{ color: C.textMuted, fontSize: 12 }}
                    onClick={cancelRecord}>
                    取消
                  </Button>
                  <Button size="small" type="primary"
                    style={{ background: C.accent, borderColor: 'transparent', fontSize: 12 }}
                    onClick={stopRecord}>
                    发送录音
                  </Button>
                </div>
              )}

              {/* 工具栏 */}
              <div style={{
                padding: '5px 14px 3px', display: 'flex', gap: 0,
                borderBottom: `1px solid ${C.divider}`,
                position: 'relative',
              }}>
                {/* Emoji */}
                <div ref={emojiRef} style={{ position: 'relative' }}>
                  <Tooltip title="表情">
                    <Button type="text" size="small"
                      onClick={() => setShowEmoji(v => !v)}
                      icon={<SmileOutlined style={{ color: showEmoji ? C.accent : C.textMuted, fontSize: 18 }} />} />
                  </Tooltip>
                  {showEmoji && (
                    <div style={{
                      position: 'absolute', bottom: 44, left: 0, zIndex: 9999,
                      borderRadius: 12, overflow: 'hidden',
                      boxShadow: '0 8px 40px rgba(0,0,0,0.55)',
                    }}>
                      <Picker
                        data={emojiData}
                        onEmojiSelect={onEmojiSelect}
                        theme="dark"
                        locale="zh"
                        previewPosition="none"
                        skinTonePosition="none"
                        perLine={8}
                        emojiSize={22}
                      />
                    </div>
                  )}
                </div>

                {/* 图片 */}
                <Tooltip title={uploadingImg ? '上传中…' : '发送图片'}>
                  <Button type="text" size="small"
                    disabled={uploadingImg || uploadingVideo}
                    onClick={() => fileRef.current?.click()}
                    icon={uploadingImg
                      ? <LoadingOutlined style={{ color: C.accent, fontSize: 18 }} />
                      : <PictureOutlined style={{ color: C.textMuted, fontSize: 18 }} />}
                  />
                </Tooltip>

                {/* 视频 */}
                <Tooltip title={uploadingVideo ? '上传中…' : '发送视频（≤250MB）'}>
                  <Button type="text" size="small"
                    disabled={uploadingImg || uploadingVideo}
                    onClick={() => videoRef.current?.click()}
                    icon={uploadingVideo
                      ? <LoadingOutlined style={{ color: C.accent, fontSize: 18 }} />
                      : <VideoCameraOutlined style={{ color: C.textMuted, fontSize: 18 }} />}
                  />
                </Tooltip>

                {/* 语音 */}
                <Tooltip title={recording ? '录音中…' : '语音消息'}>
                  <Button type="text" size="small"
                    onClick={recording ? stopRecord : startRecord}
                    icon={<AudioOutlined style={{
                      color: recording ? C.danger : C.textMuted, fontSize: 18,
                    }} />}
                  />
                </Tooltip>
              </div>

              {/* 文本框 + 发送 */}
              <div style={{ padding: '8px 12px 10px', display: 'flex', gap: 8, alignItems: 'flex-end' }}>
                <div className="im-input" style={{ flex: 1 }}>
                  <Input.TextArea
                    autoSize={{ minRows: 1, maxRows: 5 }}
                    placeholder="输入消息，Enter 发送"
                    value={inputText}
                    onChange={e => setInputText(e.target.value)}
                    onKeyDown={handleKeyDown}
                    style={{
                      background: C.inputArea, borderColor: 'transparent', color: C.text,
                      borderRadius: 10, resize: 'none', fontSize: 14, padding: '8px 12px', lineHeight: 1.55,
                    }}
                  />
                </div>
                <Button
                  type="primary" shape="circle"
                  icon={<SendOutlined style={{ fontSize: 15, marginLeft: 2 }} />}
                  onClick={() => doSend()}
                  loading={sending} disabled={!inputText.trim()}
                  style={{
                    background: inputText.trim() ? C.accent : 'rgba(255,255,255,0.08)',
                    borderColor: 'transparent', width: 42, height: 42, flexShrink: 0,
                    boxShadow: inputText.trim() ? '0 4px 18px rgba(0,168,132,0.42)' : 'none',
                    transition: 'background 0.2s, box-shadow 0.2s',
                  }}
                />
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}

// ── 最小化浮窗按钮（可拖拽）────────────────────────────────────────────────
function MinimizedButton({ unread, onRestore, onClose }: {
  unread: number; onRestore: () => void; onClose: () => void
}) {
  const { pos, onMouseDown } = useDraggable(() => ({
    x: window.innerWidth  - MIN_BTN_R - 24,
    y: window.innerHeight - MIN_BTN_R - 100,
  }))
  const [hov, setHov] = useState(false)
  const dragged = useRef(false)
  const downPos = useRef({ x: 0, y: 0 })

  return (
    <div
      onMouseDown={e => {
        downPos.current = { x: e.clientX, y: e.clientY }
        dragged.current = false
        onMouseDown(e)
      }}
      onMouseMove={e => {
        const dx = Math.abs(e.clientX - downPos.current.x)
        const dy = Math.abs(e.clientY - downPos.current.y)
        if (dx > 4 || dy > 4) dragged.current = true
      }}
      onMouseUp={() => { if (!dragged.current) onRestore() }}
      onMouseEnter={() => setHov(true)}
      onMouseLeave={() => setHov(false)}
      style={{
        position: 'fixed',
        left: Math.max(0, Math.min(pos.x, window.innerWidth  - MIN_BTN_R)),
        top:  Math.max(0, Math.min(pos.y, window.innerHeight - MIN_BTN_R)),
        width: MIN_BTN_R, height: MIN_BTN_R,
        borderRadius: '50%',
        background: 'linear-gradient(135deg,#00a884,#008f72)',
        boxShadow: hov
          ? '0 8px 32px rgba(0,168,132,0.6), 0 0 0 3px rgba(0,168,132,0.25)'
          : '0 4px 20px rgba(0,168,132,0.4)',
        cursor: 'grab', zIndex: 1001,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        transition: 'box-shadow 0.2s, transform 0.15s',
        transform: hov ? 'scale(1.06)' : 'scale(1)',
        userSelect: 'none',
      }}
    >
      {/* 未读徽标（右上角，与关闭按钮区分） */}
      {unread > 0 && !hov && (
        <>
          {/* 脉冲光圈 */}
          <span style={{
            position: 'absolute', top: -6, right: -6,
            width: 22, height: 22, borderRadius: '50%',
            background: 'rgba(255,45,85,0.35)',
            animation: 'im-pulse 1.8s ease-out infinite',
            pointerEvents: 'none',
          }} />
          <span style={{
            position: 'absolute', top: -6, right: -6,
            minWidth: 20, height: 20, borderRadius: 10,
            background: 'linear-gradient(135deg,#ff4757,#ff2d55)',
            color: '#fff', fontSize: 11, fontWeight: 800,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            padding: '0 5px', lineHeight: 1,
            boxShadow: '0 2px 10px rgba(255,45,85,0.7)',
            border: '2px solid rgba(255,255,255,0.2)',
            letterSpacing: '-0.3px',
            animation: 'im-badge-pop 0.3s cubic-bezier(.34,1.56,.64,1)',
          }}>
            {unread > 99 ? '99+' : unread}
          </span>
        </>
      )}
      {/* 关闭按钮（hover时显示，替换徽标位置） */}
      {hov && (
        <button
          onClick={e => { e.stopPropagation(); onClose() }}
          onMouseDown={e => e.stopPropagation()}
          style={{
            position: 'absolute', top: -6, right: -6,
            width: 22, height: 22, borderRadius: '50%',
            background: 'linear-gradient(135deg,#ff4757,#ff2d55)',
            border: '2px solid rgba(255,255,255,0.2)', cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            color: '#fff', fontSize: 10, fontWeight: 700,
            boxShadow: '0 2px 8px rgba(255,45,85,0.6)',
          }}
        >✕</button>
      )}
      <TeamOutlined style={{ fontSize: 28, color: '#fff' }} />
    </div>
  )
}
