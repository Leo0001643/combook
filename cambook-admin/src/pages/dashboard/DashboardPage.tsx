import { useState, useEffect } from 'react'
import {
  Row, Col, Card, Typography, Space, Table, Tag, Avatar, Progress, Spin, Divider,
} from 'antd'
import {
  UserOutlined, TeamOutlined, ShoppingCartOutlined, DollarOutlined,
  RiseOutlined, ArrowUpOutlined, ArrowDownOutlined, FireOutlined,
  StarOutlined, ShopOutlined, BarChartOutlined,
} from '@ant-design/icons'
import ReactECharts from 'echarts-for-react'
import dayjs from 'dayjs'
import { usePortalScope } from '../../hooks/usePortalScope'
import { useAuthStore } from '../../store/authStore'
const { Text } = Typography

function mockWeekTrend() {
  const days = Array.from({ length: 7 }, (_, i) =>
    dayjs().subtract(6 - i, 'day').format('MM/DD')
  )
  return {
    days,
    orders:  [32, 45, 38, 62, 55, 78, 91],
    revenue: [1200, 1800, 1500, 2400, 2100, 3100, 3650],
  }
}

export default function DashboardPage() {
  const { isAdmin, dashboardStats } = usePortalScope()
  const { merchant } = useAuthStore()
  const [trend] = useState(mockWeekTrend)
  const [merchantData, setMerchantData] = useState<any>(null)
  const [merchantLoading, setMerchantLoading] = useState(false)
  const [recentOrders] = useState<any[]>([])

  // 商户模式：拉取真实数据
  useEffect(() => {
    if (!isAdmin) {
      setMerchantLoading(true)
      dashboardStats()
        .then(r => setMerchantData(r.data?.data))
        .finally(() => setMerchantLoading(false))
    }
  }, [isAdmin])

  // 商户看板统计卡片
  const merchantStats = [
    { title: '累计订单数', value: merchantData?.totalOrders ?? 0,    suffix: '单', color: '#F5A623', icon: <ShoppingCartOutlined />, bg: 'linear-gradient(135deg,#fff8e6,#fff)', trend: +5.2 },
    { title: '旗下技师数', value: merchantData?.technicianCount ?? 0, suffix: '人', color: '#6366f1', icon: <TeamOutlined />,          bg: 'linear-gradient(135deg,#eef2ff,#fff)', trend: +2.0 },
    { title: '今日新增',   value: merchantData?.todayOrders ?? 0,     suffix: '单', color: '#10b981', icon: <RiseOutlined />,          bg: 'linear-gradient(135deg,#ecfdf5,#fff)', trend: +8.0 },
    { title: '账户余额',   value: `$${Number(merchantData?.balance ?? 0).toFixed(0)}`, suffix: '', color: '#f43f5e', icon: <DollarOutlined />, bg: 'linear-gradient(135deg,#fff1f2,#fff)', trend: +3.5 },
  ]

  // 管理员看板统计卡片（模拟数据）
  const stats = isAdmin ? [
    { title: '今日新增会员', value: 128, suffix: '人',   color: '#F5A623',  icon: <UserOutlined />,         bg: 'linear-gradient(135deg,#fff8e6,#fff)', trend: +12.5 },
    { title: '今日订单数',   value: 356, suffix: '单',   color: '#6366f1',  icon: <ShoppingCartOutlined />, bg: 'linear-gradient(135deg,#eef2ff,#fff)', trend: +8.3 },
    { title: '今日交易额',   value: '3,650', suffix: 'USD', color: '#10b981', icon: <DollarOutlined />,    bg: 'linear-gradient(135deg,#ecfdf5,#fff)', trend: +15.2 },
    { title: '在线技师数',   value: 89,  suffix: '人',   color: '#f43f5e',  icon: <TeamOutlined />,         bg: 'linear-gradient(135deg,#fff1f2,#fff)', trend: -3.1 },
  ] : merchantStats

  const adminRecentOrders = [
    { key: '1', orderNo: 'CB20260413001', user: '李**', technician: '陈秀玲', service: '全身推拿 60min', amount: '$45.00', status: 3, time: '14:32' },
    { key: '2', orderNo: 'CB20260413002', user: '王**', technician: '蔡庆',   service: '精油SPA 90min', amount: '$88.00', status: 4, time: '13:55' },
    { key: '3', orderNo: 'CB20260413003', user: '张**', technician: '阿丽达', service: '足疗足浴 45min', amount: '$30.00', status: 2, time: '13:20' },
    { key: '4', orderNo: 'CB20260413004', user: '刘**', technician: '任菁',   service: '头颈肩理疗 60min', amount: '$50.00', status: 1, time: '12:48' },
    { key: '5', orderNo: 'CB20260413005', user: '陈**', technician: '李洋',   service: '中式推拿 90min', amount: '$65.00', status: 5, time: '11:15' },
  ]
  const displayOrders = isAdmin ? adminRecentOrders : recentOrders

  const STATUS_MAP: Record<number, { color: string; text: string }> = {
    0: { color: 'gold',    text: '待支付' },
    1: { color: 'blue',    text: '待接单' },
    2: { color: 'cyan',    text: '已接单' },
    3: { color: 'orange',  text: '服务中' },
    4: { color: 'green',   text: '已完成' },
    5: { color: 'default', text: '已取消' },
  }

  const orderColumns = [
    {
      title: '订单号',
      dataIndex: 'orderNo',
      render: (v: string) => <Text code style={{ fontSize: 11 }}>{v}</Text>,
    },
    {
      title: '用户',
      dataIndex: 'user',
    },
    {
      title: '技师',
      dataIndex: 'technician',
      render: (v: string) => (
        <Space>
          <Avatar size={22} style={{ background: '#F5A623', fontSize: 11 }}>{v[0]}</Avatar>
          {v}
        </Space>
      ),
    },
    {
      title: '服务',
      dataIndex: 'service',
      ellipsis: true,
    },
    {
      title: '金额',
      dataIndex: 'amount',
      render: (v: string) => <Text strong style={{ color: '#F5A623' }}>{v}</Text>,
    },
    {
      title: '状态',
      dataIndex: 'status',
      render: (v: number) => <Tag color={STATUS_MAP[v]?.color}>{STATUS_MAP[v]?.text}</Tag>,
    },
    {
      title: '时间',
      dataIndex: 'time',
      render: (v: string) => <Text type="secondary">{v}</Text>,
    },
  ]

  const hotServices = [
    { name: '全身推拿', count: 1280, percent: 85, color: '#F5A623' },
    { name: '精油SPA',  count: 980,  percent: 65, color: '#6366f1' },
    { name: '足疗足浴', count: 760,  percent: 51, color: '#10b981' },
    { name: '头颈肩理疗', count: 540, percent: 36, color: '#f43f5e' },
    { name: '中式推拿', count: 420,  percent: 28, color: '#f59e0b' },
  ]

  const trendOption = {
    tooltip: { trigger: 'axis', axisPointer: { type: 'cross' } },
    legend: { data: ['订单数', '交易额(USD)'], top: 0, right: 0 },
    grid: { top: 30, right: 60, bottom: 20, left: 50 },
    xAxis: { type: 'category', data: trend.days, axisLine: { lineStyle: { color: '#e5e7eb' } } },
    yAxis: [
      { type: 'value', name: '订单',    axisLabel: { color: '#9ca3af' } },
      { type: 'value', name: 'USD',     axisLabel: { color: '#9ca3af' }, position: 'right' },
    ],
    series: [
      {
        name: '订单数',
        type: 'bar',
        data: trend.orders,
        barWidth: 18,
        itemStyle: { color: { type: 'linear', x: 0, y: 0, x2: 0, y2: 1, colorStops: [{ offset: 0, color: '#F5A623' }, { offset: 1, color: '#F97316' }] }, borderRadius: [4, 4, 0, 0] },
      },
      {
        name: '交易额(USD)',
        type: 'line',
        yAxisIndex: 1,
        data: trend.revenue,
        smooth: true,
        symbol: 'circle',
        symbolSize: 6,
        lineStyle: { color: '#6366f1'},
        itemStyle: { color: '#6366f1' },
        areaStyle: { color: { type: 'linear', x: 0, y: 0, x2: 0, y2: 1, colorStops: [{ offset: 0, color: 'rgba(99,102,241,0.2)' }, { offset: 1, color: 'rgba(99,102,241,0)' }] } },
      },
    ],
  }

  const pieOption = {
    tooltip: { trigger: 'item' },
    legend: { orient: 'vertical', left: 'right', top: 'center' },
    series: [{
      type: 'pie',
      radius: ['50%', '75%'],
      center: ['35%', '50%'],
      data: hotServices.map(s => ({ value: s.count, name: s.name })),
      itemStyle: { borderRadius: 6, borderWidth: 2, borderColor: '#fff' },
      label: { show: false },
      color: hotServices.map(s => s.color),
    }],
  }

  if (!isAdmin && merchantLoading) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: 400 }}>
        <Spin size="large" />
      </div>
    )
  }

  return (
    <div style={{ marginTop: -24, height: 'calc(100vh - 64px)', display: 'flex', flexDirection: 'column' }}>
      <div style={{ position: 'sticky', top: 64, zIndex: 88, marginLeft: -24, marginRight: -24, background: 'rgba(255,255,255,0.97)', backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)', borderBottom: '1px solid rgba(0,0,0,0.07)', boxShadow: '0 4px 20px rgba(0,0,0,0.06)' }}>
        <div style={{ display: 'flex', alignItems: 'center', padding: '10px 24px 12px', gap: 12 }}>
          <div style={{ width: 34, height: 34, borderRadius: 10, background: isAdmin ? 'linear-gradient(135deg,#6366f1,#8b5cf6)' : 'linear-gradient(135deg,#10b981,#059669)', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 4px 12px rgba(99,102,241,0.3)', flexShrink: 0 }}>
            {isAdmin ? <BarChartOutlined style={{ color: '#fff', fontSize: 16 }} /> : <ShopOutlined style={{ color: '#fff', fontSize: 16 }} />}
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1e293b', lineHeight: 1.2 }}>
              {isAdmin ? '管理驾驶舱' : (merchant?.merchantNameZh || merchant?.merchantName || '商户驾驶舱')}
            </div>
            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>
              {isAdmin ? '平台核心数据 · 实时运营概览' : '商户运营数据 · 今日概览'}
            </div>
          </div>
          <Divider type="vertical" style={{ height: 20, margin: '0 4px', borderColor: '#e0e4ff' }} />
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            {(isAdmin
              ? [
                  { label: '今日订单', value: 356, color: '#6366f1', bg: 'rgba(99,102,241,0.1)', border: 'rgba(99,102,241,0.25)', icon: '📦' },
                  { label: '在线技师', value: 89, color: '#10b981', bg: 'rgba(16,185,129,0.1)', border: 'rgba(16,185,129,0.25)', icon: '🟢' },
                  { label: '今日收入', value: '$3,650', color: '#f59e0b', bg: 'rgba(245,158,11,0.1)', border: 'rgba(245,158,11,0.25)', icon: '💰' },
                ]
              : [
                  { label: '累计订单', value: merchantData?.totalOrders ?? 0, color: '#6366f1', bg: 'rgba(99,102,241,0.1)', border: 'rgba(99,102,241,0.25)', icon: '📦' },
                  { label: '旗下技师', value: merchantData?.technicianCount ?? 0, color: '#10b981', bg: 'rgba(16,185,129,0.1)', border: 'rgba(16,185,129,0.25)', icon: '👥' },
                  { label: '账户余额', value: `$${Number(merchantData?.balance ?? 0).toFixed(0)}`, color: '#f59e0b', bg: 'rgba(245,158,11,0.1)', border: 'rgba(245,158,11,0.25)', icon: '💰' },
                ]
            ).map((s, i) => (
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
      {/* 核心指标卡片 */}
      <Row gutter={[16, 16]} style={{ marginBottom: 20 }}>
        {stats.map((stat, index) => (
          <Col xs={24} sm={12} lg={6} key={index}>
            <Card
              className="stat-card"
              style={{ borderRadius: 14, border: 'none', background: stat.bg, boxShadow: '0 2px 14px rgba(0,0,0,0.07)' }}
              styles={{ body: { padding: '20px 24px' } }}
            >
              <Space style={{ width: '100%', justifyContent: 'space-between' }}>
                <div>
                  <Text type="secondary" style={{ fontSize: 12 }}>{stat.title}</Text>
                  <div style={{ marginTop: 8, display: 'flex', alignItems: 'baseline', gap: 4 }}>
                    <span style={{ fontSize: 28, fontWeight: 800, color: stat.color, lineHeight: 1 }}>
                      {stat.value}
                    </span>
                    <Text type="secondary" style={{ fontSize: 12 }}>{stat.suffix}</Text>
                  </div>
                  <div style={{ marginTop: 8 }}>
                    {stat.trend > 0
                      ? <Text style={{ color: '#10b981', fontSize: 12 }}><ArrowUpOutlined /> {stat.trend}% 较昨日</Text>
                      : <Text style={{ color: '#f43f5e', fontSize: 12 }}><ArrowDownOutlined /> {Math.abs(stat.trend)}% 较昨日</Text>
                    }
                  </div>
                </div>
                <div style={{
                  width: 52, height: 52, borderRadius: 14,
                  background: stat.color + '18',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 22, color: stat.color,
                }}>
                  {stat.icon}
                </div>
              </Space>
            </Card>
          </Col>
        ))}
      </Row>

      {/* 趋势图 + 服务排行 */}
      <Row gutter={[16, 16]} style={{ marginBottom: 16 }}>
        <Col xs={24} xl={16}>
          <Card
            title={<Space><RiseOutlined style={{ color: '#F5A623' }} /><span>近 7 天订单趋势</span></Space>}
            style={{ borderRadius: 14, border: 'none', boxShadow: '0 2px 14px rgba(0,0,0,0.06)' }}
          >
            <ReactECharts option={trendOption} style={{ height: 280 }} />
          </Card>
        </Col>
        <Col xs={24} xl={8}>
          <Card
            title={<Space><FireOutlined style={{ color: '#F5A623' }} /><span>服务类型分布</span></Space>}
            style={{ borderRadius: 14, border: 'none', boxShadow: '0 2px 14px rgba(0,0,0,0.06)', height: '100%' }}
          >
            <ReactECharts option={pieOption} style={{ height: 280 }} />
          </Card>
        </Col>
      </Row>

      {/* 最新订单 + 热门服务 */}
      <Row gutter={[16, 16]}>
        <Col xs={24} xl={16}>
          <Card
            title={<Space><ShoppingCartOutlined style={{ color: '#F5A623' }} /><span>最新订单</span></Space>}
            extra={<Text type="secondary" style={{ fontSize: 13, cursor: 'pointer' }}>查看全部 →</Text>}
            style={{ borderRadius: 14, border: 'none', boxShadow: '0 2px 14px rgba(0,0,0,0.06)' }}
          >
            <Table
              dataSource={displayOrders}
              columns={orderColumns}
              pagination={false}
              size="small"
              rowKey="key"
            />
          </Card>
        </Col>

        <Col xs={24} xl={8}>
          <Card
            title={<Space><StarOutlined style={{ color: '#F5A623' }} /><span>热门服务排行</span></Space>}
            style={{ borderRadius: 14, border: 'none', boxShadow: '0 2px 14px rgba(0,0,0,0.06)' }}
          >
            <Space orientation="vertical" style={{ width: '100%' }} size={16}>
              {hotServices.map((service, index) => (
                <div key={service.name}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
                    <Space>
                      <div style={{
                        width: 22, height: 22, borderRadius: 6,
                        background: index < 3 ? service.color : '#e5e7eb',
                        color: index < 3 ? '#fff' : '#9ca3af',
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                        fontSize: 11, fontWeight: 700,
                      }}>{index + 1}</div>
                      <Text style={{ fontSize: 13 }}>{service.name}</Text>
                    </Space>
                    <Text type="secondary" style={{ fontSize: 12 }}>{service.count.toLocaleString()} 单</Text>
                  </div>
                  <Progress
                    percent={service.percent}
                    showInfo={false}
                    strokeColor={service.color}
                    trailColor="#f3f4f6"
                    size={['100%', 6] as any}
                    strokeLinecap="round"
                  />
                </div>
              ))}
            </Space>
          </Card>
        </Col>
      </Row>
      </div>
    </div>
  )
}
