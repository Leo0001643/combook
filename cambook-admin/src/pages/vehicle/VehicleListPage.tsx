import { useState, useEffect } from 'react'
import {
  Row, Col, Table, Input, Select, Space, Tag, Button,
  Typography, message, Modal, Form, Tooltip, Popconfirm, Dropdown,
  Divider,
} from 'antd'
import type { ColumnsType } from 'antd/es/table'
import type { MenuProps } from 'antd'
import {
  CarOutlined, CarFilled, PlusOutlined, EditOutlined, DeleteOutlined,
  SearchOutlined, ReloadOutlined, ShopOutlined,
  ToolOutlined, InfoCircleOutlined, CarryOutOutlined, CalendarOutlined,
  FileTextOutlined, DownOutlined, TagOutlined, BgColorsOutlined,
  SafetyCertificateOutlined, ClockCircleOutlined, SettingOutlined,
} from '@ant-design/icons'
import dayjs from 'dayjs'
import { usePortalScope } from '../../hooks/usePortalScope'
import { merchantApi } from '../../api/api'
import RichTextInput from '../../components/common/RichTextInput'
import PagePagination from '../../components/common/PagePagination'
import { col, INPUT_STYLE, styledTableComponents } from '../../components/common/tableComponents'
import PermGuard from '../../components/common/PermGuard'

const { Text } = Typography
const { Option } = Select

interface VehicleVO {
  id: number
  plateNumber: string
  brand: string
  model: string
  color: string
  seats: number
  inspectionCode: string
  inspectionExpiry: string
  photo: string
  status: number
  remark: string
  createTime: string
}

const STATUS_CFG: Record<number, { label: string; color: string; icon: React.ReactNode; bg: string }> = {
  0: { label: '空闲中', color: '#10b981', icon: <CarOutlined />, bg: '#ecfdf5' },
  1: { label: '使用中', color: '#3b82f6', icon: <CarFilled />, bg: '#eff6ff' },
  2: { label: '维修中', color: '#f59e0b', icon: <ToolOutlined />, bg: '#fffbeb' },
}

const BRAND_COLORS: Record<string, string> = {
  Toyota: '#eb0a1e', Honda: '#cc0000', Mazda: '#c00000',
  Mitsubishi: '#e60012', Hyundai: '#002c5f', Kia: '#05141f',
  Lexus: '#1a1a1a', default: '#667eea',
}

const PAGE_GRADIENT = 'linear-gradient(135deg,#10b981,#059669)'

export default function VehicleListPage() {
  const { isMerchant, vehicleList, vehicleAdd, vehicleEdit, vehicleDelete, vehicleStatus } = usePortalScope()
  const [data, setData]               = useState<VehicleVO[]>([])
  const [total, setTotal]             = useState(0)
  const [loading, setLoading]         = useState(false)
  const [current, setCurrent]         = useState(1)
  const [pageSize, setPageSize]       = useState(20)
  const [keyword, setKeyword]         = useState('')
  const [status, setStatus]           = useState<number | undefined>()
  const [seatFilter, setSeat]         = useState<number | undefined>()
  const [merchantId, setMerchantId]   = useState<number | undefined>()
  const [merchantOpts, setMerchantOpts] = useState<{ value: number; label: string }[]>([])
  const [drawerOpen, setDrawer]       = useState(false)
  const [editing, setEditing]         = useState<VehicleVO | null>(null)
  const [form] = Form.useForm()

  useEffect(() => {
    if (!isMerchant) {
      merchantApi.list({ page: 1, size: 200 }).then(res => {
        const list = res.data?.data?.list ?? res.data?.data?.records ?? []
        setMerchantOpts(list.map((m: any) => ({ value: m.id, label: m.name })))
      }).catch(() => {})
    }
  }, [isMerchant])

  useEffect(() => { loadData() }, [current, pageSize, keyword, status, seatFilter, merchantId])

  const loadData = async () => {
    setLoading(true)
    try {
      const res = await vehicleList({
        page: current, size: pageSize,
        keyword: keyword || undefined, status,
        ...(merchantId != null ? { merchantId } : {}),
      })
      const page = res.data?.data
      let list: VehicleVO[] = page?.list ?? page?.records ?? page?.data ?? []
      if (seatFilter) list = list.filter((v: VehicleVO) => v.seats === seatFilter)
      setData(list)
      setTotal(page?.total ?? 0)
    } catch { setData([]) } finally { setLoading(false) }
  }

  const openAdd = () => {
    setEditing(null)
    form.resetFields()
    form.setFieldsValue({ status: 0, seats: 5 })
    setDrawer(true)
  }

  const openEdit = (r: VehicleVO) => {
    setEditing(r)
    form.setFieldsValue({ ...r })
    setDrawer(true)
  }

  const handleSubmit = async () => {
    const values = await form.validateFields()
    try {
      if (editing) {
        await vehicleEdit({ ...values, id: editing.id })
        message.success('车辆信息已更新')
      } else {
        await vehicleAdd(values)
        message.success('车辆已添加')
      }
      setDrawer(false)
      loadData()
    } catch { /* interceptor handles */ }
  }

  const handleDelete = (r: VehicleVO) => {
    Modal.confirm({
      title: '确认删除该车辆档案？',
      icon: <DeleteOutlined style={{ color: '#ff4d4f' }} />,
      content: <span>车牌号：<Text strong>{r.plateNumber}</Text>，删除后无法恢复。</span>,
      okType: 'danger',
      okText: '确认删除',
      onOk: async () => {
        await vehicleDelete(r.id)
        message.success('已删除')
        loadData()
      },
    })
  }

  const handleStatus = async (r: VehicleVO, next: number) => {
    await vehicleStatus(r.id, next)
    message.success(`已切换为「${STATUS_CFG[next]?.label}」`)
    loadData()
  }

  const isExpiringSoon = (expiry: string) => {
    if (!expiry) return false
    return dayjs(expiry).diff(dayjs(), 'day') <= 30
  }

  const stats = {
    total,
    idle:  data.filter(v => v.status === 0).length,
    busy:  data.filter(v => v.status === 1).length,
    repair: data.filter(v => v.status === 2).length,
  }

  const headerStats = [
    { icon: '🚗', label: '车辆总数', value: stats.total, bg: '#ecfdf5', border: '#a7f3d0', color: '#059669' },
    { icon: '🟢', label: '空闲', value: stats.idle, bg: '#eff6ff', border: '#bfdbfe', color: '#2563eb' },
    { icon: '🔵', label: '使用中', value: stats.busy, bg: '#eef2ff', border: '#c7d2fe', color: '#4f46e5' },
    { icon: '🔧', label: '维修中', value: stats.repair, bg: '#fffbeb', border: '#fde68a', color: '#d97706' },
  ]

  const handleSearch = () => { setCurrent(1) }
  const handleReset = () => {
    setKeyword('')
    setStatus(undefined)
    setSeat(undefined)
    setMerchantId(undefined)
    setCurrent(1)
  }

  const columns: ColumnsType<VehicleVO> = [
    {
      title: col(<TagOutlined style={{ color: '#2563eb' }} />, '车牌号码'),
      dataIndex: 'plateNumber',
      width: 140,
      fixed: 'left',
      render: (v: string) => (
        <div style={{
          display: 'inline-flex', alignItems: 'center', gap: 6,
          background: '#1a1f2e', color: '#fff', borderRadius: 8,
          padding: '4px 10px', fontSize: 13, fontWeight: 700,
          letterSpacing: 1, boxShadow: '0 2px 8px rgba(0,0,0,0.2)',
        }}>
          <CarOutlined style={{ fontSize: 12, color: '#fbbf24' }} />
          {v}
        </div>
      ),
    },
    {
      title: col(<CarOutlined style={{ color: '#10b981' }} />, '品牌/型号'),
      key: 'brand',
      width: 160,
      render: (_, r) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, width: '100%' }}>
          <div style={{
            width: 36, height: 36, borderRadius: 8, flexShrink: 0,
            background: `${BRAND_COLORS[r.brand] ?? BRAND_COLORS.default}18`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <Text style={{ color: BRAND_COLORS[r.brand] ?? BRAND_COLORS.default, fontWeight: 700, fontSize: 12 }}>
              {r.brand?.slice(0, 2)}
            </Text>
          </div>
          <div>
            <div style={{ fontWeight: 600, fontSize: 13 }}>{r.brand}</div>
            <Text type="secondary" style={{ fontSize: 11 }}>{r.model || '—'}</Text>
          </div>
        </div>
      ),
    },
    {
      title: col(<BgColorsOutlined style={{ color: '#f97316' }} />, '颜色/座位'),
      key: 'color',
      width: 130,
      render: (_, r) => (
        <Space orientation="vertical" size={2}>
          <Space size={6}>
            <div style={{
              width: 14, height: 14, borderRadius: '50%',
              background: COLOR_MAP[r.color] ?? '#ccc',
              border: '2px solid #f0f0f0', flexShrink: 0,
            }} />
            <Text style={{ fontSize: 12 }}>{r.color || '—'}</Text>
          </Space>
          <Text type="secondary" style={{ fontSize: 11 }}>
            <CarOutlined style={{ marginRight: 3 }} />{r.seats ?? '—'} 座
          </Text>
        </Space>
      ),
    },
    {
      title: col(<CalendarOutlined style={{ color: '#ef4444' }} />, '年检有效期'),
      dataIndex: 'inspectionExpiry',
      width: 150,
      render: (v: string) => {
        if (!v) return <Text type="secondary">—</Text>
        const soon = isExpiringSoon(v)
        return (
          <Space size={4}>
            <CalendarOutlined style={{ color: soon ? '#f59e0b' : '#aaa' }} />
            <Text style={{ color: soon ? '#f59e0b' : undefined, fontSize: 12 }}>
              {dayjs(v).format('YYYY-MM-DD')}
            </Text>
            {soon && (
              <Tooltip title="年检即将到期（30天内）">
                <InfoCircleOutlined style={{ color: '#f59e0b' }} />
              </Tooltip>
            )}
          </Space>
        )
      },
    },
    {
      title: col(<SafetyCertificateOutlined style={{ color: '#10b981' }} />, '状态'),
      dataIndex: 'status',
      width: 120,
      render: (v: number, record: VehicleVO) => {
        const cfg = STATUS_CFG[v]
        if (!cfg) return null
        const menuItems: MenuProps['items'] = Object.entries(STATUS_CFG).map(([k, c]) => ({
          key: k,
          disabled: Number(k) === v,
          label: (
            <Space size={8}>
              <span style={{ color: c.color }}>{c.icon}</span>
              <span>{c.label}</span>
            </Space>
          ),
        }))
        return (
          <PermGuard
            code="vehicle:status"
            fallback={(
              <Tag
                icon={cfg.icon}
                style={{
                  borderRadius: 20, padding: '2px 10px',
                  background: cfg.bg, border: `1px solid ${cfg.color}40`,
                  color: cfg.color, fontWeight: 600,
                  userSelect: 'none',
                }}
              >
                {cfg.label}
              </Tag>
            )}
          >
            <Dropdown
              menu={{ items: menuItems, onClick: ({ key }) => handleStatus(record, Number(key)) }}
              trigger={['click']}
            >
              <Tag
                icon={cfg.icon}
                style={{
                  borderRadius: 20, padding: '2px 10px',
                  background: cfg.bg, border: `1px solid ${cfg.color}40`,
                  color: cfg.color, fontWeight: 600, cursor: 'pointer',
                  userSelect: 'none',
                }}
              >
                {cfg.label} <DownOutlined style={{ fontSize: 9, marginLeft: 2 }} />
              </Tag>
            </Dropdown>
          </PermGuard>
        )
      },
    },
    {
      title: col(<FileTextOutlined style={{ color: '#9ca3af' }} />, '备注'),
      dataIndex: 'remark',
      ellipsis: true,
      render: v => v
        ? <Tooltip title={v}><Text type="secondary" style={{ fontSize: 12 }}><FileTextOutlined style={{ marginRight: 4 }} />{v}</Text></Tooltip>
        : <Text type="secondary" style={{ fontSize: 12 }}>—</Text>,
    },
    {
      title: col(<ClockCircleOutlined style={{ color: '#9ca3af' }} />, '登记日期'),
      dataIndex: 'createTime',
      width: 120,
      render: v => <Text type="secondary" style={{ fontSize: 12 }}>{v ? dayjs(v).format('YYYY-MM-DD') : '—'}</Text>,
    },
    {
      title: col(<SettingOutlined style={{ color: '#9ca3af' }} />, '操作'),
      key: 'action',
      fixed: 'right',
      width: 145,
      render: (_, r) => (
        <Space size={4}>
          <PermGuard code="vehicle:edit">
            <Button size="small" icon={<EditOutlined />}
              style={{ borderRadius: 6, color: '#fa8c16', borderColor: '#ffd591' }}
              onClick={() => openEdit(r)}>编辑</Button>
          </PermGuard>
          <PermGuard code="vehicle:delete">
            <Popconfirm title="确认删除该车辆？" onConfirm={() => handleDelete(r)} okText="删除" cancelText="取消" okButtonProps={{ danger: true }}>
              <Button size="small" danger icon={<DeleteOutlined />} style={{ borderRadius: 6 }}>删除</Button>
            </Popconfirm>
          </PermGuard>
        </Space>
      ),
    },
  ]

  return (
    <div style={{ marginTop: -24 }}>
      <div style={{
        position: 'sticky', top: 64, zIndex: 88,
        marginLeft: -24, marginRight: -24,
        background: 'rgba(255,255,255,0.97)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderBottom: '1px solid rgba(0,0,0,0.07)',
        boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', padding: '10px 24px 0', gap: 12 }}>
          <div style={{
            width: 34, height: 34, borderRadius: 10, background: PAGE_GRADIENT,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 4px 12px rgba(16,185,129,0.35)', flexShrink: 0,
          }}>
            <CarOutlined style={{ color: '#fff', fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1e293b', lineHeight: 1.2 }}>车辆管理</div>
            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>
              {isMerchant ? '商户车辆档案 · 管理本店车辆状态与年检信息' : '管理平台车辆档案 · 实时跟踪车辆状态与年检信息'}
            </div>
          </div>
          <Divider type="vertical" style={{ height: 20, margin: '0 4px', borderColor: '#e0e4ff' }} />
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            {headerStats.map((s, i) => (
              <div key={i} style={{
                display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20,
                background: s.bg, border: `1px solid ${s.border}`,
              }}>
                <span style={{ fontSize: 13 }}>{s.icon}</span>
                <span style={{ fontSize: 12, color: '#6b7280' }}>{s.label}</span>
                <span style={{ fontSize: 13, fontWeight: 700, color: s.color }}>{s.value}</span>
              </div>
            ))}
          </div>
          <div style={{ flex: 1 }} />
          <PermGuard code="vehicle:add">
            <Button type="primary" icon={<PlusOutlined />} onClick={openAdd}
              style={{
                borderRadius: 8, border: 'none',
                background: 'linear-gradient(135deg,#6366f1,#8b5cf6)',
                boxShadow: '0 2px 8px rgba(99,102,241,0.35)',
              }}>
              录入新车辆
            </Button>
          </PermGuard>
        </div>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', padding: '10px 24px 12px' }}>
          <Input
            placeholder="搜索车牌号 / 品牌 / 型号"
            prefix={<SearchOutlined style={{ color: '#10b981' }} />}
            allowClear value={keyword}
            onChange={e => setKeyword(e.target.value)}
            onPressEnter={handleSearch}
            style={{ ...INPUT_STYLE, width: 180 }}
          />
          {!isMerchant && (
            <Select
              placeholder={<span><ShopOutlined style={{ color: '#6366f1', marginRight: 4 }} />所属商户</span>}
              allowClear
              size="middle"
              style={{ width: 160 }}
              value={merchantId}
              onChange={v => { setMerchantId(v); setCurrent(1) }}
              showSearch
              filterOption={(input, opt) =>
                String(opt?.label ?? '').toLowerCase().includes(input.toLowerCase())
              }
              options={merchantOpts}
            />
          )}
          <Select
            placeholder="车辆状态"
            allowClear
            style={{ ...INPUT_STYLE, width: 120 }}
            value={status}
            onChange={v => { setStatus(v); setCurrent(1) }}
          >
            {Object.entries(STATUS_CFG).map(([k, v]) => (
              <Option key={k} value={Number(k)}>
                <Space><span style={{ color: v.color }}>{v.icon}</span>{v.label}</Space>
              </Option>
            ))}
          </Select>
          <Select
            placeholder="座位数"
            allowClear
            style={{ ...INPUT_STYLE, width: 110 }}
            value={seatFilter}
            onChange={v => { setSeat(v); setCurrent(1) }}
          >
            {[4, 5, 6, 7, 8].map(n => <Option key={n} value={n}>{n} 座</Option>)}
          </Select>
          <div style={{ flex: 1 }} />
          <Button icon={<ReloadOutlined />} size="middle" style={{ borderRadius: 8 }} onClick={handleReset}>重置</Button>
          <Tooltip title="刷新列表">
            <Button
              icon={<ReloadOutlined />}
              size="middle"
              loading={loading}
              style={{ borderRadius: 8, color: '#6366f1', borderColor: '#c7d2fe' }}
              onClick={() => loadData()}
            />
          </Tooltip>
          <Button
            type="primary"
            icon={<SearchOutlined />}
            style={{
              borderRadius: 8, border: 'none',
              background: 'linear-gradient(135deg,#6366f1,#8b5cf6)',
              boxShadow: '0 2px 8px rgba(99,102,241,0.35)',
            }}
            onClick={handleSearch}
          >
            搜索
          </Button>
        </div>
      </div>

      <div style={{
        marginLeft: -24, marginRight: -24, marginBottom: -24,
        background: '#fff', borderTop: '1px solid #eef0f8',
      }}>
        <Table
          rowKey="id"
          columns={columns}
          dataSource={data}
          loading={loading}
          components={styledTableComponents}
          scroll={{ x: 'max-content', y: 'calc(100vh - 272px)' }}
          size="middle"
          pagination={false}
          rowClassName={() => 'table-row-hover'}
        />
        <PagePagination
          total={total}
          current={current}
          pageSize={pageSize}
          onChange={setCurrent}
          onSizeChange={setPageSize}
          countLabel="辆车辆"
        />
      </div>

      {/* ── 新增/编辑 Modal ── */}
      <Modal
        title={
          <div style={{
            background: editing
              ? 'linear-gradient(135deg,#667eea,#764ba2)'
              : 'linear-gradient(135deg,#f59e0b,#d97706)',
            margin: '-20px -24px 20px',
            padding: '18px 24px',
            borderRadius: '8px 8px 0 0',
            display: 'flex', alignItems: 'center', gap: 12,
          }}>
            <div style={{
              width: 40, height: 40, borderRadius: 10,
              background: 'rgba(255,255,255,0.2)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <CarOutlined style={{ color: '#fff', fontSize: 20 }} />
            </div>
            <div>
              <div style={{ color: '#fff', fontWeight: 800, fontSize: 16 }}>
                {editing ? `编辑车辆 — ${editing.plateNumber}` : '录入新车辆'}
              </div>
              <div style={{ color: 'rgba(255,255,255,0.8)', fontSize: 12, marginTop: 2 }}>
                {editing ? '修改车辆信息，确保数据准确无误' : '🚗 欢迎新车辆加入车队，驰骋属于你的精彩！'}
              </div>
            </div>
          </div>
        }
        open={drawerOpen}
        onCancel={() => setDrawer(false)}
        onOk={handleSubmit}
        okText="保存"
        cancelText="取消"
        okButtonProps={{ style: { background: 'linear-gradient(135deg,#667eea,#764ba2)', border: 'none', borderRadius: 8 } }}
        cancelButtonProps={{ style: { borderRadius: 8 } }}
        width={880}
        styles={{ body: { maxHeight: 'calc(85vh - 150px)', overflowY: 'auto', overflowX: 'hidden' } }}
        destroyOnHidden
      >
        <Form form={form} layout="vertical" style={{ marginTop: 8 }}>
          <Row gutter={16}>
            <Col span={8}>
              <Form.Item name="plateNumber" label={<><CarOutlined style={{ color: '#667eea' }} /> 车牌号</>}
                rules={[{ required: true, message: '请输入车牌号' }]}>
                <Input placeholder="如：PP-001-A" disabled={!!editing} />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="brand" label="品牌" rules={[{ required: true, message: '请输入品牌' }]}>
                <Select placeholder="选择或输入品牌" showSearch allowClear>
                  {['Toyota', 'Honda', 'Mazda', 'Mitsubishi', 'Hyundai', 'Kia', 'Lexus', '其他'].map(b => (
                    <Option key={b} value={b}>{b}</Option>
                  ))}
                </Select>
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="model" label="型号">
                <Input placeholder="如：Camry 2.5V" />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="color" label="车身颜色">
                <Select placeholder="选择颜色" allowClear>
                  {['珍珠白', '深空黑', '银灰色', '磁性灰', '魂动红', '星云蓝', '橄榄绿', '水晶黑', '晶石白'].map(c => (
                    <Option key={c} value={c}>
                      <Space>
                        <div style={{ width: 12, height: 12, borderRadius: '50%', background: COLOR_MAP[c] ?? '#ccc', border: '1px solid #eee' }} />
                        {c}
                      </Space>
                    </Option>
                  ))}
                </Select>
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="seats" label="座位数">
                <Select>
                  {[4, 5, 6, 7, 8].map(n => <Option key={n} value={n}>{n} 座</Option>)}
                </Select>
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="status" label="车辆状态">
                <Select>
                  {Object.entries(STATUS_CFG).map(([k, v]) => (
                    <Option key={k} value={Number(k)}>
                      <Space><span style={{ color: v.color }}>{v.icon}</span>{v.label}</Space>
                    </Option>
                  ))}
                </Select>
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="inspectionCode" label={<><CarryOutOutlined style={{ color: '#52c41a' }} /> 年检编号</>}>
                <Input placeholder="如：KH2024001" />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="inspectionExpiry" label={<><CalendarOutlined style={{ color: '#1677ff' }} /> 年检有效期</>}>
                <Input placeholder="yyyy-MM-dd" />
              </Form.Item>
            </Col>
          </Row>
          <Form.Item name="remark" label={<><FileTextOutlined style={{ color: '#8b5cf6' }} /> 备注说明</>}>
            <RichTextInput placeholder="车辆用途说明，如：金边主城区运营专用，负责VIP客户接送..." minHeight={110} />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  )
}

const COLOR_MAP: Record<string, string> = {
  珍珠白: '#f0ede8', 深空黑: '#1a1a1a', 银灰色: '#c0c0c0', 磁性灰: '#757575',
  魂动红: '#c1121f', 星云蓝: '#2563eb', 橄榄绿: '#4d7c0f', 水晶黑: '#0f172a',
  晶石白: '#f8fafc', 岩石灰: '#6b7280', 锆沙银: '#94a3b8', 极地白: '#f1f5f9',
}
