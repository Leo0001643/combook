/**
 * 门店订单管理 — 手环 Session 列表 + 新增门店订单 + 结算
 *
 * 业务流程：
 *   前台发手环 → 录入系统(手环号+技师) → 消费项叠加 → 前台结算(多种支付方式) → 完结
 */
import React, { useState, useEffect, useCallback } from 'react'
import {
  Table, Input, Select, Button, Space, Typography, message,
  Modal, Form, InputNumber, Drawer, Descriptions,
  Badge, Row, Col, Popconfirm, Avatar,
} from 'antd'
import {
  PlusOutlined, SearchOutlined, ReloadOutlined, SettingOutlined,
  UserOutlined, EditOutlined, CheckCircleOutlined, CloseCircleOutlined,
  DollarOutlined, WalletOutlined, QrcodeOutlined, ClockCircleOutlined,
  ShoppingCartOutlined, PhoneOutlined, CreditCardOutlined, IdcardOutlined,
  DeleteOutlined,
} from '@ant-design/icons'
import dayjs from 'dayjs'
import { fmtTime, dayjsFromApi } from '../../utils/time'
import type { ColumnsType } from 'antd/es/table'
import { col, styledTableComponents, INPUT_STYLE } from '../../components/common/tableComponents'
import PagePagination from '../../components/common/PagePagination'
import { useTableBodyHeight } from '../../hooks/useTableBodyHeight'
import { usePortalScope } from '../../hooks/usePortalScope'
import { merchantPortalApi } from '../../api/api'
import { useServiceCategories } from '../../hooks/useServiceCategories'
import { useDict, parseRemark } from '../../hooks/useDict'

const { Text } = Typography
const { Option } = Select
const { TextArea } = Input


// 💡 只有银行转账（method=4）需要选择币种，其余支付方式使用商户默认币种
const PAY_METHODS_FB: Record<number, { label: string; color: string; icon: React.ReactNode; needCurrency?: boolean }> = {
  1: { label: '现金',     color: '#10b981', icon: '💵' },
  2: { label: '微信支付', color: '#07C160', icon: <span style={{ display:'inline-flex',alignItems:'center',justifyContent:'center',width:18,height:18,background:'#07C160',borderRadius:4,fontSize:11,color:'#fff',fontWeight:900,verticalAlign:'middle',lineHeight:'18px' }}>W</span> },
  3: { label: '支付宝',   color: '#1677FF', icon: <span style={{ display:'inline-flex',alignItems:'center',justifyContent:'center',width:18,height:18,background:'#1677FF',borderRadius:4,fontSize:11,color:'#fff',fontWeight:900,verticalAlign:'middle',lineHeight:'18px',fontStyle:'italic' }}>a</span> },
  4: { label: '银行转账', color: '#6366f1', icon: '🏦', needCurrency: true },
  5: { label: 'USDT',    color: '#f59e0b', icon: '₮'  },
  6: { label: '其它',    color: '#94a3b8', icon: '💳' },
}

const SESSION_STATUS_FB: Record<number, { text: string; color: string; badge: 'default' | 'processing' | 'success' | 'error' | 'warning' }> = {
  0: { text: '待服务', color: '#3b82f6', badge: 'processing' },
  1: { text: '服务中', color: '#f97316', badge: 'processing' },
  2: { text: '待结算', color: '#f59e0b', badge: 'warning' },
  3: { text: '已结算', color: '#10b981', badge: 'success' },
  4: { text: '已取消', color: '#94a3b8', badge: 'default' },
}

// ── Mock data（前端先跑通，后端接口就绪后替换）────────────────────────────────

// ════════════════════════════════════════════════════════════════════════════════
// 服务进度条组件（支持实时倒计时动画）
// ────────────────────────────────────────────────────────────────────────────────

const SVC_COLORS = [
  { bar: 'linear-gradient(90deg,#6366f1,#8b5cf6,#a78bfa)', glow: 'rgba(99,102,241,0.35)', text: '#6366f1', bg: '#eef2ff', border: '#c7d2fe' },
  { bar: 'linear-gradient(90deg,#10b981,#34d399,#6ee7b7)', glow: 'rgba(16,185,129,0.35)', text: '#059669', bg: '#ecfdf5', border: '#a7f3d0' },
  { bar: 'linear-gradient(90deg,#f59e0b,#fbbf24,#fde68a)', glow: 'rgba(245,158,11,0.35)', text: '#d97706', bg: '#fffbeb', border: '#fde68a' },
  { bar: 'linear-gradient(90deg,#3b82f6,#60a5fa,#93c5fd)', glow: 'rgba(59,130,246,0.35)', text: '#2563eb', bg: '#eff6ff', border: '#bfdbfe' },
  { bar: 'linear-gradient(90deg,#ec4899,#f472b6,#fbcfe8)', glow: 'rgba(236,72,153,0.35)', text: '#db2777', bg: '#fdf2f8', border: '#fbcfe8' },
]

const SVC_STATUS_CFG_FB = {
  0: { label: '待服务', badge: '#9ca3af', badgeBg: '#f3f4f6', icon: '⏳' },
  1: { label: '服务中', badge: '#f97316', badgeBg: '#fff7ed', icon: '🔄' },
  2: { label: '已完成', badge: '#10b981', badgeBg: '#ecfdf5', icon: '✅' },
}

function ServiceProgressBar({ item, colorIdx, compact = false, svcStatusMap }: {
  item: any; colorIdx: number; compact?: boolean
  svcStatusMap?: Record<number, { label: string; badge: string; badgeBg: string; icon: string }>
}) {
  const [now, setNow] = React.useState(dayjs())
  const color = SVC_COLORS[colorIdx % SVC_COLORS.length]
  const statusMap = svcStatusMap ?? SVC_STATUS_CFG_FB
  const cfg = statusMap[item.svcStatus as 0|1|2] ?? statusMap[0] ?? SVC_STATUS_CFG_FB[0]

  React.useEffect(() => {
    if (item.svcStatus !== 1) return
    const id = setInterval(() => setNow(dayjs()), 1000)
    return () => clearInterval(id)
  }, [item.svcStatus])

  let pct = 0
  let elapsed = 0
  let remaining = item.duration

  if (item.svcStatus === 1 && item.startTime) {
    const start = dayjsFromApi(item.startTime)
    elapsed = start ? now.diff(start, 'minute') : 0
    pct = Math.min(100, Math.round((elapsed / item.duration) * 100))
    remaining = Math.max(0, item.duration - elapsed)
  } else if (item.svcStatus === 2) {
    pct = 100
    elapsed = item.duration
    remaining = 0
  }

  const animId = `prog-${item.serviceId}-${colorIdx}`

  if (compact) {
    // ── 表格单元格内紧凑版 ──
    return (
      <div style={{ marginBottom: 5 }}>
        <style>{`
          @keyframes ${animId}-shimmer {
            0%   { background-position: -200% center; }
            100% { background-position: 200% center; }
          }
        `}</style>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 3 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
            <span style={{ fontSize: 9, padding: '1px 5px', borderRadius: 6, background: cfg.badgeBg, color: cfg.badge, fontWeight: 700, whiteSpace: 'nowrap' }}>
              {cfg.icon} {cfg.label}
            </span>
            <span style={{ fontSize: 11, fontWeight: 600, color: '#374151' }}>{item.name}</span>
          </div>
          <span style={{ fontSize: 10, color: '#9ca3af', flexShrink: 0 }}>{item.duration}min</span>
        </div>
        <div style={{ position: 'relative', height: 5, borderRadius: 8, background: '#f1f5f9', overflow: 'hidden' }}>
          <div style={{
            position: 'absolute', left: 0, top: 0, bottom: 0,
            width: `${pct}%`,
            background: item.svcStatus === 1
              ? `${color.bar}, linear-gradient(90deg, transparent 25%, rgba(255,255,255,0.4) 50%, transparent 75%)`
              : color.bar,
            backgroundSize: item.svcStatus === 1 ? '200% 100%, 200% 100%' : '100% 100%',
            animation: item.svcStatus === 1 ? `${animId}-shimmer 1.8s linear infinite` : 'none',
            borderRadius: 8,
            boxShadow: item.svcStatus === 1 ? `0 0 6px ${color.glow}` : 'none',
            transition: 'width 1s linear',
          }} />
        </div>
        {item.svcStatus === 1 && (
          <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 2, fontSize: 9, color: '#9ca3af' }}>
            <span>已用 {elapsed}min</span>
            <span style={{ color: color.text, fontWeight: 700 }}>剩余 {remaining}min</span>
          </div>
        )}
      </div>
    )
  }

  // ── 详情抽屉内完整版 ──
  return (
    <div style={{
      borderRadius: 14, overflow: 'hidden',
      border: `1.5px solid ${color.border}`,
      marginBottom: 10,
    }}>
      <style>{`
        @keyframes ${animId}-shimmer {
          0%   { background-position: -200% center; }
          100% { background-position: 200% center; }
        }
        @keyframes ${animId}-pulse {
          0%, 100% { opacity: 1; }
          50%       { opacity: 0.55; }
        }
      `}</style>

      {/* 头部 */}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 10,
        padding: '10px 14px', background: color.bg,
        borderBottom: `1px solid ${color.border}`,
      }}>
        <div style={{
          width: 28, height: 28, borderRadius: 8, flexShrink: 0,
          background: color.bar, boxShadow: `0 2px 8px ${color.glow}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 13,
          animation: item.svcStatus === 1 ? `${animId}-pulse 2s ease-in-out infinite` : 'none',
        }}>
          <span>{cfg.icon}</span>
        </div>
        <div style={{ flex: 1 }}>
          <div style={{ fontWeight: 700, fontSize: 14, color: '#111827' }}>{item.name}</div>
          <div style={{ fontSize: 11, color: '#9ca3af', marginTop: 1 }}>时长 {item.duration}min · ${item.unitPrice}</div>
        </div>
        <div style={{
          padding: '3px 10px', borderRadius: 20,
          background: cfg.badgeBg, color: cfg.badge, fontSize: 11, fontWeight: 800,
        }}>
          {cfg.label}
        </div>
      </div>

      {/* 进度条 */}
      <div style={{ padding: '12px 14px', background: '#fff' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 7 }}>
          <span style={{ fontSize: 12, fontWeight: 600, color: '#6b7280' }}>服务进度</span>
          <span style={{ fontSize: 16, fontWeight: 900, color: color.text }}>{pct}%</span>
        </div>

        <div style={{ position: 'relative', height: 10, borderRadius: 10, background: '#f1f5f9', overflow: 'hidden', marginBottom: 8 }}>
          <div style={{
            position: 'absolute', left: 0, top: 0, bottom: 0,
            width: `${pct}%`, borderRadius: 10,
            background: item.svcStatus === 1
              ? `${color.bar}, linear-gradient(90deg, transparent 20%, rgba(255,255,255,0.5) 50%, transparent 80%)`
              : color.bar,
            backgroundSize: item.svcStatus === 1 ? '200% 100%, 200% 100%' : '100% 100%',
            animation: item.svcStatus === 1 ? `${animId}-shimmer 1.6s linear infinite` : 'none',
            boxShadow: item.svcStatus === 1 ? `0 0 10px ${color.glow}` : 'none',
            transition: 'width 1s linear',
          }} />
          {/* 进度头光点 */}
          {item.svcStatus === 1 && pct > 2 && (
            <div style={{
              position: 'absolute', top: 1, bottom: 1, width: 8, borderRadius: '50%',
              left: `calc(${pct}% - 4px)`,
              background: '#fff',
              boxShadow: `0 0 6px ${color.glow}`,
              animation: `${animId}-pulse 1.2s ease-in-out infinite`,
            }} />
          )}
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8 }}>
          {[
            { label: '总时长', val: `${item.duration}min` },
            { label: '已用时', val: item.svcStatus === 0 ? '—' : `${elapsed}min` },
            { label: item.svcStatus === 2 ? '已完成' : '剩余', val: item.svcStatus === 0 ? `${item.duration}min` : item.svcStatus === 2 ? '完成' : `${remaining}min`, highlight: item.svcStatus === 1 },
          ].map((s, i) => (
            <div key={i} style={{ textAlign: 'center', padding: '6px 8px', borderRadius: 8, background: '#f8fafc' }}>
              <div style={{ fontSize: 10, color: '#9ca3af', marginBottom: 2 }}>{s.label}</div>
              <div style={{ fontSize: 13, fontWeight: 800, color: s.highlight ? color.text : '#374151' }}>{s.val}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}

// ════════════════════════════════════════════════════════════════════════════════
export default function WalkinSessionPage() {
  const { ref, height: tableBodyH } = useTableBodyHeight(46)
  const scope = usePortalScope()

  // ── 字典数据（动态覆盖模块级静态常量，所有下游用法无需修改）──────────────────
  const { items: dictPayItems }     = useDict('walkin_pay_type')
  const { items: sessionItems } = useDict('walkin_session_status')
  const { items: svcItems }     = useDict('walkin_svc_status')

  const PAY_METHODS: Record<number, { label: string; color: string; icon: React.ReactNode; needCurrency?: boolean }> =
    dictPayItems.length > 0
      ? Object.fromEntries(dictPayItems.map(i => {
          const { color, icon, needCurrency } = parseRemark(i.remark)
          return [Number(i.dictValue), {
            label: i.labelZh,
            color: color ?? '#94a3b8',
            icon: icon ?? '💳',
            needCurrency: needCurrency ?? false,
          }]
        }))
      : PAY_METHODS_FB

  const SESSION_STATUS: Record<number, { text: string; color: string; badge: 'default' | 'processing' | 'success' | 'error' | 'warning' }> =
    sessionItems.length > 0
      ? Object.fromEntries(sessionItems.map(i => {
          const { color, badge } = parseRemark(i.remark)
          return [Number(i.dictValue), { text: i.labelZh, color: color ?? '#94a3b8', badge: (badge ?? 'default') as any }]
        }))
      : SESSION_STATUS_FB

  const SVC_STATUS_CFG: Record<number, { label: string; badge: string; badgeBg: string; icon: string }> =
    svcItems.length > 0
      ? Object.fromEntries(svcItems.map(i => {
          const { color, icon } = parseRemark(i.remark)
          return [Number(i.dictValue), { label: i.labelZh, badge: color ?? '#9ca3af', badgeBg: `${color ?? '#9ca3af'}20`, icon: icon ?? '⏳' }]
        }))
      : SVC_STATUS_CFG_FB

  // DB service categories (sub-items only)
  const { categories: dbServices } = useServiceCategories()

  const [sessions,  setSessions]  = useState<any[]>([])
  const [total,     setTotal]     = useState(0)
  const [loading,   setLoading]   = useState(false)
  const [page,     setPage]     = useState(1)
  const [pageSize, setPageSize] = useState(20)
  const [keyword,  setKeyword]  = useState('')
  const [statusFilter, setStatusFilter] = useState<number | undefined>()

  // 商户已启用的币种
  const [currencies, setCurrencies] = useState<any[]>([])
  const defaultCurrency = currencies.find(c => c.isDefault)?.currencyCode ?? currencies[0]?.currencyCode ?? 'USD'

  // 新增门店订单弹窗
  const [createOpen,    setCreateOpen]    = useState(false)
  const [createForm]                      = Form.useForm()
  const [createLoading, setCreateLoading] = useState(false)
  // 当前选中的技师ID（用于实时查询该技师的专属价格）
  const [createTechId, setCreateTechId]   = useState<number | null>(null)
  // 技师专属定价缓存：technicianId → serviceItemId → price
  const [techPricing, setTechPricing] = useState<Record<number, number>>({})
  // 新增门店订单时的服务消费列表
  const [orderItems, setOrderItems] = useState<Array<{
    serviceId: number; name: string; duration: number; unitPrice: number; qty: number
  }>>([])

  /** 获取某服务对特定技师的实际价格（专属价 > 系统指导价 > 0） */
  const getEffectivePrice = (serviceId: number, techId: number | null): number => {
    const svc = dbServices.find(s => s.id === serviceId)
    if (techId && techPricing[serviceId] != null) return techPricing[serviceId]
    return svc?.price ?? 0
  }

  // 当选中技师变化时，加载该技师的专属定价，并刷新已选服务项目的价格
  const onCreateTechChange = async (techId: number) => {
    setCreateTechId(techId)
    let pricing: Record<number, number> = {}
    try {
      const res = await merchantPortalApi.technicianPricingList(techId)
      const list: { serviceItemId: number; price: number }[] = res.data?.data ?? []
      list.forEach(p => { pricing[p.serviceItemId] = Number(p.price) })
    } catch { /* 专属定价不可用时回退系统指导价 */ }
    setTechPricing(pricing)
    setOrderItems(prev => prev.map(item => ({
      ...item,
      unitPrice: pricing[item.serviceId] ?? dbServices.find(s => s.id === item.serviceId)?.price ?? item.unitPrice,
    })))
  }

  const addOrderItem = (serviceId: number) => {
    const svc = dbServices.find(s => s.id === serviceId)
    if (!svc) return
    if (orderItems.some(i => i.serviceId === serviceId)) {
      message.warning('该服务已在消费列表中')
      return
    }
    const price = getEffectivePrice(serviceId, createTechId)
    setOrderItems(prev => [...prev, {
      serviceId: svc.id, name: svc.nameZh, duration: svc.duration ?? 60, unitPrice: price, qty: 1,
    }])
  }

  const removeOrderItem = (serviceId: number) =>
    setOrderItems(prev => prev.filter(i => i.serviceId !== serviceId))

  const updateOrderItemPrice = (serviceId: number, price: number) =>
    setOrderItems(prev => prev.map(i => i.serviceId === serviceId ? { ...i, unitPrice: price } : i))

  const orderTotal = orderItems.reduce((s, i) => s + i.unitPrice * i.qty, 0)

  // 编辑订单弹窗
  const [editOpen,   setEditOpen]   = useState(false)
  const [editTarget, setEditTarget] = useState<any>(null)
  const [editItems,  setEditItems]  = useState<Array<{
    serviceId: number; name: string; duration: number; unitPrice: number; qty: number
  }>>([])

  const openEdit = (record: any) => {
    const items = record.orderItems ?? []
    setEditTarget(record)
    setEditItems(items.map((it: any) => ({ ...it })))
    setEditOpen(true)
  }

  const editTotal = editItems.reduce((s, i) => s + i.unitPrice * i.qty, 0)

  const addEditItem = (serviceId: number) => {
    const svc = dbServices.find(s => s.id === serviceId)
    if (!svc) return
    if (editItems.some(i => i.serviceId === serviceId)) {
      message.warning('该服务已在列表中')
      return
    }
    const price = svc.price ?? 0
    setEditItems(prev => [...prev, { serviceId: svc.id, name: svc.nameZh, duration: svc.duration ?? 60, unitPrice: price, qty: 1 }])
  }

  const handleSaveEdit = () => {
    if (!editTarget) return
    message.info('编辑功能需调用接口，请确认后端支持')
    setEditOpen(false)
  }

  // 详情抽屉
  const [detailOpen, setDetailOpen] = useState(false)
  const [detail,     setDetail]     = useState<any>(null)

  // 结算弹窗
  const [settleOpen,   setSettleOpen]   = useState(false)
  const [settleTarget, setSettleTarget] = useState<any>(null)
  const [settleForm]                    = Form.useForm()
  const [settleLoading, setSettleLoading] = useState(false)
  const [payItems,  setPayItems]  = useState<{ method: number; currency: string; amount: number }[]>([])

  useEffect(() => {
    scope.enabledCurrencies()
      .then(res => setCurrencies(res.data?.data ?? []))
      .catch(() => {})
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  // 技师列表（从 API 读取，用于新增订单/编辑订单技师选择器）
  const [technicians, setTechnicians] = useState<any[]>([])
  useEffect(() => {
    merchantPortalApi.technicians({ page: 1, size: 200 })
      .then(res => {
        const d = res.data?.data
        const list: any[] = Array.isArray(d)
          ? d
          : Array.isArray(d?.records)
          ? d.records
          : Array.isArray(d?.list)
          ? d.list
          : []
        setTechnicians(list)
      })
      .catch(() => {})
  }, [])

  const fetchList = useCallback(() => {
    setLoading(true)
    merchantPortalApi.walkinList({
      page, size: pageSize,
      keyword: keyword || undefined,
      status: statusFilter,
    })
      .then(res => {
        const data = res.data?.data ?? res.data
        const list = data?.list ?? data?.records ?? []
        setSessions(list)
        setTotal(data?.total ?? list.length)
      })
      .catch(() => {
        setSessions([])
        setTotal(0)
      })
      .finally(() => setLoading(false))
  }, [keyword, statusFilter, page, pageSize])

  useEffect(() => { fetchList() }, [fetchList])

  const handleCreate = async () => {
    let values: any
    try {
      values = await createForm.validateFields()
    } catch {
      return
    }
    if (orderItems.length === 0) {
      message.warning('请至少添加一项消费服务')
      return
    }
    setCreateLoading(true)
    try {
      const tech = technicians.find((t: any) => t.id === values.technicianId)
      const totalAmount = orderItems.reduce((s, i) => s + i.unitPrice * i.qty, 0)
      // 使用原子接口：session + 所有服务项在同一事务内完成，任一失败全部回滚
      const itemsJson = JSON.stringify(orderItems.map(i => ({
        serviceItemId:   i.serviceId,
        serviceName:     i.name,
        serviceDuration: i.duration,
        unitPrice:       i.unitPrice,
      })))
      await merchantPortalApi.walkinCreateWithItems({
        wristbandNo:      values.wristbandNo,
        memberName:       values.memberName   ?? '',
        memberMobile:     values.memberMobile ?? '',
        technicianId:     tech?.id,
        technicianName:   tech?.nickname ?? tech?.name ?? '',
        technicianNo:     tech?.techNo   ?? tech?.no   ?? '',
        technicianMobile: tech?.mobile   ?? '',
        remark:           '',
        itemsJson,
      })
      fetchList()
      message.success(`手环 ${values.wristbandNo} 下单成功，共 ${orderItems.length} 项服务，合计 $${totalAmount}`)
      createForm.resetFields()
      setOrderItems([])
      setCreateTechId(null)
      setCreateOpen(false)
    } catch { message.error('创建失败，请检查网络后重试') }
    finally { setCreateLoading(false) }
  }

  const openSettle = (record: any) => {
    setSettleTarget(record)
    settleForm.setFieldsValue({ remark: '' })
    setPayItems([{ method: 1, currency: defaultCurrency, amount: record.totalAmount }])
    setSettleOpen(true)
  }

  const handleSettle = async () => {
    setSettleLoading(true)
    try {
      const paidTotal = payItems.reduce((s, p) => s + (p.amount || 0), 0)
      await merchantPortalApi.walkinSettle(settleTarget.id, paidTotal)
      message.success('结算成功！')
      setSettleOpen(false)
      fetchList()
    } catch { message.error('结算失败，请重试') }
    finally { setSettleLoading(false) }
  }

  const payTotal = payItems.reduce((s, p) => s + (p.amount || 0), 0)

  const columns: ColumnsType<any> = [
    // ① 手环编号 — 固定左列
    {
      title: col(<QrcodeOutlined style={{ color: '#64748b' }} />, '手环编号', 'center'),
      dataIndex: 'wristbandNo', key: 'wristbandNo', width: 110, align: 'center', fixed: 'left',
      render: v => (
        <span style={{
          fontFamily: 'monospace', fontSize: 18, fontWeight: 900,
          color: '#6366f1', letterSpacing: 2,
          padding: '2px 10px', background: '#eef2ff', borderRadius: 8,
        }}>{v}</span>
      ),
    },
    // ② 订单流水
    {
      title: col(<UserOutlined style={{ color: '#64748b' }} />, '订单流水', 'left'),
      dataIndex: 'sessionNo', width: 155, align: 'left',
      render: v => <Text style={{ fontSize: 11, fontFamily: 'monospace', color: '#6b7280' }}>{v}</Text>,
    },
    // ③ 客户信息
    {
      title: col(<UserOutlined style={{ color: '#64748b' }} />, '客户信息', 'left'), key: 'member', width: 150, align: 'left',
      render: (_, r) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, width: '100%' }}>
          <Avatar
            size={32} icon={<UserOutlined />}
            style={{
              background: r.memberName ? 'linear-gradient(135deg,#6366f1,#8b5cf6)' : '#e5e7eb',
              flexShrink: 0, fontSize: 13, fontWeight: 700,
            }}
          >
            {r.memberName ? r.memberName.charAt(0) : undefined}
          </Avatar>
          <div style={{ minWidth: 0, flex: 1 }}>
            <div style={{ fontWeight: 600, color: '#111827', fontSize: 13 }}>
              {r.memberName || <Text type="secondary" style={{ fontSize: 12 }}>散客</Text>}
            </div>
            {r.memberMobile && (
              <div style={{ fontSize: 11, color: '#9ca3af', marginTop: 1 }}>
                <PhoneOutlined style={{ marginRight: 3 }} />{r.memberMobile}
              </div>
            )}
          </div>
        </div>
      ),
    },
    // ④ 服务技师（移至客户信息后）
    {
      title: col(<IdcardOutlined style={{ color: '#64748b' }} />, '服务技师', 'left'), key: 'technician', width: 170, align: 'left',
      render: (_, r) => r.technicianName ? (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, width: '100%' }}>
          <Avatar
            size={32}
            style={{ background: 'linear-gradient(135deg,#f59e0b,#f97316)', fontWeight: 700, fontSize: 13, flexShrink: 0 }}
          >
            {r.technicianName.charAt(0)}
          </Avatar>
          <div style={{ minWidth: 0, flex: 1 }}>
            <div style={{ fontWeight: 600, color: '#111827', fontSize: 13 }}>{r.technicianName}</div>
            <div style={{ fontSize: 11, color: '#9ca3af', marginTop: 1 }}>
              <IdcardOutlined style={{ marginRight: 3 }} />{r.technicianNo}
              {r.technicianMobile && <span style={{ marginLeft: 6 }}><PhoneOutlined style={{ marginRight: 2 }} />{r.technicianMobile}</span>}
            </div>
          </div>
        </div>
      ) : (
        <Text type="secondary" style={{ fontSize: 12 }}>待分配</Text>
      ),
    },
    // ⑤ 消费金额（移至服务技师后）
    {
      title: col(<DollarOutlined style={{ color: '#64748b' }} />, '消费金额', 'center'), key: 'amount', width: 115, align: 'center',
      render: (_, r) => (
        <div>
          <div style={{ fontSize: 15, fontWeight: 800, color: '#F5A623' }}>${r.totalAmount.toFixed(2)}</div>
          {r.paidAmount > 0 && <div style={{ fontSize: 10, color: '#10b981' }}>已收 ${r.paidAmount.toFixed(2)}</div>}
        </div>
      ),
    },
    // ⑥ 状态（移至消费金额后）
    {
      title: col(<SettingOutlined style={{ color: '#64748b' }} />, '状态', 'center'), dataIndex: 'status', width: 90, align: 'center',
      render: s => {
        const cfg = SESSION_STATUS[s] ?? { text: '未知', badge: 'default' }
        return <Badge status={cfg.badge} text={<span style={{ fontWeight: 600, color: cfg.color }}>{cfg.text}</span>} />
      },
    },
    // ⑦ 服务项目（含实时进度）
    {
      title: col(<ShoppingCartOutlined style={{ color: '#64748b' }} />, '服务项目', 'left'), key: 'service', width: 210, align: 'left',
      render: (_, r) => {
        const items = (r.orderItems?.length ? r.orderItems : null) ?? []
        if (!items.length) return <span style={{ fontSize: 12, color: '#9ca3af' }}>待录入</span>
        return (
          <div style={{ paddingTop: 2, paddingBottom: 2 }}>
            {items.map((it: { serviceId: number }, idx: number) => (
              <ServiceProgressBar key={it.serviceId} item={it} colorIdx={idx} compact svcStatusMap={SVC_STATUS_CFG} />
            ))}
          </div>
        )
      },
    },
    // ⑧ 到店时间（移至最后）
    {
      title: col(<ClockCircleOutlined style={{ color: '#64748b' }} />, '到店时间', 'left'), dataIndex: 'checkInTime', width: 115, align: 'left',
      render: v => <Text style={{ fontSize: 12 }}>{v != null && v !== '' ? fmtTime(v, 'MM-DD HH:mm') : '—'}</Text>,
    },
    // ⑨ 操作 — 固定右列
    {
      title: col(<SettingOutlined style={{ color: '#64748b' }} />, '操作', 'center'), key: 'action', fixed: 'right', width: 285,
      render: (_, r) => (
        <Space size={4} style={{ whiteSpace: 'nowrap', flexWrap: 'nowrap' }}>
          <Button size="small" type="primary" ghost icon={<EditOutlined />}
            style={{ borderRadius: 6, fontSize: 12 }}
            onClick={() => { setDetail(r); setDetailOpen(true) }}>详情</Button>
          {(r.status === 0 || r.status === 1 || r.status === 2) && (
            <Button size="small" icon={<ShoppingCartOutlined />}
              style={{ borderRadius: 6, fontSize: 12, color: '#6366f1', borderColor: '#a5b4fc' }}
              onClick={() => openEdit(r)}>修改</Button>
          )}
          {r.status !== 3 && r.status !== 4 && (
            <Button size="small" icon={<CreditCardOutlined />}
              style={{ borderRadius: 6, fontSize: 12, color: '#10b981', borderColor: '#6ee7b7' }}
              onClick={() => openSettle(r)}>结算</Button>
          )}
          {r.status === 0 && (
            <Popconfirm
              title="确认取消此订单？"
              description="该客户尚未开始任何服务项目，确认取消。"
              onConfirm={async () => {
                try {
                  await merchantPortalApi.walkinCancel(r.id, '前台取消')
                  fetchList()
                  message.success('订单已取消')
                } catch {
                  // 拦截器处理
                }
              }}
            >
              <Button size="small" danger icon={<CloseCircleOutlined />} style={{ borderRadius: 6, fontSize: 12 }}>取消</Button>
            </Popconfirm>
          )}
        </Space>
      ),
    },
  ]

  const stats = [
    { label: '今日订单', value: sessions.length, icon: <UserOutlined />, color: '#6366f1', bg: '#eef2ff', border: '#c7d2fe' },
    { label: '服务中',   value: sessions.filter(s => s.status === 1).length, icon: <ClockCircleOutlined />, color: '#f97316', bg: '#fff7ed', border: '#fed7aa' },
    { label: '待结算',   value: sessions.filter(s => s.status === 2).length, icon: <WalletOutlined />,     color: '#f59e0b', bg: '#fffbeb', border: '#fde68a' },
    { label: '今日营收', value: `$${sessions.filter(s => s.status === 3).reduce((s, r) => s + r.paidAmount, 0).toFixed(0)}`, icon: <DollarOutlined />, color: '#10b981', bg: '#ecfdf5', border: '#a7f3d0' },
  ]

  return (
    <div style={{ marginTop: -24 }}>

      {/* ── 粘性复合头部 ────────────────────────────────────────────────── */}
      <div style={{
        position: 'sticky', top: 64, zIndex: 88,
        marginLeft: -24, marginRight: -24,
        background: 'rgba(255,255,255,0.97)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderBottom: '1px solid rgba(0,0,0,0.07)',
        boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
      }}>
        {/* 标题行 */}
        <div style={{ display: 'flex', alignItems: 'center', padding: '10px 24px 0', gap: 16, flexWrap: 'wrap' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, flex: '0 0 auto' }}>
            <div style={{
              width: 34, height: 34, borderRadius: 10,
              background: 'linear-gradient(135deg,#4f46e5,#7c3aed)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: '0 4px 12px rgba(79,70,229,0.35)', flexShrink: 0,
            }}>
              <QrcodeOutlined style={{ color: '#fff', fontSize: 16 }} />
            </div>
            <div>
              <div style={{ fontWeight: 700, fontSize: 15, color: '#111827', lineHeight: 1.2 }}>门店订单管理</div>
              <div style={{ fontSize: 11, color: '#9ca3af', lineHeight: 1.3, marginTop: 1 }}>手环点单 · 多服务叠加 · 一键结算</div>
            </div>
          </div>
          <div style={{ width: 1, height: 28, margin: '0 4px', background: '#e5e7eb', flexShrink: 0 }} />
          <div style={{ display: 'flex', gap: 8, flex: 1, flexWrap: 'wrap', alignItems: 'center' }}>
            {stats.map(s => (
              <div key={s.label} style={{
                display: 'flex', alignItems: 'center', gap: 6,
                padding: '5px 12px', borderRadius: 20,
                background: s.bg, border: `1px solid ${s.border}`,
              }}>
                <span style={{ fontSize: 12 }}>{s.icon}</span>
                <span style={{ color: s.color, fontWeight: 700, fontSize: 13, lineHeight: 1 }}>{s.value}</span>
                <span style={{ color: s.color, fontSize: 11, opacity: 0.8 }}>{s.label}</span>
              </div>
            ))}
          </div>
          <Button
            type="primary" icon={<PlusOutlined />}
            style={{
              flexShrink: 0, borderRadius: 8, border: 'none', fontSize: 13,
              background: 'linear-gradient(135deg,#4f46e5,#7c3aed)',
              boxShadow: '0 2px 8px rgba(79,70,229,0.35)',
            }}
            onClick={() => setCreateOpen(true)}
          >新增门店订单</Button>
        </div>

        {/* 筛选行 */}
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', padding: '10px 24px 12px' }}>
          <Input
            prefix={<SearchOutlined style={{ color: '#6366f1', fontSize: 12 }} />}
            placeholder="手环号 / 客户姓名"
            value={keyword} onChange={e => setKeyword(e.target.value)}
            style={{ ...INPUT_STYLE, width: 180 }}
            allowClear
          />
          <Select
            placeholder={<><QrcodeOutlined style={{ color: '#6366f1', marginRight: 5 }} />订单状态</>}
            value={statusFilter}
            onChange={setStatusFilter} allowClear
            style={{ width: 140 }}
          >
            {Object.entries(SESSION_STATUS).map(([k, v]) => (
              <Option key={k} value={+k}>
                <Badge status={v.badge} text={v.text} />
              </Option>
            ))}
          </Select>
          <div style={{ flex: 1 }} />
          <Button icon={<ReloadOutlined />} style={{ borderRadius: 8 }} onClick={fetchList}>刷新</Button>
        </div>
      </div>

      {/* ── 数据表格 ────────────────────────────────────────────────────── */}
      <div ref={ref} className="walkin-table" style={{
        marginLeft: -24, marginRight: -24, marginBottom: -24,
        background: '#fff', borderTop: '1px solid #eef0f8',
      }}>
        <Table
          dataSource={sessions}
          columns={columns}
          components={styledTableComponents}
          rowKey="id"
          size="middle"
          loading={loading}
          scroll={{ x: 1380, y: tableBodyH }}
          pagination={false}
        />
        <PagePagination
          total={total} current={page} pageSize={pageSize}
          onChange={setPage} onSizeChange={setPageSize}
        />
      </div>

      {/* ── 新增门店订单弹窗 ─────────────────────────────────────────────── */}
      <Modal
        title={
          <div style={{
            background: 'linear-gradient(135deg,#1e1b4b,#4338ca)',
            margin: '-20px -24px 0', padding: '10px 20px',
            borderRadius: '8px 8px 0 0', display: 'flex', alignItems: 'center', gap: 10,
          }}>
            <div style={{
              width: 36, height: 36, borderRadius: 10, flexShrink: 0,
              background: 'rgba(255,255,255,0.15)', backdropFilter: 'blur(8px)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <QrcodeOutlined style={{ color: '#fff', fontSize: 17 }} />
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ color: '#fff', fontWeight: 800, fontSize: 14, lineHeight: 1.25 }}>新增门店订单</div>
              <div style={{ color: 'rgba(255,255,255,0.65)', fontSize: 11, marginTop: 1 }}>录入手环编号，创建门店服务订单</div>
            </div>
            {/* 关闭按钮 — 内嵌在 banner 内 */}
            <button
              onClick={() => { setCreateOpen(false); setOrderItems([]); setCreateTechId(null); createForm.resetFields() }}
              style={{
                display: 'flex', alignItems: 'center', gap: 5, flexShrink: 0,
                padding: '5px 12px', borderRadius: 20,
                background: 'rgba(255,255,255,0.18)', border: '1px solid rgba(255,255,255,0.35)',
                backdropFilter: 'blur(8px)', cursor: 'pointer', transition: 'all .15s',
                color: '#fff', fontSize: 12, fontWeight: 700,
              }}
              onMouseEnter={e => (e.currentTarget.style.background = 'rgba(255,255,255,0.32)')}
              onMouseLeave={e => (e.currentTarget.style.background = 'rgba(255,255,255,0.18)')}
            >
              <CloseCircleOutlined style={{ fontSize: 14 }} />
              关闭
            </button>
          </div>
        }
        closeIcon={null}
        open={createOpen}
        onCancel={() => { setCreateOpen(false); setOrderItems([]); setCreateTechId(null); createForm.resetFields() }}
        destroyOnHidden
        width={560}
        style={{ top: 40 }}
        styles={{ body: { maxHeight: 'calc(100vh - 260px)', overflowY: 'auto', padding: '16px 24px 8px' } }}
        footer={
          <div style={{ display: 'flex', justifyContent: 'center', gap: 12 }}>
            <Button style={{ minWidth: 88 }}
              onClick={() => { setCreateOpen(false); setOrderItems([]); setCreateTechId(null); createForm.resetFields() }}>
              取消
            </Button>
            <Button type="primary" loading={createLoading} onClick={handleCreate}
              style={{ minWidth: 130, background: 'linear-gradient(135deg,#4338ca,#6366f1)', border: 'none', borderRadius: 8, fontWeight: 700 }}
              icon={<CheckCircleOutlined />}>确认开单</Button>
          </div>
        }
      >
        <Form form={createForm} layout="vertical">
          <Form.Item name="wristbandNo" label="手环编号" rules={[{ required: true, message: '请输入手环编号' }]}>
            <Input
              prefix={<QrcodeOutlined style={{ color: '#6366f1', fontSize: 18 }} />}
              placeholder="如：0928"
              style={{ ...INPUT_STYLE, fontSize: 20, fontWeight: 900, letterSpacing: 4, textAlign: 'center' }}
              maxLength={10}
            />
          </Form.Item>

          {/* 技师选择 */}
          <Form.Item name="technicianId" label="指定技师" rules={[{ required: true, message: '请选择服务技师' }]}>
            <Select
              placeholder={<Space size={4}><IdcardOutlined style={{ color: '#f59e0b' }} />选择技师（价格因人而异）</Space>}
              optionLabelProp="label"
              showSearch
              filterOption={(input, opt) =>
                (opt?.searchText ?? '').toLowerCase().includes(input.toLowerCase())
              }
              onChange={(v) => onCreateTechChange(v as number)}
              style={{ borderRadius: 8 }}
              dropdownStyle={{ padding: 4 }}
            >
              {technicians.map((t: any) => (
                <Select.Option
                  key={t.id}
                  value={t.id}
                  label={`${t.nickname ?? t.name} · ${t.techNo ?? t.no ?? ''}`}
                  searchText={`${t.nickname ?? t.name}${t.techNo ?? t.no ?? ''}${t.mobile ?? ''}`}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '4px 0' }}>
                    <Avatar size={32} src={t.avatar || undefined}
                      style={{ background: 'linear-gradient(135deg,#f59e0b,#f97316)', fontWeight: 700, flexShrink: 0 }}>
                      {!t.avatar && (t.nickname ?? t.name ?? '').charAt(0)}
                    </Avatar>
                    <div>
                      <div style={{ fontWeight: 700, fontSize: 13, color: '#111827' }}>
                        {t.nickname ?? t.name}
                        <span style={{ marginLeft: 8, fontSize: 11, fontWeight: 600, color: '#f59e0b', background: '#fffbeb', border: '1px solid #fde68a', borderRadius: 4, padding: '1px 6px' }}>{t.techNo ?? t.no}</span>
                      </div>
                      <div style={{ fontSize: 11, color: '#9ca3af', marginTop: 1 }}>
                        <PhoneOutlined style={{ marginRight: 3 }} />{t.mobile ?? '—'}
                      </div>
                    </div>
                  </div>
                </Select.Option>
              ))}
            </Select>
          </Form.Item>

          {/* 消费服务项目 — 卡片网格选择器 */}
          <div style={{ marginBottom: 16 }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <PlusOutlined style={{ color: '#6366f1', fontSize: 13 }} />
                <span style={{ fontWeight: 700, fontSize: 13, color: '#374151' }}>添加服务项目</span>
                {!createTechId && (
                  <span style={{ fontSize: 11, color: '#f59e0b', background: '#fffbeb', border: '1px solid #fde68a', borderRadius: 20, padding: '1px 8px', marginLeft: 4 }}>
                    先选技师查看专属价
                  </span>
                )}
              </div>
              {orderItems.length > 0 && (
                <span style={{ fontSize: 12, color: '#6366f1', fontWeight: 700 }}>
                  已选 {orderItems.length} 项 · 合计 <span style={{ fontSize: 15 }}>${orderTotal.toFixed(2)}</span>
                </span>
              )}
            </div>

            {/* 服务项目卡片网格 */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8, marginBottom: orderItems.length > 0 ? 12 : 0 }}>
              {dbServices.map(svc => {
                const isAdded = orderItems.some(i => i.serviceId === svc.id)
                const sysPrice = svc.price ?? 0
                const techPrice = createTechId && techPricing[svc.id] != null ? techPricing[svc.id] : null
                const price = techPrice ?? sysPrice
                const hasOverride = techPrice != null && techPrice !== sysPrice
                return (
                  <div
                    key={svc.id}
                    onClick={() => isAdded ? removeOrderItem(svc.id) : addOrderItem(svc.id)}
                    style={{
                      position: 'relative',
                      borderRadius: 10,
                      border: isAdded
                        ? '1.5px solid #e5e7eb'
                        : '1.5px solid #c7d2fe',
                      background: isAdded ? '#f9fafb' : '#fff',
                      padding: '12px 12px 10px',
                      cursor: 'pointer',
                      transition: 'border-color 0.18s, box-shadow 0.18s, background 0.18s',
                      boxShadow: isAdded ? 'none' : '0 1px 6px rgba(99,102,241,0.08)',
                      userSelect: 'none',
                    }}
                    onMouseEnter={e => {
                      if (!isAdded) (e.currentTarget as HTMLDivElement).style.boxShadow = '0 4px 14px rgba(99,102,241,0.18)'
                    }}
                    onMouseLeave={e => {
                      if (!isAdded) (e.currentTarget as HTMLDivElement).style.boxShadow = '0 1px 6px rgba(99,102,241,0.08)'
                    }}
                  >
                    {/* 状态徽章 */}
                    <div style={{
                      position: 'absolute', top: 10, right: 10,
                      padding: '2px 8px', borderRadius: 20,
                      fontSize: 11, fontWeight: 700, lineHeight: '18px',
                      background: isAdded ? '#f3f4f6' : '#ecfdf5',
                      color: isAdded ? '#9ca3af' : '#059669',
                      border: `1px solid ${isAdded ? '#e5e7eb' : '#a7f3d0'}`,
                    }}>
                      {isAdded ? '已添加' : '+ 添加'}
                    </div>

                    {/* 图标 + 类型标签 */}
                    <div style={{ display: 'flex', alignItems: 'center', gap: 5, marginBottom: 6 }}>
                      <span style={{ fontSize: 16 }}>{svc.icon ?? '💆'}</span>
                      {svc.isSpecial === 1 && (
                        <span style={{ fontSize: 9, padding: '1px 5px', borderRadius: 10, background: '#fff7ed', color: '#f97316', border: '1px solid #fed7aa', fontWeight: 700 }}>特殊</span>
                      )}
                    </div>

                    {/* 服务名称 */}
                    <div style={{
                      fontWeight: 700, fontSize: 13, lineHeight: 1.3,
                      color: isAdded ? '#9ca3af' : '#111827',
                      paddingRight: 54, marginBottom: 8,
                    }}>
                      {svc.nameZh}
                    </div>

                    {/* 时长 + 价格 */}
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <span style={{ fontSize: 12, color: '#9ca3af' }}>{svc.duration ?? '—'}min</span>
                      <div style={{ display: 'flex', alignItems: 'baseline', gap: 4 }}>
                        {hasOverride && (
                          <span style={{ fontSize: 10, color: '#cbd5e1', textDecoration: 'line-through' }}>
                            ${sysPrice}
                          </span>
                        )}
                        <span style={{
                          fontSize: 15, fontWeight: 800,
                          color: isAdded ? '#9ca3af' : (hasOverride ? '#6366f1' : '#3b82f6'),
                        }}>
                          ${price}
                        </span>
                      </div>
                    </div>
                  </div>
                )
              })}
            </div>

            {/* 已选服务明细（可调价） */}
            {orderItems.length > 0 && (
              <div style={{ border: '1.5px solid #e0e7ff', borderRadius: 10, overflow: 'hidden' }}>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 110px 36px', gap: 8, padding: '7px 12px', background: 'linear-gradient(135deg,#eef2ff,#f5f3ff)', fontSize: 11, color: '#6366f1', fontWeight: 700 }}>
                  <span>服务项目</span>
                  <span style={{ textAlign: 'right' }}>价格（可调整）</span>
                  <span />
                </div>
                {orderItems.map((item, idx) => (
                  <div key={item.serviceId} style={{
                    display: 'grid', gridTemplateColumns: '1fr 110px 36px', gap: 8,
                    padding: '8px 12px', alignItems: 'center',
                    background: idx % 2 === 0 ? '#fff' : '#fafbff',
                    borderTop: '1px solid #eef0f8',
                  }}>
                    <div>
                      <div style={{ fontWeight: 600, fontSize: 12, color: '#111827' }}>{item.name}</div>
                      <div style={{ fontSize: 11, color: '#9ca3af' }}>{item.duration}min</div>
                    </div>
                    <div style={{ textAlign: 'right' }}>
                      <InputNumber
                        size="small" min={0} precision={2} value={item.unitPrice} prefix="$"
                        style={{ width: 100 }}
                        onChange={v => updateOrderItemPrice(item.serviceId, v ?? 0)}
                      />
                    </div>
                    <div style={{ textAlign: 'right' }}>
                      <Button size="small" danger icon={<DeleteOutlined />} type="text"
                        onClick={() => removeOrderItem(item.serviceId)} />
                    </div>
                  </div>
                ))}
                <div style={{ display: 'flex', justifyContent: 'flex-end', alignItems: 'center', gap: 8, padding: '8px 14px', background: 'linear-gradient(135deg,#eef2ff,#f5f3ff)', borderTop: '2px solid #e0e7ff' }}>
                  <span style={{ fontSize: 12, color: '#6b7280' }}>合计</span>
                  <span style={{ fontWeight: 800, color: '#6366f1', fontSize: 18 }}>${orderTotal.toFixed(2)}</span>
                </div>
              </div>
            )}
          </div>

          <Row gutter={12}>
            <Col span={12}>
              <Form.Item name="memberName" label="客户姓名">
                <Input prefix={<UserOutlined style={{ color: '#6366f1' }} />} placeholder="散客可不填" style={INPUT_STYLE} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="memberMobile" label="联系电话">
                <Input prefix={<PhoneOutlined style={{ color: '#6366f1' }} />} placeholder="可不填" style={INPUT_STYLE} />
              </Form.Item>
            </Col>
          </Row>
          <Form.Item name="remark" label="备注" style={{ marginBottom: 0 }}>
            <TextArea rows={2} placeholder="客户特殊要求、偏好等" style={{ borderRadius: 8 }} />
          </Form.Item>
        </Form>
      </Modal>

      {/* ── 结算弹窗 ────────────────────────────────────────────────────── */}
      <Modal
        title={
          <div style={{
            background: 'linear-gradient(135deg,#064e3b,#10b981)',
            margin: '-20px -24px 0', padding: '12px 20px',
            borderRadius: '8px 8px 0 0', display: 'flex', alignItems: 'center', gap: 12,
          }}>
            <div style={{
              width: 38, height: 38, borderRadius: 10, flexShrink: 0,
              background: 'rgba(255,255,255,0.15)', backdropFilter: 'blur(8px)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <CreditCardOutlined style={{ color: '#fff', fontSize: 18 }} />
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ color: '#fff', fontWeight: 800, fontSize: 14, lineHeight: 1.25 }}>前台结算</div>
              <div style={{ color: 'rgba(255,255,255,0.65)', fontSize: 11, marginTop: 2 }}>
                手环 {settleTarget?.wristbandNo} · 组合支付 · 多币种结算
              </div>
            </div>
            {/* 关闭按钮 — 内嵌在 banner 内 */}
            <button
              onClick={() => setSettleOpen(false)}
              style={{
                display: 'flex', alignItems: 'center', gap: 5, flexShrink: 0,
                padding: '5px 12px', borderRadius: 20,
                background: 'rgba(255,255,255,0.18)', border: '1px solid rgba(255,255,255,0.35)',
                backdropFilter: 'blur(8px)', cursor: 'pointer', transition: 'all .15s',
                color: '#fff', fontSize: 12, fontWeight: 700,
              }}
              onMouseEnter={e => (e.currentTarget.style.background = 'rgba(255,255,255,0.32)')}
              onMouseLeave={e => (e.currentTarget.style.background = 'rgba(255,255,255,0.18)')}
            >
              <CloseCircleOutlined style={{ fontSize: 14 }} />
              关闭
            </button>
          </div>
        }
        closeIcon={null}
        open={settleOpen}
        onCancel={() => setSettleOpen(false)}
        destroyOnHidden
        width={620}
        style={{ top: 40 }}
        styles={{ body: { maxHeight: 'calc(100vh - 260px)', overflowY: 'auto', padding: '16px 24px 8px' } }}
        footer={
          settleTarget ? (() => {
            const isBalanced = Math.abs(payTotal - settleTarget.totalAmount) < 0.01
            const symbol = currencies.find(c => c.isDefault)?.symbol ?? '$'
            return (
              <div style={{ display: 'flex', justifyContent: 'center', gap: 12 }}>
                <Button style={{ minWidth: 88 }} onClick={() => setSettleOpen(false)}>取消</Button>
                <Button type="primary" loading={settleLoading} onClick={handleSettle}
                  style={{
                    minWidth: 160, height: 40, border: 'none', borderRadius: 10, fontWeight: 700, fontSize: 14,
                    background: isBalanced
                      ? 'linear-gradient(135deg,#10b981,#059669)'
                      : 'linear-gradient(135deg,#f59e0b,#d97706)',
                    boxShadow: `0 4px 14px ${isBalanced ? 'rgba(16,185,129,0.4)' : 'rgba(245,158,11,0.4)'}`,
                  }}
                  icon={<CheckCircleOutlined />}>
                  {isBalanced ? `确认结算 ${symbol}${payTotal.toFixed(2)}` : '差额结算'}
                </Button>
              </div>
            )
          })() : null
        }
      >
        {settleTarget && (() => {
          const symbol = currencies.find(c => c.isDefault)?.symbol ?? '$'
          // Use session's own orderItems if available (newly created sessions), otherwise use mock data
          const serviceItems = settleTarget.orderItems ?? []
          const isBalanced = Math.abs(payTotal - settleTarget.totalAmount) < 0.01

          return (
            <>
              {/* ── 客户信息栏 ── */}
              <div style={{
                display: 'flex', alignItems: 'center', gap: 16,
                background: 'linear-gradient(135deg,#0f0c29,#302b63)',
                borderRadius: 14, padding: '16px 20px', marginBottom: 20,
                boxShadow: '0 4px 20px rgba(15,12,41,0.25)',
              }}>
                <div style={{
                  width: 56, height: 56, borderRadius: 14, flexShrink: 0,
                  background: 'linear-gradient(135deg,#4338ca,#6366f1)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 22, fontWeight: 900, color: '#fff', letterSpacing: 2,
                  boxShadow: '0 4px 12px rgba(99,102,241,0.4)',
                }}>
                  {settleTarget.wristbandNo}
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ color: 'rgba(255,255,255,0.55)', fontSize: 11, fontWeight: 600 }}>手环号 · 订单流水</div>
                  <div style={{ color: '#fff', fontWeight: 800, fontSize: 16, marginTop: 2 }}>
                    {settleTarget.memberName || '散客'} · #{settleTarget.sessionNo.slice(-6)}
                  </div>
                  {settleTarget.technicianName && (
                    <div style={{ color: 'rgba(255,255,255,0.55)', fontSize: 12, marginTop: 2 }}>
                      技师：{settleTarget.technicianName}
                    </div>
                  )}
                </div>
                <div style={{ textAlign: 'right', flexShrink: 0 }}>
                  <div style={{ color: 'rgba(255,255,255,0.55)', fontSize: 11, fontWeight: 600, marginBottom: 4 }}>应付总额</div>
                  <div style={{ fontSize: 32, fontWeight: 900, color: '#34d399', lineHeight: 1 }}>
                    {symbol}{settleTarget.totalAmount.toFixed(2)}
                  </div>
                </div>
              </div>

              {/* ── 服务消费明细 ── */}
              {serviceItems.length > 0 && (
                <div style={{ marginBottom: 20 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
                    <ShoppingCartOutlined style={{ color: '#6366f1', fontSize: 14 }} />
                    <span style={{ fontWeight: 700, color: '#111827', fontSize: 13 }}>消费服务明细</span>
                  </div>
                  <div style={{ border: '1px solid #eef0f8', borderRadius: 12, overflow: 'hidden' }}>
                    {/* 表头 */}
                    <div style={{
                      display: 'grid', gridTemplateColumns: '1fr 80px 80px 90px',
                      background: 'linear-gradient(180deg,#f5f7ff,#eef1ff)',
                      padding: '8px 16px', gap: 12,
                      borderBottom: '2px solid #e0e4ff',
                    }}>
                      {['服务项目', '技师', '单价', '小计'].map(h => (
                        <span key={h} style={{ fontSize: 11, fontWeight: 700, color: '#6366f1', textAlign: h === '服务项目' ? 'left' : 'center' }}>{h}</span>
                      ))}
                    </div>
                    {/* 行 */}
                    {serviceItems.map((item: { name: string; qty: number; technician: string; unitPrice: number }, i: number) => (
                      <div key={i} style={{
                        display: 'grid', gridTemplateColumns: '1fr 80px 80px 90px',
                        padding: '10px 16px', gap: 12, alignItems: 'center',
                        background: i % 2 === 0 ? '#fff' : '#fafbff',
                        borderBottom: i < serviceItems.length - 1 ? '1px solid #f0f2ff' : 'none',
                      }}>
                        <div>
                          <div style={{ fontWeight: 600, fontSize: 13, color: '#111827' }}>{item.name}</div>
                          {item.qty > 1 && <div style={{ fontSize: 11, color: '#9ca3af' }}>× {item.qty}</div>}
                        </div>
                        <div style={{ textAlign: 'center', fontSize: 12, color: '#6b7280', whiteSpace: 'nowrap' }}>{item.technician}</div>
                        <div style={{ textAlign: 'center', fontSize: 13, color: '#374151', whiteSpace: 'nowrap' }}>{symbol}{item.unitPrice}</div>
                        <div style={{ textAlign: 'center', fontSize: 13, fontWeight: 700, color: '#6366f1', whiteSpace: 'nowrap' }}>
                          {symbol}{(item.unitPrice * item.qty).toFixed(2)}
                        </div>
                      </div>
                    ))}
                    {/* 合计行 */}
                    <div style={{
                      display: 'grid', gridTemplateColumns: '1fr auto',
                      padding: '10px 16px',
                      background: 'linear-gradient(135deg,#f0fdf4,#dcfce7)',
                      borderTop: '2px solid #bbf7d0',
                    }}>
                      <span style={{ fontWeight: 700, color: '#065f46', fontSize: 13 }}>合计</span>
                      <span style={{ fontSize: 18, fontWeight: 900, color: '#10b981' }}>
                        {symbol}{serviceItems.reduce((s: number, it: { unitPrice: number; qty: number }) => s + it.unitPrice * it.qty, 0).toFixed(2)}
                      </span>
                    </div>
                  </div>
                </div>
              )}

              {/* ── 组合支付 ── */}
              <div style={{ marginBottom: 16 }}>
                {/* 标题行 */}
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <CreditCardOutlined style={{ color: '#6366f1', fontSize: 14 }} />
                    <span style={{ fontWeight: 700, color: '#111827', fontSize: 13 }}>组合支付</span>
                    {payItems.length > 1 && (
                      <span style={{
                        display: 'inline-flex', alignItems: 'center', padding: '1px 8px',
                        borderRadius: 20, background: 'linear-gradient(135deg,#eef2ff,#e0e7ff)',
                        border: '1px solid #c7d2fe', color: '#6366f1', fontSize: 11, fontWeight: 700,
                      }}>{payItems.length} 种支付</span>
                    )}
                  </div>
                  {/* 快捷添加方式 chips */}
                  <div style={{ display: 'flex', gap: 5, flexWrap: 'wrap', justifyContent: 'flex-end' }}>
                    {Object.entries(PAY_METHODS).map(([k, v]) => {
                      const already = payItems.some(p => p.method === +k)
                      const remaining = settleTarget ? +(settleTarget.totalAmount - payTotal).toFixed(2) : 0
                      return (
                        <button key={k}
                          disabled={already}
                          onClick={() => {
                            const rem = Math.max(0, remaining)
                            setPayItems(prev => [...prev, { method: +k, currency: defaultCurrency, amount: rem }])
                          }}
                          style={{
                            display: 'inline-flex', alignItems: 'center', gap: 4,
                            padding: '3px 10px', borderRadius: 20, border: `1px solid ${already ? '#e5e7eb' : v.color}`,
                            background: already ? '#f9fafb' : `${v.color}14`,
                            color: already ? '#9ca3af' : v.color,
                            fontSize: 11, fontWeight: 700, cursor: already ? 'not-allowed' : 'pointer',
                            transition: 'all .15s',
                          }}>
                          <span style={{ fontSize: 13, lineHeight: 1 }}>{v.icon as any}</span>{v.label}
                        </button>
                      )
                    })}
                  </div>
                </div>

                {/* 支付项列表 */}
                {payItems.map((item, idx) => {
                  const method = PAY_METHODS[item.method]
                  const needCurrency = !!method?.needCurrency
                  const cur = currencies.find(c => c.currencyCode === item.currency)
                  const sym = cur?.symbol ?? symbol
                  const remaining = settleTarget ? +(settleTarget.totalAmount - payItems.filter((_, i) => i !== idx).reduce((s, p) => s + p.amount, 0)).toFixed(2) : 0

                  return (
                    <div key={idx} style={{
                      marginBottom: 8, borderRadius: 12, overflow: 'hidden',
                      border: `1.5px solid ${method?.color ?? '#e5e7eb'}33`,
                      background: `${method?.color ?? '#6366f1'}06`,
                    }}>
                      {/* 方法标签栏 */}
                      <div style={{
                        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                        padding: '7px 12px', background: `${method?.color ?? '#6366f1'}12`,
                        borderBottom: `1px solid ${method?.color ?? '#e5e7eb'}22`,
                      }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                          <span style={{ fontSize: 16, lineHeight: 1 }}>{method?.icon as any}</span>
                          <span style={{ fontWeight: 700, color: method?.color, fontSize: 13 }}>{method?.label}</span>
                          {idx === 0 && payItems.length === 1 && (
                            <span style={{ fontSize: 10, color: '#9ca3af', fontWeight: 500 }}>单一支付</span>
                          )}
                          {payItems.length > 1 && (
                            <span style={{ fontSize: 10, color: method?.color, fontWeight: 600, opacity: 0.7 }}>
                              第 {idx + 1} 笔
                            </span>
                          )}
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                          {/* 补足差额快捷按钮 */}
                          {remaining > 0 && item.amount < remaining && (
                            <button
                              onClick={() => { const arr = [...payItems]; arr[idx].amount = remaining; setPayItems(arr) }}
                              style={{
                                padding: '2px 8px', borderRadius: 6, border: '1px solid #fcd34d',
                                background: '#fffbeb', color: '#d97706', fontSize: 10, fontWeight: 700,
                                cursor: 'pointer',
                              }}>
                              补足 {sym}{remaining.toFixed(2)}
                            </button>
                          )}
                          {payItems.length > 1 && (
                            <button
                              onClick={() => setPayItems(payItems.filter((_, i) => i !== idx))}
                              style={{
                                width: 20, height: 20, borderRadius: 4, border: 'none',
                                background: '#fee2e2', color: '#ef4444', fontSize: 12,
                                cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
                              }}>×</button>
                          )}
                        </div>
                      </div>

                      {/* 金额 + 币种输入 */}
                      <div style={{ display: 'flex', gap: 8, padding: '10px 12px', alignItems: 'center' }}>
                        <Select
                          value={item.method}
                          onChange={v => {
                            const arr = [...payItems]
                            arr[idx].method = v
                            if (!PAY_METHODS[v]?.needCurrency) arr[idx].currency = defaultCurrency
                            setPayItems([...arr])
                          }}
                          style={{ width: 120 }}
                          optionLabelProp="label"
                          size="small"
                        >
                          {Object.entries(PAY_METHODS).map(([k, v]) => (
                            <Option key={k} value={+k} label={v.label}>
                              <span style={{ color: v.color, fontWeight: 600, display: 'flex', alignItems: 'center', gap: 5 }}>
                                <span style={{ fontSize: 14 }}>{v.icon as any}</span>{v.label}
                              </span>
                            </Option>
                          ))}
                        </Select>

                        {needCurrency && (
                          <Select
                            value={item.currency}
                            onChange={v => { const arr = [...payItems]; arr[idx].currency = v; setPayItems([...arr]) }}
                            style={{ width: 100 }}
                            size="small"
                            placeholder="币种"
                          >
                            {currencies.length > 0
                              ? currencies.map(c => <Option key={c.currencyCode} value={c.currencyCode}>{c.flag} {c.currencyCode}</Option>)
                              : [<Option key="USD" value="USD">🇺🇸 USD</Option>, <Option key="USDT" value="USDT">💵 USDT</Option>]
                            }
                          </Select>
                        )}

                        <InputNumber
                          value={item.amount} min={0} step={0.01} precision={2}
                          addonBefore={<span style={{ color: method?.color, fontWeight: 700 }}>{sym}</span>}
                          onChange={(v: number | null) => { const arr = [...payItems]; arr[idx].amount = v ?? 0; setPayItems([...arr]) }}
                          style={{ flex: 1 }}
                          placeholder="0.00"
                          size="small"
                        />
                      </div>
                    </div>
                  )
                })}

                {/* 添加支付方式按钮 */}
                <button
                  onClick={() => {
                    const remaining = settleTarget ? Math.max(0, +(settleTarget.totalAmount - payTotal).toFixed(2)) : 0
                    setPayItems(prev => [...prev, { method: 5, currency: defaultCurrency, amount: remaining }])
                  }}
                  style={{
                    width: '100%', height: 38, borderRadius: 10,
                    border: '1.5px dashed #c7d2fe', background: 'linear-gradient(135deg,#f5f7ff,#eef1ff)',
                    color: '#6366f1', fontSize: 13, fontWeight: 700, cursor: 'pointer',
                    display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
                  }}>
                  <PlusOutlined /> 添加支付方式（组合支付）
                </button>
              </div>

              {/* ── 实收合计 ── */}
              <div style={{
                borderRadius: 14, marginBottom: 16, overflow: 'hidden',
                border: `2px solid ${isBalanced ? '#6ee7b7' : '#fcd34d'}`,
              }}>
                {/* 各方式分项 */}
                {payItems.length > 1 && (
                  <div style={{ padding: '10px 16px 6px', background: '#f8fafc' }}>
                    {payItems.map((p, i) => {
                      const m = PAY_METHODS[p.method]
                      return (
                        <div key={i} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 5 }}>
                          <span style={{ fontSize: 12, color: m?.color, fontWeight: 600, display: 'flex', alignItems: 'center', gap: 5 }}>
                            <span>{m?.icon as any}</span>{m?.label}
                          </span>
                          <span style={{ fontWeight: 700, color: '#374151' }}>{symbol}{p.amount.toFixed(2)}</span>
                        </div>
                      )
                    })}
                    <div style={{ height: 1, background: '#e5e7eb', margin: '6px 0' }} />
                  </div>
                )}
                {/* 合计行 */}
                <div style={{
                  display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                  padding: '12px 16px',
                  background: isBalanced
                    ? 'linear-gradient(135deg,#ecfdf5,#d1fae5)'
                    : 'linear-gradient(135deg,#fffbeb,#fef3c7)',
                }}>
                  <div>
                    <div style={{ fontSize: 12, color: isBalanced ? '#065f46' : '#92400e', fontWeight: 700 }}>
                      {isBalanced ? '✓ 金额匹配，可以结算' : '实收合计'}
                    </div>
                    {!isBalanced && (
                      <div style={{ fontSize: 11, color: '#d97706', marginTop: 2, fontWeight: 600 }}>
                        ⚠ 还差 {symbol}{Math.max(0, settleTarget.totalAmount - payTotal).toFixed(2)}，可差额结算
                      </div>
                    )}
                  </div>
                  <div style={{ textAlign: 'right' }}>
                    <div style={{ fontSize: 26, fontWeight: 900, color: isBalanced ? '#10b981' : '#f59e0b', lineHeight: 1 }}>
                      {symbol}{payTotal.toFixed(2)}
                    </div>
                    {!isBalanced && (
                      <div style={{ fontSize: 11, color: '#9ca3af', marginTop: 2 }}>
                        应收 {symbol}{settleTarget.totalAmount.toFixed(2)}
                      </div>
                    )}
                  </div>
                </div>
              </div>

              <Form form={settleForm} layout="vertical">
                <Form.Item name="remark" label="结算备注" style={{ marginBottom: 0 }}>
                  <TextArea rows={2} placeholder="如有特殊情况可备注，选填" style={{ borderRadius: 10 }} />
                </Form.Item>
              </Form>
            </>
          )
        })()}
      </Modal>

      {/* ── 修改订单弹窗 ─────────────────────────────────────────────────── */}
      <Modal
        open={editOpen}
        onCancel={() => setEditOpen(false)}
        destroyOnHidden
        width={700}
        style={{ top: 32 }}
        styles={{ body: { maxHeight: 'calc(100vh - 240px)', overflowY: 'auto', padding: '0 24px 12px' } }}
        closeIcon={null}
        footer={null}
        title={
          <div style={{
            background: 'linear-gradient(135deg,#1e1b4b,#4338ca)',
            margin: '-20px -24px 0', padding: '12px 20px',
            borderRadius: '8px 8px 0 0', display: 'flex', alignItems: 'center', gap: 12,
          }}>
            <div style={{
              width: 38, height: 38, borderRadius: 10, flexShrink: 0,
              background: 'rgba(255,255,255,0.15)', backdropFilter: 'blur(8px)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <ShoppingCartOutlined style={{ color: '#fff', fontSize: 18 }} />
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ color: '#fff', fontWeight: 800, fontSize: 14 }}>修改门店订单</div>
              <div style={{ color: 'rgba(255,255,255,0.65)', fontSize: 11, marginTop: 2 }}>
                手环 {editTarget?.wristbandNo} · {editTarget?.memberName || '散客'} · 可增删服务项目
              </div>
            </div>
            {/* 合计金额 */}
            <div style={{ textAlign: 'right', marginRight: 8 }}>
              <div style={{ color: 'rgba(255,255,255,0.6)', fontSize: 10 }}>当前合计</div>
              <div style={{ color: '#fbbf24', fontSize: 18, fontWeight: 900 }}>${editTotal.toFixed(2)}</div>
            </div>
            <button
              onClick={() => setEditOpen(false)}
              style={{
                display: 'flex', alignItems: 'center', gap: 5, flexShrink: 0,
                padding: '5px 12px', borderRadius: 20,
                background: 'rgba(255,255,255,0.18)', border: '1px solid rgba(255,255,255,0.35)',
                cursor: 'pointer', color: '#fff', fontSize: 12, fontWeight: 700,
              }}
              onMouseEnter={e => (e.currentTarget.style.background = 'rgba(255,255,255,0.32)')}
              onMouseLeave={e => (e.currentTarget.style.background = 'rgba(255,255,255,0.18)')}
            >
              <CloseCircleOutlined style={{ fontSize: 14 }} />关闭
            </button>
          </div>
        }
      >
        {editTarget && (
          <>
            {/* ── 客户 + 技师信息卡 ── */}
            <div style={{
              display: 'flex', gap: 12, marginTop: 20, marginBottom: 20,
            }}>
              {[
                { label: '手环编号', value: editTarget.wristbandNo, icon: <QrcodeOutlined />, color: '#6366f1' },
                { label: '客户姓名', value: editTarget.memberName || '散客', icon: <UserOutlined />, color: '#10b981' },
                { label: '服务技师', value: editTarget.technicianName || '待分配', icon: <IdcardOutlined />, color: '#f59e0b' },
                { label: '到店时间', value: fmtTime(editTarget.checkInTime, 'MM-DD HH:mm'), icon: <ClockCircleOutlined />, color: '#3b82f6' },
              ].map((item, i) => (
                <div key={i} style={{
                  flex: 1, padding: '10px 14px', borderRadius: 12,
                  background: `${item.color}0d`, border: `1px solid ${item.color}28`,
                  display: 'flex', flexDirection: 'column', gap: 4,
                }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 5, color: item.color, fontSize: 11, fontWeight: 600 }}>
                    {item.icon}<span>{item.label}</span>
                  </div>
                  <div style={{ fontWeight: 700, fontSize: 13, color: '#111827', fontFamily: i === 0 ? 'monospace' : undefined }}>
                    {item.value}
                  </div>
                </div>
              ))}
            </div>

            {/* ── 当前服务项目列表 ── */}
            <div style={{ marginBottom: 16 }}>
              <div style={{ fontWeight: 700, fontSize: 13, color: '#374151', marginBottom: 10, display: 'flex', alignItems: 'center', gap: 6 }}>
                <ShoppingCartOutlined style={{ color: '#6366f1' }} />
                已选服务项目
                <span style={{ marginLeft: 4, padding: '1px 8px', borderRadius: 10, background: '#eef2ff', color: '#6366f1', fontSize: 11 }}>{editItems.length} 项</span>
              </div>

              {editItems.length === 0 ? (
                <div style={{
                  textAlign: 'center', padding: '32px 0',
                  border: '2px dashed #e0e4ff', borderRadius: 14, color: '#9ca3af', fontSize: 13,
                }}>
                  <ShoppingCartOutlined style={{ fontSize: 28, marginBottom: 8, display: 'block', color: '#c7d2fe' }} />
                  暂无服务项目，请从下方添加
                </div>
              ) : (
                <div style={{ border: '1px solid #e0e4ff', borderRadius: 14, overflow: 'hidden' }}>
                  {/* 表头 */}
                  <div style={{
                    display: 'grid', gridTemplateColumns: '1fr 70px 120px 80px 36px',
                    gap: 8, padding: '8px 16px',
                    background: 'linear-gradient(180deg,#f5f7ff,#eef1ff)',
                    fontSize: 11, fontWeight: 700, color: '#6366f1',
                    borderBottom: '2px solid #e0e4ff',
                  }}>
                    <span>服务项目</span>
                    <span style={{ textAlign: 'center' }}>时长</span>
                    <span style={{ textAlign: 'center' }}>单价（可调）</span>
                    <span style={{ textAlign: 'right' }}>小计</span>
                    <span />
                  </div>
                  {/* 数据行 */}
                  {editItems.map((item, i) => (
                    <div key={item.serviceId} style={{
                      display: 'grid', gridTemplateColumns: '1fr 70px 120px 80px 36px',
                      gap: 8, padding: '10px 16px', alignItems: 'center',
                      background: i % 2 === 0 ? '#fff' : '#fafbff',
                      borderBottom: i < editItems.length - 1 ? '1px solid #f0f2ff' : 'none',
                      transition: 'background .12s',
                    }}>
                      <div>
                        <div style={{ fontWeight: 600, fontSize: 13, color: '#111827' }}>{item.name}</div>
                        <div style={{ fontSize: 10, color: '#9ca3af', marginTop: 2 }}>数量 × {item.qty}</div>
                      </div>
                      <div style={{ textAlign: 'center', fontSize: 11, color: '#9ca3af' }}>{item.duration}min</div>
                      <InputNumber
                        value={item.unitPrice}
                        min={0} step={1} precision={2}
                        addonBefore="$"
                        size="small"
                        style={{ width: '100%' }}
                        onChange={v => setEditItems(prev => prev.map(it =>
                          it.serviceId === item.serviceId ? { ...it, unitPrice: v ?? 0 } : it
                        ))}
                      />
                      <div style={{ textAlign: 'right', fontWeight: 700, color: '#6366f1', fontSize: 13 }}>
                        ${(item.unitPrice * item.qty).toFixed(2)}
                      </div>
                      <button
                        onClick={() => setEditItems(prev => prev.filter(it => it.serviceId !== item.serviceId))}
                        style={{
                          width: 28, height: 28, borderRadius: 8, border: 'none',
                          background: '#fee2e2', color: '#ef4444', fontSize: 16,
                          cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
                          fontWeight: 700,
                        }}>×</button>
                    </div>
                  ))}
                  {/* 合计行 */}
                  <div style={{
                    display: 'flex', justifyContent: 'flex-end', alignItems: 'center', gap: 16,
                    padding: '12px 16px',
                    background: 'linear-gradient(135deg,#f0fdf4,#dcfce7)',
                    borderTop: '2px solid #bbf7d0',
                  }}>
                    <span style={{ fontSize: 12, color: '#065f46', fontWeight: 600 }}>
                      合计 {editItems.length} 项 / {editItems.reduce((s, i) => s + i.duration * i.qty, 0)}min
                    </span>
                    <span style={{ fontSize: 22, fontWeight: 900, color: '#10b981' }}>${editTotal.toFixed(2)}</span>
                  </div>
                </div>
              )}
            </div>

            {/* ── 添加服务项目 ── */}
            <div style={{ marginBottom: 20 }}>
              <div style={{ fontWeight: 700, fontSize: 13, color: '#374151', marginBottom: 10, display: 'flex', alignItems: 'center', gap: 6 }}>
                <PlusOutlined style={{ color: '#10b981' }} />
                添加服务项目
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))', gap: 10 }}>
                {dbServices.map(svc => {
                  const added = editItems.some(i => i.serviceId === svc.id)
                  const price = svc.price ?? 0
                  return (
                    <button
                      key={svc.id}
                      disabled={added}
                      onClick={() => addEditItem(svc.id)}
                      style={{
                        padding: '10px 14px', borderRadius: 12, textAlign: 'left', cursor: added ? 'not-allowed' : 'pointer',
                        border: `1.5px solid ${added ? '#e5e7eb' : '#c7d2fe'}`,
                        background: added ? '#f9fafb' : 'linear-gradient(135deg,#f5f7ff,#eef1ff)',
                        transition: 'all .15s',
                        display: 'flex', flexDirection: 'column', gap: 4,
                      }}
                      onMouseEnter={e => { if (!added) e.currentTarget.style.borderColor = '#6366f1' }}
                      onMouseLeave={e => { if (!added) e.currentTarget.style.borderColor = '#c7d2fe' }}
                    >
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <span style={{ fontWeight: 700, fontSize: 13, color: added ? '#9ca3af' : '#111827' }}>
                          {svc.icon && <span style={{ marginRight: 5 }}>{svc.icon}</span>}{svc.nameZh}
                        </span>
                        {added && <span style={{ fontSize: 10, color: '#9ca3af', background: '#e5e7eb', padding: '1px 6px', borderRadius: 4 }}>已添加</span>}
                        {!added && <span style={{ fontSize: 10, color: '#10b981', background: '#dcfce7', padding: '1px 6px', borderRadius: 4, fontWeight: 700 }}>+ 添加</span>}
                      </div>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <span style={{ fontSize: 11, color: '#9ca3af' }}>{svc.duration ?? '—'}min</span>
                        <span style={{ fontSize: 13, fontWeight: 800, color: added ? '#9ca3af' : '#6366f1' }}>${price}</span>
                      </div>
                    </button>
                  )
                })}
              </div>
            </div>

            {/* ── 底部操作按钮 ── */}
            <div style={{
              display: 'flex', justifyContent: 'center', gap: 12,
              padding: '14px 0 4px', borderTop: '1px solid #eef0f8',
            }}>
              <Button style={{ minWidth: 88, borderRadius: 8 }} onClick={() => setEditOpen(false)}>取消</Button>
              <Button type="primary" icon={<CheckCircleOutlined />}
                style={{
                  minWidth: 140, height: 40, borderRadius: 10, fontWeight: 700, fontSize: 14, border: 'none',
                  background: 'linear-gradient(135deg,#4338ca,#6366f1)',
                  boxShadow: '0 4px 14px rgba(99,102,241,0.4)',
                }}
                onClick={handleSaveEdit}>
                保存修改 · ${editTotal.toFixed(2)}
              </Button>
            </div>
          </>
        )}
      </Modal>

      {/* ── 详情抽屉 ───────────────────────────────────────────────────── */}
      <Drawer
        title={
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            {/* 手环编号徽章 — 宽度自适应，数字完整显示 */}
            <div style={{
              display: 'inline-flex', alignItems: 'center', gap: 6,
              padding: '4px 12px 4px 8px', borderRadius: 10, flexShrink: 0,
              background: 'linear-gradient(135deg,#4338ca,#6366f1)',
              boxShadow: '0 2px 8px rgba(99,102,241,0.35)',
            }}>
              <div style={{
                width: 22, height: 22, borderRadius: 6, flexShrink: 0,
                background: 'rgba(255,255,255,0.25)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <QrcodeOutlined style={{ color: '#fff', fontSize: 12 }} />
              </div>
              <span style={{ color: '#fff', fontSize: 16, fontWeight: 900, letterSpacing: 2, fontFamily: 'monospace' }}>
                {detail?.wristbandNo}
              </span>
            </div>
            <div>
              <div style={{ fontWeight: 700, fontSize: 15, color: '#111827' }}>订单详情</div>
              <div style={{ fontSize: 11, color: '#9ca3af', fontWeight: 400, fontFamily: 'monospace' }}>{detail?.sessionNo}</div>
            </div>
          </div>
        }
        open={detailOpen} onClose={() => setDetailOpen(false)}
        styles={{ wrapper: { width: 760 } }} placement="right"
      >
        {detail && (
          <>
            {/* 状态 + 金额 概览 */}
            <div style={{
              display: 'flex', alignItems: 'center', gap: 16,
              background: 'linear-gradient(135deg,#1e1b4b,#312e81)',
              borderRadius: 14, padding: '16px 20px', marginBottom: 20,
            }}>
              <div style={{
                display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
                minWidth: 60, height: 52, borderRadius: 14, flexShrink: 0, padding: '0 14px',
                background: 'linear-gradient(135deg,#4338ca,#6366f1)',
                boxShadow: '0 4px 14px rgba(99,102,241,0.45)',
                fontSize: 20, fontWeight: 900, color: '#fff', letterSpacing: 3, fontFamily: 'monospace',
              }}>{detail.wristbandNo}</div>
              <div style={{ flex: 1 }}>
                <Badge status={SESSION_STATUS[detail.status]?.badge} text={
                  <span style={{ fontWeight: 700, fontSize: 13, color: SESSION_STATUS[detail.status]?.color }}>
                    {SESSION_STATUS[detail.status]?.text}
                  </span>
                } />
                <div style={{ color: 'rgba(255,255,255,0.55)', fontSize: 11, marginTop: 4 }}>
                  {fmtTime(detail.checkInTime, 'YYYY-MM-DD HH:mm')} 到店
                  {detail.checkOutTime && ` · ${fmtTime(detail.checkOutTime, 'HH:mm')} 离店`}
                </div>
              </div>
              <div style={{ textAlign: 'right' }}>
                <div style={{ color: 'rgba(255,255,255,0.55)', fontSize: 11 }}>应付 / 已付</div>
                <div style={{ color: '#fbbf24', fontSize: 22, fontWeight: 900, lineHeight: 1.2 }}>${detail.totalAmount.toFixed(2)}</div>
                {detail.paidAmount > 0 && <div style={{ color: '#34d399', fontSize: 12 }}>已收 ${detail.paidAmount.toFixed(2)}</div>}
              </div>
            </div>

            <Descriptions column={2} size="small" bordered style={{ marginBottom: 20 }}>
              <Descriptions.Item label="客户姓名">{detail.memberName || <Text type="secondary">散客</Text>}</Descriptions.Item>
              <Descriptions.Item label="联系电话">{detail.memberMobile || '—'}</Descriptions.Item>
              <Descriptions.Item label="服务技师">{detail.technicianName || '—'}</Descriptions.Item>
              <Descriptions.Item label="技师编号">{detail.technicianNo || '—'}</Descriptions.Item>
            </Descriptions>

            {/* 服务项目明细 + 实时进度 */}
            <div style={{ marginBottom: 20 }}>
              <div style={{ fontWeight: 700, fontSize: 13, color: '#374151', marginBottom: 12, display: 'flex', alignItems: 'center', gap: 6 }}>
                <ShoppingCartOutlined style={{ color: '#6366f1' }} />服务项目进度
              </div>
              {(() => {
                const items = detail.orderItems ?? []
                if (!items.length) return (
                  <div style={{ textAlign: 'center', padding: 20, color: '#9ca3af', fontSize: 12, border: '1px dashed #e5e7eb', borderRadius: 10 }}>暂无服务项目</div>
                )
                const total = items.reduce((s: number, it: any) => s + it.unitPrice * (it.qty ?? 1), 0)
                return (
                  <>
                    {items.map((it: any, idx: number) => (
                      <ServiceProgressBar key={it.serviceId} item={it} colorIdx={idx} compact={false} svcStatusMap={SVC_STATUS_CFG} />
                    ))}
                    <div style={{ display: 'flex', justifyContent: 'flex-end', alignItems: 'center', gap: 16, padding: '10px 16px', background: 'linear-gradient(135deg,#f0fdf4,#dcfce7)', borderRadius: 12, marginTop: 4 }}>
                      <span style={{ fontSize: 12, color: '#065f46', fontWeight: 600 }}>消费合计</span>
                      <span style={{ fontSize: 20, fontWeight: 900, color: '#10b981' }}>${total.toFixed(2)}</span>
                    </div>
                  </>
                )
              })()}
            </div>

            {detail.status !== 3 && detail.status !== 4 && (
              <Button block type="primary" icon={<CreditCardOutlined />}
                style={{ background: 'linear-gradient(135deg,#10b981,#059669)', border: 'none', borderRadius: 10, height: 44, fontWeight: 700 }}
                onClick={() => { setDetailOpen(false); openSettle(detail) }}>
                前台结算
              </Button>
            )}
          </>
        )}
      </Drawer>
    </div>
  )
}
