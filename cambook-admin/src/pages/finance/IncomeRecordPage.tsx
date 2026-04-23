/**
 * 收入记录 — 客户支付流水、结算详情
 */
import React, { useState, useCallback } from 'react'
import {
  Table, Input, Select, Button, Tag, Typography, Space,
  Drawer, Descriptions,
} from 'antd'
import {
  SearchOutlined, ReloadOutlined, SettingOutlined,
  DollarOutlined, ShoppingCartOutlined, RiseOutlined, FileTextOutlined, WalletOutlined,
  UserOutlined, IdcardOutlined,
} from '@ant-design/icons'
import { fmtTime } from '../../utils/time'
import type { ColumnsType } from 'antd/es/table'
import { col, styledTableComponents, INPUT_STYLE } from '../../components/common/tableComponents'
import PagePagination from '../../components/common/PagePagination'
import { useTableBodyHeight } from '../../hooks/useTableBodyHeight'
import { useDict } from '../../hooks/useDict'
import DateTimeRangePicker from '../../components/common/DateTimeRangePicker'

const { Text } = Typography
const { Option } = Select

const PAY_METHODS_FB: Record<number, { label: string; color: string; icon: React.ReactNode }> = {
  1: { label: '现金',     color: '#10b981', icon: '💵' },
  2: { label: '微信',     color: '#07C160', icon: <span style={{ display:'inline-flex',alignItems:'center',justifyContent:'center',width:16,height:16,background:'#07C160',borderRadius:3,fontSize:10,color:'#fff',fontWeight:900,verticalAlign:'middle',lineHeight:'16px' }}>W</span> },
  3: { label: '支付宝',   color: '#1677FF', icon: <span style={{ display:'inline-flex',alignItems:'center',justifyContent:'center',width:16,height:16,background:'#1677FF',borderRadius:3,fontSize:10,color:'#fff',fontWeight:900,verticalAlign:'middle',lineHeight:'16px',fontStyle:'italic' }}>a</span> },
  4: { label: '银行',     color: '#6366f1', icon: '🏦' },
  5: { label: 'USDT',    color: '#f59e0b', icon: '₮'  },
  8: { label: '其它',    color: '#94a3b8', icon: '💳' },
}

const INCOME_TYPES_FB: Record<number, { label: string; color: string }> = {
  1: { label: '订单收入', color: '#6366f1' },
  2: { label: '散客结算', color: '#F5A623' },
  3: { label: '会员充值', color: '#10b981' },
  4: { label: '其它收入', color: '#94a3b8' },
}

function mockIncome() {
  return [
    { id: 1, referenceNo: 'PMT20260413001', incomeType: 1, orderNo: 'OD20260413001001', payMethod: 1, amount: 88.00, currency: 'USD', memberName: '李先生', technicianName: '陈秀玲', payTime: '2026-04-13 14:35:00', remark: '' },
    { id: 2, referenceNo: 'PMT20260413002', incomeType: 2, orderNo: 'WK20260413003',    payMethod: 5, amount: 320.00, currency: 'USD', memberName: '散客', technicianName: '阿丽达', payTime: '2026-04-13 14:20:00', remark: 'USDT 到账' },
    { id: 3, referenceNo: 'PMT20260413003', incomeType: 1, orderNo: 'OD20260413002001', payMethod: 2, amount: 45.00, currency: 'USD', memberName: '王女士', technicianName: '蔡庆', payTime: '2026-04-13 13:55:00', remark: '' },
    { id: 4, referenceNo: 'PMT20260413004', incomeType: 3, orderNo: '',                 payMethod: 4, amount: 2000.00, currency: 'USD', memberName: '张先生', technicianName: '', payTime: '2026-04-13 13:00:00', remark: '会员卡充值' },
    { id: 5, referenceNo: 'PMT20260413005', incomeType: 1, orderNo: 'OD20260413003001', payMethod: 1, amount: 120.00, currency: 'USD', memberName: '陈女士', technicianName: '任菁', payTime: '2026-04-13 12:30:00', remark: '' },
    { id: 6, referenceNo: 'PMT20260413006', incomeType: 2, orderNo: 'WK20260413002',    payMethod: 3, amount: 188.00, currency: 'USD', memberName: '散客', technicianName: '蔡庆', payTime: '2026-04-13 11:45:00', remark: '' },
  ]
}

export default function IncomeRecordPage() {
  const { ref, height: tableBodyH } = useTableBodyHeight(46)
  const [records, setRecords] = useState<any[]>(mockIncome())
  const [keyword, setKeyword] = useState('')
  const [payMethod, setPayMethod] = useState<number | undefined>()
  const [incomeType, setIncomeType] = useState<number | undefined>()

  const { items: payItems }        = useDict('walkin_pay_type')
  const { items: incomeTypeItems } = useDict('income_type')

  const PAY_METHODS: Record<number, { label: string; color: string; icon: React.ReactNode }> =
    payItems.length > 0
      ? Object.fromEntries(payItems.map(i => [Number(i.dictValue), { label: i.labelZh, color: i.remark ?? '#94a3b8', icon: i.remark ?? '💳' }]))
      : PAY_METHODS_FB

  const INCOME_TYPES: Record<number, { label: string; color: string }> =
    incomeTypeItems.length > 0
      ? Object.fromEntries(incomeTypeItems.map(i => [Number(i.dictValue), { label: i.labelZh, color: i.remark ?? '#94a3b8' }]))
      : INCOME_TYPES_FB

  const [detailOpen, setDetailOpen] = useState(false)
  const [detail,     setDetail]     = useState<any>(null)

  const fetchList = useCallback(() => {
    setRecords(mockIncome().filter(r =>
      (!keyword || r.referenceNo.includes(keyword) || (r.memberName ?? '').includes(keyword)) &&
      (payMethod  === undefined || r.payMethod  === payMethod) &&
      (incomeType === undefined || r.incomeType === incomeType)
    ))
  }, [keyword, payMethod, incomeType])

  const totalAmount = records.reduce((s, r) => s + r.amount, 0)

  const columns: ColumnsType<any> = [
    { title: col(<DollarOutlined style={{ color: '#64748b' }} />, '支付流水', 'center'), dataIndex: 'referenceNo', width: 180, align: 'center', render: v => <Text style={{ fontFamily: 'monospace', fontSize: 11, color: '#6b7280' }}>{v}</Text> },
    {
      title: col(<ShoppingCartOutlined style={{ color: '#64748b' }} />, '收入类型', 'center'), key: 'type', width: 130, align: 'center',
      render: (_, r) => (
        <div style={{ textAlign: 'center' }}>
          <Tag color={INCOME_TYPES[r.incomeType]?.color} style={{ borderRadius: 8, fontWeight: 600, border: 'none' }}>{INCOME_TYPES[r.incomeType]?.label}</Tag>
          {r.orderNo && <div style={{ fontSize: 10, color: '#9ca3af', marginTop: 2 }}>{r.orderNo}</div>}
        </div>
      ),
    },
    { title: col(<UserOutlined style={{ color: '#64748b' }} />, '客户', 'center'), dataIndex: 'memberName', width: 90, align: 'center', render: v => <span style={{ fontWeight: 600 }}>{v}</span> },
    { title: col(<IdcardOutlined style={{ color: '#64748b' }} />, '技师', 'center'), dataIndex: 'technicianName', width: 90, align: 'center', render: v => v || '—' },
    {
      title: col(<WalletOutlined style={{ color: '#64748b' }} />, '支付方式', 'center'), dataIndex: 'payMethod', width: 110, align: 'center',
      render: v => {
        const m = PAY_METHODS[v]
        return m ? <span style={{ fontWeight: 600, display: 'inline-flex', alignItems: 'center', gap: 4 }}>{m.icon}{m.label}</span> : '—'
      },
    },
    {
      title: col(<DollarOutlined style={{ color: '#64748b' }} />, '收入金额', 'center'), dataIndex: 'amount', width: 120, align: 'center',
      render: v => <span style={{ fontSize: 16, fontWeight: 900, color: '#10b981' }}>${v.toFixed(2)}</span>,
    },
    {
      title: col(<RiseOutlined style={{ color: '#64748b' }} />, '收款时间', 'center'), dataIndex: 'payTime', width: 150, align: 'center',
      render: v => <Text style={{ fontSize: 12 }}>{fmtTime(v, 'MM-DD HH:mm')}</Text>,
    },
    {
      title: col(<SettingOutlined style={{ color: '#64748b' }} />, '操作', 'center'), key: 'action', fixed: 'right', width: 80, align: 'center',
      render: (_, r) => <Button size="small" type="primary" ghost style={{ borderRadius: 6, fontSize: 12 }} onClick={() => { setDetail(r); setDetailOpen(true) }}>详情</Button>,
    },
  ]

  const incomeStats = [
    { label: '今日笔数',   value: `${records.length} 笔`,       icon: <FileTextOutlined />,  color: '#6366f1', bg: '#eef2ff', border: '#c7d2fe' },
    { label: '今日合计',   value: `$${totalAmount.toFixed(2)}`, icon: <RiseOutlined />,      color: '#10b981', bg: '#ecfdf5', border: '#a7f3d0' },
    { label: '现金收入',   value: `$${records.filter(r => r.payMethod === 1).reduce((s, r) => s + r.amount, 0).toFixed(0)}`, icon: <DollarOutlined />, color: '#f59e0b', bg: '#fffbeb', border: '#fde68a' },
    { label: 'USDT收入',  value: `$${records.filter(r => r.payMethod === 5).reduce((s, r) => s + r.amount, 0).toFixed(0)}`, icon: <WalletOutlined />, color: '#3b82f6', bg: '#eff6ff', border: '#bfdbfe' },
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
              background: 'linear-gradient(135deg,#047857,#34d399)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: '0 4px 12px rgba(4,120,87,0.35)', flexShrink: 0,
            }}>
              <RiseOutlined style={{ color: '#fff', fontSize: 16 }} />
            </div>
            <div>
              <div style={{ fontWeight: 700, fontSize: 15, color: '#111827', lineHeight: 1.2 }}>收入记录</div>
              <div style={{ fontSize: 11, color: '#9ca3af', lineHeight: 1.3, marginTop: 1 }}>客户支付流水 · 多种支付方式汇总</div>
            </div>
          </div>
          <div style={{ width: 1, height: 28, margin: '0 4px', background: '#e5e7eb', flexShrink: 0 }} />
          <div style={{ display: 'flex', gap: 8, flex: 1, flexWrap: 'wrap', alignItems: 'center' }}>
            {incomeStats.map(s => (
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
        </div>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', padding: '10px 24px 12px' }}>
          <Input prefix={<SearchOutlined style={{ color: '#10b981', fontSize: 12 }} />}
            placeholder="流水号 / 客户名"
            value={keyword} onChange={e => { setKeyword(e.target.value); fetchList() }}
            style={{ ...INPUT_STYLE, width: 200 }}
            allowClear />
          <Select
            placeholder={<Space size={4}><RiseOutlined style={{ color: '#10b981', fontSize: 12 }} />收入类型</Space>}
            value={incomeType} onChange={v => { setIncomeType(v); fetchList() }} allowClear style={{ width: 130 }}>
            {Object.entries(INCOME_TYPES).map(([k, v]) => <Option key={k} value={+k}>{v.label}</Option>)}
          </Select>
          <Select
            placeholder={<Space size={4}><WalletOutlined style={{ color: '#6366f1', fontSize: 12 }} />支付方式</Space>}
            value={payMethod} onChange={v => { setPayMethod(v); fetchList() }} allowClear style={{ width: 130 }}>
            {Object.entries(PAY_METHODS).map(([k, v]) => <Option key={k} value={+k}>{v.icon} {v.label}</Option>)}
          </Select>
          <DateTimeRangePicker onChange={() => {}} style={{ width: 260 }} disabled />
          <div style={{ flex: 1 }} />
          <Button icon={<ReloadOutlined />} style={{ borderRadius: 8 }} onClick={fetchList}>刷新</Button>
        </div>
      </div>

      {/* ── 数据表格 ────────────────────────────────────────────────────── */}
      <div ref={ref} style={{
        marginLeft: -24, marginRight: -24, marginBottom: -24,
        background: '#fff', borderTop: '1px solid #eef0f8',
      }}>
        <Table dataSource={records} columns={columns} components={styledTableComponents}
          rowKey="id" size="middle" scroll={{ x: 900, y: tableBodyH }} pagination={false} />
        <PagePagination total={records.length} current={1} pageSize={20} onChange={() => {}} style={{ opacity: 0.5, pointerEvents: 'none' }} />
      </div>

      <Drawer title={`收入详情 · ${detail?.referenceNo}`} open={detailOpen} onClose={() => setDetailOpen(false)} styles={{ wrapper: { width: 660 } }}>
        {detail && (
          <>
            <div style={{ background: 'linear-gradient(135deg,#ecfdf5,#d1fae5)', borderRadius: 12, padding: '18px', textAlign: 'center', marginBottom: 20, border: '1px solid #6ee7b7' }}>
              <div style={{ fontSize: 11, color: '#065f46', fontWeight: 600 }}>收款金额</div>
              <div style={{ fontSize: 36, fontWeight: 900, color: '#10b981' }}>${detail.amount.toFixed(2)}</div>
              <Tag color={INCOME_TYPES[detail.incomeType]?.color} style={{ borderRadius: 8, border: 'none', fontWeight: 600, marginTop: 6 }}>{INCOME_TYPES[detail.incomeType]?.label}</Tag>
            </div>
            <Descriptions column={1} size="small" bordered>
              <Descriptions.Item label="流水号">{detail.referenceNo}</Descriptions.Item>
              {detail.orderNo && <Descriptions.Item label="关联单号">{detail.orderNo}</Descriptions.Item>}
              <Descriptions.Item label="客户">{detail.memberName}</Descriptions.Item>
              {detail.technicianName && <Descriptions.Item label="技师">{detail.technicianName}</Descriptions.Item>}
              <Descriptions.Item label="支付方式">{PAY_METHODS[detail.payMethod]?.icon} {PAY_METHODS[detail.payMethod]?.label}</Descriptions.Item>
              <Descriptions.Item label="收款时间">{fmtTime(detail.payTime)}</Descriptions.Item>
              {detail.remark && <Descriptions.Item label="备注">{detail.remark}</Descriptions.Item>}
            </Descriptions>
          </>
        )}
      </Drawer>
    </div>
  )
}
