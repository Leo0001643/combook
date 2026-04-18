/**
 * 车辆派车记录管理
 */
import { useState, useEffect, useCallback, useRef } from 'react'
import {
  Table, Input, Select, Button, Tag, Space, Typography, message,
  Modal, Form, DatePicker, InputNumber, Row, Col, Drawer, Descriptions, Divider,
  Badge, Statistic,
} from 'antd'
import {
  PlusOutlined, SearchOutlined, ReloadOutlined, SettingOutlined,
  CarOutlined, UserOutlined, EditOutlined, ClockCircleOutlined,
  EnvironmentOutlined, DollarOutlined, CheckCircleOutlined,
} from '@ant-design/icons'
import dayjs from 'dayjs'
import type { ColumnsType } from 'antd/es/table'
import { col, styledTableComponents, INPUT_STYLE } from '../../components/common/tableComponents'
import PagePagination from '../../components/common/PagePagination'
import { useTableBodyHeight } from '../../hooks/useTableBodyHeight'
import DateTimeRangePicker from '../../components/common/DateTimeRangePicker'
import { useDict, parseRemark } from '../../hooks/useDict'

const { Text } = Typography
const { TextArea } = Input

/** 字典兜底 - 派车用途 */
const PURPOSE_FALLBACK = [
  { value: '1', label: '接送客户', color: '#6366f1', icon: '🚕' },
  { value: '2', label: '采购物资', color: '#f59e0b', icon: '🛒' },
  { value: '3', label: '员工通勤', color: '#3b82f6', icon: '🚌' },
  { value: '4', label: '业务出行', color: '#10b981', icon: '💼' },
  { value: '5', label: '其它',     color: '#94a3b8', icon: '🚗' },
]
/** 字典兜底 - 调度状态 */
const STATUS_FALLBACK = [
  { value: '0', label: '待出发', color: '#3b82f6', badge: 'default' },
  { value: '1', label: '行程中', color: '#f97316', badge: 'processing' },
  { value: '2', label: '已返回', color: '#10b981', badge: 'success' },
  { value: '3', label: '已取消', color: '#94a3b8', badge: 'default' },
]

function mockDispatches() {
  return [
    { id: 1, dispatchNo: 'DC20260413001', vehiclePlate: '粤B 12345', driverName: '张师傅', purpose: '1', destination: '金边机场', departTime: '2026-04-13 09:00:00', returnTime: '2026-04-13 11:30:00', mileage: 45.2, fuelCost: 12.00, otherCost: 0, totalCost: 12.00, status: '2', passengerInfo: '客户 VIP 001', remark: '' },
    { id: 2, dispatchNo: 'DC20260413002', vehiclePlate: '粤B 67890', driverName: '李师傅', purpose: '2', destination: '中央市场', departTime: '2026-04-13 10:00:00', returnTime: null, mileage: null, fuelCost: 0, otherCost: 0, totalCost: 0, status: '1', passengerInfo: '', remark: '采购精油材料' },
    { id: 3, dispatchNo: 'DC20260413003', vehiclePlate: '粤B 11111', driverName: '王师傅', purpose: '3', destination: '员工宿舍→店面', departTime: '2026-04-13 07:30:00', returnTime: '2026-04-13 08:15:00', mileage: 8.5, fuelCost: 3.00, otherCost: 0, totalCost: 3.00, status: '2', passengerInfo: '员工 5 人', remark: '' },
    { id: 4, dispatchNo: 'DC20260413004', vehiclePlate: '粤B 22222', driverName: '陈师傅', purpose: '1', destination: '诺富特酒店', departTime: '2026-04-13 15:00:00', returnTime: null, mileage: null, fuelCost: 0, otherCost: 0, totalCost: 0, status: '0', passengerInfo: '手环 0928', remark: '' },
  ]
}

export default function VehicleDispatchPage() {
  const { ref, height: tableBodyH } = useTableBodyHeight(46)

  const { items: purposeItems } = useDict('vehicle_dispatch_purpose')
  const { items: statusItems }  = useDict('vehicle_dispatch_status')

  /** 取用途元数据（含颜色/图标） */
  const purposeMeta = useCallback((val: string | number) => {
    const v = String(val)
    const item = purposeItems.find(i => i.dictValue === v)
    if (item) { const { color, icon } = parseRemark(item.remark); return { label: item.labelZh, color: color ?? '#6366f1', icon: icon ?? '🚗' } }
    return PURPOSE_FALLBACK.find(f => f.value === v) ?? { label: v, color: '#94a3b8', icon: '🚗' }
  }, [purposeItems])

  /** 取调度状态元数据（含颜色/badge） */
  const statusMeta = useCallback((val: string | number) => {
    const v = String(val)
    const item = statusItems.find(i => i.dictValue === v)
    if (item) { const { color, badge } = parseRemark(item.remark); return { label: item.labelZh, color: color ?? '#94a3b8', badge: badge ?? 'default' } }
    return STATUS_FALLBACK.find(f => f.value === v) ?? { label: v, color: '#94a3b8', badge: 'default' }
  }, [statusItems])

  const masterRef = useRef<any[]>(mockDispatches())

  const [records,  setRecords]  = useState<any[]>(masterRef.current)
  const [total,    setTotal]    = useState(masterRef.current.length)
  const [page,     setPage]     = useState(1)
  const [pageSize, setPageSize] = useState(20)
  const [keyword,  setKeyword]  = useState('')
  const [purpose,  setPurpose]  = useState<string | undefined>()
  const [status,   setStatus]   = useState<string | undefined>()
  const [dateRange, setDateRange] = useState<[string, string] | null>(null)

  const [createOpen,  setCreateOpen]  = useState(false)
  const [createForm]                  = Form.useForm()
  const [createLoading, setCreateLoading] = useState(false)

  const [detailOpen, setDetailOpen] = useState(false)
  const [detail,     setDetail]     = useState<any>(null)

  const [returnOpen,   setReturnOpen]   = useState(false)
  const [returnTarget, setReturnTarget] = useState<any>(null)
  const [returnForm]                    = Form.useForm()

  const applyFilter = useCallback(() => {
    const filtered = masterRef.current.filter(r =>
      (!keyword || r.vehiclePlate.includes(keyword) || (r.driverName ?? '').includes(keyword) || (r.destination ?? '').includes(keyword)) &&
      (purpose === undefined || r.purpose === purpose) &&
      (status  === undefined || r.status  === status)
    )
    setRecords(filtered)
    setTotal(filtered.length)
  }, [keyword, purpose, status, dateRange])

  const fetchList = applyFilter

  useEffect(() => { applyFilter() }, [applyFilter])

  const handleDepart = (record: any) => {
    masterRef.current = masterRef.current.map(r =>
      r.id === record.id
        ? { ...r, status: '1', departTime: r.departTime ?? dayjs().format('YYYY-MM-DD HH:mm:ss') }
        : r
    )
    applyFilter()
    message.success(`${record.vehiclePlate} 已标记出发！`)
  }

  const handleCreate = async () => {
    try {
      const values = await createForm.validateFields()
      setCreateLoading(true)
      const newRecord = {
        id: Date.now(),
        dispatchNo: `DC${dayjs().format('YYYYMMDDHHmmss')}`,
        vehiclePlate: values.vehiclePlate,
        driverName: values.driverName,
        purpose: String(values.purpose),
        destination: values.destination || '',
        departTime: values.departTime?.format('YYYY-MM-DD HH:mm:ss') ?? dayjs().format('YYYY-MM-DD HH:mm:ss'),
        returnTime: null,
        mileage: null,
        fuelCost: 0, otherCost: 0, totalCost: 0,
        status: '0',
        passengerInfo: values.passengerInfo || '',
        remark: values.remark || '',
      }
      masterRef.current = [newRecord, ...masterRef.current]
      applyFilter()
      message.success('派车记录已创建！')
      createForm.resetFields()
      setCreateOpen(false)
    } catch { message.error('请填写必填项') }
    finally { setCreateLoading(false) }
  }

  const openReturn = (record: any) => {
    setReturnTarget(record)
    returnForm.resetFields()
    returnForm.setFieldsValue({ returnTime: dayjs() })
    setReturnOpen(true)
  }

  const handleReturn = async () => {
    try {
      const values = await returnForm.validateFields()
      const fuelCost  = values.fuelCost  ?? 0
      const otherCost = values.otherCost ?? 0
      masterRef.current = masterRef.current.map(r =>
        r.id === returnTarget.id
          ? {
              ...r,
              status: '2',
              returnTime: values.returnTime?.format('YYYY-MM-DD HH:mm:ss') ?? dayjs().format('YYYY-MM-DD HH:mm:ss'),
              mileage:  values.mileage ?? 0,
              fuelCost, otherCost,
              totalCost: fuelCost + otherCost,
            }
          : r
      )
      applyFilter()
      message.success(`${returnTarget.vehiclePlate} 已记录返回！`)
      setReturnOpen(false)
      setReturnTarget(null)
    } catch { message.error('请填写返回时间') }
  }

  const purposeOpts = purposeItems.length > 0
    ? purposeItems.filter(i => i.status === 1).map(i => ({ value: i.dictValue, label: `${parseRemark(i.remark).icon ?? ''} ${i.labelZh}`.trim() }))
    : PURPOSE_FALLBACK.map(f => ({ value: f.value, label: `${f.icon} ${f.label}` }))

  const statusOpts = statusItems.length > 0
    ? statusItems.filter(i => i.status === 1).map(i => ({ value: i.dictValue, label: i.labelZh }))
    : STATUS_FALLBACK.map(f => ({ value: f.value, label: f.label }))

  const columns: ColumnsType<any> = [
    {
      title: col(<CarOutlined style={{ color: '#64748b' }} />, '派车单号'),
      dataIndex: 'dispatchNo', width: 160,
      render: v => <Text style={{ fontFamily: 'monospace', fontSize: 11, color: '#6b7280' }}>{v}</Text>,
    },
    {
      title: col(<CarOutlined style={{ color: '#64748b' }} />, '车牌'),
      dataIndex: 'vehiclePlate', width: 120,
      render: v => (
        <span style={{
          fontFamily: 'monospace', fontWeight: 800, color: '#1e40af',
          background: '#dbeafe', padding: '3px 10px', borderRadius: 8, fontSize: 13,
        }}>{v}</span>
      ),
    },
    {
      title: col(<UserOutlined style={{ color: '#64748b' }} />, '驾驶员'),
      dataIndex: 'driverName', width: 100,
      render: v => <span style={{ fontWeight: 600 }}>{v || '—'}</span>,
    },
    {
      title: col(<EnvironmentOutlined style={{ color: '#64748b' }} />, '用途 / 目的地'),
      key: 'purpose', width: 200,
      render: (_, r) => {
        const p = purposeMeta(r.purpose)
        return (
          <div>
            <Tag style={{ borderRadius: 8, fontWeight: 600, border: 'none', marginBottom: 2, background: `${p.color}18`, color: p.color }}>
              {p.icon} {p.label}
            </Tag>
            <div style={{ fontSize: 11, color: '#6b7280', marginTop: 2 }}>{r.destination || '—'}</div>
          </div>
        )
      },
    },
    {
      title: col(<ClockCircleOutlined style={{ color: '#64748b' }} />, '出发 / 返回'),
      key: 'time', width: 180,
      render: (_, r) => (
        <div style={{ fontSize: 12 }}>
          <div><span style={{ color: '#6b7280' }}>出:</span> {r.departTime ? dayjs(r.departTime).format('MM-DD HH:mm') : '—'}</div>
          <div><span style={{ color: '#6b7280' }}>返:</span> {r.returnTime ? dayjs(r.returnTime).format('MM-DD HH:mm') : <Text type="secondary">未返回</Text>}</div>
        </div>
      ),
    },
    {
      title: col(<DollarOutlined style={{ color: '#64748b' }} />, '里程 / 费用'),
      key: 'cost', width: 130, align: 'right',
      render: (_, r) => (
        <div style={{ textAlign: 'right', fontSize: 12 }}>
          <div style={{ color: '#6b7280' }}>{r.mileage ? `${r.mileage} km` : '—'}</div>
          <div style={{ fontWeight: 700, color: '#F5A623' }}>
            ${r.totalCost.toFixed(2)}
          </div>
        </div>
      ),
    },
    {
      title: col(<SettingOutlined style={{ color: '#64748b' }} />, '状态'),
      dataIndex: 'status', width: 90,
      render: s => {
        const m = statusMeta(s)
        return <Badge status={m.badge as any} text={<span style={{ fontWeight: 600, color: m.color }}>{m.label}</span>} />
      },
    },
    {
      title: col(<SettingOutlined style={{ color: '#64748b' }} />, '操作'),
      key: 'action', fixed: 'right', width: 180,
      render: (_, r) => (
        <Space size={4} wrap>
          <Button size="small" type="primary" ghost icon={<EditOutlined />}
            style={{ borderRadius: 6, fontSize: 12 }}
            onClick={() => { setDetail(r); setDetailOpen(true) }}>详情</Button>
          {r.status === '1' && (
            <Button size="small" icon={<CheckCircleOutlined />}
              style={{ borderRadius: 6, fontSize: 12, color: '#10b981', borderColor: '#6ee7b7' }}
              onClick={() => openReturn(r)}>
              记录返回
            </Button>
          )}
          {r.status === '0' && (
            <Button size="small" icon={<CarOutlined />}
              style={{ borderRadius: 6, fontSize: 12, color: '#6366f1', borderColor: '#a5b4fc' }}
              onClick={() => handleDepart(r)}>出发</Button>
          )}
        </Space>
      ),
    },
  ]

  const totalCost = records.reduce((s, r) => s + r.totalCost, 0)
  const totalMile = records.filter(r => r.mileage).reduce((s, r) => s + (r.mileage ?? 0), 0)

  const dispatchStats = [
    { label: '今日派车', value: records.length + ' 次',         icon: <CarOutlined />,          color: '#3b82f6', bg: '#eff6ff', border: '#bfdbfe' },
    { label: '行程中',   value: records.filter(r => r.status === '1').length + ' 辆', icon: <ClockCircleOutlined />, color: '#f97316', bg: '#fff7ed', border: '#fed7aa' },
    { label: '累计里程', value: totalMile.toFixed(1) + ' km',   icon: <EnvironmentOutlined />,  color: '#10b981', bg: '#ecfdf5', border: '#a7f3d0' },
    { label: '今日油费', value: '$' + totalCost.toFixed(2),     icon: <DollarOutlined />,       color: '#f59e0b', bg: '#fffbeb', border: '#fde68a' },
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
              background: 'linear-gradient(135deg,#1d4ed8,#3b82f6)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: '0 4px 12px rgba(29,78,216,0.35)', flexShrink: 0,
            }}>
              <CarOutlined style={{ color: '#fff', fontSize: 16 }} />
            </div>
            <div>
              <div style={{ fontWeight: 700, fontSize: 15, color: '#111827', lineHeight: 1.2 }}>派车记录</div>
              <div style={{ fontSize: 11, color: '#9ca3af', lineHeight: 1.3, marginTop: 1 }}>车辆使用全程追踪 · 费用统计</div>
            </div>
          </div>
          <div style={{ width: 1, height: 28, margin: '0 4px', background: '#e5e7eb', flexShrink: 0 }} />
          <div style={{ display: 'flex', gap: 8, flex: 1, flexWrap: 'wrap', alignItems: 'center' }}>
            {dispatchStats.map(s => (
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
          <Button type="primary" icon={<PlusOutlined />}
            style={{
              flexShrink: 0, borderRadius: 8, border: 'none', fontSize: 13,
              background: 'linear-gradient(135deg,#1d4ed8,#3b82f6)',
              boxShadow: '0 2px 8px rgba(29,78,216,0.35)',
            }}
            onClick={() => setCreateOpen(true)}>新增派车</Button>
        </div>

        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', padding: '10px 24px 12px' }}>
          <Input prefix={<SearchOutlined style={{ color: '#3b82f6', fontSize: 12 }} />}
            placeholder="车牌 / 驾驶员 / 目的地"
            value={keyword} onChange={e => setKeyword(e.target.value)}
            style={{ ...INPUT_STYLE, width: 240 }}
            allowClear />
          <Select
            placeholder={<Space size={4}><CarOutlined style={{ color: '#3b82f6', fontSize: 12 }} />用途</Space>}
            value={purpose} onChange={setPurpose} allowClear style={{ width: 130 }}
            options={purposeOpts} />
          <Select
            placeholder={<Space size={4}><CheckCircleOutlined style={{ color: '#10b981', fontSize: 12 }} />状态</Space>}
            value={status} onChange={setStatus} allowClear style={{ width: 110 }}
            options={statusOpts} />
          <DateTimeRangePicker onChange={(_, strs) => setDateRange(strs as any)} style={{ width: 260 }} />
          <div style={{ flex: 1 }} />
          <Button icon={<ReloadOutlined />} style={{ borderRadius: 8 }} onClick={fetchList}>刷新</Button>
        </div>
      </div>

      {/* ── 数据表格 ────────────────────────────────────────────────────── */}
      <div ref={ref} style={{
        marginLeft: -24, marginRight: -24, marginBottom: -24,
        background: '#fff', borderTop: '1px solid #eef0f8',
      }}>
        <Table
          dataSource={records} columns={columns}
          components={styledTableComponents}
          rowKey="id" size="middle"
          scroll={{ x: 900, y: tableBodyH }} pagination={false}
        />
        <PagePagination total={total} current={page} pageSize={pageSize}
          onChange={setPage} onSizeChange={setPageSize} />
      </div>

      {/* ── 新增派车弹窗 ─────────────────────────────────────────────── */}
      <Modal
        title={
          <div style={{ background: 'linear-gradient(135deg,#1e3a5f,#1d4ed8)', margin: '-20px -24px 20px', padding: '18px 24px', borderRadius: '8px 8px 0 0', display: 'flex', alignItems: 'center', gap: 12 }}>
            <CarOutlined style={{ color: '#fff', fontSize: 22 }} />
            <div>
              <div style={{ color: '#fff', fontWeight: 800, fontSize: 16 }}>新增派车记录</div>
              <div style={{ color: 'rgba(255,255,255,0.7)', fontSize: 12 }}>登记车辆使用信息</div>
            </div>
          </div>
        }
        open={createOpen} onCancel={() => setCreateOpen(false)} footer={null} destroyOnHidden width={560}
      >
        <Form form={createForm} layout="vertical">
          <Row gutter={12}>
            <Col span={12}>
              <Form.Item name="vehiclePlate" label="车辆" rules={[{ required: true }]}>
                <Input prefix={<CarOutlined style={{ color: '#1d4ed8' }} />} placeholder="输入车牌号或选择" style={INPUT_STYLE} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="driverName" label="驾驶员" rules={[{ required: true }]}>
                <Input prefix={<UserOutlined style={{ color: '#1d4ed8' }} />} placeholder="驾驶员姓名" style={INPUT_STYLE} />
              </Form.Item>
            </Col>
          </Row>
          <Row gutter={12}>
            <Col span={12}>
              <Form.Item name="purpose" label="用途" rules={[{ required: true }]}>
                <Select placeholder="选择用途" options={purposeOpts} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="departTime" label="计划出发时间">
                <DatePicker showTime style={{ width: '100%', borderRadius: 8 }} />
              </Form.Item>
            </Col>
          </Row>
          <Form.Item name="destination" label="目的地">
            <Input prefix={<EnvironmentOutlined style={{ color: '#1d4ed8' }} />} placeholder="目的地地址" style={INPUT_STYLE} />
          </Form.Item>
          <Form.Item name="passengerInfo" label="乘客/随行信息">
            <Input placeholder="乘客姓名、客户手环号等" style={INPUT_STYLE} />
          </Form.Item>
          <Form.Item name="remark" label="备注">
            <TextArea rows={2} style={{ borderRadius: 8 }} />
          </Form.Item>
        </Form>
        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10 }}>
          <Button onClick={() => setCreateOpen(false)}>取消</Button>
          <Button type="primary" loading={createLoading} onClick={handleCreate}
            style={{ background: 'linear-gradient(135deg,#1e3a5f,#1d4ed8)', border: 'none', borderRadius: 8, fontWeight: 700 }}
            icon={<CarOutlined />}>确认派车</Button>
        </div>
      </Modal>

      {/* ── 记录返回弹窗 ──────────────────────────────────────────────── */}
      <Modal
        title={
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <CheckCircleOutlined style={{ color: '#10b981', fontSize: 18 }} />
            <div>
              <div style={{ fontWeight: 700, fontSize: 15 }}>记录返回</div>
              {returnTarget && (
                <div style={{ fontSize: 12, color: '#6b7280', fontWeight: 400 }}>
                  {returnTarget.vehiclePlate} · {returnTarget.driverName}
                </div>
              )}
            </div>
          </div>
        }
        open={returnOpen} onCancel={() => { setReturnOpen(false); setReturnTarget(null) }} footer={null} destroyOnHidden>
        <Form form={returnForm} layout="vertical">
          <Form.Item name="returnTime" label="返回时间" rules={[{ required: true, message: '请选择返回时间' }]}>
            <DatePicker showTime style={{ width: '100%', borderRadius: 8 }} />
          </Form.Item>
          <Row gutter={12}>
            <Col span={12}>
              <Form.Item name="mileage" label="行驶里程(km)">
                <InputNumber min={0} step={0.1} precision={1} style={{ width: '100%' }} placeholder="0.0" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="fuelCost" label="油费($)">
                <InputNumber min={0} step={0.5} precision={2} prefix="$" style={{ width: '100%' }} placeholder="0.00" />
              </Form.Item>
            </Col>
          </Row>
          <Form.Item name="otherCost" label="其它费用($)">
            <InputNumber min={0} step={0.5} precision={2} prefix="$" style={{ width: '100%' }} placeholder="0.00" />
          </Form.Item>
          <Form.Item name="remark" label="备注">
            <TextArea rows={2} style={{ borderRadius: 8 }} />
          </Form.Item>
        </Form>
        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10 }}>
          <Button onClick={() => setReturnOpen(false)}>取消</Button>
          <Button type="primary" onClick={handleReturn}
            style={{ background: 'linear-gradient(135deg,#10b981,#059669)', border: 'none', borderRadius: 8, fontWeight: 700 }}
            icon={<CheckCircleOutlined />}>确认返回</Button>
        </div>
      </Modal>

      {/* ── 详情抽屉 ──────────────────────────────────────────────────── */}
      <Drawer title={`派车详情 · ${detail?.dispatchNo}`} open={detailOpen} onClose={() => setDetailOpen(false)} styles={{ wrapper: { width: 700 } }}>
        {detail && (() => {
          const p = purposeMeta(detail.purpose)
          const s = statusMeta(detail.status)
          return (
            <>
              <div style={{
                display: 'flex', alignItems: 'center', gap: 12, padding: '14px 16px',
                background: 'linear-gradient(135deg,#dbeafe,#eff6ff)', borderRadius: 12, marginBottom: 20,
              }}>
                <div style={{ width: 48, height: 48, borderRadius: 14, background: 'linear-gradient(135deg,#1e3a5f,#1d4ed8)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <CarOutlined style={{ color: '#fff', fontSize: 24 }} />
                </div>
                <div>
                  <div style={{ fontSize: 20, fontWeight: 900, color: '#1e40af', fontFamily: 'monospace' }}>{detail.vehiclePlate}</div>
                  <Tag style={{ borderRadius: 6, border: 'none', fontWeight: 600, marginTop: 2, background: `${p.color}18`, color: p.color }}>
                    {p.icon} {p.label}
                  </Tag>
                </div>
                <div style={{ marginLeft: 'auto' }}>
                  <Badge status={s.badge as any} text={
                    <span style={{ fontWeight: 700, color: s.color }}>{s.label}</span>
                  } />
                </div>
              </div>

              <Descriptions column={1} size="small" bordered>
                <Descriptions.Item label="驾驶员">{detail.driverName}</Descriptions.Item>
                <Descriptions.Item label="目的地">{detail.destination || '—'}</Descriptions.Item>
                <Descriptions.Item label="乘客信息">{detail.passengerInfo || '—'}</Descriptions.Item>
                <Descriptions.Item label="出发时间">{detail.departTime ? dayjs(detail.departTime).format('YYYY-MM-DD HH:mm') : '—'}</Descriptions.Item>
                <Descriptions.Item label="返回时间">{detail.returnTime ? dayjs(detail.returnTime).format('YYYY-MM-DD HH:mm') : '—'}</Descriptions.Item>
                {detail.mileage && <Descriptions.Item label="行驶里程">{detail.mileage} km</Descriptions.Item>}
                <Descriptions.Item label="备注">{detail.remark || '—'}</Descriptions.Item>
              </Descriptions>

              <Divider />
              <Row gutter={16}>
                <Col span={8}><Statistic title="油费" value={`$${detail.fuelCost.toFixed(2)}`} valueStyle={{ color: '#f59e0b', fontWeight: 800 }} /></Col>
                <Col span={8}><Statistic title="其它" value={`$${detail.otherCost.toFixed(2)}`} valueStyle={{ color: '#6b7280', fontWeight: 800 }} /></Col>
                <Col span={8}><Statistic title="合计" value={`$${detail.totalCost.toFixed(2)}`} valueStyle={{ color: '#F5A623', fontWeight: 800 }} /></Col>
              </Row>
            </>
          )
        })()}
      </Drawer>
    </div>
  )
}
