import { useState, useEffect } from 'react'
import { Row, Col, Card, Statistic, Typography, Progress, Spin, Space } from 'antd'
import {
  DollarOutlined, BarChartOutlined, RiseOutlined,
  WalletOutlined, PercentageOutlined,
} from '@ant-design/icons'
import ReactECharts from 'echarts-for-react'
import dayjs from 'dayjs'
import { merchantPortalApi } from '../../api/api'
const { Text } = Typography

export default function MerchantFinanceView() {
  const [data, setData]       = useState<any>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    merchantPortalApi.financeOverview()
      .then(r => setData(r.data?.data))
      .finally(() => setLoading(false))
  }, [])

  if (loading) return <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: 400 }}><Spin size="large" /></div>

  const totalRevenue    = Number(data?.totalRevenue    ?? 0)
  const balance         = Number(data?.balance         ?? 0)
  const platformFee     = Number(data?.platformFee     ?? 0)
  const technicianFee   = Number(data?.technicianFee   ?? 0)
  const merchantRevenue = totalRevenue - platformFee - technicianFee
  const todayIncome     = Number(data?.todayIncome     ?? 0)

  const pieOption = {
    tooltip: { trigger: 'item', formatter: '{b}: ¥{c} ({d}%)' },
    legend: { bottom: 0, type: 'scroll' },
    series: [{
      type: 'pie', radius: ['50%', '75%'], avoidLabelOverlap: false,
      label: { show: false }, emphasis: { label: { show: true, fontWeight: 'bold' } },
      data: [
        { value: merchantRevenue.toFixed(2), name: '商户净收入',  itemStyle: { color: '#10b981' } },
        { value: platformFee.toFixed(2),     name: '平台佣金',    itemStyle: { color: '#6366f1' } },
        { value: technicianFee.toFixed(2),   name: '技师提成',    itemStyle: { color: '#f59e0b' } },
      ],
    }],
  }

  const days = Array.from({ length: 7 }, (_, i) => dayjs().subtract(6 - i, 'day').format('MM/DD'))
  const incomeOption = {
    tooltip: { trigger: 'axis' },
    xAxis: { type: 'category', data: days },
    yAxis: { type: 'value' },
    series: [{ type: 'bar', data: [120, 340, 280, 460, 390, 520, todayIncome], itemStyle: { color: '#F5A623', borderRadius: 6 } }],
    grid: { top: 20, bottom: 30, left: 50, right: 20 },
  }

  const cards = [
    { title: '账户余额',     value: balance,         suffix: '', prefix: '¥', color: '#F5A623', bg: '#fff8e6', icon: <WalletOutlined />,       desc: '可申请提现' },
    { title: '累计总流水',   value: totalRevenue,    suffix: '', prefix: '¥', color: '#6366f1', bg: '#eef2ff', icon: <BarChartOutlined />,      desc: '全部订单总额' },
    { title: '商户净收入',   value: merchantRevenue, suffix: '', prefix: '¥', color: '#10b981', bg: '#ecfdf5', icon: <RiseOutlined />,          desc: '扣除平台与技师提成' },
    { title: '今日收入',     value: todayIncome,     suffix: '', prefix: '¥', color: '#f43f5e', bg: '#fff1f2', icon: <DollarOutlined />,        desc: '今天的收入' },
  ]

  return (
    <div style={{ marginTop: -24, height: 'calc(100vh - 64px)', display: 'flex', flexDirection: 'column' }}>
      <div style={{ position: 'sticky', top: 64, zIndex: 88, marginLeft: -24, marginRight: -24, background: 'rgba(255,255,255,0.97)', backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)', borderBottom: '1px solid rgba(0,0,0,0.07)', boxShadow: '0 4px 20px rgba(0,0,0,0.06)' }}>
        <div style={{ display: 'flex', alignItems: 'center', padding: '10px 24px 12px', gap: 12 }}>
          <div style={{ width: 34, height: 34, borderRadius: 10, background: 'linear-gradient(135deg,#10b981,#059669)', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 4px 12px rgba(16,185,129,0.35)', flexShrink: 0 }}>
            <DollarOutlined style={{ color: '#fff', fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1e293b', lineHeight: 1.2 }}>财务概览</div>
            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>商户收入分析 · 资金流水 · 余额管理</div>
          </div>
          <div style={{ width: 1, height: 20, margin: '0 4px', background: '#e0e4ff', flexShrink: 0 }} />
          <div style={{ display: 'flex', gap: 8 }}>
            {[
              { label: '总收入', value: `$${totalRevenue.toFixed(0)}`, color: '#10b981', bg: 'rgba(16,185,129,0.1)', border: 'rgba(16,185,129,0.25)', icon: '💰' },
              { label: '账户余额', value: `$${balance.toFixed(0)}`, color: '#6366f1', bg: 'rgba(99,102,241,0.1)', border: 'rgba(99,102,241,0.25)', icon: '🏦' },
              { label: '今日收入', value: `$${todayIncome.toFixed(0)}`, color: '#f59e0b', bg: 'rgba(245,158,11,0.1)', border: 'rgba(245,158,11,0.25)', icon: '📈' },
            ].map((s, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: s.bg, border: `1px solid ${s.border}` }}>
                <span style={{ fontSize: 13 }}>{s.icon}</span>
                <span style={{ fontSize: 12, color: '#6b7280' }}>{s.label}</span>
                <span style={{ fontSize: 13, fontWeight: 700, color: s.color }}>{s.value}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
      <div style={{ paddingTop: 20, flex: 1, overflowY: 'auto' }}>
      <Row gutter={[16, 16]} style={{ marginBottom: 20 }}>
        {cards.map((c, i) => (
          <Col key={i} xs={12} sm={6}>
            <Card variant="borderless" style={{ borderRadius: 16, boxShadow: '0 2px 12px rgba(0,0,0,0.06)' }}
                  styles={{ body: { padding: '18px 20px' } }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <div style={{ width: 36, height: 36, borderRadius: 10, background: c.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                  <span style={{ color: c.color, fontSize: 20 }}>{c.icon}</span>
                </div>
                <Statistic
                  title={<Text type="secondary" style={{ fontSize: 12 }}>{c.title}</Text>}
                  value={c.value.toFixed(2)}
                  prefix={c.prefix}
                  styles={{ content: { color: c.color, fontSize: 18, fontWeight: 800 } }}
                />
              </div>
              <Text type="secondary" style={{ fontSize: 11, marginLeft: 46 }}>{c.desc}</Text>
            </Card>
          </Col>
        ))}
      </Row>

      <Row gutter={[16, 16]}>
        {/* 收入分配 */}
        <Col xs={24} lg={10}>
          <Card variant="borderless" title={<Space><PercentageOutlined style={{ color: '#F5A623' }} /><span style={{ fontWeight: 700 }}>收入分配占比</span></Space>}
                style={{ borderRadius: 16, boxShadow: '0 2px 12px rgba(0,0,0,0.06)' }}>
            <ReactECharts option={pieOption} style={{ height: 240 }} />
            {[
              { label: '商户净收入', value: merchantRevenue, color: '#10b981', pct: totalRevenue > 0 ? Math.round(merchantRevenue / totalRevenue * 100) : 0 },
              { label: '平台佣金',   value: platformFee,     color: '#6366f1', pct: totalRevenue > 0 ? Math.round(platformFee   / totalRevenue * 100) : 0 },
              { label: '技师提成',   value: technicianFee,   color: '#f59e0b', pct: totalRevenue > 0 ? Math.round(technicianFee / totalRevenue * 100) : 0 },
            ].map((item, i) => (
              <div key={i} style={{ marginBottom: 12 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                  <Space size={6}>
                    <div style={{ width: 10, height: 10, borderRadius: '50%', background: item.color }} />
                    <Text style={{ fontSize: 13 }}>{item.label}</Text>
                  </Space>
                  <Text strong style={{ color: item.color }}>¥{item.value.toFixed(2)} ({item.pct}%)</Text>
                </div>
                <Progress percent={item.pct} strokeColor={item.color} showInfo={false} size="small" />
              </div>
            ))}
          </Card>
        </Col>

        {/* 7日收入趋势 */}
        <Col xs={24} lg={14}>
          <Card variant="borderless" title={<Space><BarChartOutlined style={{ color: '#F5A623' }} /><span style={{ fontWeight: 700 }}>近7日收入趋势</span></Space>}
                style={{ borderRadius: 16, boxShadow: '0 2px 12px rgba(0,0,0,0.06)' }}>
            <ReactECharts option={incomeOption} style={{ height: 240 }} />
          </Card>
        </Col>
      </Row>
      </div>
    </div>
  )
}
