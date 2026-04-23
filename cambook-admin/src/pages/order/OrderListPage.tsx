/**
 * 在线订单管理
 *
 * 业务流程：
 *   客户下单（上门/到店）→ 技师接单 → 前往/到达 → 服务中（多项目进度条）→ 结算（组合支付）→ 完结
 *
 * 与门店订单的区别：
 *   • 服务方式：上门服务 / 到店服务（筛选维度）
 *   • 上门服务不显示手牌号，改为技师编号
 *   • 支付方式：现金、银行转账、USDT、组合支付等
 *   • 支持多项目服务（ServiceProgressBar）
 */
import React, { useState, useEffect, useCallback } from 'react'
import {
  Table, Input, Select, Button, Space, Typography, message,
  Modal, Form, InputNumber, Drawer, Descriptions,
  Badge, Popconfirm, Avatar, Tag, Timeline,
} from 'antd'
import {
  PlusOutlined, SearchOutlined, ReloadOutlined, SettingOutlined,
  UserOutlined, CheckCircleOutlined, CloseCircleOutlined,
  DollarOutlined, WalletOutlined, ClockCircleOutlined,
  ShoppingCartOutlined, PhoneOutlined, IdcardOutlined, CreditCardOutlined,
  DeleteOutlined, OrderedListOutlined, EyeOutlined,
  StopOutlined, EnvironmentOutlined,
  HomeOutlined, ShopOutlined,
} from '@ant-design/icons'
import dayjs from 'dayjs'
import type { Dayjs } from 'dayjs'
import type { ColumnsType } from 'antd/es/table'
import { fmtTime, toEpochSec, fromEpochSec, dayjsFromApi } from '../../utils/time'
import { col, styledTableComponents, INPUT_STYLE } from '../../components/common/tableComponents'
import PagePagination from '../../components/common/PagePagination'
import { useTableBodyHeight } from '../../hooks/useTableBodyHeight'
import { usePortalScope } from '../../hooks/usePortalScope'
import { merchantPortalApi, merchantApi } from '../../api/api'
import { useDict, parseRemark } from '../../hooks/useDict'
import DateTimeRangePicker from '../../components/common/DateTimeRangePicker'
import PermGuard from '../../components/common/PermGuard'

const { Text } = Typography
const { Option } = Select
const { TextArea } = Input

// ── 静态兜底常量（字典加载前使用）─────────────────────────────────────────────
const PAY_METHODS_FB: Record<number, { label: string; color: string; icon: string; needCurrency?: boolean }> = {
  1: { label: '现金',     color: '#10b981', icon: '💵' },
  2: { label: '微信支付', color: '#07C160', icon: '💚' },
  3: { label: '支付宝',   color: '#1677FF', icon: '🔵' },
  4: { label: '银行转账', color: '#6366f1', icon: '🏦', needCurrency: true },
  5: { label: 'USDT',    color: '#f59e0b', icon: '₮'  },
  6: { label: '其它',    color: '#94a3b8', icon: '💳' },
}

const ORDER_STATUS_FB: Record<number, { text: string; color: string; badge: 'default'|'processing'|'success'|'error'|'warning' }> = {
  0: { text: '待支付', color: '#f59e0b', badge: 'warning' },
  1: { text: '待接单', color: '#3b82f6', badge: 'processing' },
  2: { text: '已接单', color: '#8b5cf6', badge: 'processing' },
  3: { text: '前往中', color: '#f97316', badge: 'processing' },
  4: { text: '已到达', color: '#06b6d4', badge: 'processing' },
  5: { text: '服务中', color: '#f97316', badge: 'processing' },
  6: { text: '已完成', color: '#10b981', badge: 'success' },
  7: { text: '已取消', color: '#94a3b8', badge: 'default' },
  8: { text: '退款中', color: '#ec4899', badge: 'warning' },
  9: { text: '已退款', color: '#6b7280', badge: 'default' },
}

const SVC_STATUS_CFG_FB: Record<number, { label: string; badge: string; badgeBg: string; icon: string }> = {
  0: { label: '待服务', badge: '#9ca3af', badgeBg: '#f3f4f6', icon: '⏳' },
  1: { label: '服务中', badge: '#f97316', badgeBg: '#fff7ed', icon: '🔄' },
  2: { label: '已完成', badge: '#10b981', badgeBg: '#ecfdf5', icon: '✅' },
}

const SVC_COLORS = [
  { bar: 'linear-gradient(90deg,#6366f1,#8b5cf6,#a78bfa)', glow: 'rgba(99,102,241,0.35)', text: '#6366f1', bg: '#eef2ff', border: '#c7d2fe' },
  { bar: 'linear-gradient(90deg,#10b981,#34d399,#6ee7b7)', glow: 'rgba(16,185,129,0.35)', text: '#059669', bg: '#ecfdf5', border: '#a7f3d0' },
  { bar: 'linear-gradient(90deg,#f59e0b,#fbbf24,#fde68a)', glow: 'rgba(245,158,11,0.35)', text: '#d97706', bg: '#fffbeb', border: '#fde68a' },
  { bar: 'linear-gradient(90deg,#3b82f6,#60a5fa,#93c5fd)', glow: 'rgba(59,130,246,0.35)', text: '#2563eb', bg: '#eff6ff', border: '#bfdbfe' },
  { bar: 'linear-gradient(90deg,#ec4899,#f472b6,#fbcfe8)', glow: 'rgba(236,72,153,0.35)', text: '#db2777', bg: '#fdf2f8', border: '#fbcfe8' },
]

// ── 服务进度条组件（和门店订单共用同款 UI）───────────────────────────────────────
function ServiceProgressBar({ item, colorIdx, compact = false, svcStatusMap }: {
  item: any; colorIdx: number; compact?: boolean
  svcStatusMap?: Record<number, { label: string; badge: string; badgeBg: string; icon: string }>
}) {
  const [now, setNow] = React.useState(dayjs())
  const color = SVC_COLORS[colorIdx % SVC_COLORS.length]
  const statusMap = svcStatusMap ?? SVC_STATUS_CFG_FB
  const cfg = statusMap[item.svcStatus as 0|1|2] ?? SVC_STATUS_CFG_FB[0]

  React.useEffect(() => {
    if (item.svcStatus !== 1) return
    const id = setInterval(() => setNow(dayjs()), 1000)
    return () => clearInterval(id)
  }, [item.svcStatus])

  let pct = 0; let elapsed = 0; let remaining = item.serviceDuration ?? item.duration ?? 60
  if (item.svcStatus === 1 && item.startTime) {
    const start = dayjsFromApi(item.startTime)
    elapsed = start ? now.diff(start, 'minute') : 0
    pct = Math.min(100, Math.round((elapsed / (item.serviceDuration ?? item.duration ?? 60)) * 100))
    remaining = Math.max(0, (item.serviceDuration ?? item.duration ?? 60) - elapsed)
  } else if (item.svcStatus === 2) { pct = 100; elapsed = item.serviceDuration ?? item.duration ?? 60; remaining = 0 }

  const dur = item.serviceDuration ?? item.duration ?? 60
  const animId = `op-${item.id ?? item.serviceItemId}-${colorIdx}`

  if (compact) {
    return (
      <div style={{ marginBottom: 5 }}>
        <style>{`@keyframes ${animId}{0%{background-position:-200% center}100%{background-position:200% center}}`}</style>
        <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', marginBottom:3 }}>
          <div style={{ display:'flex', alignItems:'center', gap:5 }}>
            <span style={{ fontSize:9, padding:'1px 5px', borderRadius:6, background:cfg.badgeBg, color:cfg.badge, fontWeight:700, whiteSpace:'nowrap' }}>
              {cfg.icon} {cfg.label}
            </span>
            <span style={{ fontSize:11, fontWeight:600, color:'#374151' }}>{item.serviceName ?? item.name}</span>
          </div>
          <span style={{ fontSize:10, color:'#9ca3af', flexShrink:0 }}>{dur}min</span>
        </div>
        <div style={{ position:'relative', height:5, borderRadius:8, background:'#f1f5f9', overflow:'hidden' }}>
          <div style={{
            position:'absolute', left:0, top:0, bottom:0, width:`${pct}%`,
            background: item.svcStatus===1 ? `${color.bar},linear-gradient(90deg,transparent 25%,rgba(255,255,255,.4) 50%,transparent 75%)` : color.bar,
            backgroundSize: item.svcStatus===1 ? '200% 100%,200% 100%' : '100% 100%',
            animation: item.svcStatus===1 ? `${animId} 1.8s linear infinite` : 'none',
            borderRadius:8, boxShadow: item.svcStatus===1 ? `0 0 6px ${color.glow}` : 'none',
            transition:'width 1s linear',
          }} />
        </div>
        {item.svcStatus===1 && (
          <div style={{ display:'flex', justifyContent:'space-between', marginTop:2, fontSize:9, color:'#9ca3af' }}>
            <span>已用 {elapsed}min</span>
            <span style={{ color:color.text, fontWeight:700 }}>剩余 {remaining}min</span>
          </div>
        )}
      </div>
    )
  }

  return (
    <div style={{ borderRadius:14, overflow:'hidden', border:`1.5px solid ${color.border}`, marginBottom:10 }}>
      <style>{`@keyframes ${animId}{0%{background-position:-200% center}100%{background-position:200% center}}@keyframes ${animId}-p{0%,100%{opacity:1}50%{opacity:.55}}`}</style>
      <div style={{ display:'flex', alignItems:'center', gap:10, padding:'10px 14px', background:color.bg, borderBottom:`1px solid ${color.border}` }}>
        <div style={{ width:28, height:28, borderRadius:8, flexShrink:0, background:color.bar, boxShadow:`0 2px 8px ${color.glow}`, display:'flex', alignItems:'center', justifyContent:'center', fontSize:13, animation: item.svcStatus===1 ? `${animId}-p 2s ease-in-out infinite` : 'none' }}>
          <span>{cfg.icon}</span>
        </div>
        <div style={{ flex:1 }}>
          <div style={{ fontWeight:700, fontSize:14, color:'#111827' }}>{item.serviceName ?? item.name}</div>
          <div style={{ fontSize:11, color:'#9ca3af', marginTop:1 }}>时长 {dur}min · ${item.unitPrice}</div>
        </div>
        <div style={{ padding:'3px 10px', borderRadius:20, background:cfg.badgeBg, color:cfg.badge, fontSize:11, fontWeight:800 }}>{cfg.label}</div>
      </div>
      <div style={{ padding:'12px 14px', background:'#fff' }}>
        <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:7 }}>
          <span style={{ fontSize:12, fontWeight:600, color:'#6b7280' }}>服务进度</span>
          <span style={{ fontSize:16, fontWeight:900, color:color.text }}>{pct}%</span>
        </div>
        <div style={{ position:'relative', height:10, borderRadius:10, background:'#f1f5f9', overflow:'hidden', marginBottom:8 }}>
          <div style={{
            position:'absolute', left:0, top:0, bottom:0, width:`${pct}%`, borderRadius:10,
            background: item.svcStatus===1 ? `${color.bar},linear-gradient(90deg,transparent 20%,rgba(255,255,255,.5) 50%,transparent 80%)` : color.bar,
            backgroundSize: item.svcStatus===1 ? '200% 100%,200% 100%' : '100% 100%',
            animation: item.svcStatus===1 ? `${animId} 1.6s linear infinite` : 'none',
            boxShadow: item.svcStatus===1 ? `0 0 10px ${color.glow}` : 'none',
            transition:'width 1s linear',
          }} />
          {item.svcStatus===1 && pct>2 && (
            <div style={{ position:'absolute', top:1, bottom:1, width:8, borderRadius:'50%', left:`calc(${pct}% - 4px)`, background:'#fff', boxShadow:`0 0 6px ${color.glow}`, animation:`${animId}-p 1.2s ease-in-out infinite` }} />
          )}
        </div>
        <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr 1fr', gap:8 }}>
          {[
            { label:'总时长', val:`${dur}min` },
            { label:'已用时', val: item.svcStatus===0 ? '—' : `${elapsed}min` },
            { label: item.svcStatus===2 ? '已完成' : '剩余', val: item.svcStatus===0 ? `${dur}min` : item.svcStatus===2 ? '完成' : `${remaining}min`, highlight: item.svcStatus===1 },
          ].map((s,i) => (
            <div key={i} style={{ textAlign:'center', padding:'6px 8px', borderRadius:8, background:'#f8fafc' }}>
              <div style={{ fontSize:10, color:'#9ca3af', marginBottom:2 }}>{s.label}</div>
              <div style={{ fontSize:13, fontWeight:800, color: s.highlight ? color.text : '#374151' }}>{s.val}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}

// ════════════════════════════════════════════════════════════════════════════════
export default function OrderListPage() {
  const { ref, height: tableBodyH } = useTableBodyHeight(46)
  const { orderList, orderCancel, orderDelete, isMerchant, enabledCurrencies } = usePortalScope()

  // ── 字典数据 ─────────────────────────────────────────────────────────────
  const { items: dictPayItems }    = useDict('walkin_pay_type')
  const { items: statusItems }     = useDict('order_status')
  const { items: svcItems }        = useDict('walkin_svc_status')

  const PAY_METHODS: Record<number, { label: string; color: string; icon: string; needCurrency?: boolean }> =
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

  const ORDER_STATUS: typeof ORDER_STATUS_FB =
    statusItems.length > 0
      ? Object.fromEntries(statusItems.map(i => {
          const { color, badge } = parseRemark(i.remark)
          return [Number(i.dictValue), { text: i.labelZh, color: color ?? '#94a3b8', badge: (badge ?? 'default') as any }]
        }))
      : ORDER_STATUS_FB

  const SVC_STATUS_CFG: typeof SVC_STATUS_CFG_FB =
    svcItems.length > 0
      ? Object.fromEntries(svcItems.map(i => {
          const { color, icon } = parseRemark(i.remark)
          return [Number(i.dictValue), { label: i.labelZh, badge: color ?? '#9ca3af', badgeBg: `${color ?? '#9ca3af'}20`, icon: icon ?? '⏳' }]
        }))
      : SVC_STATUS_CFG_FB

  // dbServices not needed for list view (used in create/edit modal if added later)

  // ── 状态 ─────────────────────────────────────────────────────────────────
  const [orders,   setOrders]   = useState<any[]>([])
  const [total,    setTotal]    = useState(0)
  const [loading,  setLoading]  = useState(false)
  const [page,     setPage]     = useState(1)
  const [pageSize, setPageSize] = useState(20)
  const [keyword,  setKeyword]  = useState('')
  const [statusFilter,      setStatusFilter]      = useState<number | undefined>()
  const [serviceModeFilter, setServiceModeFilter] = useState<number | undefined>()
  const [dateRange,  setDateRange]  = useState<[number, number] | null>(null)
  const [merchantId, setMerchantId] = useState<number | undefined>()
  const [merchantOpts, setMerchantOpts] = useState<{ value: number; label: string }[]>([])

  // 币种
  const [currencies, setCurrencies] = useState<any[]>([])
  const defaultCurrency = currencies.find(c => c.isDefault)?.currencyCode ?? currencies[0]?.currencyCode ?? 'USD'

  // 详情抽屉
  const [detailOpen, setDetailOpen] = useState(false)
  const [detail,     setDetail]     = useState<any>(null)
  const [detailItems, setDetailItems] = useState<any[]>([])
  const [detailLoading, setDetailLoading] = useState(false)

  // 结算弹窗
  const [settleOpen,    setSettleOpen]    = useState(false)
  const [settleTarget,  setSettleTarget]  = useState<any>(null)
  const [settleForm]                      = Form.useForm()
  const [settleLoading, setSettleLoading] = useState(false)
  const [payItems, setPayItems] = useState<{ method: number; currency: string; amount: number }[]>([])

  // ── 初始化 ─────────────────────────────────────────────────────────────
  useEffect(() => {
    if (!isMerchant) {
      merchantApi.list({ page: 1, size: 200 }).then(res => {
        const list = res.data?.data?.list ?? res.data?.data?.records ?? []
        setMerchantOpts(list.map((m: any) => ({ value: m.id, label: m.merchantNameZh || m.merchantNameEn || `商户#${m.id}` })))
      }).catch(() => {})
    }
  }, [isMerchant])

  useEffect(() => {
    enabledCurrencies()
      .then((res: any) => setCurrencies(res.data?.data ?? []))
      .catch(() => {})
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  // ── 列表加载 ────────────────────────────────────────────────────────────
  const fetchList = useCallback((
    pg = page, kw = keyword, st = statusFilter, sm = serviceModeFilter,
    dr: [number, number] | null = dateRange, mid = merchantId,
  ) => {
    setLoading(true)
    orderList({
      page: pg, size: pageSize,
      keyword: kw || undefined,
      status: st,
      serviceMode: sm,
      startDate: dr?.[0], endDate: dr?.[1],
      ...(mid != null ? { merchantId: mid } : {}),
    })
      .then((res: any) => {
        const d = res.data?.data ?? res.data
        setOrders(d?.list ?? d?.records ?? [])
        setTotal(d?.total ?? 0)
      })
      .catch(() => { setOrders([]); setTotal(0) })
      .finally(() => setLoading(false))
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [page, pageSize, keyword, statusFilter, serviceModeFilter, dateRange, merchantId])

  useEffect(() => { fetchList() }, [fetchList])

  // ── 操作 ─────────────────────────────────────────────────────────────
  const handleCancel = async (r: any) => {
    try {
      await orderCancel(r.id, '前台取消')
      message.success('订单已取消')
      fetchList()
    } catch { /* 拦截器处理 */ }
  }

  const handleDelete = async (r: any) => {
    try {
      await orderDelete(r.id)
      message.success('订单已删除')
      fetchList()
    } catch { /* 拦截器处理 */ }
  }

  const openDetail = async (r: any) => {
    setDetail(r)
    setDetailItems([])
    setDetailOpen(true)
    setDetailLoading(true)
    try {
      const res = await merchantPortalApi.orderDetail(r.id)
      const vo = res.data?.data ?? res.data
      if (vo) {
        setDetail(vo)
        setDetailItems(vo.orderItems ?? [])
      }
    } catch { /* 使用列表数据展示 */ }
    finally { setDetailLoading(false) }
  }

  const openSettle = (r: any) => {
    setSettleTarget(r)
    settleForm.resetFields()
    const amt = Number(r.payAmount ?? r.originalAmount ?? 0)
    setPayItems([{ method: 1, currency: defaultCurrency, amount: amt }])
    setSettleOpen(true)
  }

  const handleSettle = async () => {
    setSettleLoading(true)
    try {
      const paidTotal = payItems.reduce((s, p) => s + (p.amount || 0), 0)
      const payRecords = JSON.stringify(payItems)
      await merchantPortalApi.orderSettle(settleTarget.id, paidTotal, payRecords)
      message.success('结算成功！')
      setSettleOpen(false)
      fetchList()
    } catch { message.error('结算失败，请重试') }
    finally { setSettleLoading(false) }
  }

  const payTotal = payItems.reduce((s, p) => s + (p.amount || 0), 0)

  const handleReset = () => {
    setKeyword(''); setStatusFilter(undefined); setServiceModeFilter(undefined)
    setDateRange(null); setMerchantId(undefined); setPage(1)
    fetchList(1, '', undefined, undefined, null, undefined)
  }

  // ── 统计 ─────────────────────────────────────────────────────────────
  const activeCount    = orders.filter(d => [1,2,3,4,5].includes(d.status)).length
  const completedCount = orders.filter(d => d.status === 6).length
  const totalAmount    = orders.reduce((s, d) => s + Number(d.payAmount ?? 0), 0)
  const homeCount      = orders.filter(d => d.serviceMode === 1).length

  const statsBadges = [
    { icon: '📋', label: '订单总数', value: total,           color: '#0ea5e9', bg: 'rgba(14,165,233,.08)',  border: 'rgba(14,165,233,.22)' },
    { icon: '⚡', label: '进行中',  value: activeCount,      color: '#6366f1', bg: 'rgba(99,102,241,.08)',  border: 'rgba(99,102,241,.22)' },
    { icon: '✅', label: '已完成',  value: completedCount,   color: '#16a34a', bg: 'rgba(22,163,74,.08)',   border: 'rgba(22,163,74,.22)'  },
    { icon: '🏠', label: '上门服务', value: homeCount,       color: '#f97316', bg: 'rgba(249,115,22,.08)',  border: 'rgba(249,115,22,.22)' },
    { icon: '💰', label: '金额(页)', value: `$${totalAmount.toFixed(0)}`, color: '#d97706', bg: 'rgba(217,119,6,.08)', border: 'rgba(217,119,6,.22)' },
  ]

  // ── 表格列 ────────────────────────────────────────────────────────────
  const columns: ColumnsType<any> = [
    // ① 服务方式 + 订单号（固定左）
    {
      title: col(<OrderedListOutlined style={{ color: '#6366f1' }} />, '订单信息', 'left'),
      key: 'orderInfo', width: 180, fixed: 'left',
      render: (_, r) => (
        <div>
          <Tag
            icon={r.serviceMode === 1 ? <HomeOutlined /> : <ShopOutlined />}
            color={r.serviceMode === 1 ? 'orange' : 'blue'}
            style={{ marginBottom: 4, fontSize: 11 }}
          >
            {r.serviceMode === 1 ? '上门服务' : '到店服务'}
          </Tag>
          <div style={{ fontFamily: 'monospace', fontSize: 11, color: '#6b7280', marginTop: 2 }}>{r.orderNo}</div>
        </div>
      ),
    },
    // ② 客户信息
    {
      title: col(<UserOutlined style={{ color: '#64748b' }} />, '客户信息', 'left'),
      key: 'member', width: 150,
      render: (_, r) => (
        <div style={{ display:'flex', alignItems:'center', gap:8 }}>
          <Avatar size={32} icon={<UserOutlined />}
            style={{ background: r.memberNickname ? 'linear-gradient(135deg,#6366f1,#8b5cf6)' : '#e5e7eb', flexShrink:0, fontWeight:700 }}>
            {r.memberNickname?.charAt(0)}
          </Avatar>
          <div style={{ minWidth:0 }}>
            <div style={{ fontWeight:600, fontSize:13, color:'#111827' }}>
              {r.memberNickname || <Text type="secondary" style={{ fontSize:12 }}>散客</Text>}
            </div>
            {r.memberMobile && (
              <div style={{ fontSize:11, color:'#9ca3af' }}>
                <PhoneOutlined style={{ marginRight:3 }} />{r.memberMobile}
              </div>
            )}
          </div>
        </div>
      ),
    },
    // ③ 服务技师
    {
      title: col(<IdcardOutlined style={{ color: '#64748b' }} />, '服务技师', 'left'),
      key: 'technician', width: 170,
      render: (_, r) => r.technicianNickname ? (
        <div style={{ display:'flex', alignItems:'center', gap:8 }}>
          <Avatar size={32}
            style={{ background:'linear-gradient(135deg,#f59e0b,#f97316)', fontWeight:700, fontSize:13, flexShrink:0 }}>
            {r.technicianNickname.charAt(0)}
          </Avatar>
          <div style={{ minWidth:0 }}>
            <div style={{ fontWeight:600, fontSize:13, color:'#111827' }}>{r.technicianNickname}</div>
            <div style={{ fontSize:11, color:'#9ca3af' }}>
              {/* 上门服务显示技师编号，到店服务也显示 */}
              {r.technicianNo && <><IdcardOutlined style={{ marginRight:3 }} />{r.technicianNo}</>}
              {r.technicianMobile && <><PhoneOutlined style={{ marginLeft:6, marginRight:2 }} />{r.technicianMobile}</>}
            </div>
          </div>
        </div>
      ) : (
        <Text type="secondary" style={{ fontSize:12 }}>待分配</Text>
      ),
    },
    // ④ 消费金额
    {
      title: col(<DollarOutlined style={{ color: '#64748b' }} />, '消费金额', 'center'),
      key: 'amount', width: 120, align: 'center',
      render: (_, r) => (
        <div>
          <div style={{ fontSize:15, fontWeight:800, color:'#F5A623' }}>
            ${Number(r.payAmount ?? r.originalAmount ?? 0).toFixed(2)}
          </div>
          {r.payAmount != null && r.originalAmount != null && Number(r.originalAmount) > Number(r.payAmount) && (
            <div style={{ fontSize:10, color:'#9ca3af', textDecoration:'line-through' }}>
              ${Number(r.originalAmount).toFixed(2)}
            </div>
          )}
        </div>
      ),
    },
    // ⑤ 状态
    {
      title: col(<SettingOutlined style={{ color: '#64748b' }} />, '状态', 'center'),
      dataIndex: 'status', width: 95, align: 'center',
      render: (s: number) => {
        const cfg = ORDER_STATUS[s] ?? { text: '未知', badge: 'default', color: '#9ca3af' }
        return <Badge status={cfg.badge} text={<span style={{ fontWeight:600, color:cfg.color }}>{cfg.text}</span>} />
      },
    },
    // ⑥ 服务项目（含进度条）
    {
      title: col(<ShoppingCartOutlined style={{ color: '#64748b' }} />, '服务项目', 'left'),
      key: 'service', width: 210,
      render: (_, r) => {
        const items: any[] = r.orderItems ?? []
        if (!items.length) {
          const sn = r.serviceName
          if (sn) return (
            <div style={{ marginBottom:5 }}>
              <span style={{ fontSize:9, padding:'1px 5px', borderRadius:6, background:'#f3f4f6', color:'#9ca3af', fontWeight:700 }}>⏳ 待服务</span>
              <span style={{ fontSize:11, fontWeight:600, color:'#374151', marginLeft:5 }}>{sn}</span>
            </div>
          )
          return <span style={{ fontSize:12, color:'#9ca3af' }}>待录入</span>
        }
        return (
          <div style={{ paddingTop:2, paddingBottom:2 }}>
            {items.map((it, idx) => (
              <ServiceProgressBar key={it.id ?? idx} item={it} colorIdx={idx} compact svcStatusMap={SVC_STATUS_CFG} />
            ))}
          </div>
        )
      },
    },
    // ⑦ 预约时间 / 下单时间
    {
      title: col(<ClockCircleOutlined style={{ color: '#64748b' }} />, '时间', 'center'),
      key: 'time', width: 130, align: 'center',
      render: (_, r) => (
        <div>
          {r.appointTime && (
            <div style={{ fontSize:11, color:'#6366f1', fontWeight:600 }}>
              📅 {fmtTime(r.appointTime, 'MM-DD HH:mm')}
            </div>
          )}
          <div style={{ fontSize:11, color:'#9ca3af', marginTop: r.appointTime ? 2 : 0 }}>
            {r.createTime ? fmtTime(r.createTime, 'MM-DD HH:mm') : '—'}
          </div>
        </div>
      ),
    },
    // ⑧ 操作
    {
      title: col(<SettingOutlined style={{ color: '#6366f1' }} />, '操作'),
      key: 'action', fixed: 'right', width: 160,
      render: (_, r) => (
        <Space size={4} wrap>
          <Button size="small" type="primary" ghost icon={<EyeOutlined />}
            style={{ borderRadius:6 }} onClick={() => openDetail(r)}>详情</Button>
          {[1,2,3,4,5].includes(r.status) && (
            <Button size="small" icon={<DollarOutlined />}
              style={{ borderRadius:6, color:'#10b981', borderColor:'#a7f3d0' }}
              onClick={() => openSettle(r)}>结算</Button>
          )}
          {[0,1,2].includes(r.status) && (
            <PermGuard code="order:cancel">
              <Popconfirm title="确认取消该订单？" onConfirm={() => handleCancel(r)}
                okText="取消订单" cancelText="返回" okButtonProps={{ danger:true }}>
                <Button size="small" icon={<StopOutlined />}
                  style={{ borderRadius:6, color:'#fa8c16', borderColor:'#ffd591' }}>取消</Button>
              </Popconfirm>
            </PermGuard>
          )}
          {[6,7].includes(r.status) && (
            <PermGuard code="order:delete">
              <Popconfirm title="确认删除该订单记录？" onConfirm={() => handleDelete(r)}
                okText="删除" cancelText="取消" okButtonProps={{ danger:true }}>
                <Button size="small" danger icon={<DeleteOutlined />} style={{ borderRadius:6 }}>删除</Button>
              </Popconfirm>
            </PermGuard>
          )}
        </Space>
      ),
    },
  ]

  const subtitle = isMerchant
    ? '管理在线预约订单 · 上门/到店服务 · 实时追踪服务进度'
    : '查看平台全部在线订单 · 上门/到店服务 · 实时追踪服务进度'

  // ── 渲染 ─────────────────────────────────────────────────────────────
  return (
    <div style={{ marginTop: -24 }}>
      {/* ── 固定头部 ────────────────────────────────────────────────────── */}
      <div style={{
        position: 'sticky', top: 64, zIndex: 88,
        marginLeft: -24, marginRight: -24,
        background: 'rgba(255,255,255,0.97)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderBottom: '1px solid rgba(0,0,0,0.07)',
        boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
      }}>
        {/* 标题 + 统计徽章 */}
        <div style={{ display:'flex', alignItems:'center', padding:'10px 24px 0', gap:12 }}>
          <div style={{
            width:34, height:34, borderRadius:10,
            background:'linear-gradient(135deg,#6366f1,#8b5cf6)',
            display:'flex', alignItems:'center', justifyContent:'center',
            boxShadow:'0 4px 14px rgba(99,102,241,0.35)', flexShrink:0,
          }}>
            <OrderedListOutlined style={{ color:'#fff', fontSize:16 }} />
          </div>
    <div>
            <div style={{ fontSize:15, fontWeight:700, color:'#1e293b', lineHeight:1.2 }}>在线订单</div>
            <div style={{ fontSize:11, color:'#94a3b8', marginTop:1 }}>{subtitle}</div>
          </div>
          <div style={{ width:1, height:20, margin:'0 4px', background:'#e0e4ff', flexShrink:0 }} />
          <div style={{ display:'flex', gap:8, flexWrap:'wrap' }}>
            {statsBadges.map((s,i) => (
              <div key={i} style={{
                display:'flex', alignItems:'center', gap:5,
                padding:'3px 10px', borderRadius:20,
                background:s.bg, border:`1px solid ${s.border}`,
              }}>
                <span style={{ fontSize:13 }}>{s.icon}</span>
                <span style={{ fontSize:12, color:'#6b7280' }}>{s.label}</span>
                <span style={{ fontSize:13, fontWeight:700, color:s.color }}>{s.value}</span>
              </div>
            ))}
          </div>
          <div style={{ flex:1 }} />
        </div>

        {/* 筛选栏 */}
        <div style={{ display:'flex', gap:8, flexWrap:'wrap', alignItems:'center', padding:'10px 24px 12px' }}>
          <Input
            placeholder="搜索订单号 / 客户 / 技师编号"
            prefix={<SearchOutlined style={{ color:'#6366f1' }} />}
            allowClear size="middle" value={keyword}
            onChange={e => setKeyword(e.target.value)}
            onPressEnter={() => { setPage(1); fetchList(1) }}
            style={{ ...INPUT_STYLE, width: 220 }}
          />
          {/* 服务方式筛选 */}
          <Select
            placeholder={<Space size={4}><HomeOutlined style={{ color:'#f97316', fontSize:12 }} />服务方式</Space>}
            allowClear size="middle" style={{ width:120 }}
            value={serviceModeFilter}
            onChange={v => { setServiceModeFilter(v); setPage(1); fetchList(1, keyword, statusFilter, v, dateRange) }}
            options={[
              { value:1, label: <Space><HomeOutlined style={{ color:'#f97316' }} />上门服务</Space> },
              { value:2, label: <Space><ShopOutlined style={{ color:'#3b82f6' }} />到店服务</Space> },
            ]}
          />
          {/* 订单状态筛选 */}
          <Select
            placeholder={<Space size={4}><OrderedListOutlined style={{ color:'#6366f1', fontSize:12 }} />订单状态</Space>}
            allowClear size="middle" style={{ width:120 }}
            value={statusFilter}
            onChange={v => { setStatusFilter(v); setPage(1); fetchList(1, keyword, v, serviceModeFilter, dateRange) }}
            options={Object.entries(ORDER_STATUS).map(([k,v]) => ({
              value: Number(k),
              label: <Space size={4}><Badge status={v.badge} />{v.text}</Space>,
            }))}
          />
          {!isMerchant && (
            <Select
              placeholder={<span><ShopOutlined style={{ color:'#6366f1', marginRight:4 }} />所属商户</span>}
              allowClear size="middle" style={{ width:155 }}
              value={merchantId}
              onChange={v => { setMerchantId(v); setPage(1); fetchList(1, keyword, statusFilter, serviceModeFilter, dateRange, v) }}
              showSearch
              filterOption={(input, opt) => String(opt?.label ?? '').toLowerCase().includes(input.toLowerCase())}
              options={merchantOpts}
            />
          )}
          <DateTimeRangePicker
            placeholder={['开始时间', '结束时间']}
            value={(() => {
              if (dateRange?.[0] == null || dateRange?.[1] == null) return null
              const a = fromEpochSec(dateRange[0])
              const b = fromEpochSec(dateRange[1])
              return a && b ? ([a, b] as [Dayjs, Dayjs]) : null
            })()}
            onChange={dates => {
              const s0 = dates?.[0] ? toEpochSec(dates[0]) : null
              const s1 = dates?.[1] ? toEpochSec(dates[1]) : null
              const next = s0 != null && s1 != null ? [s0, s1] as [number, number] : null
              setDateRange(next)
              setPage(1)
              fetchList(1, keyword, statusFilter, serviceModeFilter, next)
            }}
          />
          <div style={{ flex:1 }} />
          <Button icon={<ReloadOutlined />} size="middle" style={{ borderRadius:8 }} onClick={handleReset}>重置</Button>
          <Button
            icon={<ReloadOutlined />} size="middle" loading={loading}
            style={{ borderRadius:8, color:'#6366f1', borderColor:'#c7d2fe' }}
            onClick={() => fetchList()}
          />
          <Button
            type="primary" icon={<SearchOutlined />}
            style={{ borderRadius:8, border:'none', background:'linear-gradient(135deg,#6366f1,#8b5cf6)', boxShadow:'0 2px 8px rgba(99,102,241,.35)' }}
            onClick={() => { setPage(1); fetchList(1) }}
          >搜索</Button>
        </div>
      </div>

      {/* ── 表格 ─────────────────────────────────────────────────────────── */}
      <div ref={ref} style={{ marginLeft:-24, marginRight:-24, marginBottom:-24, background:'#fff', borderTop:'1px solid #eef0f8' }}>
        <Table
          rowKey="id"
          dataSource={orders}
          columns={columns}
          loading={loading}
          size="middle"
          components={styledTableComponents}
          scroll={{ x:'max-content', y:tableBodyH }}
          pagination={false}
        />
        <PagePagination
          total={total} current={page} pageSize={pageSize} countLabel="条订单"
          onChange={p => { setPage(p); fetchList(p) }}
          onSizeChange={s => { setPageSize(s); setPage(1) }}
        />
      </div>

      {/* ── 详情抽屉 ───────────────────────────────────────────────────── */}
      <Drawer
        title={
          <Space>
            <div style={{ width:28, height:28, borderRadius:8, background:'linear-gradient(135deg,#6366f1,#8b5cf6)', display:'flex', alignItems:'center', justifyContent:'center' }}>
              <OrderedListOutlined style={{ color:'#fff', fontSize:13 }} />
            </div>
            <span>订单详情</span>
          </Space>
        }
        open={detailOpen}
        onClose={() => setDetailOpen(false)}
        styles={{ wrapper: { width: 900 } }}
        loading={detailLoading}
      >
        {detail && (
          <div>
            {/* 头部卡片 */}
            <div style={{
              background: detail.serviceMode === 1
                ? 'linear-gradient(135deg,#f97316,#ea580c)'
                : 'linear-gradient(135deg,#6366f1,#4f46e5)',
              borderRadius:14, padding:'14px 18px', marginBottom:20, color:'#fff',
            }}>
              <div style={{ display:'flex', alignItems:'center', gap:8, marginBottom:8 }}>
                {detail.serviceMode === 1
                  ? <HomeOutlined style={{ fontSize:16 }} />
                  : <ShopOutlined style={{ fontSize:16 }} />}
                <span style={{ fontSize:13, opacity:0.9 }}>
                  {detail.serviceMode === 1 ? '上门服务' : '到店服务'}
                </span>
                <Tag
                  color="rgba(255,255,255,0.25)"
                  style={{ color:'#fff', border:'none', marginLeft:8, fontSize:12 }}>
                  {ORDER_STATUS[detail.status]?.text ?? '—'}
                </Tag>
              </div>
              <div style={{ fontSize:12, opacity:0.75, marginBottom:3 }}>订单号</div>
              <div style={{ fontSize:15, fontWeight:700, fontFamily:'monospace' }}>{detail.orderNo}</div>
              <div style={{ marginTop:12, display:'flex', justifyContent:'space-between', alignItems:'flex-end' }}>
                <div style={{ fontSize:11, opacity:0.75 }}>
                  {detail.appointTime ? `预约：${fmtTime(detail.appointTime, 'MM-DD HH:mm')}` : ''}
                </div>
                <div style={{ fontSize:24, fontWeight:900 }}>
                  ${Number(detail.payAmount ?? detail.originalAmount ?? 0).toFixed(2)}
                </div>
              </div>
            </div>

            {/* 基础信息 */}
            <Descriptions column={2} size="small" bordered style={{ marginBottom:20 }}>
              <Descriptions.Item label="客户">
                {detail.memberNickname ?? `#${detail.memberId ?? '—'}`}
              </Descriptions.Item>
              <Descriptions.Item label="客户手机">
                {detail.memberMobile || '—'}
              </Descriptions.Item>
              <Descriptions.Item label="服务技师">
                {detail.technicianNickname || '待分配'}
              </Descriptions.Item>
              <Descriptions.Item label="技师编号">
                <Text code>{detail.technicianNo || '—'}</Text>
              </Descriptions.Item>
              <Descriptions.Item label="技师手机">
                {detail.technicianMobile || '—'}
              </Descriptions.Item>
              <Descriptions.Item label="服务地址">
                {detail.addressDetail
                  ? <><EnvironmentOutlined style={{ color:'#f97316', marginRight:4 }} />{detail.addressDetail}</>
                  : '—'}
              </Descriptions.Item>
              <Descriptions.Item label="原价">
                {detail.originalAmount != null ? `$${Number(detail.originalAmount).toFixed(2)}` : '—'}
              </Descriptions.Item>
              <Descriptions.Item label="实付">
                <Text strong style={{ color:'#f59e0b' }}>
                  {detail.payAmount != null ? `$${Number(detail.payAmount).toFixed(2)}` : '待结算'}
                </Text>
              </Descriptions.Item>
              {detail.cancelReason && (
                <Descriptions.Item label="取消原因" span={2}>
                  <Text type="danger">{detail.cancelReason}</Text>
                </Descriptions.Item>
              )}
              {detail.remark && (
                <Descriptions.Item label="备注" span={2}>{detail.remark}</Descriptions.Item>
              )}
            </Descriptions>

            {/* 服务项目 */}
            {(detailItems.length > 0 || detail.serviceName) && (
              <div style={{ marginBottom:20 }}>
                <div style={{ fontSize:13, fontWeight:700, color:'#374151', marginBottom:10, display:'flex', alignItems:'center', gap:6 }}>
                  <ShoppingCartOutlined style={{ color:'#6366f1' }} />服务项目
                </div>
                {detailItems.length > 0
                  ? detailItems.map((it, idx) => (
                      <ServiceProgressBar key={it.id ?? idx} item={it} colorIdx={idx} svcStatusMap={SVC_STATUS_CFG} />
                    ))
                  : (
                    <div style={{ padding:'10px 14px', borderRadius:10, border:'1px solid #e0e4ff', background:'#f5f3ff' }}>
                      <span style={{ color:'#6366f1', fontWeight:600 }}>{detail.serviceName}</span>
                      {detail.serviceDuration && <span style={{ fontSize:12, color:'#9ca3af', marginLeft:8 }}>{detail.serviceDuration}min</span>}
                    </div>
                  )
                }
              </div>
            )}

            {/* 支付明细 */}
            {detail.payRecords && (() => {
              try {
                const records = JSON.parse(detail.payRecords)
                if (Array.isArray(records) && records.length > 0) {
                  return (
                    <div style={{ marginBottom:20 }}>
                      <div style={{ fontSize:13, fontWeight:700, color:'#374151', marginBottom:10, display:'flex', alignItems:'center', gap:6 }}>
                        <WalletOutlined style={{ color:'#10b981' }} />支付明细
                      </div>
                      {records.map((pr: any, i: number) => {
                        const pm = PAY_METHODS[pr.method] ?? { label: '其它', color: '#94a3b8', icon: '💳' }
                        return (
                          <div key={i} style={{ display:'flex', alignItems:'center', justifyContent:'space-between', padding:'8px 12px', borderRadius:8, background:'#f8fafc', marginBottom:6 }}>
                            <Space>
                              <span style={{ fontSize:16 }}>{pm.icon}</span>
                              <span style={{ fontWeight:600, color:pm.color }}>{pm.label}</span>
                              {pr.currency && pr.currency !== 'USD' && <Tag style={{ fontSize:10 }}>{pr.currency}</Tag>}
              </Space>
                            <Text strong style={{ color:'#10b981', fontSize:15 }}>${Number(pr.amount).toFixed(2)}</Text>
                          </div>
                        )
                      })}
                    </div>
                  )
                }
              } catch { /* ignore */ }
              return null
            })()}

            {/* 订单流程时间线 */}
            <div>
              <div style={{ fontSize:13, fontWeight:700, color:'#374151', marginBottom:12, display:'flex', alignItems:'center', gap:6 }}>
                <ClockCircleOutlined style={{ color:'#6366f1' }} />订单流程
              </div>
              <Timeline
                items={[
                  { color:'green', children:'订单创建', label: detail.createTime ? fmtTime(detail.createTime, 'MM-DD HH:mm') : undefined },
                  { color: detail.status>=1?'green':'gray', children:'等待接单' },
                  { color: detail.status>=2?'green':'gray', children:'技师已接单' },
                  { color: detail.status>=3?'orange':'gray', children:'技师前往中' },
                  { color: detail.status>=4?'blue':'gray',   children:'技师已到达' },
                  { color: detail.status>=5?'orange':'gray', children:'服务进行中' },
                  { color: detail.status===6?'green':detail.status===7?'red':'gray', children: detail.status===7?'已取消':'服务完成' },
                ]}
              />
            </div>

            {/* 底部结算按钮 */}
            {[1,2,3,4,5].includes(detail.status) && (
              <div style={{ marginTop:20, paddingTop:16, borderTop:'1px solid #f1f5f9', textAlign:'right' }}>
                <Button
                  type="primary" icon={<DollarOutlined />} size="large"
                  style={{ borderRadius:10, background:'linear-gradient(135deg,#10b981,#059669)', border:'none', boxShadow:'0 4px 12px rgba(16,185,129,.35)' }}
                  onClick={() => { setDetailOpen(false); openSettle(detail) }}
                >前台结算</Button>
              </div>
            )}
          </div>
        )}
      </Drawer>

      {/* ── 结算弹窗（对标门店订单高品质 UI）─────────────────────────────── */}
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
                {settleTarget?.serviceMode === 1 ? '上门服务' : '到店服务'} · 组合支付 · 多币种结算
              </div>
            </div>
            <button
              onClick={() => setSettleOpen(false)}
              style={{
                display: 'flex', alignItems: 'center', gap: 5, flexShrink: 0,
                padding: '5px 12px', borderRadius: 20,
                background: 'rgba(255,255,255,0.18)', border: '1px solid rgba(255,255,255,0.35)',
                backdropFilter: 'blur(8px)', cursor: 'pointer',
                color: '#fff', fontSize: 12, fontWeight: 700,
              }}
              onMouseEnter={e => (e.currentTarget.style.background = 'rgba(255,255,255,0.32)')}
              onMouseLeave={e => (e.currentTarget.style.background = 'rgba(255,255,255,0.18)')}
            >
              <CloseCircleOutlined style={{ fontSize: 14 }} />关闭
            </button>
          </div>
        }
        closeIcon={null}
        open={settleOpen}
        onCancel={() => setSettleOpen(false)}
        width={620}
        style={{ top: 40 }}
        styles={{ body: { maxHeight: 'calc(100vh - 260px)', overflowY: 'auto', padding: '16px 24px 8px' } }}
        footer={
          settleTarget ? (() => {
            const totalAmt = Number(settleTarget.originalAmount ?? settleTarget.payAmount ?? 0)
            const isBalanced = Math.abs(payTotal - totalAmt) < 0.01
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
                  {isBalanced ? `确认结算 $${payTotal.toFixed(2)}` : '差额结算'}
                </Button>
              </div>
            )
          })() : null
        }
      >
        {settleTarget && (() => {
          const totalAmt = Number(settleTarget.originalAmount ?? settleTarget.payAmount ?? 0)
          const isBalanced = Math.abs(payTotal - totalAmt) < 0.01
          const serviceItems: any[] = settleTarget.orderItems ?? []

          return (
            <>
              {/* ── 客户 / 订单信息栏 ── */}
              <div style={{
                display: 'flex', alignItems: 'center', gap: 16,
                background: 'linear-gradient(135deg,#0f0c29,#302b63)',
                borderRadius: 14, padding: '16px 20px', marginBottom: 20,
                boxShadow: '0 4px 20px rgba(15,12,41,0.25)',
              }}>
                <div style={{
                  width: 52, height: 52, borderRadius: 14, flexShrink: 0,
                  background: settleTarget.serviceMode === 1
                    ? 'linear-gradient(135deg,#ea580c,#f97316)'
                    : 'linear-gradient(135deg,#4338ca,#6366f1)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 22, color: '#fff',
                  boxShadow: '0 4px 12px rgba(99,102,241,0.4)',
                }}>
                  {settleTarget.serviceMode === 1 ? <HomeOutlined /> : <ShopOutlined />}
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ color: 'rgba(255,255,255,0.55)', fontSize: 11, fontWeight: 600 }}>
                    {settleTarget.serviceMode === 1 ? '上门服务' : '到店服务'} · 订单号
                  </div>
                  <div style={{ color: '#fff', fontWeight: 800, fontSize: 15, marginTop: 2, fontFamily: 'monospace' }}>
                    {settleTarget.orderNo}
                  </div>
                  <div style={{ color: 'rgba(255,255,255,0.65)', fontSize: 12, marginTop: 3 }}>
                    {settleTarget.memberNickname || '散客'}
                    {settleTarget.technicianNickname && ` · 技师：${settleTarget.technicianNickname}`}
                    {settleTarget.technicianNo && ` #${settleTarget.technicianNo}`}
                  </div>
                </div>
                <div style={{ textAlign: 'right', flexShrink: 0 }}>
                  <div style={{ color: 'rgba(255,255,255,0.55)', fontSize: 11, fontWeight: 600, marginBottom: 4 }}>应付总额</div>
                  <div style={{ fontSize: 30, fontWeight: 900, color: '#34d399', lineHeight: 1 }}>
                    ${totalAmt.toFixed(2)}
                  </div>
                </div>
              </div>

              {/* ── 消费服务明细 ── */}
              {(serviceItems.length > 0 || settleTarget.serviceName) && (
                <div style={{ marginBottom: 20 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
                    <ShoppingCartOutlined style={{ color: '#6366f1', fontSize: 14 }} />
                    <span style={{ fontWeight: 700, color: '#111827', fontSize: 13 }}>消费服务明细</span>
                  </div>
                  <div style={{ border: '1px solid #eef0f8', borderRadius: 12, overflow: 'hidden' }}>
                    <div style={{
                      display: 'grid', gridTemplateColumns: '1fr 90px 90px',
                      background: 'linear-gradient(180deg,#f5f7ff,#eef1ff)',
                      padding: '8px 16px', gap: 12, borderBottom: '2px solid #e0e4ff',
                    }}>
                      {['服务项目', '单价', '小计'].map(h => (
                        <span key={h} style={{ fontSize: 11, fontWeight: 700, color: '#6366f1', textAlign: h === '服务项目' ? 'left' : 'center' }}>{h}</span>
                      ))}
                    </div>
                    {serviceItems.length > 0
                      ? serviceItems.map((item, i) => (
                          <div key={i} style={{
                            display: 'grid', gridTemplateColumns: '1fr 90px 90px',
                            padding: '10px 16px', gap: 12, alignItems: 'center',
                            background: i % 2 === 0 ? '#fff' : '#fafbff',
                            borderBottom: i < serviceItems.length - 1 ? '1px solid #f0f2ff' : 'none',
                          }}>
                            <div>
                              <div style={{ fontWeight: 600, fontSize: 13, color: '#111827' }}>{item.serviceName ?? item.name}</div>
                              {(item.qty ?? 1) > 1 && <div style={{ fontSize: 11, color: '#9ca3af' }}>× {item.qty}</div>}
                            </div>
                            <div style={{ textAlign: 'center', fontSize: 13, color: '#374151', whiteSpace: 'nowrap' }}>${Number(item.unitPrice).toFixed(2)}</div>
                            <div style={{ textAlign: 'center', fontSize: 13, fontWeight: 700, color: '#6366f1', whiteSpace: 'nowrap' }}>
                              ${(Number(item.unitPrice) * (item.qty ?? 1)).toFixed(2)}
                            </div>
                          </div>
                        ))
                      : (
                        <div style={{ padding: '10px 16px', display: 'grid', gridTemplateColumns: '1fr 90px 90px', gap: 12 }}>
                          <span style={{ fontWeight: 600, fontSize: 13, color: '#111827' }}>{settleTarget.serviceName}</span>
                          <span style={{ textAlign: 'center', fontSize: 13, color: '#374151' }}>${totalAmt.toFixed(2)}</span>
                          <span style={{ textAlign: 'center', fontSize: 13, fontWeight: 700, color: '#6366f1' }}>${totalAmt.toFixed(2)}</span>
                        </div>
                      )
                    }
                    <div style={{
                      display: 'grid', gridTemplateColumns: '1fr auto',
                      padding: '10px 16px',
                      background: 'linear-gradient(135deg,#f0fdf4,#dcfce7)',
                      borderTop: '2px solid #bbf7d0',
                    }}>
                      <span style={{ fontWeight: 700, color: '#065f46', fontSize: 13 }}>合计</span>
                      <span style={{ fontSize: 18, fontWeight: 900, color: '#10b981' }}>${totalAmt.toFixed(2)}</span>
                    </div>
                  </div>
                </div>
              )}

              {/* ── 组合支付 ── */}
              <div style={{ marginBottom: 16 }}>
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
                  {/* 快捷添加 chips */}
                  <div style={{ display: 'flex', gap: 5, flexWrap: 'wrap', justifyContent: 'flex-end' }}>
                    {Object.entries(PAY_METHODS).map(([k, v]) => {
                      const already = payItems.some(p => p.method === +k)
                      const remaining = +(totalAmt - payTotal).toFixed(2)
                      return (
                        <button key={k}
                          disabled={already}
                          onClick={() => {
                            const rem = Math.max(0, remaining)
                            setPayItems(prev => [...prev, { method: +k, currency: defaultCurrency, amount: rem }])
                          }}
                          style={{
                            display: 'inline-flex', alignItems: 'center', gap: 4,
                            padding: '3px 10px', borderRadius: 20,
                            border: `1px solid ${already ? '#e5e7eb' : v.color}`,
                            background: already ? '#f9fafb' : `${v.color}14`,
                            color: already ? '#9ca3af' : v.color,
                            fontSize: 11, fontWeight: 700, cursor: already ? 'not-allowed' : 'pointer',
                          }}>
                          <span style={{ fontSize: 13, lineHeight: 1 }}>{v.icon}</span>{v.label}
                        </button>
                      )
                    })}
                  </div>
                </div>

                {/* 支付项卡片 */}
                {payItems.map((item, idx) => {
                  const method = PAY_METHODS[item.method]
                  const needCurrency = !!method?.needCurrency
                  const cur = currencies.find((c: any) => c.currencyCode === item.currency)
                  const sym = cur?.symbol ?? '$'
                  const remaining = +(totalAmt - payItems.filter((_, i) => i !== idx).reduce((s, p) => s + p.amount, 0)).toFixed(2)

                  return (
                    <div key={idx} style={{
                      marginBottom: 8, borderRadius: 12, overflow: 'hidden',
                      border: `1.5px solid ${method?.color ?? '#e5e7eb'}33`,
                      background: `${method?.color ?? '#6366f1'}06`,
                    }}>
                      <div style={{
                        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                        padding: '7px 12px', background: `${method?.color ?? '#6366f1'}12`,
                        borderBottom: `1px solid ${method?.color ?? '#e5e7eb'}22`,
                      }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                          <span style={{ fontSize: 16, lineHeight: 1 }}>{method?.icon}</span>
                          <span style={{ fontWeight: 700, color: method?.color, fontSize: 13 }}>{method?.label}</span>
                          {idx === 0 && payItems.length === 1 && (
                            <span style={{ fontSize: 10, color: '#9ca3af', fontWeight: 500 }}>单一支付</span>
                          )}
                          {payItems.length > 1 && (
                            <span style={{ fontSize: 10, color: method?.color, fontWeight: 600, opacity: 0.7 }}>第 {idx + 1} 笔</span>
                          )}
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                          {remaining > 0 && item.amount < remaining && (
                            <button
                              onClick={() => { const arr = [...payItems]; arr[idx].amount = remaining; setPayItems(arr) }}
                              style={{ padding: '2px 8px', borderRadius: 6, border: '1px solid #fcd34d', background: '#fffbeb', color: '#d97706', fontSize: 10, fontWeight: 700, cursor: 'pointer' }}>
                              补足 {sym}{remaining.toFixed(2)}
                            </button>
                          )}
                          {payItems.length > 1 && (
                            <button
                              onClick={() => setPayItems(payItems.filter((_, i) => i !== idx))}
                              style={{ width: 20, height: 20, borderRadius: 4, border: 'none', background: '#fee2e2', color: '#ef4444', fontSize: 12, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>×</button>
                          )}
                        </div>
                      </div>
                      <div style={{ display: 'flex', gap: 8, padding: '10px 12px', alignItems: 'center' }}>
                        <Select
                          value={item.method}
                          onChange={v => {
                            const arr = [...payItems]; arr[idx].method = v
                            if (!PAY_METHODS[v]?.needCurrency) arr[idx].currency = defaultCurrency
                            setPayItems([...arr])
                          }}
                          style={{ width: 120 }} optionLabelProp="label" size="small"
                        >
                          {Object.entries(PAY_METHODS).map(([k, v]) => (
                            <Option key={k} value={+k} label={v.label}>
                              <span style={{ color: v.color, fontWeight: 600, display: 'flex', alignItems: 'center', gap: 5 }}>
                                <span style={{ fontSize: 14 }}>{v.icon}</span>{v.label}
                              </span>
                            </Option>
                          ))}
                        </Select>
                        {needCurrency && (
                          <Select
                            value={item.currency}
                            onChange={v => { const arr = [...payItems]; arr[idx].currency = v; setPayItems([...arr]) }}
                            style={{ width: 100 }} size="small" placeholder="币种"
                          >
                            {currencies.length > 0
                              ? currencies.map((c: any) => <Option key={c.currencyCode} value={c.currencyCode}>{c.flag ?? ''} {c.currencyCode}</Option>)
                              : [<Option key="USD" value="USD">🇺🇸 USD</Option>, <Option key="USDT" value="USDT">💵 USDT</Option>]
                            }
                          </Select>
                        )}
                        <InputNumber
                          value={item.amount} min={0} step={0.01} precision={2}
                          addonBefore={<span style={{ color: method?.color, fontWeight: 700 }}>{sym}</span>}
                          onChange={(v: number | null) => { const arr = [...payItems]; arr[idx].amount = v ?? 0; setPayItems([...arr]) }}
                          style={{ flex: 1 }} placeholder="0.00" size="small"
                        />
                      </div>
                    </div>
                  )
                })}

                {/* 添加支付方式按钮 */}
                <button
                  onClick={() => {
                    const remaining = Math.max(0, +(totalAmt - payTotal).toFixed(2))
                    setPayItems(prev => [...prev, { method: 1, currency: defaultCurrency, amount: remaining }])
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
                {payItems.length > 1 && (
                  <div style={{ padding: '10px 16px 6px', background: '#f8fafc' }}>
                    {payItems.map((p, i) => {
                      const m = PAY_METHODS[p.method]
                      return (
                        <div key={i} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 5 }}>
                          <span style={{ fontSize: 12, color: m?.color, fontWeight: 600, display: 'flex', alignItems: 'center', gap: 5 }}>
                            <span>{m?.icon}</span>{m?.label}
                          </span>
                          <span style={{ fontWeight: 700, color: '#374151' }}>${p.amount.toFixed(2)}</span>
                        </div>
                      )
                    })}
                    <div style={{ height: 1, background: '#e5e7eb', margin: '6px 0' }} />
                  </div>
                )}
                <div style={{
                  display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px 16px',
                  background: isBalanced ? 'linear-gradient(135deg,#ecfdf5,#d1fae5)' : 'linear-gradient(135deg,#fffbeb,#fef3c7)',
                }}>
                  <div>
                    <div style={{ fontSize: 12, color: isBalanced ? '#065f46' : '#92400e', fontWeight: 700 }}>
                      {isBalanced ? '✓ 金额匹配，可以结算' : '实收合计'}
                    </div>
                    {!isBalanced && (
                      <div style={{ fontSize: 11, color: '#d97706', marginTop: 2, fontWeight: 600 }}>
                        ⚠ 还差 ${Math.max(0, totalAmt - payTotal).toFixed(2)}，可差额结算
                      </div>
                    )}
                  </div>
                  <div style={{ textAlign: 'right' }}>
                    <div style={{ fontSize: 26, fontWeight: 900, color: isBalanced ? '#10b981' : '#f59e0b', lineHeight: 1 }}>
                      ${payTotal.toFixed(2)}
                    </div>
                    {!isBalanced && (
                      <div style={{ fontSize: 11, color: '#9ca3af', marginTop: 2 }}>应收 ${totalAmt.toFixed(2)}</div>
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
    </div>
  )
}
