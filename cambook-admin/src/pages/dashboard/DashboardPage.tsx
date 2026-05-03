import { useState, useEffect, useCallback } from 'react'
import {
  Row, Col, Typography, Table, Tag, Avatar,
  Select, Spin, Badge, Progress,
} from 'antd'
import {
  UserOutlined, TeamOutlined, ShoppingCartOutlined, DollarOutlined,
  RiseOutlined,
  ClockCircleOutlined, TrophyOutlined,
  ArrowUpOutlined, ArrowDownOutlined, BarChartOutlined,
  CalendarOutlined, ThunderboltOutlined, ShopOutlined,
  WalletOutlined, LineChartOutlined, PieChartOutlined,
} from '@ant-design/icons'
import ReactECharts from 'echarts-for-react'
import dayjs from 'dayjs'
import { usePortalScope } from '../../hooks/usePortalScope'
import { useDict } from '../../hooks/useDict'
import { useAuthStore } from '../../store/authStore'
import { merchantPortalApi } from '../../api/api'
import request from '../../api/request'

const { Text } = Typography
const { Option } = Select

// ── Gradient palette ───────────────────────────────────────────────────────────
const G = {
  orange:  'linear-gradient(135deg,#ff6b35 0%,#f7c59f 100%)',
  purple:  'linear-gradient(135deg,#7c3aed 0%,#a78bfa 100%)',
  teal:    'linear-gradient(135deg,#0891b2 0%,#22d3ee 100%)',
  rose:    'linear-gradient(135deg,#e11d48 0%,#fb7185 100%)',
  green:   'linear-gradient(135deg,#059669 0%,#34d399 100%)',
  amber:   'linear-gradient(135deg,#d97706 0%,#fbbf24 100%)',
  indigo:  'linear-gradient(135deg,#4338ca 0%,#818cf8 100%)',
  pink:    'linear-gradient(135deg,#be185d 0%,#f472b6 100%)',
  cyan:    'linear-gradient(135deg,#0e7490 0%,#67e8f9 100%)',
  slate:   'linear-gradient(135deg,#334155 0%,#94a3b8 100%)',
}

// ── Glass card style ──────────────────────────────────────────────────────────
const glassCard: React.CSSProperties = {
  borderRadius: 20,
  border: '1px solid rgba(255,255,255,0.7)',
  background: 'rgba(255,255,255,0.85)',
  backdropFilter: 'blur(20px)',
  boxShadow: '0 8px 32px rgba(0,0,0,0.06), 0 1px 0 rgba(255,255,255,0.9) inset',
}

const STATUS_MAP_FB: Record<number, { color: string; text: string }> = {
  0: { color: '#94a3b8', text: '待支付' },
  1: { color: '#60a5fa', text: '待接单' },
  2: { color: '#34d399', text: '已接单' },
  3: { color: '#fb923c', text: '服务中' },
  4: { color: '#a78bfa', text: '前往中' },
  5: { color: '#fbbf24', text: '待评价' },
  6: { color: '#22c55e', text: '已完成' },
  7: { color: '#ef4444', text: '已取消' },
}

const PERIOD_LABELS: Record<string, string> = {
  day: '今日（小时）', week: '近7天', month: '近30天', year: '近12月',
}

function pct(current: number, prev: number) {
  if (prev === 0) return current > 0 ? 100 : 0
  return +((current - prev) / prev * 100).toFixed(1)
}

function TrendBadge({ value }: { value: number }) {
  const up = value >= 0
  return (
    <span style={{
      fontSize: 11, fontWeight: 700, padding: '2px 6px', borderRadius: 6,
      background: up ? '#dcfce7' : '#fee2e2',
      color: up ? '#16a34a' : '#dc2626',
      display: 'inline-flex', alignItems: 'center', gap: 2,
    }}>
      {up ? <ArrowUpOutlined style={{ fontSize: 9 }} /> : <ArrowDownOutlined style={{ fontSize: 9 }} />}
      {Math.abs(value)}%
    </span>
  )
}

interface KpiCardProps {
  title: string
  value: string | number
  suffix?: string
  icon: React.ReactNode
  gradient: string
  trend?: number
  trendLabel?: string
  sub?: string
}

function KpiCard({ title, value, suffix, icon, gradient, trend, trendLabel, sub }: KpiCardProps) {
  return (
    <div style={{
      ...glassCard,
      padding: '20px 22px',
      position: 'relative',
      overflow: 'hidden',
      transition: 'transform 0.2s, box-shadow 0.2s',
      cursor: 'default',
    }}
      onMouseEnter={e => {
        (e.currentTarget as HTMLDivElement).style.transform = 'translateY(-2px)'
        ;(e.currentTarget as HTMLDivElement).style.boxShadow = '0 16px 40px rgba(0,0,0,0.1), 0 1px 0 rgba(255,255,255,0.9) inset'
      }}
      onMouseLeave={e => {
        (e.currentTarget as HTMLDivElement).style.transform = 'translateY(0)'
        ;(e.currentTarget as HTMLDivElement).style.boxShadow = '0 8px 32px rgba(0,0,0,0.06), 0 1px 0 rgba(255,255,255,0.9) inset'
      }}
    >
      {/* 渐变装饰条 */}
      <div style={{
        position: 'absolute', top: 0, left: 0, right: 0, height: 3,
        background: gradient, borderRadius: '20px 20px 0 0',
      }} />
      {/* 右侧装饰圆 */}
      <div style={{
        position: 'absolute', top: -24, right: -24, width: 80, height: 80,
        borderRadius: '50%', background: gradient, opacity: 0.06,
      }} />

      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 12 }}>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 12, color: '#6b7280', fontWeight: 600, marginBottom: 8, letterSpacing: 0.3 }}>
            {title}
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 4, flexWrap: 'wrap' }}>
            <span style={{ fontSize: 26, fontWeight: 900, color: '#111827', lineHeight: 1.1, letterSpacing: -0.5 }}>
              {value}
            </span>
            {suffix && <span style={{ fontSize: 13, color: '#94a3b8', fontWeight: 600 }}>{suffix}</span>}
          </div>
          {(trend !== undefined || sub) && (
            <div style={{ marginTop: 10, display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
              {trend !== undefined && <TrendBadge value={trend} />}
              {trendLabel && <span style={{ fontSize: 11, color: '#94a3b8' }}>{trendLabel}</span>}
              {sub && <span style={{ fontSize: 11, color: '#94a3b8' }}>{sub}</span>}
            </div>
          )}
        </div>
        <div style={{
          width: 46, height: 46, borderRadius: 14, flexShrink: 0,
          background: gradient,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: '#fff', fontSize: 20,
          boxShadow: '0 6px 16px rgba(0,0,0,0.18)',
        }}>
          {icon}
        </div>
      </div>
    </div>
  )
}

// ── Trend chart option ─────────────────────────────────────────────────────────
function trendChartOption(labels: string[], orders: number[], _revenues: number[]) {
  return {
    backgroundColor: 'transparent',
    tooltip: {
      trigger: 'axis',
      backgroundColor: '#1e293b',
      borderColor: 'transparent',
      textStyle: { color: '#f1f5f9', fontSize: 12 },
      axisPointer: { type: 'cross', lineStyle: { color: '#475569' } },
    },
    legend: {
      data: ['订单数', '营业额(USD)'],
      textStyle: { color: '#6b7280', fontSize: 12, fontWeight: 600 },
      top: 0,
    },
    grid: { top: 36, bottom: 24, left: 48, right: 56, containLabel: false },
    xAxis: {
      type: 'category', data: labels,
      axisLabel: { color: '#9ca3af', fontSize: 11 },
      axisLine: { lineStyle: { color: '#e5e7eb' } },
      splitLine: { show: false },
    },
    yAxis: [
      {
        type: 'value', name: '订单',
        axisLabel: { color: '#9ca3af', fontSize: 11 },
        splitLine: { lineStyle: { color: '#f3f4f6', type: 'dashed' } },
        nameTextStyle: { color: '#9ca3af', fontSize: 11 },
      },
      {
        type: 'value', name: 'USD',
        axisLabel: { color: '#9ca3af', fontSize: 11, formatter: (v: number) => `$${v}` },
        splitLine: { show: false },
        nameTextStyle: { color: '#9ca3af', fontSize: 11 },
      },
    ],
    series: [
      {
        name: '订单数', type: 'bar', yAxisIndex: 0,
        data: orders,
        barMaxWidth: 32, barMinWidth: 6,
        itemStyle: { color: { type: 'linear', x: 0, y: 0, x2: 0, y2: 1, colorStops: [
          { offset: 0, color: '#6366f1' }, { offset: 1, color: '#a5b4fc' },
        ] }, borderRadius: [6, 6, 0, 0] },
        emphasis: { itemStyle: { color: '#4f46e5' } },
      },
      {
        name: '营业额(USD)', type: 'line', yAxisIndex: 1,
        data: _revenues, smooth: true,
        symbol: 'circle', symbolSize: 6,
        lineStyle: { width: 2.5, color: '#F5A623' },
        itemStyle: { color: '#F5A623', borderWidth: 2, borderColor: '#fff' },
        areaStyle: { color: { type: 'linear', x: 0, y: 0, x2: 0, y2: 1, colorStops: [
          { offset: 0, color: 'rgba(245,166,35,0.18)' }, { offset: 1, color: 'rgba(245,166,35,0)' },
        ] } },
      },
    ],
  }
}

// ── Status pie option ──────────────────────────────────────────────────────────
function statusPieOption(dist: Record<number, number>, STATUS_MAP: Record<number, { text: string; color: string }>) {
  const entries = Object.entries(dist).map(([k, v]) => ({
    name: STATUS_MAP[+k]?.text ?? `状态${k}`,
    value: v,
    itemStyle: { color: STATUS_MAP[+k]?.color ?? '#94a3b8' },
  })).filter(e => e.value > 0)

  return {
    backgroundColor: 'transparent',
    tooltip: {
      trigger: 'item',
      backgroundColor: '#1e293b',
      borderColor: 'transparent',
      textStyle: { color: '#f1f5f9' },
      formatter: '{b}: {c} ({d}%)',
    },
    legend: {
      orient: 'vertical', right: 8, top: 'center',
      textStyle: { color: '#6b7280', fontSize: 11, fontWeight: 600 },
      icon: 'circle', itemWidth: 8, itemHeight: 8, itemGap: 8,
    },
    series: [{
      type: 'pie', radius: ['48%', '72%'],
      center: ['38%', '50%'],
      data: entries,
      label: { show: false },
      emphasis: { itemStyle: { shadowBlur: 10, shadowColor: 'rgba(0,0,0,0.2)' } },
    }],
  }
}

// ── Tech rank bar option ───────────────────────────────────────────────────────
function techRankOption(names: string[], counts: number[], _revenues: number[]) {
  return {
    backgroundColor: 'transparent',
    tooltip: {
      trigger: 'axis',
      backgroundColor: '#1e293b',
      borderColor: 'transparent',
      textStyle: { color: '#f1f5f9', fontSize: 12 },
    },
    grid: { top: 12, bottom: 8, left: 8, right: 16, containLabel: true },
    xAxis: { type: 'value', splitLine: { lineStyle: { color: '#f3f4f6', type: 'dashed' } }, axisLabel: { color: '#9ca3af', fontSize: 10 } },
    yAxis: { type: 'category', data: names, axisLabel: { color: '#374151', fontSize: 11, fontWeight: 600 } },
    series: [
      {
        name: '订单数', type: 'bar', data: counts, barMaxWidth: 14,
        itemStyle: { color: { type: 'linear', x: 0, y: 0, x2: 1, y2: 0, colorStops: [
          { offset: 0, color: '#6366f1' }, { offset: 1, color: '#a5b4fc' },
        ] }, borderRadius: [0, 6, 6, 0] },
      },
    ],
  }
}

// ── Revenue breakdown radar ───────────────────────────────────────────────────
function revenueRadarOption(today: number, week: number, month: number, total: number) {
  // 确保 max 至少为 100，避免数据全0时 ECharts 雷达图 "min:0,max:1 ticks not readable" 警告
  const rawMax = Math.max(today * 30, week * 4, month, total > 0 && month > 0 ? total / 12 : 0)
  const max = Math.max(rawMax, 100)
  const monthAvg = total > 0 && month > 0 ? +(total / 12).toFixed(0) : 0
  return {
    backgroundColor: 'transparent',
    tooltip: { trigger: 'item', backgroundColor: '#1e293b', borderColor: 'transparent', textStyle: { color: '#f1f5f9' } },
    radar: {
      indicator: [
        { name: '今日', max, min: 0 },
        { name: '本周', max, min: 0 },
        { name: '本月', max, min: 0 },
        { name: '月均', max, min: 0 },
      ],
      shape: 'polygon',
      splitNumber: 4,
      alignTicks: false,
      axisName: { color: '#6b7280', fontSize: 11, fontWeight: 600 },
      splitArea: { areaStyle: { color: ['rgba(99,102,241,0.03)', 'rgba(99,102,241,0.06)', 'rgba(99,102,241,0.09)', 'rgba(99,102,241,0.12)'] } },
      splitLine: { lineStyle: { color: '#e5e7eb' } },
      axisLine: { lineStyle: { color: '#e5e7eb' } },
    },
    series: [{
      type: 'radar',
      data: [{
        value: [today, week, month, monthAvg],
        name: '营业额',
        itemStyle: { color: '#F5A623' },
        lineStyle: { color: '#F5A623', width: 2 },
        areaStyle: { color: 'rgba(245,166,35,0.15)' },
        symbol: 'circle', symbolSize: 6,
      }],
    }],
  }
}

// ── Merchant rank bar option ──────────────────────────────────────────────────
function merchantRankOption(names: string[], revenues: number[], counts: number[]) {
  return {
    backgroundColor: 'transparent',
    tooltip: {
      trigger: 'axis',
      backgroundColor: '#1e293b', borderColor: 'transparent',
      textStyle: { color: '#f1f5f9', fontSize: 12 },
      formatter: (params: any[]) => {
        const p0 = params[0]; const p1 = params[1]
        return `${p0.name}<br/>营业额: $${p0.value?.toLocaleString()}<br/>订单数: ${p1?.value} 单`
      },
    },
    legend: { data: ['营业额', '订单数'], textStyle: { color: '#6b7280', fontSize: 11, fontWeight: 600 }, top: 0 },
    grid: { top: 36, bottom: 8, left: 8, right: 56, containLabel: true },
    xAxis: { type: 'value', axisLabel: { color: '#9ca3af', fontSize: 10, formatter: (v: number) => `$${(v/1000).toFixed(0)}k` }, splitLine: { lineStyle: { color: '#f3f4f6', type: 'dashed' } } },
    yAxis: { type: 'category', data: names, axisLabel: { color: '#374151', fontSize: 11, fontWeight: 600 } },
    series: [
      {
        name: '营业额', type: 'bar', data: revenues, barMaxWidth: 14,
        itemStyle: { color: { type: 'linear', x: 0, y: 0, x2: 1, y2: 0, colorStops: [{ offset: 0, color: '#10b981' }, { offset: 1, color: '#6ee7b7' }] }, borderRadius: [0, 6, 6, 0] },
      },
      {
        name: '订单数', type: 'bar', data: counts, barMaxWidth: 14, yAxisIndex: 0,
        xAxisIndex: 0,
        itemStyle: { color: 'transparent' },
      },
    ],
  }
}

// ════════════════════════════════════════════════════════════════════════════════
export default function DashboardPage() {
  const { isAdmin }    = usePortalScope()
  const { merchant, isMerchant } = useAuthStore()

  const { items: statusItems } = useDict('order_status')
  const STATUS_MAP: Record<number, { color: string; text: string }> =
    statusItems.length > 0
      ? Object.fromEntries(statusItems.map(i => {
          const hexMap: Record<string, string> = { default:'#94a3b8', cyan:'#34d399', blue:'#60a5fa', purple:'#a78bfa', orange:'#fb923c', 'orange-2':'#fbbf24', green:'#22c55e', red:'#ef4444', geekblue:'#60a5fa', gold:'#fbbf24', volcano:'#f97316', warning:'#f59e0b' }
          const hex = i.remark?.startsWith('#') ? i.remark : (hexMap[i.remark ?? ''] ?? '#94a3b8')
          return [Number(i.dictValue), { color: hex, text: i.labelZh }]
        }))
      : STATUS_MAP_FB

  const [period, setPeriod]         = useState<string>('week')
  const [data, setData]             = useState<any>(null)
  const [loading, setLoading]       = useState(false)

  // ⚡ 修复闪烁：只依赖稳定的基本值（period, isMerchant），
  //    不依赖 usePortalScope 每轮渲染都会生成的新函数引用
  const fetchData = useCallback(() => {
    setLoading(true)
    const promise = isMerchant
      ? merchantPortalApi.dashboard(period)
      : request.get<any>('/admin/dashboard/stats', { params: { period } })
    promise
      .then(r => setData(r.data?.data))
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [period, isMerchant])

  useEffect(() => { fetchData() }, [fetchData])

  // ── Unified data binding (both admin and merchant use real API) ───────────
  const d = data ?? {}

  // Revenue
  const todayRev  = +(d.todayRevenue   ?? 0)
  const weekRev   = +(d.weekRevenue    ?? 0)
  const monthRev  = +(d.monthRevenue   ?? 0)
  const totalRev  = +(d.totalRevenue   ?? 0)
  const yestRev   = +(d.yestRevenue    ?? 0)
  const lwRev     = +(d.lastWeekRevenue  ?? 0)
  const lmRev     = +(d.lastMonthRevenue ?? 0)

  // Orders
  const todayOrd  = +(d.todayOrders   ?? 0)
  const weekOrd   = +(d.weekOrders    ?? 0)
  const monthOrd  = +(d.monthOrders   ?? 0)
  const totalOrd  = +(d.totalOrders   ?? 0)
  const yestOrd   = +(d.yestOrders    ?? 0)
  const lwOrd     = +(d.lastWeekOrders  ?? 0)
  const lmOrd     = +(d.lastMonthOrders ?? 0)

  // Admin-specific
  const todayMembers    = +(d.todayMembers    ?? 0)
  const yestMembers     = +(d.yestMembers     ?? 0)
  const monthMembers    = +(d.monthMembers    ?? 0)
  const totalMerchants  = +(d.totalMerchants  ?? 0)
  const activeMerchants = +(d.activeMerchants ?? 0)
  const totalTechs      = +(d.totalTechs      ?? 0)
  const platformIncome  = +(d.platformIncome  ?? 0)

  // Admin KPIs — full platform view
  const adminKpi = [
    { title: '今日新增会员',  value: todayMembers,               suffix: '人',  gradient: G.orange, icon: <UserOutlined />,         trend: pct(todayMembers, yestMembers),  trendLabel: '较昨日', sub: `本月+${monthMembers}` },
    { title: '今日订单',      value: todayOrd,                   suffix: '单',  gradient: G.purple, icon: <ShoppingCartOutlined />, trend: pct(todayOrd, yestOrd),          trendLabel: '较昨日', sub: `昨日 ${yestOrd} 单` },
    { title: '今日营业额',    value: `$${todayRev.toFixed(0)}`,  suffix: '',    gradient: G.teal,   icon: <DollarOutlined />,       trend: pct(todayRev, yestRev),          trendLabel: '较昨日', sub: `昨日 $${yestRev.toFixed(0)}` },
    { title: '本月营业额',    value: `$${monthRev.toFixed(0)}`,  suffix: '',    gradient: G.green,  icon: <WalletOutlined />,       trend: pct(monthRev, lmRev),            trendLabel: '较上月', sub: `上月 $${lmRev.toFixed(0)}` },
    { title: '平台服务费',    value: `$${platformIncome.toFixed(0)}`, suffix: '', gradient: G.rose, icon: <TrophyOutlined />,      sub: `总营收 $${totalRev.toFixed(0)}` },
    { title: '本月订单',      value: monthOrd,                   suffix: '单',  gradient: G.amber,  icon: <BarChartOutlined />,    trend: pct(monthOrd, lmOrd),            trendLabel: '较上月' },
    { title: '活跃商户',      value: activeMerchants,            suffix: '家',  gradient: G.indigo, icon: <ShopOutlined />,        sub: `共 ${totalMerchants} 家` },
    { title: '技师总数',      value: totalTechs,                 suffix: '人',  gradient: G.pink,   icon: <TeamOutlined />,        sub: `在线 ${+(d.onlineTechs ?? 0)} 人` },
  ]

  // Merchant KPIs
  const merchantKpi = [
    { title: '今日营业额',  value: `$${todayRev.toFixed(0)}`,  suffix: '', gradient: G.orange, icon: <DollarOutlined />,       trend: pct(todayRev, yestRev),  trendLabel: '较昨日', sub: `昨日 $${yestRev.toFixed(0)}` },
    { title: '今日订单',    value: todayOrd,                    suffix: '单', gradient: G.purple, icon: <ShoppingCartOutlined />,trend: pct(todayOrd, yestOrd),  trendLabel: '较昨日', sub: `昨日 ${yestOrd} 单` },
    { title: '本周营业额',  value: `$${weekRev.toFixed(0)}`,   suffix: '', gradient: G.teal,   icon: <LineChartOutlined />,     trend: pct(weekRev, lwRev),     trendLabel: '较上周', sub: `上周 $${lwRev.toFixed(0)}` },
    { title: '本周订单',    value: weekOrd,                     suffix: '单', gradient: G.rose,   icon: <BarChartOutlined />,   trend: pct(weekOrd, lwOrd),     trendLabel: '较上周', sub: `上周 ${lwOrd} 单` },
    { title: '本月营业额',  value: `$${monthRev.toFixed(0)}`,  suffix: '', gradient: G.green,  icon: <WalletOutlined />,        trend: pct(monthRev, lmRev),    trendLabel: '较上月', sub: `上月 $${lmRev.toFixed(0)}` },
    { title: '本月订单',    value: monthOrd,                    suffix: '单', gradient: G.amber, icon: <RiseOutlined />,         trend: pct(monthOrd, lmOrd),    trendLabel: '较上月', sub: `上月 ${lmOrd} 单` },
    { title: '在线技师',    value: +(d.onlineTechCount ?? 0),   suffix: '人', gradient: G.indigo, icon: <TeamOutlined />,        sub: `服务中 ${d.servingTechCount ?? 0} 人` },
    { title: '平均客单价',  value: `$${+(d.avgOrderValue ?? 0).toFixed(0)}`, suffix: '', gradient: G.pink, icon: <TrophyOutlined />, sub: `共 ${totalOrd} 单` },
  ]

  const kpiList = isAdmin ? adminKpi : merchantKpi

  // ── Trend chart data ───────────────────────────────────────────────────────
  const trendRaw = {
    labels:   (d.trend ?? []).map((t: any) => t.label),
    orders:   (d.trend ?? []).map((t: any) => t.orders ?? 0),
    revenues: (d.trend ?? []).map((t: any) => +(t.revenue ?? 0)),
  }

  // ── Status dist ────────────────────────────────────────────────────────────
  const statusDist: Record<number, number> = d.statusDistribution ?? {}

  // ── Tech rank ──────────────────────────────────────────────────────────────
  const techRankRaw: any[] = d.techRank ?? []
  const techNames    = [...techRankRaw].reverse().map(t => t.name)
  const techCounts   = [...techRankRaw].reverse().map(t => t.orderCount)
  const techRevenues = [...techRankRaw].reverse().map(t => +(t.revenue ?? 0))

  // ── Merchant rank (admin only) ─────────────────────────────────────────────
  const merchantRankRaw: any[] = d.merchantRank ?? []
  const mRankNames    = [...merchantRankRaw].reverse().map(m => m.name)
  const mRankRevenues = [...merchantRankRaw].reverse().map(m => +(m.revenue ?? 0))
  const mRankCounts   = [...merchantRankRaw].reverse().map(m => m.orderCount ?? 0)

  // ── Tech status bars ──────────────────────────────────────────────────────
  const techTotal   = isAdmin ? totalTechs   : +(d.technicianCount ?? 0)
  const techOnline  = isAdmin ? +(d.onlineTechs ?? 0)  : +(d.onlineTechCount ?? 0)
  const techServing = isAdmin ? +(d.servingTechs ?? 0) : +(d.servingTechCount ?? 0)
  const techIdle    = techOnline - techServing

  // ── Recent orders ─────────────────────────────────────────────────────────
  const [recentOrders, setRecentOrders] = useState<any[]>([])
  const { orderList } = usePortalScope()

  useEffect(() => {
    orderList({ page: 1, size: 8 }).then(res => {
      const d2 = res.data?.data
      const list = d2?.list ?? d2?.records ?? []
      setRecentOrders(list.map((o: any, i: number) => ({
        key: o.id ?? i,
        orderNo:    o.orderNo,
        user:       o.memberNickname ?? o.memberName ?? '—',
        technician: o.technicianNickname ?? o.technicianName ?? '—',
        service:    o.serviceName ?? '—',
        amount:     o.payAmount != null ? `$${(+o.payAmount).toFixed(2)}` : '—',
        status:     o.status,
        time:       (o.createTime ?? '').slice(5, 16),
      })))
    }).catch(() => setRecentOrders([]))
  }, [isMerchant]) // eslint-disable-line
  const orderColumns = [
    { title: '订单号', dataIndex: 'orderNo', key: 'orderNo', width: 160, render: (v: string) => <Text style={{ fontSize: 11, fontFamily: 'monospace' }}>{v}</Text> },
    { title: '客户',   dataIndex: 'user',    key: 'user',    width: 70  },
    { title: '技师',   dataIndex: 'technician', key: 'technician', width: 80 },
    { title: '服务项', dataIndex: 'service', key: 'service', ellipsis: true },
    { title: '金额',   dataIndex: 'amount',  key: 'amount',  width: 80, render: (v: string) => <Text style={{ color: '#F5A623', fontWeight: 700 }}>{v}</Text> },
    { title: '状态', dataIndex: 'status', key: 'status', width: 80, render: (s: number) => <Tag color={STATUS_MAP[s]?.color} style={{ borderRadius: 8, fontWeight: 600, border: 'none', fontSize: 11 }}>{STATUS_MAP[s]?.text}</Tag> },
    { title: '时间', dataIndex: 'time', key: 'time', width: 70, render: (v: string) => <Text type="secondary" style={{ fontSize: 11 }}>{v}</Text> },
  ]

  return (
    <Spin spinning={loading} size="large">
      <style>{`
        .dashboard-kpi-grid {
          display: grid;
          grid-template-columns: repeat(4, 1fr);
          gap: 16px;
        }
        @media (max-width: 1200px) {
          .dashboard-kpi-grid { grid-template-columns: repeat(2, 1fr); }
        }
        @media (max-width: 600px) {
          .dashboard-kpi-grid { grid-template-columns: 1fr; }
        }
      `}</style>

      <div style={{ margin: -24, padding: '0 0 32px', background: 'linear-gradient(180deg,#f0f4ff 0%,#f8fafc 40%)', minHeight: 'calc(100vh - 64px)' }}>

        {/* ── Hero Banner ─────────────────────────────────────────────────── */}
        <div style={{
          background: 'linear-gradient(135deg,#0f0c29 0%,#302b63 45%,#24243e 100%)',
          padding: '32px 36px 44px',
          position: 'relative', overflow: 'hidden',
        }}>
          {/* Mesh gradient overlay */}
          <div style={{
            position: 'absolute', inset: 0,
            background: 'radial-gradient(ellipse at 20% 50%, rgba(99,102,241,0.35) 0%, transparent 50%), radial-gradient(ellipse at 80% 20%, rgba(139,92,246,0.3) 0%, transparent 45%), radial-gradient(ellipse at 60% 80%, rgba(59,130,246,0.2) 0%, transparent 50%)',
            pointerEvents: 'none',
          }} />
          {/* Animated orbs */}
          {[
            { size: 320, top: -100, right: -80,  opacity: 0.07, color: '#6366f1' },
            { size: 200, top: 10,   right: 220,  opacity: 0.06, color: '#a78bfa' },
            { size: 150, bottom: -50, left: 280, opacity: 0.08, color: '#38bdf8' },
            { size: 80,  top: 40,  left: 60,     opacity: 0.05, color: '#f472b6' },
          ].map((c, i) => (
            <div key={i} style={{
              position: 'absolute', width: c.size, height: c.size, borderRadius: '50%',
              background: c.color, opacity: c.opacity, filter: 'blur(1px)',
              top: c.top, bottom: c.bottom, left: c.left, right: c.right,
              pointerEvents: 'none',
            }} />
          ))}

          <div style={{ position: 'relative', zIndex: 1 }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: 16 }}>
              <div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginBottom: 10 }}>
                  <div style={{
                    width: 52, height: 52, borderRadius: 16,
                    background: 'rgba(255,255,255,0.12)',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    backdropFilter: 'blur(12px)',
                    border: '1px solid rgba(255,255,255,0.2)',
                    boxShadow: '0 4px 16px rgba(0,0,0,0.2)',
                  }}>
                    <ShopOutlined style={{ color: '#fff', fontSize: 24 }} />
                  </div>
    <div>
                    <div style={{ color: 'rgba(255,255,255,0.55)', fontSize: 12, fontWeight: 600, letterSpacing: 0.5, textTransform: 'uppercase' }}>
                      {isAdmin ? 'Super Admin · 超级管理员' : 'Merchant Portal · 商户看板'}
                    </div>
                    <div style={{ color: '#fff', fontSize: 24, fontWeight: 900, letterSpacing: -0.5, marginTop: 2 }}>
                      {isAdmin ? '平台运营总览' : (d.merchantName || merchant?.merchantNameZh || '数据看板')}
                    </div>
                  </div>
                </div>
                <div style={{ color: 'rgba(255,255,255,0.5)', fontSize: 12, display: 'flex', alignItems: 'center', gap: 6 }}>
                  <CalendarOutlined />
                  {dayjs().format('YYYY年MM月DD日 dddd')}
                  <span style={{ color: 'rgba(255,255,255,0.25)' }}>·</span>
                  <span style={{ color: '#34d399', fontWeight: 600 }}>● 数据实时更新</span>
                </div>
              </div>

        <div>
                <Select
                  value={period}
                  onChange={v => setPeriod(v)}
                  style={{ width: 140 }}
                  size="middle"
                  styles={{
                    popup: { root: { borderRadius: 12 } },
                  }}
                >
                  {Object.entries(PERIOD_LABELS).map(([k, v]) => (
                    <Option key={k} value={k}>{v}</Option>
                  ))}
                </Select>
              </div>
            </div>

            {/* Hero quick stats */}
            <div style={{ display: 'flex', gap: 12, marginTop: 24, flexWrap: 'wrap' }}>
              {(isAdmin ? [
                { label: '平台总营收', value: `$${totalRev.toLocaleString(undefined, { maximumFractionDigits: 0 })}`, accent: '#34d399' },
                { label: '平台服务费', value: `$${platformIncome.toLocaleString(undefined, { maximumFractionDigits: 0 })}`, accent: '#a78bfa' },
                { label: '注册会员',   value: `${+(d.totalMembers ?? 0).toLocaleString()} 人`, accent: '#38bdf8' },
                { label: '商户总数',   value: `${totalMerchants} 家 · 活跃 ${activeMerchants}`, accent: '#fb923c' },
                { label: '技师总数',   value: `${totalTechs} 人`, accent: '#f472b6' },
                { label: '累计订单',   value: `${totalOrd.toLocaleString()} 单`, accent: '#fbbf24' },
              ] : [
                { label: '累计营业额', value: `$${totalRev.toFixed(0)}`, accent: '#34d399' },
                { label: '累计订单',   value: `${totalOrd} 单`, accent: '#a78bfa' },
                { label: '技师团队',   value: `${d.technicianCount ?? 0} 人`, accent: '#38bdf8' },
                { label: '账户余额',   value: `$${+(d.balance ?? 0).toFixed(0)}`, accent: '#fb923c' },
              ]).map(s => (
                <div key={s.label} style={{
                  background: 'rgba(255,255,255,0.06)',
                  backdropFilter: 'blur(12px)',
                  borderRadius: 14, padding: '10px 18px',
                  border: '1px solid rgba(255,255,255,0.1)',
                  minWidth: 110,
                  transition: 'background 0.2s',
                }}>
                  <div style={{ color: 'rgba(255,255,255,0.5)', fontSize: 10, fontWeight: 600, letterSpacing: 0.3 }}>{s.label}</div>
                  <div style={{ color: s.accent, fontSize: 15, fontWeight: 800, marginTop: 3 }}>{s.value}</div>
                </div>
              ))}
            </div>
          </div>
        </div>

        <div style={{ padding: '24px 28px 0' }}>

          {/* ── KPI Cards — 精品玻璃态网格 ─────────────────────────────────── */}
          <div className="dashboard-kpi-grid" style={{ marginBottom: 24 }}>
            {kpiList.map((k, i) => (
              <KpiCard key={i} {...k} />
            ))}
      </div>

          {/* ── Trend Chart + Status Pie ────────────────────────────────────── */}
          <Row gutter={[20, 20]} style={{ marginBottom: 20 }}>
            <Col xs={24} lg={16}>
              <div style={{ ...glassCard, padding: 0, overflow: 'hidden' }}>
                <div style={{
                  padding: '18px 22px 14px',
                  background: 'linear-gradient(90deg,rgba(99,102,241,0.04),transparent)',
                  borderBottom: '1px solid rgba(0,0,0,0.04)',
                  display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                    <div style={{
                      width: 32, height: 32, borderRadius: 10, background: G.indigo,
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                    }}>
                      <LineChartOutlined style={{ color: '#fff', fontSize: 14 }} />
                    </div>
                <div>
                      <div style={{ fontWeight: 800, color: '#111827', fontSize: 14 }}>营业趋势</div>
                      <div style={{ color: '#9ca3af', fontSize: 11 }}>{PERIOD_LABELS[period]}</div>
                    </div>
                  </div>
                  <Text type="secondary" style={{ fontSize: 11 }}>订单数 · 营业额</Text>
                </div>
                <div style={{ padding: '8px 16px 16px' }}>
                  <ReactECharts
                    option={trendChartOption(trendRaw.labels, trendRaw.orders, trendRaw.revenues)}
                    style={{ height: 270 }}
                    opts={{ renderer: 'svg' }}
                  />
                </div>
              </div>
            </Col>

            <Col xs={24} lg={8}>
              <div style={{ ...glassCard, padding: 0, overflow: 'hidden', height: '100%' }}>
                <div style={{
                  padding: '18px 22px 14px',
                  borderBottom: '1px solid rgba(0,0,0,0.04)',
                  display: 'flex', alignItems: 'center', gap: 10,
                }}>
                  <div style={{ width: 32, height: 32, borderRadius: 10, background: G.amber, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <PieChartOutlined style={{ color: '#fff', fontSize: 14 }} />
                  </div>
                  <div>
                    <div style={{ fontWeight: 800, color: '#111827', fontSize: 14 }}>订单状态</div>
                    <div style={{ color: '#9ca3af', fontSize: 11 }}>状态分布</div>
                  </div>
                </div>
                <div style={{ padding: '8px 12px 16px' }}>
                  <ReactECharts
                    option={statusPieOption(statusDist, STATUS_MAP)}
                    style={{ height: 230 }}
                    opts={{ renderer: 'svg' }}
                  />
                </div>
              </div>
            </Col>
          </Row>

          {/* ── Tech Rank + Revenue Radar + Tech Status ────────────────────── */}
          <Row gutter={[20, 20]} style={{ marginBottom: 20 }}>
            <Col xs={24} lg={10}>
              <div style={{ ...glassCard, padding: 0, overflow: 'hidden' }}>
                <div style={{
                  padding: '18px 22px 14px',
                  borderBottom: '1px solid rgba(0,0,0,0.04)',
                  display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                    <div style={{ width: 32, height: 32, borderRadius: 10, background: G.amber, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <TrophyOutlined style={{ color: '#fff', fontSize: 14 }} />
                    </div>
                    <div>
                      <div style={{ fontWeight: 800, color: '#111827', fontSize: 14 }}>技师排行榜</div>
                      <div style={{ color: '#9ca3af', fontSize: 11 }}>按完成订单数</div>
                    </div>
                  </div>
                </div>
                <div style={{ padding: '8px 16px' }}>
                  {techRankRaw.length > 0 ? (
                    <>
                      <ReactECharts
                        option={techRankOption(techNames, techCounts, techRevenues)}
                        style={{ height: 180 }}
                        opts={{ renderer: 'svg' }}
                      />
                      <div style={{ marginTop: 4 }}>
                        {techRankRaw.slice(0, 5).map((t, i) => (
                          <div key={i} style={{
                            display: 'flex', alignItems: 'center', gap: 10,
                            padding: '7px 10px', borderRadius: 10, marginBottom: 4,
                            background: i === 0 ? 'linear-gradient(135deg,rgba(245,158,11,0.08),rgba(251,191,36,0.04))' : 'transparent',
                            border: i === 0 ? '1px solid rgba(245,158,11,0.15)' : '1px solid transparent',
                          }}>
                            <div style={{
                              width: 22, height: 22, borderRadius: 7, flexShrink: 0,
                              background: i === 0 ? 'linear-gradient(135deg,#f59e0b,#fbbf24)' :
                                           i === 1 ? 'linear-gradient(135deg,#9ca3af,#d1d5db)' :
                                           i === 2 ? 'linear-gradient(135deg,#b45309,#d97706)' : '#f3f4f6',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                              fontSize: 10, fontWeight: 800,
                              color: i < 3 ? '#fff' : '#6b7280',
                            }}>
                              {i < 3 ? ['🥇','🥈','🥉'][i] : i + 1}
                            </div>
                            <Avatar size={26} src={t.avatar} icon={<UserOutlined />} style={{ flexShrink: 0 }} />
                            <div style={{ flex: 1, minWidth: 0 }}>
                              <div style={{ fontSize: 12, fontWeight: 700, color: '#111827', overflow: 'hidden', whiteSpace: 'nowrap', textOverflow: 'ellipsis' }}>{t.name}</div>
                            </div>
                            <div style={{ textAlign: 'right', flexShrink: 0 }}>
                              <div style={{ fontSize: 12, fontWeight: 700, color: '#6366f1' }}>{t.orderCount} 单</div>
                              <div style={{ fontSize: 10, color: '#9ca3af' }}>${+(t.revenue ?? 0).toFixed(0)}</div>
                            </div>
                          </div>
                        ))}
                      </div>
                    </>
                  ) : (
                    <div style={{ textAlign: 'center', padding: 48, color: '#9ca3af' }}>
                      <TrophyOutlined style={{ fontSize: 32, marginBottom: 8, display: 'block', opacity: 0.3 }} />
                      暂无排行数据
                    </div>
                  )}
                </div>
              </div>
            </Col>

            <Col xs={24} lg={7}>
              <div style={{ ...glassCard, padding: 0, overflow: 'hidden', height: '100%' }}>
                <div style={{
                  padding: '18px 22px 14px',
                  borderBottom: '1px solid rgba(0,0,0,0.04)',
                  display: 'flex', alignItems: 'center', gap: 10,
                }}>
                  <div style={{ width: 32, height: 32, borderRadius: 10, background: G.green, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <BarChartOutlined style={{ color: '#fff', fontSize: 14 }} />
                  </div>
                  <div>
                    <div style={{ fontWeight: 800, color: '#111827', fontSize: 14 }}>营收雷达</div>
                    <div style={{ color: '#9ca3af', fontSize: 11 }}>多维度对比</div>
                  </div>
                </div>
                <div style={{ padding: '8px 12px 16px' }}>
                  <ReactECharts
                    option={revenueRadarOption(todayRev, weekRev, monthRev, totalRev)}
                    style={{ height: 270 }}
                    opts={{ renderer: 'svg' }}
                  />
                </div>
              </div>
          </Col>

            <Col xs={24} lg={7}>
              <div style={{ ...glassCard, padding: 0, overflow: 'hidden', height: '100%' }}>
                <div style={{
                  padding: '18px 22px 14px',
                  borderBottom: '1px solid rgba(0,0,0,0.04)',
                  display: 'flex', alignItems: 'center', gap: 10,
                }}>
                  <div style={{ width: 32, height: 32, borderRadius: 10, background: G.rose, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <ThunderboltOutlined style={{ color: '#fff', fontSize: 14 }} />
                  </div>
                  <div>
                    <div style={{ fontWeight: 800, color: '#111827', fontSize: 14 }}>技师状态</div>
                    <div style={{ color: '#9ca3af', fontSize: 11 }}>实时在线情况</div>
                  </div>
                </div>
                <div style={{ padding: '20px 22px' }}>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
                    {[
                      { label: '在线技师', value: techOnline,  total: techTotal, color: '#10b981', railBg: '#d1fae5' },
                      { label: '服务中',   value: techServing, total: techTotal, color: '#6366f1', railBg: '#ede9fe' },
                      { label: '空闲中',   value: techIdle,    total: techTotal, color: '#f59e0b', railBg: '#fef3c7' },
                      { label: '离线',     value: techTotal - techOnline, total: techTotal, color: '#94a3b8', railBg: '#f1f5f9' },
                    ].map(row => (
                      <div key={row.label}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 7 }}>
                          <span style={{ fontSize: 12, fontWeight: 600, color: '#374151' }}>{row.label}</span>
                          <span style={{ fontSize: 12, fontWeight: 800, color: row.color }}>
                            {row.value}
                            <Text type="secondary" style={{ fontSize: 10, fontWeight: 400, marginLeft: 3 }}>/ {row.total}</Text>
                          </span>
                        </div>
                        <Progress
                          percent={row.total > 0 ? Math.round(row.value / row.total * 100) : 0}
                          showInfo={false} size={8}
                          strokeColor={row.color}
                          railColor={row.railBg}
                          style={{ margin: 0 }}
                        />
                      </div>
                    ))}

                    <div style={{
                      marginTop: 4, padding: '14px 16px',
                      background: 'linear-gradient(135deg,rgba(99,102,241,0.06),rgba(139,92,246,0.04))',
                      borderRadius: 14, border: '1px solid rgba(99,102,241,0.1)',
                    }}>
                      <div style={{ fontSize: 11, color: '#6b7280', fontWeight: 600, marginBottom: 4 }}>平均分成比例</div>
                      <div style={{ fontSize: 22, fontWeight: 900, color: '#6366f1', letterSpacing: -0.5 }}>
                        {+(d.commissionRate ?? 70)}
                        <span style={{ fontSize: 14, fontWeight: 600, color: '#a5b4fc' }}>%</span>
                      </div>
                      <div style={{ fontSize: 10, color: '#9ca3af', marginTop: 2 }}>技师分成 / 单次服务</div>
                    </div>
                  </div>
                </div>
              </div>
            </Col>
      </Row>

          {/* ── Admin-only: Merchant Rank ───────────────────────────────────── */}
          {isAdmin && merchantRankRaw.length > 0 && (
            <Row gutter={[20, 20]} style={{ marginBottom: 20 }}>
              <Col xs={24} lg={14}>
                <div style={{ ...glassCard, padding: 0, overflow: 'hidden' }}>
                  <div style={{
                    padding: '18px 22px 14px',
                    borderBottom: '1px solid rgba(0,0,0,0.04)',
                    display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                  }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                      <div style={{ width: 32, height: 32, borderRadius: 10, background: G.green, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        <ShopOutlined style={{ color: '#fff', fontSize: 14 }} />
                      </div>
                      <div>
                        <div style={{ fontWeight: 800, color: '#111827', fontSize: 14 }}>商户营收排行</div>
                        <div style={{ color: '#9ca3af', fontSize: 11 }}>Top 10 · 全平台实时</div>
                      </div>
                    </div>
                  </div>
                  <div style={{ padding: '8px 16px 16px' }}>
                    <ReactECharts
                      option={merchantRankOption(mRankNames, mRankRevenues, mRankCounts)}
                      style={{ height: 280 }}
                      opts={{ renderer: 'svg' }}
                    />
                  </div>
                </div>
              </Col>
              <Col xs={24} lg={10}>
                <div style={{ ...glassCard, padding: 0, overflow: 'hidden', height: '100%' }}>
                  <div style={{
                    padding: '18px 22px 14px',
                    borderBottom: '1px solid rgba(0,0,0,0.04)',
                    display: 'flex', alignItems: 'center', gap: 10,
                  }}>
                    <div style={{ width: 32, height: 32, borderRadius: 10, background: G.amber, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <TrophyOutlined style={{ color: '#fff', fontSize: 14 }} />
                    </div>
                    <div>
                      <div style={{ fontWeight: 800, color: '#111827', fontSize: 14 }}>商户详情</div>
                      <div style={{ color: '#9ca3af', fontSize: 11 }}>营收明细</div>
                    </div>
                  </div>
                  <div style={{ padding: '14px 16px' }}>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                      {merchantRankRaw.slice(0, 6).map((m: any, i: number) => (
                        <div key={m.id} style={{
                          display: 'flex', alignItems: 'center', gap: 10,
                          padding: '8px 12px', borderRadius: 12,
                          background: i === 0 ? 'linear-gradient(135deg,rgba(245,158,11,0.08),rgba(251,191,36,0.04))' : 'rgba(248,250,252,0.8)',
                          border: i === 0 ? '1px solid rgba(245,158,11,0.2)' : '1px solid rgba(0,0,0,0.03)',
                        }}>
                          <div style={{
                            width: 24, height: 24, borderRadius: 7, flexShrink: 0,
                            background: i === 0 ? 'linear-gradient(135deg,#f59e0b,#fbbf24)' :
                                         i === 1 ? 'linear-gradient(135deg,#9ca3af,#d1d5db)' :
                                         i === 2 ? 'linear-gradient(135deg,#b45309,#d97706)' : '#e5e7eb',
                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                            fontSize: 11, fontWeight: 800, color: i < 3 ? '#fff' : '#6b7280',
                          }}>
                            {i < 3 ? ['🥇','🥈','🥉'][i] : i + 1}
                          </div>
                          <div style={{ flex: 1, minWidth: 0 }}>
                            <div style={{ fontSize: 12, fontWeight: 700, color: '#111827', overflow: 'hidden', whiteSpace: 'nowrap', textOverflow: 'ellipsis' }}>{m.name}</div>
                            <div style={{ fontSize: 10, color: '#9ca3af' }}>{m.orderCount} 单</div>
                          </div>
                          <div style={{ fontSize: 13, fontWeight: 800, color: '#10b981', flexShrink: 0 }}>
                            ${+(m.revenue ?? 0).toFixed(0)}
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              </Col>
            </Row>
          )}

          {/* ── Recent Orders ───────────────────────────────────────────────── */}
          <div style={{ ...glassCard, overflow: 'hidden', marginBottom: 32 }}>
            <div style={{
              padding: '18px 22px 14px',
              borderBottom: '1px solid rgba(0,0,0,0.04)',
              display: 'flex', alignItems: 'center', gap: 10,
            }}>
              <div style={{ width: 32, height: 32, borderRadius: 10, background: G.purple, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <ClockCircleOutlined style={{ color: '#fff', fontSize: 14 }} />
              </div>
              <div>
                <div style={{ fontWeight: 800, color: '#111827', fontSize: 14 }}>最近订单</div>
                <div style={{ color: '#9ca3af', fontSize: 11 }}>实时订单动态</div>
              </div>
              <Badge count={recentOrders.length} style={{ background: '#6366f1', marginLeft: 4 }} />
            </div>
            <Table
              dataSource={recentOrders}
              columns={orderColumns}
              pagination={false}
              size="small"
              scroll={{ x: 700 }}
              rowKey="key"
              style={{ borderRadius: '0 0 20px 20px', overflow: 'hidden' }}
              locale={{ emptyText: (
                <div style={{ padding: 40, color: '#9ca3af', textAlign: 'center' }}>
                  <ClockCircleOutlined style={{ fontSize: 36, marginBottom: 10, display: 'block', opacity: 0.25 }} />
                  <div style={{ fontWeight: 600 }}>暂无近期订单</div>
                  <div style={{ fontSize: 12, marginTop: 4 }}>订单数据将在这里实时展示</div>
                </div>
              ) }}
            />
                  </div>

                </div>
    </div>
    </Spin>
  )
}
