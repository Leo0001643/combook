/**
 * 薪资管理 — 员工工资 + 技师提成 月度结算
 */
import { useState, useRef } from 'react'
import {
  Table, Select, Button, Tag, Space, Typography, message,
  Row, Col, Drawer, Statistic,
  Avatar, Badge, Divider,
} from 'antd'
import {
  TeamOutlined, DollarOutlined, CheckCircleOutlined,
  UserOutlined, SettingOutlined, BarChartOutlined, TrophyOutlined,
  // PlusOutlined unused currently
} from '@ant-design/icons'
import dayjs from 'dayjs'
import type { ColumnsType } from 'antd/es/table'
import { col, styledTableComponents } from '../../components/common/tableComponents'
import PagePagination from '../../components/common/PagePagination'
import { useTableBodyHeight } from '../../hooks/useTableBodyHeight'
import { useDict, parseRemark } from '../../hooks/useDict'

const { Text, Title } = Typography
const { Option } = Select

const STAFF_TYPES_FB: Record<number, { label: string; color: string }> = {
  1: { label: '员工',   color: '#6366f1' },
  2: { label: '技师',   color: '#F5A623' },
}

const PAY_STATUS_FB: Record<number, { text: string; color: string; badge: any }> = {
  0: { text: '待发放', color: '#f59e0b', badge: 'warning' },
  1: { text: '已发放', color: '#10b981', badge: 'success' },
  2: { text: '已作废', color: '#94a3b8', badge: 'default' },
}

function mockSalaries(month: string) {
  return [
    { id: 1, staffName: '陈秀玲', staffType: 2, avatar: null, baseSalary: 0,    commission: 3240, bonus: 500, deduction: 0,  totalAmount: 3740, orderCount: 72,  orderRevenue: 6480,  payMethod: 3, status: 0, salaryMonth: month },
    { id: 2, staffName: '蔡庆',   staffType: 2, avatar: null, baseSalary: 0,    commission: 2875, bonus: 300, deduction: 0,  totalAmount: 3175, orderCount: 65,  orderRevenue: 5750,  payMethod: 3, status: 0, salaryMonth: month },
    { id: 3, staffName: '阿丽达', staffType: 2, avatar: null, baseSalary: 0,    commission: 2450, bonus: 200, deduction: 50, totalAmount: 2600, orderCount: 55,  orderRevenue: 4900,  payMethod: 1, status: 1, salaryMonth: month },
    { id: 4, staffName: '李经理', staffType: 1, avatar: null, baseSalary: 1500, commission: 0,    bonus: 300, deduction: 0,  totalAmount: 1800, orderCount: 0,   orderRevenue: 0,     payMethod: 4, status: 1, salaryMonth: month },
    { id: 5, staffName: '王前台', staffType: 1, avatar: null, baseSalary: 800,  commission: 0,    bonus: 100, deduction: 0,  totalAmount: 900,  orderCount: 0,   orderRevenue: 0,     payMethod: 4, status: 0, salaryMonth: month },
    { id: 6, staffName: '张司机', staffType: 1, avatar: null, baseSalary: 1200, commission: 0,    bonus: 0,   deduction: 0,  totalAmount: 1200, orderCount: 0,   orderRevenue: 0,     payMethod: 4, status: 0, salaryMonth: month },
  ]
}

export default function SalaryManagePage() {
  const { ref, height: tableBodyH } = useTableBodyHeight(46)
  const [month,     setMonth]     = useState(dayjs().format('YYYY-MM'))
  const [staffType, setStaffType] = useState<number | undefined>()

  const { items: staffTypeItems } = useDict('staff_type')
  const { items: payStatusItems } = useDict('salary_status')

  const STAFF_TYPES: Record<number, { label: string; color: string }> =
    staffTypeItems.length > 0
      ? Object.fromEntries(staffTypeItems.map(i => [Number(i.dictValue), { label: i.labelZh, color: i.remark ?? '#6366f1' }]))
      : STAFF_TYPES_FB

  const PAY_STATUS: Record<number, { text: string; color: string; badge: any }> =
    payStatusItems.length > 0
      ? Object.fromEntries(payStatusItems.map(i => {
          const b = ({ orange:'warning', green:'success', red:'error' }[i.remark ?? ''] ?? 'default')
          const hex = i.remark?.startsWith('#') ? i.remark : ({ orange:'#f59e0b', green:'#10b981', red:'#ef4444' }[i.remark ?? ''] ?? '#94a3b8')
          return [Number(i.dictValue), { text: i.labelZh, color: hex, badge: b }]
        }))
      : PAY_STATUS_FB

  // Master data store — persists across filter changes
  const masterRef = useRef<any[]>(mockSalaries(dayjs().format('YYYY-MM')))

  // Derived view — recalculated on every render (forceUpdate triggers re-render on data changes)
  const records = masterRef.current.filter(r => staffType === undefined || r.staffType === staffType)

  const total = records.length

  const [detailOpen, setDetailOpen] = useState(false)
  const [detail,     setDetail]     = useState<any>(null)
  const [payLoading, setPayLoading] = useState<number | null>(null)
  const [, forceUpdate]             = useState(0)

  const totalSalary     = records.reduce((s, r) => s + r.totalAmount, 0)
  const pendingCount    = records.filter(r => r.status === 0).length
  const pendingAmount   = records.filter(r => r.status === 0).reduce((s, r) => s + r.totalAmount, 0)
  const completedAmount = records.filter(r => r.status === 1).reduce((s, r) => s + r.totalAmount, 0)

  const handleMonthChange = (newMonth: string) => {
    setMonth(newMonth)
    masterRef.current = mockSalaries(newMonth)
    forceUpdate(n => n + 1)
  }

  const handlePay = async (id: number) => {
    setPayLoading(id)
    try {
      await new Promise(r => setTimeout(r, 600))
      masterRef.current = masterRef.current.map(r => r.id === id ? { ...r, status: 1 } : r)
      forceUpdate(n => n + 1)
      message.success('薪资已发放！')
    } finally { setPayLoading(null) }
  }

  const handleBatchPay = () => {
    const pendingIds = records.filter(r => r.status === 0).map(r => r.id)
    masterRef.current = masterRef.current.map(r => pendingIds.includes(r.id) ? { ...r, status: 1 } : r)
    forceUpdate(n => n + 1)
    message.success(`已批量发放 ${pendingIds.length} 条薪资！`)
  }

  const columns: ColumnsType<any> = [
    {
      title: col(<UserOutlined style={{ color: '#64748b' }} />, '姓名 / 类型', 'left'), key: 'staff', width: 160, align: 'left',
      render: (_, r) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <Avatar size={36} icon={<UserOutlined />} style={{ background: STAFF_TYPES[r.staffType]?.color, flexShrink: 0 }} />
          <div>
            <div style={{ fontWeight: 700, color: '#111827' }}>{r.staffName}</div>
            <Tag color={STAFF_TYPES[r.staffType]?.color} style={{ borderRadius: 6, border: 'none', fontWeight: 600, fontSize: 10 }}>{STAFF_TYPES[r.staffType]?.label}</Tag>
          </div>
        </div>
      ),
    },
    {
      title: col(<DollarOutlined style={{ color: '#64748b' }} />, '基本工资', 'center'), dataIndex: 'baseSalary', width: 100, align: 'center',
      render: v => <span style={{ fontWeight: 600 }}>{v > 0 ? `$${v}` : '—'}</span>,
    },
    {
      title: col(<TrophyOutlined style={{ color: '#64748b' }} />, '提成', 'center'), key: 'commission', width: 110, align: 'center',
      render: (_, r) => (
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontWeight: 700, color: '#F5A623' }}>{r.commission > 0 ? `$${r.commission}` : '—'}</div>
          {r.orderCount > 0 && <div style={{ fontSize: 10, color: '#9ca3af' }}>{r.orderCount} 单 · ${r.orderRevenue}</div>}
        </div>
      ),
    },
    { title: col(null, '奖金', 'center'), dataIndex: 'bonus', width: 80, align: 'center', render: v => v > 0 ? <span style={{ color: '#10b981', fontWeight: 600 }}>+${v}</span> : '—' },
    { title: col(null, '扣款', 'center'), dataIndex: 'deduction', width: 80, align: 'center', render: v => v > 0 ? <span style={{ color: '#f43f5e', fontWeight: 600 }}>-${v}</span> : '—' },
    {
      title: col(<DollarOutlined style={{ color: '#64748b' }} />, '实发工资', 'center'), dataIndex: 'totalAmount', width: 110, align: 'center',
      render: v => <span style={{ fontSize: 16, fontWeight: 900, color: '#6366f1' }}>${v.toLocaleString()}</span>,
    },
    {
      title: col(<SettingOutlined style={{ color: '#64748b' }} />, '状态', 'center'), dataIndex: 'status', width: 90, align: 'center',
      render: s => <Badge status={PAY_STATUS[s]?.badge} text={<span style={{ fontWeight: 600, color: PAY_STATUS[s]?.color }}>{PAY_STATUS[s]?.text}</span>} />,
    },
    {
      title: col(<SettingOutlined style={{ color: '#64748b' }} />, '操作'), key: 'action', fixed: 'right', width: 150,
      render: (_, r) => (
        <Space size={4} style={{ flexWrap: 'nowrap' }}>
          <Button size="small" type="primary" ghost icon={<BarChartOutlined />}
            style={{ borderRadius: 6, fontSize: 12 }}
            onClick={() => { setDetail(r); setDetailOpen(true) }}>明细</Button>
          {r.status === 0 && (
            <Button size="small" icon={<CheckCircleOutlined />}
              style={{ borderRadius: 6, fontSize: 12, color: '#10b981', borderColor: '#6ee7b7' }}
              loading={payLoading === r.id}
              onClick={() => handlePay(r.id)}>发放</Button>
          )}
        </Space>
      ),
    },
  ]

  // Monthly picker options
  const monthOptions = Array.from({ length: 12 }, (_, i) => dayjs().subtract(i, 'month').format('YYYY-MM'))

  const salaryStats = [
    { label: '本月总薪资', value: `$${totalSalary.toLocaleString()}`,                   icon: <DollarOutlined />,       color: '#3b82f6', bg: '#eff6ff', border: '#bfdbfe' },
    { label: '待发放',     value: `$${pendingAmount.toLocaleString()}(${pendingCount}人)`, icon: <BarChartOutlined />,    color: '#f59e0b', bg: '#fffbeb', border: '#fde68a' },
    { label: '已发放',     value: `$${completedAmount.toLocaleString()}`,                 icon: <CheckCircleOutlined />, color: '#10b981', bg: '#ecfdf5', border: '#a7f3d0' },
    { label: '人员总数',   value: `${records.length} 人`,                                 icon: <TeamOutlined />,        color: '#8b5cf6', bg: '#f5f3ff', border: '#ddd6fe' },
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
        <div style={{ display: 'flex', alignItems: 'center', padding: '10px 24px 0', gap: 16, flexWrap: 'wrap' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, flex: '0 0 auto' }}>
            <div style={{
              width: 34, height: 34, borderRadius: 10,
              background: 'linear-gradient(135deg,#1d6fb0,#38bdf8)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: '0 4px 12px rgba(29,111,176,0.35)', flexShrink: 0,
            }}>
              <TeamOutlined style={{ color: '#fff', fontSize: 16 }} />
            </div>
            <div>
              <div style={{ fontWeight: 700, fontSize: 15, color: '#111827', lineHeight: 1.2 }}>薪资管理</div>
              <div style={{ fontSize: 11, color: '#9ca3af', lineHeight: 1.3, marginTop: 1 }}>员工工资 · 技师提成 · 月度结算</div>
            </div>
          </div>
          <div style={{ width: 1, height: 28, margin: '0 4px', background: '#e5e7eb', flexShrink: 0 }} />
          <div style={{ display: 'flex', gap: 8, flex: 1, flexWrap: 'wrap', alignItems: 'center' }}>
            {salaryStats.map(s => (
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
          {pendingCount > 0 && (
            <Button type="primary" icon={<CheckCircleOutlined />}
              style={{
                flexShrink: 0, borderRadius: 8, border: 'none',
                background: 'linear-gradient(135deg,#10b981,#34d399)',
                boxShadow: '0 2px 8px rgba(16,185,129,0.35)',
              }}
              onClick={handleBatchPay}>一键发放 ({pendingCount})</Button>
          )}
        </div>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', padding: '10px 24px 12px' }}>
          <Select value={month} onChange={handleMonthChange} style={{ width: 130, borderRadius: 8 }}>
            {monthOptions.map(m => <Option key={m} value={m}>{m}</Option>)}
          </Select>
          <Select placeholder="人员类型" value={staffType} onChange={setStaffType} allowClear style={{ width: 120 }}>
            {Object.entries(STAFF_TYPES).map(([k, v]) => <Option key={k} value={+k}>{v.label}</Option>)}
          </Select>
        </div>
      </div>

      {/* ── 数据表格 ────────────────────────────────────────────────────── */}
      <div ref={ref} style={{
        marginLeft: -24, marginRight: -24, marginBottom: -24,
        background: '#fff', borderTop: '1px solid #eef0f8',
      }}>
        <Table dataSource={records} columns={columns} components={styledTableComponents}
          rowKey="id" size="middle" scroll={{ x: 900, y: tableBodyH }} pagination={false} />
        <PagePagination total={total} current={1} pageSize={pageSize} onChange={() => {}} style={{ opacity: 0.5, pointerEvents: 'none' }} />
      </div>

      <Drawer title={`薪资明细 · ${detail?.staffName} · ${detail?.salaryMonth}`}
        open={detailOpen} onClose={() => setDetailOpen(false)} styles={{ wrapper: { width: 680 } }}>
        {detail && (
          <>
            <div style={{ textAlign: 'center', marginBottom: 24 }}>
              <Avatar size={64} icon={<UserOutlined />} style={{ background: STAFF_TYPES[detail.staffType]?.color, marginBottom: 8 }} />
              <div style={{ fontWeight: 800, fontSize: 18 }}>{detail.staffName}</div>
              <Tag color={STAFF_TYPES[detail.staffType]?.color} style={{ borderRadius: 8, border: 'none', fontWeight: 600 }}>{STAFF_TYPES[detail.staffType]?.label}</Tag>
              <Badge status={PAY_STATUS[detail.status]?.badge} text={
                <span style={{ color: PAY_STATUS[detail.status]?.color, fontWeight: 700, marginLeft: 8 }}>{PAY_STATUS[detail.status]?.text}</span>
              } />
            </div>

            <div style={{ background: 'linear-gradient(135deg,#eef2ff,#e0e7ff)', borderRadius: 14, padding: '20px', textAlign: 'center', marginBottom: 20 }}>
              <div style={{ fontSize: 12, color: '#6b7280', fontWeight: 600 }}>实发工资</div>
              <div style={{ fontSize: 36, fontWeight: 900, color: '#6366f1' }}>${detail.totalAmount.toLocaleString()}</div>
            </div>

            <Row gutter={12} style={{ marginBottom: 16 }}>
              <Col span={12}><Statistic title="基本工资" value={`$${detail.baseSalary}`} valueStyle={{ color: '#374151', fontWeight: 700 }} /></Col>
              <Col span={12}><Statistic title="提成" value={`$${detail.commission}`} valueStyle={{ color: '#F5A623', fontWeight: 700 }} /></Col>
              <Col span={12} style={{ marginTop: 12 }}><Statistic title="奖金" value={`$${detail.bonus}`} valueStyle={{ color: '#10b981', fontWeight: 700 }} /></Col>
              <Col span={12} style={{ marginTop: 12 }}><Statistic title="扣款" value={detail.deduction > 0 ? `-$${detail.deduction}` : '$0'} valueStyle={{ color: detail.deduction > 0 ? '#f43f5e' : '#94a3b8', fontWeight: 700 }} /></Col>
            </Row>

            {detail.staffType === 2 && (
              <>
                <Divider />
                <Row gutter={12}>
                  <Col span={12}><Statistic title="完成订单" value={`${detail.orderCount} 单`} valueStyle={{ color: '#6366f1', fontWeight: 700 }} /></Col>
                  <Col span={12}><Statistic title="服务营收" value={`$${detail.orderRevenue}`} valueStyle={{ color: '#F5A623', fontWeight: 700 }} /></Col>
                </Row>
              </>
            )}

            {detail.status === 0 && (
              <>
                <Divider />
                <Button block type="primary" icon={<CheckCircleOutlined />}
                  style={{ background: 'linear-gradient(135deg,#6366f1,#4f46e5)', border: 'none', borderRadius: 10, height: 44, fontWeight: 700 }}
                  onClick={() => { handlePay(detail.id); setDetailOpen(false) }}>
                  确认发放薪资
                </Button>
              </>
            )}
          </>
        )}
      </Drawer>
    </div>
  )
}

const pageSize = 20
