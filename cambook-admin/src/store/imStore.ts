import { create } from 'zustand'
import type { ImConversationVO, ImMessageVO, ImContactGroupVO } from '../api/api'

interface ImState {
  /** 聊天面板是否打开 */
  open: boolean

  /** 面板最小化（仅显示标题栏） */
  minimized: boolean

  /** 面板最大化 */
  maximized: boolean

  /** 会话列表 */
  conversations: ImConversationVO[]

  /** 当前激活的会话 ID */
  activeConvId: number | null

  /** 消息缓存：conversationId → 消息列表（从旧到新） */
  messages: Record<number, ImMessageVO[]>

  /** 通讯录分组 */
  contactGroups: ImContactGroupVO[]

  /** 未读总数 */
  unreadTotal: number

  /** 每次有新的未知会话消息到达时自增，用于触发会话列表刷新 */
  convRefreshKey: number

  // ── Actions ──────────────────────────────────────────────────────────────

  setOpen: (open: boolean) => void
  toggleOpen: () => void
  setMinimized: (v: boolean) => void
  setMaximized: (v: boolean) => void
  setActiveConv: (id: number | null) => void
  setConversations: (list: ImConversationVO[]) => void
  updateConversation: (conv: Partial<ImConversationVO> & { conversationId: number }) => void
  setMessages: (convId: number, msgs: ImMessageVO[]) => void
  appendMessage: (msg: ImMessageVO) => void
  updateMessageStatus: (msgId: number, status: number) => void
  prependMessages: (convId: number, msgs: ImMessageVO[]) => void
  setContactGroups: (groups: ImContactGroupVO[]) => void
  clearUnread: (convId: number) => void
  computeUnreadTotal: () => void
}

export const useImStore = create<ImState>((set, get) => ({
  open: false,
  minimized: false,
  maximized: false,
  conversations: [],
  activeConvId: null,
  messages: {},
  contactGroups: [],
  unreadTotal: 0,
  convRefreshKey: 0,

  setOpen: (open) => set({ open, minimized: false }),
  toggleOpen: () => set(s => ({ open: !s.open, minimized: false })),
  setMinimized: (v) => set({ minimized: v, maximized: v ? false : undefined }),
  setMaximized: (v) => set({ maximized: v, minimized: v ? false : undefined }),

  setActiveConv: (id) => {
    set({ activeConvId: id })
    if (id != null) get().clearUnread(id)
  },

  setConversations: (list) => {
    set({ conversations: list })
    get().computeUnreadTotal()
  },

  updateConversation: (conv) => set(s => ({
    conversations: s.conversations.map(c =>
      c.conversationId === conv.conversationId ? { ...c, ...conv } : c
    ),
  })),

  setMessages: (convId, msgs) => set(s => ({
    messages: { ...s.messages, [convId]: msgs },
  })),

  appendMessage: (msg) => {
    set(s => {
      const prev = s.messages[msg.conversationId] ?? []
      const exists = prev.some(m => m.msgId === msg.msgId)
      if (exists) return s
      const updated = [...prev, msg]

      const convExists = s.conversations.some(c => c.conversationId === msg.conversationId)
      if (!convExists) {
        // 陌生会话：触发刷新信号，由 ImChatPanel 监听并重新拉取会话列表
        return {
          messages: { ...s.messages, [msg.conversationId]: updated },
          convRefreshKey: s.convRefreshKey + 1,
        }
      }

      const conversations = s.conversations.map(c =>
        c.conversationId === msg.conversationId
          ? {
              ...c,
              lastMsgPreview: msg.msgType === 1 ? msg.content : '[媒体消息]',
              lastMsgTime: msg.createTime,
              unreadCount: s.activeConvId === msg.conversationId
                ? 0
                : (c.unreadCount ?? 0) + 1,
            }
          : c
      )
      return { messages: { ...s.messages, [msg.conversationId]: updated }, conversations }
    })
    get().computeUnreadTotal()
  },

  updateMessageStatus: (msgId, status) => set(s => {
    const updated: Record<number, ImMessageVO[]> = {}
    for (const [convId, msgs] of Object.entries(s.messages)) {
      updated[Number(convId)] = msgs.map(m => m.msgId === msgId ? { ...m, status } : m)
    }
    return { messages: updated }
  }),

  prependMessages: (convId, msgs) => set(s => {
    const prev = s.messages[convId] ?? []
    const newIds = new Set(msgs.map(m => m.msgId))
    const merged = [...msgs, ...prev.filter(m => !newIds.has(m.msgId))]
    return { messages: { ...s.messages, [convId]: merged } }
  }),

  setContactGroups: (groups) => set({ contactGroups: groups }),

  clearUnread: (convId) => {
    set(s => ({
      conversations: s.conversations.map(c =>
        c.conversationId === convId ? { ...c, unreadCount: 0 } : c
      ),
    }))
    get().computeUnreadTotal()
  },

  computeUnreadTotal: () => {
    const total = get().conversations.reduce((sum, c) => sum + (c.unreadCount ?? 0), 0)
    set({ unreadTotal: total })
  },
}))
