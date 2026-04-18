import { useState, useEffect } from 'react'
import {
  Row, Col, Table, Input, Select, Space, Tag, Button,
  Typography, message, Modal, Form, Tooltip, Popconfirm, Dropdown,
  Divider, Upload,
} from 'antd'
import type { ColumnsType } from 'antd/es/table'
import type { MenuProps } from 'antd'
import type { UploadFile, UploadProps } from 'antd'
import {
  CarOutlined, CarFilled, PlusOutlined, EditOutlined, DeleteOutlined,
  SearchOutlined, ReloadOutlined, ShopOutlined,
  ToolOutlined, InfoCircleOutlined, CarryOutOutlined, CalendarOutlined,
  FileTextOutlined, DownOutlined, TagOutlined, BgColorsOutlined,
  SafetyCertificateOutlined, ClockCircleOutlined, SettingOutlined,
  PictureOutlined,
} from '@ant-design/icons'
import dayjs from 'dayjs'
import { usePortalScope } from '../../hooks/usePortalScope'
import { useDict } from '../../hooks/useDict'
import { merchantApi, uploadApi } from '../../api/api'
import RichTextInput from '../../components/common/RichTextInput'
import PagePagination from '../../components/common/PagePagination'
import { col, INPUT_STYLE, styledTableComponents } from '../../components/common/tableComponents'
import PermGuard from '../../components/common/PermGuard'
import ImageLightbox from '../../components/common/ImageLightbox'
import { useTableBodyHeight } from '../../hooks/useTableBodyHeight'

const { Text } = Typography
const { Option } = Select

interface VehicleVO {
  id: number
  plateNumber: string
  brand: string
  model: string
  color: string
  seats?: number
  inspectionCode?: string
  inspectionExpiry?: string
  photo?: string
  photos?: string
  status: number
  remark?: string
  createTime: string
}

/** 颜色兜底列表（字典未加载时使用） */
const COLOR_FALLBACK: { label: string; hex: string }[] = [
  { label: '珍珠白', hex: '#f0ede8' },
  { label: '深空黑', hex: '#1a1a1a' },
  { label: '银灰色', hex: '#c0c0c0' },
  { label: '磁性灰', hex: '#757575' },
  { label: '魂动红', hex: '#c1121f' },
  { label: '星云蓝', hex: '#2563eb' },
  { label: '橄榄绿', hex: '#4d7c0f' },
  { label: '水晶黑', hex: '#0f172a' },
  { label: '晶石白', hex: '#f8fafc' },
  { label: '岩石灰', hex: '#6b7280' },
  { label: '锆沙银', hex: '#94a3b8' },
  { label: '极地白', hex: '#f1f5f9' },
  { label: '香槟金', hex: '#c5a028' },
]

function parsePhotos(photos: string | undefined | null): string[] {
  if (!photos) return []
  try {
    const raw = String(photos).trim()
    if (raw.startsWith('[')) return JSON.parse(raw).filter(Boolean)
    return raw.split(',').map(s => s.trim()).filter(Boolean)
  } catch { return [] }
}

const STATUS_CFG_FALLBACK: Record<number, { label: string; color: string; icon: React.ReactNode; bg: string }> = {
  0: { label: '空闲中', color: '#10b981', icon: <CarOutlined />, bg: '#ecfdf5' },
  1: { label: '使用中', color: '#3b82f6', icon: <CarFilled />, bg: '#eff6ff' },
  2: { label: '维修中', color: '#f59e0b', icon: <ToolOutlined />, bg: '#fffbeb' },
}
const VEHICLE_STATUS_ICONS: React.ReactNode[] = [<CarOutlined />, <CarFilled />, <ToolOutlined />]


const PAGE_GRADIENT = 'linear-gradient(135deg,#10b981,#059669)'

export default function VehicleListPage() {
  const { ref, height: tableBodyH } = useTableBodyHeight()
  const { isMerchant, vehicleList, vehicleAdd, vehicleEdit, vehicleDelete, vehicleStatus } = usePortalScope()
  const { items: brandItems } = useDict('vehicle_brand')
  const { items: colorItems } = useDict('vehicle_color')
  const { items: vsItems }    = useDict('vehicle_status')

  /** 根据状态码获取 label/color/bg，优先字典，兜底静态配置 */
  function statusCfg(v: number) {
    const item = vsItems.find(i => i.dictValue === String(v))
    if (item) {
      const color = item.remark ?? '#94a3b8'
      const antColors: Record<string, string> = { green: '#10b981', blue: '#3b82f6', orange: '#f59e0b', red: '#ef4444' }
      const hex = color.startsWith('#') ? color : (antColors[color] ?? '#94a3b8')
      return { label: item.labelZh, color: hex, icon: VEHICLE_STATUS_ICONS[v] ?? <CarOutlined />, bg: `${hex}18` }
    }
    return STATUS_CFG_FALLBACK[v] ?? { label: String(v), color: '#94a3b8', icon: <CarOutlined />, bg: '#f5f5f5' }
  }
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
  const [photoList, setPhotoList]     = useState<UploadFile[]>([])
  const [lbOpen, setLbOpen]           = useState(false)
  const [lbIdx, setLbIdx]             = useState(0)
  const [lbUrls, setLbUrls]           = useState<string[]>([])

  useEffect(() => {
    if (!isMerchant) {
      merchantApi.list({ page: 1, size: 200 }).then(res => {
        const list = res.data?.data?.list ?? res.data?.data?.records ?? []
        setMerchantOpts(list.map((m: any) => ({ value: m.id, label: m.merchantNameZh || m.merchantNameEn || `商户#${m.id}` })))
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

  const handlePhotoUpload: UploadProps['customRequest'] = async ({ file, onSuccess, onError }) => {
    try {
      const res = await uploadApi.image(file as File)
      const url: string = res.data?.data?.url ?? res.data?.data
      ;(onSuccess as any)?.({ url })
    } catch (e) {
      ;(onError as any)?.(e)
      message.error('图片上传失败')
    }
  }

  const openAdd = () => {
    setEditing(null)
    form.resetFields()
    form.setFieldsValue({ status: 0, seats: 5 })
    setPhotoList([])
    setDrawer(true)
  }

  const openEdit = (r: VehicleVO) => {
    setEditing(r)
    form.setFieldsValue({ ...r })
    const existingPhotos = parsePhotos(r.photos)
    setPhotoList(existingPhotos.map((url, i) => ({
      uid: `-${i}`,
      name: `photo-${i}`,
      status: 'done' as const,
      url,
      response: { url },
    })))
    setDrawer(true)
  }

  const handleSubmit = async () => {
    const values = await form.validateFields()
    const photoUrls = photoList
      .filter(f => f.status === 'done' && (f.response?.url || f.url))
      .map(f => f.response?.url || f.url)
    const photosJson = photoUrls.length ? JSON.stringify(photoUrls) : undefined
    try {
      if (editing) {
        await vehicleEdit({ ...values, id: editing.id, photos: photosJson })
        message.success('车辆信息已更新')
      } else {
        await vehicleAdd({ ...values, photos: photosJson })
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
    message.success(`已切换为「${statusCfg(next)?.label}」`)
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
      title: col(<CarOutlined style={{ color: '#10b981' }} />, '品牌/型号', 'left'),
      key: 'brand',
      width: 160,
      render: (_, r) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, width: '100%' }}>
          <div style={{
            width: 36, height: 36, borderRadius: 8, flexShrink: 0,
            background: `${brandItems.find(b => b.dictValue === r.brand)?.remark ?? '#667eea'}18`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <Text style={{ color: brandItems.find(b => b.dictValue === r.brand)?.remark ?? '#667eea', fontWeight: 700, fontSize: 12 }}>
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
      title: col(<PictureOutlined style={{ color: '#6366f1' }} />, '车辆图片'),
      key: 'photos',
      width: 90,
      render: (_, r) => {
        const firstPhoto = parsePhotos(r.photos)[0]
        return firstPhoto ? (
          <img
            src={firstPhoto}
            alt="vehicle"
            onClick={() => {
              const urls = parsePhotos(r.photos)
              if (urls.length) { setLbUrls(urls); setLbIdx(0); setLbOpen(true) }
            }}
            style={{
              width: 56, height: 42,
              objectFit: 'cover',
              borderRadius: 7,
              cursor: 'pointer',
              border: '1.5px solid #e5e7eb',
              boxShadow: '0 1px 4px rgba(0,0,0,0.10)',
              transition: 'transform 0.18s',
            }}
            onMouseEnter={e => (e.currentTarget.style.transform = 'scale(1.08)')}
            onMouseLeave={e => (e.currentTarget.style.transform = 'scale(1)')}
          />
        ) : (
          <div style={{
            width: 56, height: 42, borderRadius: 7,
            background: '#f3f4f6',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            border: '1.5px dashed #d1d5db',
          }}>
            <CarOutlined style={{ color: '#9ca3af', fontSize: 18 }} />
          </div>
        )
      },
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
              background: colorItems.find(c => c.labelZh === r.color)?.remark
                ?? COLOR_FALLBACK.find(c => c.label === r.color)?.hex
                ?? '#ccc',
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
        const cfg = statusCfg(v)
        const allStatuses = vsItems.length > 0
          ? vsItems.map(i => ({ v: Number(i.dictValue), cfg: statusCfg(Number(i.dictValue)) }))
          : Object.entries(STATUS_CFG_FALLBACK).map(([k, c]) => ({ v: Number(k), cfg: c }))
        const menuItems: MenuProps['items'] = allStatuses.map(({ v: k, cfg: c }) => ({
          key: String(k),
          disabled: k === v,
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
          <div style={{ width: 1, height: 20, margin: '0 4px', background: '#e0e4ff', flexShrink: 0 }} />
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
            {(vsItems.length > 0 ? vsItems.map(i => ({ k: i.dictValue, cfg: statusCfg(Number(i.dictValue)) })) : Object.entries(STATUS_CFG_FALLBACK).map(([k, c]) => ({ k, cfg: c }))).map(({ k, cfg }) => (
              <Option key={k} value={Number(k)}>
                <Space><span style={{ color: cfg.color }}>{cfg.icon}</span>{cfg.label}</Space>
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

      <div ref={ref} style={{
        marginLeft: -24, marginRight: -24, marginBottom: -24,
        background: '#fff', borderTop: '1px solid #eef0f8',
      }}>
        <Table
          rowKey="id"
          columns={columns}
          dataSource={data}
          loading={loading}
          components={styledTableComponents}
          scroll={{ x: 'max-content', y: tableBodyH }}
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
                <Select placeholder="选择或输入品牌" showSearch allowClear
                  options={brandItems.length > 0
                    ? brandItems.filter(b => b.status === 1).map(b => ({ value: b.dictValue, label: b.labelZh }))
                    : ['Toyota','Honda','Hyundai','Kia','Lexus','BMW','Mercedes','Mazda','Nissan','Audi','Ford','Suzuki','Other'].map(v => ({ value: v, label: v }))} />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="model" label="型号">
                <Input placeholder="如：Camry 2.5V" />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="color" label="车身颜色">
                <Select placeholder="选择颜色" allowClear
                  optionRender={option => {
                    const hex = colorItems.find(c => c.labelZh === option.label)?.remark
                      ?? COLOR_FALLBACK.find(c => c.label === option.label)?.hex
                      ?? '#ccc'
                    return (
                      <Space>
                        <div style={{ width: 12, height: 12, borderRadius: '50%', background: hex, border: '1px solid #eee' }} />
                        {option.label}
                      </Space>
                    )
                  }}
                  options={
                    colorItems.length > 0
                      ? colorItems.filter(c => c.status === 1).map(c => ({ value: c.labelZh, label: c.labelZh }))
                      : COLOR_FALLBACK.map(c => ({ value: c.label, label: c.label }))
                  }
                />
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
                  {(vsItems.length > 0 ? vsItems.map(i => ({ k: i.dictValue, cfg: statusCfg(Number(i.dictValue)) })) : Object.entries(STATUS_CFG_FALLBACK).map(([k, c]) => ({ k, cfg: c }))).map(({ k, cfg }) => (
                    <Option key={k} value={Number(k)}>
                      <Space><span style={{ color: cfg.color }}>{cfg.icon}</span>{cfg.label}</Space>
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
          <Divider style={{ margin: '4px 0 16px' }} />
          <Form.Item label={<><PictureOutlined style={{ color: '#6366f1' }} /> 车辆图片（最多 9 张）</>}>
            <Upload
              listType="picture-card"
              fileList={photoList}
              customRequest={handlePhotoUpload}
              onChange={({ fileList }) => setPhotoList(fileList)}
              accept="image/*"
              maxCount={9}
              multiple
            >
              {photoList.length < 9 && (
                <div>
                  <PlusOutlined style={{ color: '#6366f1' }} />
                  <div style={{ marginTop: 4, fontSize: 12, color: '#6366f1' }}>上传图片</div>
                </div>
              )}
            </Upload>
          </Form.Item>
        </Form>
      </Modal>

      {/* 图片灯箱 */}
      <ImageLightbox
        images={lbUrls}
        current={lbIdx}
        open={lbOpen}
        onClose={() => setLbOpen(false)}
        onChange={setLbIdx}
      />
    </div>
  )
}


