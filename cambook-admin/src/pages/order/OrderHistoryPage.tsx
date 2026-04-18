/**
 * 历史订单管理 — 门店订单 + 预约订单 全量记录
 */
import React, { useCallback, useEffect, useRef, useState } from 'react'
import {
  Avatar, Button, DatePicker, Descriptions, Drawer,
  Input, message, Popconfirm, Select, Space, Table, Tag,
  Timeline, Tooltip, Typography,
} from 'antd'
import type { ColumnsType } from 'antd/es/table'
import { useServiceCategories } from '../../hooks/useServiceCategories'
import {
  AppstoreOutlined, CalendarOutlined, CheckCircleOutlined, ClockCircleOutlined,
  CloseCircleOutlined, DownloadOutlined, DollarOutlined, EyeOutlined,
  FileTextOutlined, IdcardOutlined, ReloadOutlined,
  SafetyCertificateOutlined, SearchOutlined, ShopOutlined, StopOutlined,
  TrophyOutlined, UserOutlined, CarOutlined, DeleteOutlined, SettingOutlined,
  TagsOutlined,
} from '@ant-design/icons'
import dayjs from 'dayjs'
import type { OrderVO } from '../../api/api'
import { merchantApi } from '../../api/api'
import { usePortalScope } from '../../hooks/usePortalScope'
import { useDict } from '../../hooks/useDict'
import { col, styledTableComponents, INPUT_STYLE } from '../../components/common/tableComponents'
import PagePagination from '../../components/common/PagePagination'
import PermGuard from '../../components/common/PermGuard'
import { useTableBodyHeight } from '../../hooks/useTableBodyHeight'

const { Text } = Typography
const { RangePicker } = DatePicker

// ── Status map ───────────────────────────────────────────────────────────────

const STATUS_MAP_FB: Record<number, {
  color: string; text: string; icon: React.ReactNode
  badgeStatus: 'default' | 'processing' | 'success' | 'error' | 'warning'
}> = {
  0: { color: 'gold',    text: '待支付', icon: <DollarOutlined />,      badgeStatus: 'warning' },
  1: { color: 'blue',    text: '待接单', icon: <ClockCircleOutlined />,  badgeStatus: 'processing' },
  2: { color: 'cyan',    text: '已接单', icon: <CheckCircleOutlined />,  badgeStatus: 'processing' },
  3: { color: 'orange',  text: '服务中', icon: <CarOutlined />,          badgeStatus: 'processing' },
  4: { color: 'green',   text: '已完成', icon: <CheckCircleOutlined />,  badgeStatus: 'success' },
  5: { color: 'default', text: '已取消', icon: <CloseCircleOutlined />,  badgeStatus: 'default' },
}

// ════════════════════════════════════════════════════════════════════════════════

export default function OrderHistoryPage() {
  const { ref, height: tableBodyH } = useTableBodyHeight(46)
  const { orderList, orderCancel, orderDelete, isMerchant } = usePortalScope()

  const { items: statusItems } = useDict('order_status')
  const STATUS_MAP: Record<number, { color: string; text: string; icon: React.ReactNode; badgeStatus: string }> =
    statusItems.length > 0
      ? Object.fromEntries(statusItems.map(i => [Number(i.dictValue), {
          color: i.remark ?? 'default',
          text: i.labelZh,
          icon: <CheckCircleOutlined />,
          badgeStatus: 'default',
        }]))
      : STATUS_MAP_FB

  // DB service categories for filter
  const { categories: dbServices } = useServiceCategories()

  const [loading, setLoading]     = useState(false)
  const [data, setData]           = useState<OrderVO[]>([])
  const [total, setTotal]         = useState(0)
  const [page, setPage]           = useState(1)
  const [pageSize, setPageSize]   = useState(20)
  const pageSizeRef               = useRef(20)

  // Filters
  const [keyword, setKeyword]           = useState('')
  const [status, setStatus]             = useState<number | undefined>()
  const [dateRange, setDateRange]       = useState<[string, string] | null>(null)
  const [merchantId, setMerchantId]     = useState<number | undefined>()
  const [merchantOpts, setMerchantOpts] = useState<{ value: number; label: string }[]>([])
  const [technicianName, setTechnicianName] = useState('')
  const [serviceItemId, setServiceItemId]   = useState<number | undefined>()

  // Detail drawer
  const [detail, setDetail]       = useState<OrderVO | null>(null)
  const [drawerOpen, setDrawerOpen] = useState(false)

  // Admin: load merchant options
  useEffect(() => {
    if (!isMerchant) {
      merchantApi.list({ page: 1, size: 200 }).then(res => {
        const list = res.data?.data?.list ?? res.data?.data?.records ?? []
        setMerchantOpts(list.map((m: any) => ({
          value: m.id,
          label: m.merchantNameZh || m.merchantNameEn || `#${m.id}`,
        })))
      }).catch(() => {})
    }
  }, [isMerchant])

  const fetchList = useCallback(async (pg = page) => {
    setLoading(true)
    try {
      const serviceName = serviceItemId
        ? dbServices.find(s => s.id === serviceItemId)?.nameZh
        : undefined
      const res = await orderList({
        page: pg, size: pageSizeRef.current, status,
        keyword, startDate: dateRange?.[0], endDate: dateRange?.[1],
        ...(merchantId     != null ? { merchantId }                   : {}),
        ...(technicianName ? { technicianName }                       : {}),
        ...(serviceName    ? { serviceName }                          : {}),
      })
      const d = res.data?.data
      if (d?.list != null) {
        setData(d.list)
        setTotal(d.total ?? d.list.length)
      } else if (d?.list != null) {
        setData(d.list)
        setTotal(d.total ?? d.list.length)
      } else {
        setData([])
        setTotal(0)
      }
    } catch {
      setData([])
      setTotal(0)
    } finally {
      setLoading(false)
    }
  }, [page, keyword, status, dateRange, merchantId, technicianName, serviceItemId])

  useEffect(() => { fetchList() }, [fetchList])

  // ── Actions ────────────────────────────────────────────────────────────────

  const handleCancel = async (r: OrderVO) => {
    try {
      await orderCancel(r.id)
      message.success('订单已取消')
      fetchList()
    } catch { /**/ }
  }

  const handleDelete = async (r: OrderVO) => {
    try {
      await orderDelete(r.id)
      message.success('订单已删除')
      fetchList()
    } catch { /**/ }
  }

  const handleReset = () => {
    setKeyword(''); setStatus(undefined); setDateRange(null)
    setMerchantId(undefined); setTechnicianName(''); setServiceItemId(undefined)
    setPage(1); setTimeout(() => fetchList(1), 0)
  }

  const exportCSV = () => {
    const rows = data.map(r => [
      r.orderNo, r.memberNickname, (r as any).memberMobile,
      r.technicianNickname, r.serviceName,
      STATUS_MAP[r.status]?.text ?? r.status,
      r.payAmount, r.createTime, (r as any).finishTime ?? '',
    ])
    const header = ['订单号', '客户', '手机号', '技师', '服务项目', '状态', '实付金额', '下单时间', '完成时间']
    const csv = [header, ...rows].map(row => row.join(',')).join('\n')
    const blob = new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8;' })
    const a = document.createElement('a')
    a.href = URL.createObjectURL(blob)
    a.download = `历史订单_${dayjs().format('YYYYMMDD')}.csv`
    a.click()
    message.success('导出成功')
  }

  // ── Summary stats from current page data ──────────────────────────────────

  const completedCount = data.filter(r => r.status === 4).length
  const servingCount   = data.filter(r => r.status === 3).length
  const totalRevenue   = data.filter(r => r.status === 4).reduce((s, r) => s + Number(r.payAmount ?? 0), 0)

  const stats = [
    { label: '订单总数', value: total,           color: '#6366f1', bg: '#eef2ff',  border: '#c7d2fe' },
    { label: '服务中',   value: servingCount,    color: '#f97316', bg: '#fff7ed',  border: '#fed7aa' },
    { label: '已完成',   value: completedCount,  color: '#10b981', bg: '#ecfdf5',  border: '#a7f3d0' },
    { label: '本页营收', value: `$${totalRevenue.toFixed(0)}`, color: '#f59e0b', bg: '#fffbeb', border: '#fde68a' },
  ]

  // ── Columns ────────────────────────────────────────────────────────────────

  const columns: ColumnsType<OrderVO> = [
    {
      title: col(<FileTextOutlined style={{ color: '#6366f1' }} />, '订单号', 'left'),
      dataIndex: 'orderNo', width: 180, align: 'left', fixed: 'left',
      render: (v: string) => (
        <span style={{ fontFamily: 'monospace', fontSize: 11, color: '#6366f1', fontWeight: 700 }}>{v}</span>
      ),
    },
    {
      title: col(<UserOutlined style={{ color: '#f97316' }} />, '客户信息', 'left'),
      dataIndex: 'memberNickname', width: 150, align: 'left',
      render: (v: string, r: any) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <Avatar size={30} icon={<UserOutlined />}
            style={{ background: 'linear-gradient(135deg,#f97316,#fb923c)', flexShrink: 0 }} />
          <div style={{ minWidth: 0 }}>
            <div style={{ fontSize: 13, fontWeight: 600, whiteSpace: 'nowrap' }}>{v || '—'}</div>
            {r.memberMobile && (
              <div style={{ fontSize: 11, color: '#94a3b8', whiteSpace: 'nowrap' }}>{r.memberMobile}</div>
            )}
          </div>
        </div>
      ),
    },
    {
      title: col(<IdcardOutlined style={{ color: '#8b5cf6' }} />, '服务技师', 'left'),
      dataIndex: 'technicianNickname', width: 130, align: 'left',
      render: (v: string) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <Avatar size={30} icon={<IdcardOutlined />}
            style={{ background: 'linear-gradient(135deg,#6366f1,#8b5cf6)', flexShrink: 0 }} />
          <Text style={{ fontSize: 13 }}>{v || '未分配'}</Text>
        </div>
      ),
    },
    {
      title: col(<AppstoreOutlined style={{ color: '#0ea5e9' }} />, '服务项目', 'left'),
      dataIndex: 'serviceName', ellipsis: true, align: 'left',
      render: (v: string) => (
        <Tooltip title={v}>
          <Text style={{ fontSize: 13 }}>{v || '—'}</Text>
        </Tooltip>
      ),
    },
    {
      title: col(<DollarOutlined style={{ color: '#f59e0b' }} />, '实付金额', 'center'),
      dataIndex: 'payAmount', width: 110, align: 'center',
      sorter: (a, b) => Number(a.payAmount ?? 0) - Number(b.payAmount ?? 0),
      render: (v: number) => (
        <span style={{ fontSize: 14, fontWeight: 800, color: '#f59e0b' }}>
          ${v != null ? Number(v).toFixed(2) : '—'}
        </span>
      ),
    },
    {
      title: col(<SafetyCertificateOutlined style={{ color: '#10b981' }} />, '状态', 'center'),
      dataIndex: 'status', width: 100, align: 'center',
      render: (v: number) => {
        const s = STATUS_MAP[v] ?? STATUS_MAP[1]
        return <Tag color={s.color} style={{ borderRadius: 8, fontWeight: 600, border: 'none', margin: 0 }}>{s.text}</Tag>
      },
    },
    {
      title: col(<ClockCircleOutlined style={{ color: '#64748b' }} />, '下单时间', 'center'),
      dataIndex: 'createTime', width: 135, align: 'center',
      render: (v: string) => (
        <Text type="secondary" style={{ fontSize: 12 }}>
          {v ? dayjs(v).format('MM-DD HH:mm') : '—'}
        </Text>
      ),
    },
    {
      title: col(<CalendarOutlined style={{ color: '#10b981' }} />, '完成时间', 'center'),
      dataIndex: 'finishTime', width: 135, align: 'center',
      render: (v: string) => (
        <Text type="secondary" style={{ fontSize: 12 }}>
          {v ? dayjs(v).format('MM-DD HH:mm') : '—'}
        </Text>
      ),
    },
    ...(!isMerchant ? [{
      title: col(<ShopOutlined style={{ color: '#a78bfa' }} />, '所属商户', 'center'),
      dataIndex: 'merchantName' as keyof OrderVO, width: 130, align: 'center' as const,
      render: (v: string) => v ? <Tag color="purple" icon={<ShopOutlined />}>{v}</Tag> : '—',
    }] : []),
    {
      title: col(<SettingOutlined style={{ color: '#64748b' }} />, '操作', 'center'),
      key: 'action', fixed: 'right', width: 150,
      render: (_, r) => (
        <Space size={4}>
          <Button size="small" type="primary" ghost icon={<EyeOutlined />}
            style={{ borderRadius: 6 }}
            onClick={() => { setDetail(r); setDrawerOpen(true) }}>
            详情
          </Button>
          {[0, 1, 2].includes(r.status) && (
            <PermGuard code="order:cancel">
              <Popconfirm title="确认取消该订单？" onConfirm={() => handleCancel(r)}
                okText="取消订单" cancelText="返回" okButtonProps={{ danger: true }}>
                <Button size="small" icon={<StopOutlined />} danger style={{ borderRadius: 6 }}>
                  取消
                </Button>
              </Popconfirm>
            </PermGuard>
          )}
          {r.status === 5 && (
            <PermGuard code="order:delete">
              <Popconfirm title="确认删除该订单？此操作不可恢复" onConfirm={() => handleDelete(r)}
                okText="删除" cancelText="返回" okButtonProps={{ danger: true }}>
                <Button size="small" icon={<DeleteOutlined />} danger ghost style={{ borderRadius: 6 }}>
                  删除
                </Button>
              </Popconfirm>
            </PermGuard>
          )}
        </Space>
      ),
    },
  ]

  // ── Render ────────────────────────────────────────────────────────────────

  return (
    <div style={{ marginTop: -24 }}>

      {/* ── 粘性复合头部 ───────────────────────────────────────────────────── */}
      <div style={{
        position: 'sticky', top: 64, zIndex: 88,
        marginLeft: -24, marginRight: -24,
        background: 'rgba(255,255,255,0.97)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderBottom: '1px solid rgba(0,0,0,0.07)',
        boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
      }}>
        {/* 标题行 */}
        <div style={{ display: 'flex', alignItems: 'center', padding: '10px 24px 0', gap: 16, flexWrap: 'wrap' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, flex: '0 0 auto' }}>
            <div style={{
              width: 34, height: 34, borderRadius: 10,
              background: 'linear-gradient(135deg,#6366f1,#8b5cf6)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: '0 4px 12px rgba(99,102,241,0.35)', flexShrink: 0,
            }}>
              <FileTextOutlined style={{ color: '#fff', fontSize: 16 }} />
            </div>
            <div>
              <div style={{ fontWeight: 700, fontSize: 15, color: '#111827', lineHeight: 1.2 }}>历史订单</div>
              <div style={{ fontSize: 11, color: '#9ca3af', lineHeight: 1.3, marginTop: 1 }}>全量订单记录 · 多维度筛选 · 一键导出</div>
            </div>
          </div>

          <div style={{ width: 1, height: 28, background: '#e5e7eb', flexShrink: 0 }} />

          {/* 统计标签 */}
          <div style={{ display: 'flex', gap: 8, flex: 1, flexWrap: 'wrap', alignItems: 'center' }}>
            {stats.map(s => (
              <div key={s.label} style={{
                display: 'flex', alignItems: 'center', gap: 6,
                padding: '5px 12px', borderRadius: 20,
                background: s.bg, border: `1px solid ${s.border}`,
              }}>
                <span style={{ color: s.color, fontWeight: 800, fontSize: 13, lineHeight: 1 }}>{s.value}</span>
                <span style={{ color: s.color, fontSize: 11, opacity: 0.8 }}>{s.label}</span>
              </div>
            ))}
          </div>

          {/* 操作按钮 */}
          <div style={{ display: 'flex', gap: 8, flexShrink: 0 }}>
            <Button icon={<DownloadOutlined />} onClick={exportCSV} style={{ borderRadius: 8 }}>导出</Button>
            <Button icon={<ReloadOutlined />} onClick={() => fetchList()} style={{ borderRadius: 8 }}>刷新</Button>
          </div>
        </div>

        {/* 筛选行 */}
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', padding: '10px 24px 12px' }}>
          <Input
            prefix={<SearchOutlined style={{ color: '#6366f1', fontSize: 12 }} />}
            placeholder="订单号 / 客户昵称 / 手机号"
            value={keyword}
            onChange={e => setKeyword(e.target.value)}
            onPressEnter={() => { setPage(1); fetchList(1) }}
            style={{ ...INPUT_STYLE, width: 220 }}
            allowClear
          />
          <Select
            allowClear
            style={{ width: 130 }}
            value={status}
            onChange={v => { setStatus(v); setPage(1) }}
            placeholder={
              <Space size={4}>
                <SafetyCertificateOutlined style={{ color: '#10b981', fontSize: 12 }} />
                订单状态
              </Space>
            }
            options={Object.entries(STATUS_MAP).map(([k, v]) => ({ value: +k, label: v.text }))}
          />
          <Input
            prefix={<IdcardOutlined style={{ color: '#8b5cf6', fontSize: 12 }} />}
            placeholder="技师姓名"
            value={technicianName}
            onChange={e => setTechnicianName(e.target.value)}
            onPressEnter={() => { setPage(1); fetchList(1) }}
            style={{ ...INPUT_STYLE, width: 130 }}
            allowClear
          />
          <Select
            allowClear showSearch
            style={{ width: 150 }}
            value={serviceItemId}
            onChange={v => { setServiceItemId(v); setPage(1) }}
            placeholder={
              <Space size={4}>
                <TagsOutlined style={{ color: '#f97316', fontSize: 12 }} />
                服务项目
              </Space>
            }
            filterOption={(input, opt) =>
              (opt?.label as string ?? '').toLowerCase().includes(input.toLowerCase())
            }
            options={dbServices.map(s => ({
              value: s.id,
              label: s.nameZh,
              icon: s.icon,
            }))}
            optionRender={opt => (
              <Space size={6}>
                <span>{(opt.data as any).icon}</span>
                <span>{opt.label}</span>
              </Space>
            )}
          />
          <RangePicker
            style={{ width: 240 }}
            onChange={(_, strs) => {
              setDateRange(strs[0] && strs[1] ? [strs[0], strs[1]] : null)
              setPage(1)
            }}
          />
          {!isMerchant && (
            <Select
              allowClear showSearch style={{ width: 150 }} value={merchantId}
              onChange={v => { setMerchantId(v); setPage(1) }}
              placeholder={
                <Space size={4}>
                  <ShopOutlined style={{ color: '#a78bfa', fontSize: 12 }} />
                  所属商户
                </Space>
              }
              filterOption={(input, opt) =>
                (opt?.label as string ?? '').toLowerCase().includes(input.toLowerCase())
              }
              options={merchantOpts}
            />
          )}
          <Button icon={<ReloadOutlined />} style={{ borderRadius: 8 }} onClick={handleReset}>重置</Button>
        </div>
      </div>

      {/* ── 数据表格 ───────────────────────────────────────────────────────── */}
      <div ref={ref} style={{
        marginLeft: -24, marginRight: -24, marginBottom: -24,
        background: '#fff', borderTop: '1px solid #eef0f8',
      }}>
        <Table<OrderVO>
          components={styledTableComponents}
          rowKey="id"
          size="middle"
          loading={loading}
          columns={columns}
          dataSource={data}
          scroll={{ x: 1200, y: tableBodyH }}
          pagination={false}
        />
        <PagePagination
          total={total} current={page} pageSize={pageSize}
          onChange={p => { setPage(p); fetchList(p) }}
          onSizeChange={ps => { pageSizeRef.current = ps; setPageSize(ps); setPage(1); fetchList(1) }}
        />
      </div>

      {/* ── 订单详情抽屉 ───────────────────────────────────────────────────── */}
      <Drawer
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        styles={{ wrapper: { width: 660 } }}
        title={
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{
              width: 32, height: 32, borderRadius: 8,
              background: 'linear-gradient(135deg,#6366f1,#8b5cf6)',
              display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
            }}>
              <FileTextOutlined style={{ color: '#fff', fontSize: 14 }} />
            </div>
            <div>
              <div style={{ fontWeight: 700, fontSize: 14, color: '#111827' }}>订单详情</div>
              {detail && (
                <div style={{ fontSize: 11, color: '#94a3b8', fontFamily: 'monospace', marginTop: 1 }}>
                  {detail.orderNo}
                </div>
              )}
            </div>
            {detail && (
              <Tag color={STATUS_MAP[detail.status]?.color ?? 'default'}
                style={{ marginLeft: 8, borderRadius: 8, fontWeight: 600, border: 'none', fontSize: 12 }}>
                {STATUS_MAP[detail.status]?.text}
              </Tag>
            )}
          </div>
        }
      >
        {detail && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>

            {/* 金额高亮卡片 */}
            <div style={{
              borderRadius: 14, padding: '18px 22px',
              background: detail.status === 4
                ? 'linear-gradient(135deg,#ecfdf5,#d1fae5)'
                : 'linear-gradient(135deg,#f8fafc,#f1f5f9)',
              border: detail.status === 4 ? '1px solid #a7f3d0' : '1px solid #e2e8f0',
            }}>
              <div style={{ fontSize: 11, color: '#6b7280', marginBottom: 4 }}>实付金额</div>
              <div style={{
                fontSize: 32, fontWeight: 900, lineHeight: 1,
                color: detail.status === 4 ? '#059669' : '#94a3b8',
              }}>
                ${Number(detail.payAmount ?? 0).toFixed(2)}
              </div>
              <div style={{ fontSize: 12, color: '#9ca3af', marginTop: 6 }}>{detail.serviceName}</div>
            </div>

            {/* 客户 + 技师 */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
              <div style={{
                borderRadius: 12, padding: '14px 16px',
                background: 'linear-gradient(135deg,#fff7ed,#ffedd5)',
                border: '1px solid #fed7aa',
              }}>
                <div style={{ fontSize: 11, color: '#92400e', marginBottom: 8, fontWeight: 600 }}>
                  <UserOutlined style={{ marginRight: 4 }} />客户
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                  <Avatar size={36} icon={<UserOutlined />}
                    style={{ background: 'linear-gradient(135deg,#f97316,#fb923c)', flexShrink: 0 }} />
                  <div>
                    <div style={{ fontWeight: 700, fontSize: 13 }}>{detail.memberNickname || '—'}</div>
                    <div style={{ fontSize: 11, color: '#78716c' }}>{(detail as any).memberMobile || '未留电话'}</div>
                  </div>
                </div>
              </div>
              <div style={{
                borderRadius: 12, padding: '14px 16px',
                background: 'linear-gradient(135deg,#eef2ff,#e0e7ff)',
                border: '1px solid #c7d2fe',
              }}>
                <div style={{ fontSize: 11, color: '#3730a3', marginBottom: 8, fontWeight: 600 }}>
                  <IdcardOutlined style={{ marginRight: 4 }} />技师
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                  <Avatar size={36} icon={<IdcardOutlined />}
                    style={{ background: 'linear-gradient(135deg,#6366f1,#8b5cf6)', flexShrink: 0 }} />
                  <div>
                    <div style={{ fontWeight: 700, fontSize: 13 }}>{detail.technicianNickname || '未分配'}</div>
                    <div style={{ fontSize: 11, color: '#6366f1' }}>{(detail as any).merchantName ?? ''}</div>
                  </div>
                </div>
              </div>
            </div>

            {/* 订单基础信息 */}
            <Descriptions size="small" column={2} bordered labelStyle={{ fontSize: 12, whiteSpace: 'nowrap' }}>
              <Descriptions.Item label="订单号" span={2}>
                <span style={{ fontFamily: 'monospace', color: '#6366f1', fontSize: 11 }}>{detail.orderNo}</span>
              </Descriptions.Item>
              <Descriptions.Item label="服务项目" span={2}>
                <Tag color="blue" style={{ borderRadius: 6 }}>{detail.serviceName}</Tag>
              </Descriptions.Item>
              <Descriptions.Item label="下单时间">
                {detail.createTime ? dayjs(detail.createTime).format('YYYY-MM-DD HH:mm') : '—'}
              </Descriptions.Item>
              <Descriptions.Item label="完成时间">
                {(detail as any).finishTime ? dayjs((detail as any).finishTime).format('YYYY-MM-DD HH:mm') : '—'}
              </Descriptions.Item>
              {(detail as any).remark && (
                <Descriptions.Item label="备注" span={2}>
                  <Text type="secondary">{(detail as any).remark}</Text>
                </Descriptions.Item>
              )}
            </Descriptions>

            {/* 时间轴 */}
            <div>
              <div style={{ fontWeight: 700, fontSize: 13, marginBottom: 12, color: '#374151' }}>
                <ClockCircleOutlined style={{ marginRight: 6, color: '#6366f1' }} />订单时间轴
              </div>
              <Timeline
                items={[
                  {
                    color: 'blue',
                    dot: <DollarOutlined style={{ fontSize: 14 }} />,
                    children: (
                      <div>
                        <div style={{ fontWeight: 600 }}>订单创建</div>
                        <div style={{ fontSize: 12, color: '#94a3b8' }}>
                          {detail.createTime ? dayjs(detail.createTime).format('YYYY-MM-DD HH:mm:ss') : '—'}
                        </div>
                      </div>
                    ),
                  },
                  ...(detail.status >= 2 ? [{
                    color: 'cyan',
                    dot: <CheckCircleOutlined style={{ fontSize: 14 }} />,
                    children: (
                      <div>
                        <div style={{ fontWeight: 600 }}>已接单 · 技师确认</div>
                        <div style={{ fontSize: 12, color: '#94a3b8' }}>技师 {detail.technicianNickname}</div>
                      </div>
                    ),
                  }] : []),
                  ...(detail.status >= 3 ? [{
                    color: 'orange',
                    dot: <CarOutlined style={{ fontSize: 14 }} />,
                    children: (
                      <div>
                        <div style={{ fontWeight: 600 }}>服务开始</div>
                        <div style={{ fontSize: 12, color: '#94a3b8' }}>服务进行中</div>
                      </div>
                    ),
                  }] : []),
                  ...(detail.status === 4 ? [{
                    color: 'green',
                    dot: <TrophyOutlined style={{ fontSize: 14 }} />,
                    children: (
                      <div>
                        <div style={{ fontWeight: 700, color: '#10b981' }}>服务完成 ✓</div>
                        <div style={{ fontSize: 12, color: '#94a3b8' }}>
                          {(detail as any).finishTime
                            ? dayjs((detail as any).finishTime).format('YYYY-MM-DD HH:mm:ss') : '—'}
                        </div>
                      </div>
                    ),
                  }] : []),
                  ...(detail.status === 5 ? [{
                    color: 'red',
                    dot: <CloseCircleOutlined style={{ fontSize: 14 }} />,
                    children: (
                      <div>
                        <div style={{ fontWeight: 600, color: '#ef4444' }}>订单取消</div>
                        <div style={{ fontSize: 12, color: '#94a3b8' }}>已取消</div>
                      </div>
                    ),
                  }] : []),
                ]}
              />
            </div>

            {/* 快捷操作 */}
            {[0, 1, 2].includes(detail.status) && (
              <Popconfirm title="确认取消该订单？"
                onConfirm={() => { handleCancel(detail); setDrawerOpen(false) }}
                okText="取消订单" cancelText="返回" okButtonProps={{ danger: true }}>
                <Button danger block icon={<StopOutlined />} style={{ borderRadius: 8 }}>取消订单</Button>
              </Popconfirm>
            )}
          </div>
        )}
      </Drawer>
    </div>
  )
}
