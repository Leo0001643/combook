/**
 * 支出管理 — 店租、车辆、水电、工资、采购、营销等全类目支出记录
 */
import { useState, useCallback, useRef } from 'react'
import {
  Table, Input, Select, Button, Tag, Space, Typography, message,
  Modal, Form, InputNumber, DatePicker, Upload, Row, Col, Drawer, Descriptions,
} from 'antd'
import {
  PlusOutlined, SearchOutlined, ReloadOutlined, SettingOutlined,
  DollarOutlined, HomeOutlined, CarOutlined, TeamOutlined, TagsOutlined,
  ShoppingOutlined, BarChartOutlined, DeleteOutlined, EditOutlined, CheckCircleOutlined,
  PictureOutlined,
} from '@ant-design/icons'
import dayjs from 'dayjs'
import type { ColumnsType } from 'antd/es/table'
import { col, styledTableComponents, INPUT_STYLE } from '../../components/common/tableComponents'
import PagePagination from '../../components/common/PagePagination'
import { useTableBodyHeight } from '../../hooks/useTableBodyHeight'
import { useDict } from '../../hooks/useDict'
import DateTimeRangePicker from '../../components/common/DateTimeRangePicker'

const { Text, Title } = Typography
const { Option } = Select
const { TextArea } = Input

const EXPENSE_CATS_FB: Record<number, { label: string; color: string; icon: React.ReactNode }> = {
  1: { label: '店租/场地', color: '#6366f1', icon: <HomeOutlined /> },
  2: { label: '车辆费用', color: '#3b82f6', icon: <CarOutlined /> },
  3: { label: '水电费',   color: '#06b6d4', icon: <BarChartOutlined /> },
  4: { label: '员工工资', color: '#10b981', icon: <TeamOutlined /> },
  5: { label: '采购进货', color: '#f59e0b', icon: <ShoppingOutlined /> },
  6: { label: '营销推广', color: '#ec4899', icon: <BarChartOutlined /> },
  7: { label: '设备维修', color: '#f97316', icon: <BarChartOutlined /> },
  8: { label: '其它',    color: '#94a3b8', icon: <DollarOutlined /> },
}

const PAY_METHODS_MAP_FB: Record<number, string> = {
  1: '💵 现金', 2: '💚 微信', 3: '💙 支付宝', 4: '🏦 银行', 5: '₮ USDT', 8: '💳 其它',
}

function mockExpenses() {
  return [
    { id: 1, expenseNo: 'EX20260413001', category: 1, title: '4月场地租金', amount: 8000, currency: 'USD', payMethod: 4, expenseDate: '2026-04-01', status: 1, description: '商铺月租金，含水电押金', operatorName: '张管理' },
    { id: 2, expenseNo: 'EX20260413002', category: 2, title: '车辆加油', amount: 120, currency: 'USD', payMethod: 1, expenseDate: '2026-04-13', status: 1, description: '两辆车本周加油', operatorName: '李师傅' },
    { id: 3, expenseNo: 'EX20260413003', category: 5, title: '精油采购', amount: 680, currency: 'USD', payMethod: 3, expenseDate: '2026-04-12', status: 1, description: '泰式精油、护肤品采购', operatorName: '王采购' },
    { id: 4, expenseNo: 'EX20260413004', category: 6, title: '朋友圈广告', amount: 350, currency: 'USD', payMethod: 2, expenseDate: '2026-04-10', status: 1, description: '微信朋友圈推广投放', operatorName: '陈运营' },
    { id: 5, expenseNo: 'EX20260413005', category: 3, title: '4月水电费', amount: 420, currency: 'USD', payMethod: 4, expenseDate: '2026-04-05', status: 1, description: '店面水电煤气费用', operatorName: '张管理' },
  ]
}

export default function ExpenseManagePage() {
  const { ref, height: tableBodyH } = useTableBodyHeight(46)

  const { items: expCatItems } = useDict('expense_category')
  const { items: payItems }    = useDict('walkin_pay_type')

  const EXPENSE_CATS: Record<number, { label: string; color: string; icon: React.ReactNode }> =
    expCatItems.length > 0
      ? Object.fromEntries(expCatItems.map(i => [Number(i.dictValue), { label: i.labelZh, color: i.remark ?? '#94a3b8', icon: <DollarOutlined /> }]))
      : EXPENSE_CATS_FB

  const PAY_METHODS_MAP: Record<number, string> =
    payItems.length > 0
      ? Object.fromEntries(payItems.map(i => [Number(i.dictValue), `${i.remark ?? ''} ${i.labelZh}`.trim()]))
      : PAY_METHODS_MAP_FB

  const masterRef = useRef<any[]>(mockExpenses())

  const [records,  setRecords]  = useState<any[]>(masterRef.current)
  const [total,    setTotal]    = useState(masterRef.current.length)
  const [page,    setPage]    = useState(1)
  const [pageSize, setPageSize] = useState(20)
  const [keyword,  setKeyword]  = useState('')
  const [category, setCategory] = useState<number | undefined>()

  const [createOpen,    setCreateOpen]    = useState(false)
  const [createForm]                      = Form.useForm()
  const [createLoading, setCreateLoading] = useState(false)
  const [detailOpen,    setDetailOpen]    = useState(false)
  const [detail,        setDetail]        = useState<any>(null)

  const fetchList = useCallback(() => {
    const filtered = masterRef.current.filter(r =>
      (!keyword || r.title.includes(keyword) || r.expenseNo.includes(keyword)) &&
      (category === undefined || r.category === category)
    )
    setRecords(filtered)
    setTotal(filtered.length)
  }, [keyword, category])

  const handleCreate = async () => {
    // Wrap validateFields in try-catch to prevent unhandled rejection (React 19 white screen)
    let values: any
    try {
      values = await createForm.validateFields()
    } catch {
      return  // Validation failed — form shows inline errors, no page crash
    }
    setCreateLoading(true)
    try {
      const newRecord = {
        id: Date.now(),
        expenseNo: `EX${dayjs().format('YYYYMMDDHHmmss')}`,
        category:  values.category,
        title:     values.title,
        amount:    values.amount,
        currency:  'USD',
        payMethod: values.payMethod,
        expenseDate: values.expenseDate?.format('YYYY-MM-DD') ?? dayjs().format('YYYY-MM-DD'),
        status:    1,
        description: values.description ?? '',
        operatorName: '当前用户',
      }
      masterRef.current = [newRecord, ...masterRef.current]
      fetchList()
      message.success('支出记录已添加！')
      createForm.resetFields()
      setCreateOpen(false)
    } catch { message.error('操作失败') }
    finally { setCreateLoading(false) }
  }

  // Stats
  const totalAmount  = records.reduce((s, r) => s + r.amount, 0)
  const catAmounts   = Object.keys(EXPENSE_CATS).map(k => ({
    cat: +k, label: EXPENSE_CATS[+k].label, color: EXPENSE_CATS[+k].color,
    amount: records.filter(r => r.category === +k).reduce((s, r) => s + r.amount, 0),
  })).sort((a, b) => b.amount - a.amount).slice(0, 4)

  const columns: ColumnsType<any> = [
    { title: col(<DollarOutlined style={{ color: '#64748b' }} />, '支出单号', 'center'), dataIndex: 'expenseNo', width: 160, align: 'center', render: v => <Text style={{ fontFamily: 'monospace', fontSize: 11, color: '#6b7280' }}>{v}</Text> },
    {
      title: col(<BarChartOutlined style={{ color: '#64748b' }} />, '类型 / 标题', 'center'), key: 'title', width: 220, align: 'center',
      render: (_, r) => (
        <div style={{ textAlign: 'center' }}>
          <Tag color={EXPENSE_CATS[r.category]?.color} style={{ borderRadius: 8, fontWeight: 600, border: 'none', marginBottom: 3 }}>
            {EXPENSE_CATS[r.category]?.label}
          </Tag>
          <div style={{ fontSize: 13, fontWeight: 600, color: '#111827' }}>{r.title}</div>
        </div>
      ),
    },
    {
      title: col(<DollarOutlined style={{ color: '#64748b' }} />, '金额', 'center'), dataIndex: 'amount', width: 110, align: 'center',
      render: (v, r) => <span style={{ fontSize: 15, fontWeight: 800, color: '#f43f5e' }}>${v.toLocaleString()} <Text style={{ fontSize: 10 }}>{r.currency}</Text></span>,
    },
    { title: col(null, '支付方式', 'center'), dataIndex: 'payMethod', width: 110, align: 'center', render: v => <Text style={{ fontSize: 12 }}>{PAY_METHODS_MAP[v] ?? '其它'}</Text> },
    { title: col(null, '支出日期', 'center'), dataIndex: 'expenseDate', width: 110, align: 'center', render: v => <Text style={{ fontSize: 12 }}>{v}</Text> },
    { title: col(null, '经办人', 'center'), dataIndex: 'operatorName', width: 90, align: 'center' },
    {
      title: col(<SettingOutlined style={{ color: '#64748b' }} />, '操作', 'center'), key: 'action', fixed: 'right', width: 140, align: 'center',
      render: (_, r) => (
        <Space size={4}>
          <Button size="small" type="primary" ghost icon={<EditOutlined />}
            style={{ borderRadius: 6, fontSize: 12 }}
            onClick={() => { setDetail(r); setDetailOpen(true) }}>详情</Button>
          <Button size="small" danger icon={<DeleteOutlined />} style={{ borderRadius: 6, fontSize: 12 }}
            onClick={() => message.success('已删除')}>删除</Button>
        </Space>
      ),
    },
  ]

  const expenseStats = [
    { label: '本月支出总计', value: `$${totalAmount.toLocaleString()}`, icon: <DollarOutlined />, color: '#ef4444', bg: '#fef2f2', border: '#fecaca' },
    ...catAmounts.map(c => ({ label: c.label, value: `$${c.amount.toLocaleString()}`, icon: <TagsOutlined />, color: '#f97316', bg: '#fff7ed', border: '#fed7aa' })),
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
              background: 'linear-gradient(135deg,#dc2626,#f87171)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: '0 4px 12px rgba(220,38,38,0.35)', flexShrink: 0,
            }}>
              <DollarOutlined style={{ color: '#fff', fontSize: 16 }} />
            </div>
            <div>
              <div style={{ fontWeight: 700, fontSize: 15, color: '#111827', lineHeight: 1.2 }}>支出管理</div>
              <div style={{ fontSize: 11, color: '#9ca3af', lineHeight: 1.3, marginTop: 1 }}>店租 · 车辆 · 水电 · 采购 · 营销 · 全类目</div>
            </div>
          </div>
          <div style={{ width: 1, height: 28, margin: '0 4px', background: '#e5e7eb', flexShrink: 0 }} />
          <div style={{ display: 'flex', gap: 8, flex: 1, flexWrap: 'wrap', alignItems: 'center' }}>
            {expenseStats.map(s => (
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
              background: 'linear-gradient(135deg,#dc2626,#f87171)',
              boxShadow: '0 2px 8px rgba(220,38,38,0.35)',
            }}
            onClick={() => setCreateOpen(true)}>记录支出</Button>
        </div>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', padding: '10px 24px 12px' }}>
          <Input prefix={<SearchOutlined style={{ color: '#ef4444', fontSize: 12 }} />}
            placeholder="搜索支出标题 / 单号"
            value={keyword} onChange={e => setKeyword(e.target.value)}
            style={{ ...INPUT_STYLE, width: 220 }}
            allowClear />
          <Select
            placeholder={<Space size={4}><TagsOutlined style={{ color: '#ef4444', fontSize: 12 }} />支出类型</Space>}
            value={category} onChange={setCategory} allowClear style={{ width: 140 }}>
            {Object.entries(EXPENSE_CATS).map(([k, v]) => <Option key={k} value={+k}>{v.icon} {v.label}</Option>)}
          </Select>
          <DateTimeRangePicker onChange={() => {}} style={{ width: 260 }} />
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
        <PagePagination total={total} current={page} pageSize={pageSize} onChange={setPage} onSizeChange={setPageSize} />
      </div>

      {/* 新增弹窗 */}
      <Modal
        title={<div style={{ background: 'linear-gradient(135deg,#7f1d1d,#dc2626)', margin: '-20px -24px 20px', padding: '18px 24px', borderRadius: '8px 8px 0 0', display: 'flex', alignItems: 'center', gap: 12 }}>
          <DollarOutlined style={{ color: '#fff', fontSize: 22 }} />
          <div><div style={{ color: '#fff', fontWeight: 800, fontSize: 16 }}>记录支出</div><div style={{ color: 'rgba(255,255,255,0.7)', fontSize: 12 }}>登记本次支出信息</div></div>
        </div>}
        open={createOpen} onCancel={() => setCreateOpen(false)} footer={null} destroyOnHidden width={560}
      >
        <Form form={createForm} layout="vertical" initialValues={{ expenseDate: dayjs() }}>
          <Row gutter={12}>
            <Col span={12}>
              <Form.Item name="category" label="支出类型" rules={[{ required: true }]}>
                <Select placeholder="选择类型">
                  {Object.entries(EXPENSE_CATS).map(([k, v]) => <Option key={k} value={+k}>{v.label}</Option>)}
                </Select>
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="expenseDate" label="支出日期" rules={[{ required: true }]}>
                <DatePicker style={{ width: '100%', borderRadius: 8 }} />
              </Form.Item>
            </Col>
          </Row>
          <Form.Item name="title" label="支出标题" rules={[{ required: true }]}>
            <Input placeholder="如：4月场地租金" style={INPUT_STYLE} />
          </Form.Item>
          <Row gutter={12}>
            <Col span={12}>
              <Form.Item name="amount" label="金额" rules={[{ required: true }]}>
                <InputNumber min={0} step={1} precision={2} prefix="$" style={{ width: '100%' }} placeholder="0.00" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="payMethod" label="支付方式" rules={[{ required: true }]}>
                <Select placeholder="支付方式">
                  {Object.entries(PAY_METHODS_MAP).map(([k, v]) => <Option key={k} value={+k}>{v}</Option>)}
                </Select>
              </Form.Item>
            </Col>
          </Row>
          <Form.Item name="description" label="详细说明">
            <TextArea rows={2} style={{ borderRadius: 8 }} placeholder="描述支出用途、数量等详情" />
          </Form.Item>
          <Form.Item name="voucher" label="凭证图片（可选）">
            <Upload listType="picture-card" maxCount={3} beforeUpload={() => false}>
              <div><PictureOutlined /><div style={{ fontSize: 11, marginTop: 4 }}>上传凭证</div></div>
            </Upload>
          </Form.Item>
        </Form>
        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10 }}>
          <Button onClick={() => setCreateOpen(false)}>取消</Button>
          <Button type="primary" loading={createLoading} onClick={handleCreate}
            style={{ background: 'linear-gradient(135deg,#dc2626,#b91c1c)', border: 'none', borderRadius: 8, fontWeight: 700 }}
            icon={<CheckCircleOutlined />}>确认记录</Button>
        </div>
      </Modal>

      {/* 详情抽屉 */}
      <Drawer title={`支出详情 · ${detail?.expenseNo}`} open={detailOpen} onClose={() => setDetailOpen(false)} styles={{ wrapper: { width: 680 } }}>
        {detail && (
          <>
            <div style={{ padding: '14px 16px', background: 'linear-gradient(135deg,#fff1f2,#ffe4e6)', borderRadius: 12, marginBottom: 20, border: '1px solid #fca5a5' }}>
              <Tag color={EXPENSE_CATS[detail.category]?.color} style={{ borderRadius: 8, border: 'none', fontWeight: 600 }}>{EXPENSE_CATS[detail.category]?.label}</Tag>
              <div style={{ fontSize: 16, fontWeight: 700, color: '#111827', marginTop: 6 }}>{detail.title}</div>
              <div style={{ fontSize: 28, fontWeight: 900, color: '#f43f5e', marginTop: 4 }}>${detail.amount.toLocaleString()}</div>
            </div>
            <Descriptions column={1} size="small" bordered>
              <Descriptions.Item label="支出单号">{detail.expenseNo}</Descriptions.Item>
              <Descriptions.Item label="支出日期">{detail.expenseDate}</Descriptions.Item>
              <Descriptions.Item label="支付方式">{PAY_METHODS_MAP[detail.payMethod]}</Descriptions.Item>
              <Descriptions.Item label="经办人">{detail.operatorName || '—'}</Descriptions.Item>
              <Descriptions.Item label="说明">{detail.description || '—'}</Descriptions.Item>
            </Descriptions>
          </>
        )}
      </Drawer>
    </div>
  )
}
