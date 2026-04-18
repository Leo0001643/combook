/**
 * 财务总览 — 综合财务看板
 * 营业收入 / 支出 / 净利润 / 技师提成 / 薪资
 */
import { useState } from 'react'
import { Row, Col, Card, Typography, Select, Table, Progress, Tag } from 'antd'
import {
  DollarOutlined, ArrowUpOutlined, ArrowDownOutlined,
  BarChartOutlined, WalletOutlined, TeamOutlined, CarOutlined,
  HomeOutlined, ShoppingOutlined, RiseOutlined,
} from '@ant-design/icons'
import ReactECharts from 'echarts-for-react'
import dayjs from 'dayjs'

const { Text } = Typography
const { Option } = Select

const EXPENSE_CATS: Record<number, { label: string; color: string; icon: React.ReactNode }> = {
  1: { label: '店租/场地', color: '#6366f1', icon: <HomeOutlined /> },
  2: { label: '车辆费用', color: '#3b82f6', icon: <CarOutlined /> },
  3: { label: '水电费',   color: '#06b6d4', icon: <BarChartOutlined /> },
  4: { label: '员工工资', color: '#10b981', icon: <TeamOutlined /> },
  5: { label: '采购进货', color: '#f59e0b', icon: <ShoppingOutlined /> },
  6: { label: '营销推广', color: '#ec4899', icon: <RiseOutlined /> },
  7: { label: '设备维修', color: '#f97316', icon: <BarChartOutlined /> },
  8: { label: '其它',    color: '#94a3b8', icon: <DollarOutlined /> },
}

// Mock data
const mockMonths = Array.from({ length: 6 }, (_, i) => dayjs().subtract(5 - i, 'month').format('YYYY-MM'))
const mockIncome  = [28000, 32000, 29500, 41000, 38500, 48200]
const mockExpense = [12000, 14000, 13500, 17000, 16000, 19800]
const mockProfit  = mockIncome.map((v, i) => v - mockExpense[i])

const mockExpenseBreakdown = [
  { category: 1, amount: 8000,  pct: 40 },
  { category: 4, amount: 5000,  pct: 25 },
  { category: 2, amount: 2500,  pct: 13 },
  { category: 3, amount: 1800,  pct: 9  },
  { category: 5, amount: 1200,  pct: 6  },
  { category: 6, amount: 800,   pct: 4  },
  { category: 8, amount: 500,   pct: 3  },
]

const mockRecentIncome = [
  { key: '1', date: '2026-04-13', type: '订单收入',   method: '现金',     amount: 1280, status: 1 },
  { key: '2', date: '2026-04-13', type: '订单收入',   method: 'USDT',     amount: 880,  status: 1 },
  { key: '3', date: '2026-04-12', type: '散客结算',   method: '微信支付', amount: 560,  status: 1 },
  { key: '4', date: '2026-04-12', type: '订单收入',   method: '现金',     amount: 320,  status: 1 },
  { key: '5', date: '2026-04-11', type: '会员充值',   method: '支付宝',   amount: 2000, status: 1 },
]

function financeChartOption() {
  return {
    backgroundColor: 'transparent',
    tooltip: { trigger: 'axis', backgroundColor: '#1e293b', borderColor: 'transparent', textStyle: { color: '#f1f5f9' } },
    legend: { data: ['收入', '支出', '净利润'], textStyle: { color: '#6b7280', fontWeight: 600 }, top: 0 },
    grid: { top: 36, bottom: 24, left: 56, right: 20, containLabel: false },
    xAxis: { type: 'category', data: mockMonths, axisLabel: { color: '#9ca3af', fontSize: 11 }, axisLine: { lineStyle: { color: '#e5e7eb' } }, splitLine: { show: false } },
    yAxis: { type: 'value', axisLabel: { color: '#9ca3af', fontSize: 11, formatter: (v: number) => `$${(v/1000).toFixed(0)}k` }, splitLine: { lineStyle: { color: '#f3f4f6', type: 'dashed' } } },
    series: [
      { name: '收入', type: 'bar', data: mockIncome, barWidth: 18, itemStyle: { color: { type: 'linear', x: 0, y: 0, x2: 0, y2: 1, colorStops: [{ offset: 0, color: '#10b981' }, { offset: 1, color: '#6ee7b7' }] }, borderRadius: [6, 6, 0, 0] } },
      { name: '支出', type: 'bar', data: mockExpense, barWidth: 18, itemStyle: { color: { type: 'linear', x: 0, y: 0, x2: 0, y2: 1, colorStops: [{ offset: 0, color: '#f43f5e' }, { offset: 1, color: '#fca5a5' }] }, borderRadius: [6, 6, 0, 0] } },
      { name: '净利润', type: 'line', data: mockProfit, smooth: true, lineStyle: { width: 2.5, color: '#6366f1' }, itemStyle: { color: '#6366f1' }, areaStyle: { color: { type: 'linear', x: 0, y: 0, x2: 0, y2: 1, colorStops: [{ offset: 0, color: 'rgba(99,102,241,0.15)' }, { offset: 1, color: 'rgba(99,102,241,0)' }] } }, symbol: 'circle', symbolSize: 6 },
    ],
  }
}

function expensePieOption() {
  return {
    backgroundColor: 'transparent',
    tooltip: { trigger: 'item', backgroundColor: '#1e293b', borderColor: 'transparent', textStyle: { color: '#f1f5f9' }, formatter: '{b}: ${c} ({d}%)' },
    series: [{
      type: 'pie', radius: ['42%', '68%'], center: ['50%', '50%'],
      data: mockExpenseBreakdown.map(e => ({
        name: EXPENSE_CATS[e.category]?.label,
        value: e.amount,
        itemStyle: { color: EXPENSE_CATS[e.category]?.color },
      })),
      label: { show: true, formatter: '{b}\n{d}%', fontSize: 10, color: '#6b7280' },
      emphasis: { itemStyle: { shadowBlur: 10, shadowColor: 'rgba(0,0,0,0.2)' } },
    }],
  }
}

export default function FinanceOverviewPage() {
  const [period, setPeriod] = useState('month')

  const thisMonth = mockIncome[5]
  const lastMonth = mockIncome[4]
  const thisExp   = mockExpense[5]
  const lastExp   = mockExpense[4]
  const thisProfit = thisMonth - thisExp
  const lastProfit = lastMonth - lastExp

  const pct = (a: number, b: number) => b === 0 ? 0 : +((a - b) / b * 100).toFixed(1)

  const kpis = [
    { title: '本月营业收入', value: `$${thisMonth.toLocaleString()}`, color: '#10b981', bg: 'linear-gradient(135deg,#ecfdf5,#d1fae5)', trend: pct(thisMonth, lastMonth), icon: <RiseOutlined />, border: '#6ee7b7' },
    { title: '本月总支出',   value: `$${thisExp.toLocaleString()}`,   color: '#f43f5e', bg: 'linear-gradient(135deg,#fff1f2,#ffe4e6)', trend: pct(thisExp, lastExp),    icon: <ArrowDownOutlined />, border: '#fca5a5' },
    { title: '本月净利润',   value: `$${thisProfit.toLocaleString()}`, color: '#6366f1', bg: 'linear-gradient(135deg,#eef2ff,#e0e7ff)', trend: pct(thisProfit, lastProfit), icon: <WalletOutlined />, border: '#a5b4fc' },
    { title: '利润率',       value: `${(thisProfit / thisMonth * 100).toFixed(1)}%`, color: '#f59e0b', bg: 'linear-gradient(135deg,#fffbeb,#fef3c7)', icon: <BarChartOutlined />, border: '#fde68a' },
  ]

  const incomeColumns = [
    { title: '日期', dataIndex: 'date', width: 100, render: (v: string) => <Text style={{ fontSize: 12 }}>{v}</Text> },
    { title: '类型', dataIndex: 'type', width: 100, render: (v: string) => <Tag style={{ borderRadius: 8, fontWeight: 600, border: 'none', background: '#eef2ff', color: '#6366f1' }}>{v}</Tag> },
    { title: '支付方式', dataIndex: 'method', width: 100 },
    { title: '金额', dataIndex: 'amount', align: 'right' as const, render: (v: number) => <span style={{ fontWeight: 800, color: '#10b981', fontSize: 14 }}>${v.toLocaleString()}</span> },
  ]

  const overviewStats = [
    { label: '本月营收', value: `$${thisMonth.toLocaleString()}`, icon: <RiseOutlined />, color: '#10b981', bg: '#ecfdf5', border: '#a7f3d0' },
    { label: '本月支出', value: `$${thisExp.toLocaleString()}`,   icon: <ArrowDownOutlined />, color: '#f43f5e', bg: '#fff1f2', border: '#fca5a5' },
    { label: '净利润',   value: `$${thisProfit.toLocaleString()}`, icon: <WalletOutlined />,   color: '#6366f1', bg: '#eef2ff', border: '#c7d2fe' },
    { label: '利润率',   value: `${(thisProfit / thisMonth * 100).toFixed(1)}%`, icon: <BarChartOutlined />, color: '#f59e0b', bg: '#fffbeb', border: '#fde68a' },
  ]

  return (
    <div style={{ marginTop: -24 }}>
      {/* ── 粘性复合头部（统一白色风格）────────────────────────────────── */}
      <div style={{
        position: 'sticky', top: 64, zIndex: 88,
        marginLeft: -24, marginRight: -24,
        background: 'rgba(255,255,255,0.97)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderBottom: '1px solid rgba(0,0,0,0.07)',
        boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', padding: '10px 24px 0', gap: 16, flexWrap: 'wrap' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, flex: '0 0 auto' }}>
            <div style={{
              width: 34, height: 34, borderRadius: 10,
              background: 'linear-gradient(135deg,#047857,#10b981)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: '0 4px 12px rgba(4,120,87,0.35)', flexShrink: 0,
            }}>
              <DollarOutlined style={{ color: '#fff', fontSize: 16 }} />
            </div>
            <div>
              <div style={{ fontWeight: 700, fontSize: 15, color: '#111827', lineHeight: 1.2 }}>财务总览</div>
              <div style={{ fontSize: 11, color: '#9ca3af', lineHeight: 1.3, marginTop: 1 }}>收入 · 支出 · 利润 · 全维度财务分析</div>
            </div>
          </div>
          <div style={{ width: 1, height: 28, margin: '0 4px', background: '#e5e7eb', flexShrink: 0 }} />
          <div style={{ display: 'flex', gap: 8, flex: 1, flexWrap: 'wrap', alignItems: 'center' }}>
            {overviewStats.map(s => (
              <div key={s.label} style={{
                display: 'flex', alignItems: 'center', gap: 6,
                padding: '5px 12px', borderRadius: 20,
                background: s.bg, border: `1px solid ${s.border}`,
              }}>
                <span style={{ fontSize: 12, color: s.color }}>{s.icon}</span>
                <span style={{ color: s.color, fontWeight: 700, fontSize: 13, lineHeight: 1 }}>{s.value}</span>
                <span style={{ color: s.color, fontSize: 11, opacity: 0.8 }}>{s.label}</span>
              </div>
            ))}
          </div>
          <Select value={period} onChange={setPeriod} style={{ width: 110 }} size="small">
            <Option value="month">本月</Option>
            <Option value="quarter">本季度</Option>
            <Option value="year">本年</Option>
          </Select>
        </div>
        <div style={{ height: 12 }} />
      </div>

      {/* ── 内容区（可上下滚动）──────────────────────────────────────────── */}
      <div style={{ padding: '20px 0 40px' }}>
        {/* KPI cards */}
        <Row gutter={[16, 16]} style={{ marginBottom: 20 }}>
          {kpis.map((k, i) => (
            <Col key={i} xs={24} sm={12} lg={6}>
              <Card style={{ borderRadius: 16, border: `1.5px solid ${k.border}`, background: k.bg, boxShadow: '0 2px 12px rgba(0,0,0,0.06)' }} styles={{ body: { padding: '18px 20px' } }}>
                <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
                  <div>
                    <div style={{ fontSize: 12, fontWeight: 600, color: '#6b7280', marginBottom: 6 }}>{k.title}</div>
                    <div style={{ fontSize: 26, fontWeight: 900, color: k.color }}>{k.value}</div>
                    {k.trend !== undefined && (
                      <div style={{ marginTop: 6, fontSize: 11, color: k.trend >= 0 ? '#16a34a' : '#dc2626', fontWeight: 700 }}>
                        {k.trend >= 0 ? <ArrowUpOutlined /> : <ArrowDownOutlined />} {Math.abs(k.trend)}% 较上月
                      </div>
                    )}
                  </div>
                  <div style={{ width: 40, height: 40, borderRadius: 12, background: k.color, display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', fontSize: 18, opacity: 0.85 }}>
                    {k.icon}
                  </div>
                </div>
              </Card>
            </Col>
          ))}
        </Row>

        {/* Charts */}
        <Row gutter={[16, 16]} style={{ marginBottom: 16 }}>
          <Col xs={24} lg={15}>
            <Card style={{ borderRadius: 16, border: 'none', boxShadow: '0 4px 20px rgba(0,0,0,0.07)' }} styles={{ body: { padding: '20px 24px' } }}
              title={<span style={{ fontWeight: 700 }}>📊 近6月收支趋势</span>}>
              <ReactECharts option={financeChartOption()} style={{ height: 280 }} opts={{ renderer: 'svg' }} />
            </Card>
          </Col>
          <Col xs={24} lg={9}>
            <Card style={{ borderRadius: 16, border: 'none', boxShadow: '0 4px 20px rgba(0,0,0,0.07)', height: '100%' }} styles={{ body: { padding: '20px' } }}
              title={<span style={{ fontWeight: 700 }}>💸 本月支出结构</span>}>
              <ReactECharts option={expensePieOption()} style={{ height: 200 }} opts={{ renderer: 'svg' }} />
              <div style={{ marginTop: 12 }}>
                {mockExpenseBreakdown.slice(0, 4).map(e => (
                  <div key={e.category} style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
                    <div style={{ width: 8, height: 8, borderRadius: 2, background: EXPENSE_CATS[e.category]?.color, flexShrink: 0 }} />
                    <span style={{ fontSize: 11, color: '#6b7280', flex: 1 }}>{EXPENSE_CATS[e.category]?.label}</span>
                    <Progress percent={e.pct} showInfo={false} size={6} strokeColor={EXPENSE_CATS[e.category]?.color} style={{ width: 80, margin: 0 }} />
                    <span style={{ fontSize: 11, fontWeight: 700, color: '#374151', width: 60, textAlign: 'right' }}>${e.amount.toLocaleString()}</span>
                  </div>
                ))}
              </div>
            </Card>
          </Col>
        </Row>

        {/* Recent income */}
        <Card style={{ borderRadius: 16, border: 'none', boxShadow: '0 4px 20px rgba(0,0,0,0.07)' }} styles={{ body: { padding: 0 } }}
          title={<span style={{ fontWeight: 700, padding: '0 4px' }}>💰 近期收入流水</span>}>
          <Table dataSource={mockRecentIncome} columns={incomeColumns} pagination={false} size="small" />
        </Card>
      </div>
    </div>
  )
}
