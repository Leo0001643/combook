import { useState, useEffect, useCallback, useRef } from 'react'
import {
  Table, Input, Select, Tag, Avatar, Space, Button,
  Typography, Drawer, Descriptions, Timeline, DatePicker,
  Popconfirm, message, Divider, Tooltip,
} from 'antd'
import {
  SearchOutlined, ClockCircleOutlined, CheckCircleOutlined,
  CloseCircleOutlined, CarOutlined, ReloadOutlined, EyeOutlined,
  DollarOutlined, OrderedListOutlined, StopOutlined, DeleteOutlined,
  FileTextOutlined, UserOutlined, IdcardOutlined, AppstoreOutlined,
  SafetyCertificateOutlined, SettingOutlined, ShopOutlined, CalendarOutlined,
} from '@ant-design/icons'
import type { ColumnsType } from 'antd/es/table'
import dayjs from 'dayjs'
import type { OrderVO } from '../../api/api'
import { merchantApi } from '../../api/api'
import { usePortalScope } from '../../hooks/usePortalScope'
import { col, styledTableComponents, INPUT_STYLE } from '../../components/common/tableComponents'
import PagePagination from '../../components/common/PagePagination'
import PermGuard from '../../components/common/PermGuard'

const { Text } = Typography
const { RangePicker } = DatePicker

const STATUS_MAP: Record<number, { color: string; text: string; icon: React.ReactNode }> = {
  0: { color: 'gold',    text: '待支付',  icon: <DollarOutlined /> },
  1: { color: 'blue',    text: '待接单',  icon: <ClockCircleOutlined /> },
  2: { color: 'cyan',    text: '已接单',  icon: <CheckCircleOutlined /> },
  3: { color: 'orange',  text: '服务中',  icon: <CarOutlined /> },
  4: { color: 'green',   text: '已完成',  icon: <CheckCircleOutlined /> },
  5: { color: 'default', text: '已取消',  icon: <CloseCircleOutlined /> },
}

export default function OrderListPage() {
  const { orderList, orderCancel, orderDelete, isMerchant } = usePortalScope()
  const [loading, setLoading]         = useState(false)
  const [data, setData]               = useState<OrderVO[]>([])
  const [total, setTotal]             = useState(0)
  const [page, setPage]               = useState(1)
  const [pageSize, setPageSize]       = useState(20)
  const pageSizeRef                   = useRef(20)
  const [keyword, setKeyword]         = useState('')
  const [status, setStatus]           = useState<number | undefined>()
  const [dateRange, setDateRange]     = useState<[string, string] | null>(null)
  const [merchantId, setMerchantId]   = useState<number | undefined>()
  const [merchantOpts, setMerchantOpts] = useState<{ value: number; label: string }[]>([])
  const [detail, setDetail]           = useState<OrderVO | null>(null)
  const [drawerOpen, setDrawerOpen]   = useState(false)

  useEffect(() => {
    if (!isMerchant) {
      merchantApi.list({ page: 1, size: 200 }).then(res => {
        const list = res.data?.data?.list ?? res.data?.data?.records ?? []
        setMerchantOpts(list.map((m: any) => ({ value: m.id, label: m.name })))
      }).catch(() => {})
    }
  }, [isMerchant])

  const fetchList = useCallback(async (
    pg = page, kw = keyword, st = status,
    dr: [string, string] | null = dateRange,
    mid = merchantId,
  ) => {
    setLoading(true)
    try {
      const res = await orderList({
        page: pg, size: pageSizeRef.current, status: st, keyword: kw,
        startDate: dr?.[0], endDate: dr?.[1],
        ...(mid != null ? { merchantId: mid } : {}),
      })
      const d = res.data.data
      setData(d?.list ?? [])
      setTotal(d?.total ?? 0)
    } catch {
      // 错误由拦截器处理
    } finally {
      setLoading(false)
    }
  }, [page, keyword, status, dateRange, merchantId])

  useEffect(() => { fetchList() }, [fetchList])

  const handleCancel = async (r: OrderVO) => {
    try {
      await orderCancel(r.id)
      message.success('订单已取消')
      fetchList()
    } catch { /* 错误由拦截器处理 */ }
  }

  const handleDelete = async (r: OrderVO) => {
    try {
      await orderDelete(r.id)
      message.success('订单已删除')
      fetchList()
    } catch { /* 错误由拦截器处理 */ }
  }

  const columns: ColumnsType<OrderVO> = [
    {
      title: col(<FileTextOutlined style={{ color: '#6366f1' }} />, '订单号'),
      dataIndex: 'orderNo',
      width: 160,
      render: (v: string) => <Text code style={{ fontSize: 11 }}>{v}</Text>,
    },
    {
      title: col(<UserOutlined style={{ color: '#f97316' }} />, '用户', 'left'),
      dataIndex: 'memberNickname',
      width: 130,
      render: (v: string) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, width: '100%' }}>
          <Avatar size={30} icon={<UserOutlined />}
            style={{ background: 'linear-gradient(135deg,#F5A623,#F97316)', flexShrink: 0 }} />
          <Text style={{ fontSize: 13 }}>{v || '—'}</Text>
        </div>
      ),
    },
    {
      title: col(<IdcardOutlined style={{ color: '#8b5cf6' }} />, '技师', 'left'),
      dataIndex: 'technicianNickname',
      width: 130,
      render: (v: string) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, width: '100%' }}>
          <Avatar size={30} icon={<IdcardOutlined />}
            style={{ background: 'linear-gradient(135deg,#6366f1,#8b5cf6)', flexShrink: 0 }} />
          <Text style={{ fontSize: 13 }}>{v || '未分配'}</Text>
        </div>
      ),
    },
    {
      title: col(<AppstoreOutlined style={{ color: '#0ea5e9' }} />, '服务项目'),
      dataIndex: 'serviceName',
      ellipsis: true,
      render: (v: string) => <Text style={{ fontSize: 13 }}>{v}</Text>,
    },
    {
      title: col(<DollarOutlined style={{ color: '#f59e0b' }} />, '实付金额'),
      dataIndex: 'payAmount',
      width: 110,
      sorter: (a, b) => Number(a.payAmount ?? 0) - Number(b.payAmount ?? 0),
      render: (v: number) => (
        <Text strong style={{ color: '#F5A623', fontSize: 14 }}>
          ${v != null ? Number(v).toFixed(2) : '—'}
        </Text>
      ),
    },
    {
      title: col(<SafetyCertificateOutlined style={{ color: '#10b981' }} />, '状态'),
      dataIndex: 'status',
      width: 95,
      render: (v: number) => {
        const s = STATUS_MAP[v] ?? STATUS_MAP[1]
        return <Tag color={s.color}>{s.text}</Tag>
      },
    },
    {
      title: col(<ClockCircleOutlined style={{ color: '#64748b' }} />, '下单时间'),
      dataIndex: 'createTime',
      width: 140,
      render: (v: string) => (
        <Text type="secondary" style={{ fontSize: 12 }}>{v ? dayjs(v).format('MM-DD HH:mm') : '—'}</Text>
      ),
    },
    {
      title: col(<SettingOutlined style={{ color: '#6366f1' }} />, '操作'),
      key: 'action',
      fixed: 'right',
      width: 145,
      render: (_, r) => (
        <Space size={4}>
          <Button size="small" type="primary" ghost icon={<EyeOutlined />}
            style={{ borderRadius: 6 }}
            onClick={() => { setDetail(r); setDrawerOpen(true) }}>查看</Button>
          {[0, 1, 2].includes(r.status) && (
            <PermGuard code="order:cancel">
              <Popconfirm title="确认取消该订单？" onConfirm={() => handleCancel(r)}
                okText="取消订单" cancelText="返回" okButtonProps={{ danger: true }}>
                <Button size="small" icon={<StopOutlined />}
                  style={{ borderRadius: 6, color: '#fa8c16', borderColor: '#ffd591' }}>取消</Button>
              </Popconfirm>
            </PermGuard>
          )}
          {[4, 5].includes(r.status) && (
            <PermGuard code="order:delete">
              <Popconfirm title="确认删除该订单记录？" onConfirm={() => handleDelete(r)}
                okText="删除" cancelText="取消" okButtonProps={{ danger: true }}>
                <Button size="small" danger icon={<DeleteOutlined />} style={{ borderRadius: 6 }}>删除</Button>
              </Popconfirm>
            </PermGuard>
          )}
        </Space>
      ),
    },
  ]

  const completedCount = data.filter(d => d.status === 4).length
  const activeCount    = data.filter(d => [1,2,3].includes(d.status)).length
  const totalAmount    = data.reduce((s, d) => s + Number(d.payAmount ?? 0), 0)

  const subtitle = isMerchant
    ? '管理您商户旗下的所有服务订单 · 实时跟踪订单状态'
    : '查看和管理平台全部服务订单 · 实时跟踪订单状态'

  const statsBadges = [
    { icon: '📋', label: '订单总数', value: total, color: '#0ea5e9', bg: 'rgba(14,165,233,0.08)', border: 'rgba(14,165,233,0.22)' },
    { icon: '⚡', label: '进行中', value: activeCount, color: '#6366f1', bg: 'rgba(99,102,241,0.08)', border: 'rgba(99,102,241,0.22)' },
    { icon: '✅', label: '已完成', value: completedCount, color: '#16a34a', bg: 'rgba(22,163,74,0.08)', border: 'rgba(22,163,74,0.22)' },
    { icon: '💰', label: '金额(本页)', value: `$${totalAmount.toFixed(0)}`, color: '#d97706', bg: 'rgba(217,119,6,0.08)', border: 'rgba(217,119,6,0.22)' },
  ]

  const handleReset = () => {
    setKeyword('')
    setStatus(undefined)
    setDateRange(null)
    setMerchantId(undefined)
    setPage(1)
    fetchList(1, '', undefined, null, undefined)
  }

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
            width: 34, height: 34, borderRadius: 10,
            background: 'linear-gradient(135deg,#0ea5e9,#6366f1)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 4px 14px rgba(14,165,233,0.35)', flexShrink: 0,
          }}>
            <OrderedListOutlined style={{ color: '#fff', fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1e293b', lineHeight: 1.2 }}>订单管理</div>
            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>{subtitle}</div>
          </div>
          <Divider type="vertical" style={{ height: 20, margin: '0 4px', borderColor: '#e0e4ff' }} />
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            {statsBadges.map((s, i) => (
              <div key={i} style={{
                display: 'flex', alignItems: 'center', gap: 5,
                padding: '3px 10px', borderRadius: 20, background: s.bg,
                border: `1px solid ${s.border}`,
              }}>
                <span style={{ fontSize: 13 }}>{s.icon}</span>
                <span style={{ fontSize: 12, color: '#6b7280' }}>{s.label}</span>
                <span style={{ fontSize: 13, fontWeight: 700, color: s.color }}>{s.value}</span>
              </div>
            ))}
          </div>
          <div style={{ flex: 1 }} />
        </div>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', padding: '10px 24px 12px' }}>
          <Input
            placeholder="搜索订单号 / 用户昵称"
            prefix={<SearchOutlined style={{ color: '#0ea5e9' }} />}
            allowClear
            size="middle"
            value={keyword}
            onChange={e => setKeyword(e.target.value)}
            onPressEnter={() => { setPage(1); fetchList(1) }}
            style={{ ...INPUT_STYLE, width: 200 }}
          />
          {!isMerchant && (
            <Select
              placeholder={<span><ShopOutlined style={{ color: '#6366f1', marginRight: 4 }} />所属商户</span>}
              allowClear
              size="middle"
              style={{ width: 160 }}
              value={merchantId}
              onChange={v => { setMerchantId(v); setPage(1); fetchList(1, keyword, status, dateRange, v) }}
              showSearch
              filterOption={(input, opt) =>
                String(opt?.label ?? '').toLowerCase().includes(input.toLowerCase())
              }
              options={merchantOpts}
            />
          )}
          <Select
            placeholder={<Space size={4}><OrderedListOutlined style={{ color: '#0ea5e9', fontSize: 12 }} />订单状态</Space>}
            allowClear
            size="middle"
            style={{ width: 115 }}
            value={status}
            onChange={v => { setStatus(v); setPage(1); fetchList(1, keyword, v, dateRange) }}
            options={Object.entries(STATUS_MAP).map(([k, v]) => ({
              value: Number(k), label: <Space size={4}>{v.icon}{v.text}</Space>,
            }))}
          />
          <RangePicker
            size="middle"
            placeholder={['开始日期', '结束日期']}
            suffixIcon={<CalendarOutlined style={{ color: '#6366f1', fontSize: 12 }} />}
            value={dateRange?.[0] && dateRange?.[1] ? [dayjs(dateRange[0]), dayjs(dateRange[1])] : null}
            style={{ ...INPUT_STYLE, minWidth: 240, flex: '1 1 220px', maxWidth: 320 }}
            onChange={(_, s) => {
              const dr: [string, string] | null = s[0] && s[1] ? [s[0], s[1]] : null
              setDateRange(dr)
              setPage(1)
              fetchList(1, keyword, status, dr)
            }}
          />
          <div style={{ flex: 1 }} />
          <Button icon={<ReloadOutlined />} size="middle" style={{ borderRadius: 8 }} onClick={handleReset}>重置</Button>
          <Tooltip title="刷新列表">
            <Button
              icon={<ReloadOutlined />}
              size="middle"
              loading={loading}
              style={{ borderRadius: 8, color: '#6366f1', borderColor: '#c7d2fe' }}
              onClick={() => fetchList()}
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
            onClick={() => { setPage(1); fetchList(1, keyword, status, dateRange, merchantId) }}
          >搜索</Button>
        </div>
      </div>

      <div style={{ marginLeft: -24, marginRight: -24, marginBottom: -24, background: '#fff', borderTop: '1px solid #eef0f8' }}>
        <Table
          rowKey="id"
          dataSource={data}
          columns={columns}
          loading={loading}
          size="middle"
          components={styledTableComponents}
          scroll={{ x: 'max-content', y: 'calc(100vh - 272px)' }}
          pagination={false}
        />
        <PagePagination
          total={total}
          current={page}
          pageSize={pageSize}
          countLabel="条订单"
          onChange={p => { setPage(p); fetchList(p) }}
          onSizeChange={s => {
            pageSizeRef.current = s
            setPageSize(s)
            setPage(1)
          }}
        />
      </div>

      {/* 详情抽屉 */}
      <Drawer
        title={<Space><OrderedListOutlined style={{ color: '#F5A623' }} /><span>订单详情</span></Space>}
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        styles={{ wrapper: { width: 880 } }}>
        {detail && (
          <div>
            <div style={{
              background: 'linear-gradient(135deg,#F5A623,#F97316)',
              borderRadius: 12, padding: '10px 16px',
              marginBottom: 20, color: '#fff',
            }}>
              <div style={{ fontSize: 12, opacity: 0.85, marginBottom: 4 }}>订单号</div>
              <div style={{ fontSize: 14, fontWeight: 700, fontFamily: 'monospace' }}>{detail.orderNo}</div>
              <div style={{ marginTop: 12, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Tag color="rgba(255,255,255,0.3)" style={{ color: '#fff', border: 'none' }}>
                  {STATUS_MAP[detail.status]?.text}
                </Tag>
                <div style={{ fontSize: 22, fontWeight: 800 }}>
                  ${detail.payAmount != null ? Number(detail.payAmount).toFixed(2) : '—'}
                </div>
              </div>
            </div>
            <Descriptions column={1} size="small" bordered>
              <Descriptions.Item label="用户">{detail.memberNickname ?? `#${detail.memberId}`}</Descriptions.Item>
              <Descriptions.Item label="技师">{detail.technicianNickname || '未分配'}</Descriptions.Item>
              <Descriptions.Item label="服务项目">{detail.serviceName}</Descriptions.Item>
              <Descriptions.Item label="原价">{detail.originalAmount != null ? `$${Number(detail.originalAmount).toFixed(2)}` : '—'}</Descriptions.Item>
              <Descriptions.Item label="实付金额" ><Text strong style={{ color: '#f59e0b' }}>{detail.payAmount != null ? `$${Number(detail.payAmount).toFixed(2)}` : '—'}</Text></Descriptions.Item>
              <Descriptions.Item label="服务地址">{detail.addressDetail || '—'}</Descriptions.Item>
              <Descriptions.Item label="下单时间">{detail.createTime ? dayjs(detail.createTime).format('YYYY-MM-DD HH:mm:ss') : '—'}</Descriptions.Item>
            </Descriptions>
            <div style={{ marginTop: 20 }}>
              <Text type="secondary" style={{ fontSize: 12, marginBottom: 12, display: 'block' }}>订单流程</Text>
              <Timeline
                items={[
                  { color: 'green',  children: '订单创建' },
                  { color: detail.status >= 1 ? 'green' : 'gray', children: '等待接单' },
                  { color: detail.status >= 2 ? 'green' : 'gray', children: '技师已接单' },
                  { color: detail.status >= 3 ? 'orange' : 'gray', children: '服务进行中' },
                  { color: detail.status === 4 ? 'green' : 'gray', children: '服务完成' },
                ]}
              />
            </div>
          </div>
        )}
      </Drawer>
    </div>
  )
}
