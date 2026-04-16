import { useState, useCallback, useEffect, useRef } from 'react'
import {
  Table, Button, Space, Row, Col, Input, Select, Avatar,
  Typography, Descriptions, Drawer, message, Tag, Tooltip,
  Modal, InputNumber, Form, Badge, Divider,
} from 'antd'
import {
  SearchOutlined, ReloadOutlined, EyeOutlined,
  ShopOutlined, CheckCircleOutlined, CloseCircleOutlined, MinusCircleOutlined,
  TeamOutlined,
  PhoneOutlined, EnvironmentOutlined, PercentageOutlined,
  EditOutlined, StopOutlined, PlusOutlined,
  AuditOutlined, ClockCircleOutlined, SettingOutlined,
  WalletOutlined,
} from '@ant-design/icons'
import type { ColumnsType } from 'antd/es/table'
import { col, styledTableComponents, INPUT_STYLE } from '../../components/common/tableComponents'
import PagePagination from '../../components/common/PagePagination'
import { merchantApi } from '../../api/api'
import MerchantCreateModal from '../../components/merchant/MerchantCreateModal'
import PermGuard from '../../components/common/PermGuard'
import { useTableBodyHeight } from '../../hooks/useTableBodyHeight'

const { Text } = Typography

interface Merchant {
  id: number
  merchantNo: string
  mobile: string
  merchantNameZh: string
  merchantNameEn?: string
  contactPerson?: string
  contactMobile?: string
  city?: string
  addressZh?: string
  techCount: number
  balance: number
  commissionRate: number
  businessType: number
  auditStatus: number
  status: number
  createTime: string
}

const AUDIT_MAP: Record<number, { label: string; color: string; bg: string }> = {
  0: { label: '待审核', color: '#fa8c16', bg: 'rgba(250,140,22,0.1)' },
  1: { label: '已通过', color: '#52c41a', bg: 'rgba(82,196,26,0.1)' },
  2: { label: '已拒绝', color: '#ff4d4f', bg: 'rgba(255,77,79,0.1)' },
}

const CITIES = ['金边', '暹粒', '西哈努克', '贡布', '白马']

export default function MerchantListPage() {
  const { ref, height: tableBodyH } = useTableBodyHeight()
  const [data, setData]               = useState<Merchant[]>([])
  const [loading, setLoading]         = useState(false)
  const [total, setTotal]             = useState(0)
  const [page, setPage]               = useState(1)
  const [pageSize, setPageSize]       = useState(10)
  const pageSizeRef                   = useRef(10)
  const [keyword, setKeyword]         = useState('')
  const [statusFilter, setStatusFilter] = useState<number | undefined>()
  const [auditFilter, setAuditFilter] = useState<number | undefined>()
  const [cityFilter, setCityFilter]   = useState<string | undefined>()
  const [selected, setSelected]       = useState<Merchant | null>(null)
  const [drawerOpen, setDrawerOpen]   = useState(false)
  const [commModal, setCommModal]     = useState(false)
  const [commForm]                    = Form.useForm()
  const [createOpen, setCreateOpen]   = useState(false)

  const fetchData = useCallback(async (pg = page) => {
    setLoading(true)
    try {
      const res = await merchantApi.list({
        current: pg, size: pageSizeRef.current,
        keyword: keyword || undefined,
        city: cityFilter,
        status: statusFilter,
        auditStatus: auditFilter,
      })
      const d = res.data?.data
      setData(d?.list ?? [])
      setTotal(d?.total ?? 0)
    } catch {
      message.error('加载失败')
    } finally {
      setLoading(false)
    }
  }, [page, keyword, cityFilter, statusFilter, auditFilter])

  useEffect(() => { fetchData() }, [fetchData])

  const handleSearch = () => { setPage(1); fetchData(1) }
  const handleReset  = () => {
    setKeyword(''); setCityFilter(undefined)
    setStatusFilter(undefined); setAuditFilter(undefined)
    setPage(1); fetchData(1)
  }

  const handleStatusToggle = async (r: Merchant) => {
    const next = r.status === 1 ? 0 : 1
    await merchantApi.updateStatus(r.id, next)
    message.success(next === 1 ? '已开启营业' : '已停业')
    fetchData()
  }

  const handleAudit = (id: number, status: number) => {
    Modal.confirm({
      title: status === 1 ? '确认通过审核？' : '确认拒绝该商户？',
      icon: status === 1
        ? <CheckCircleOutlined style={{ color: '#52c41a' }} />
        : <CloseCircleOutlined style={{ color: '#ff4d4f' }} />,
      okButtonProps: status === 1
        ? { style: { background: '#52c41a', borderColor: '#52c41a' } }
        : { danger: true },
      async onOk() {
        await merchantApi.audit(id, status)
        message.success(status === 1 ? '审核已通过' : '已拒绝')
        fetchData()
      },
    })
  }

  const handleCommSubmit = async () => {
    const { rate } = await commForm.validateFields()
    await merchantApi.updateCommission(selected!.id, rate)
    message.success('佣金比例已更新')
    setCommModal(false)
    fetchData()
  }

  const activeCount  = data.filter(m => m.status === 1).length
  const pendingCount = data.filter(m => m.auditStatus === 0).length
  const totalTech    = data.reduce((s, m) => s + (m.techCount || 0), 0)

  const statsBadges = [
    { icon: '🏪', label: '商户总数', value: total, color: '#7c3aed', bg: 'rgba(114,46,209,0.08)', border: 'rgba(114,46,209,0.22)' },
    { icon: '🟢', label: '营业中', value: activeCount, color: '#16a34a', bg: 'rgba(22,163,74,0.08)', border: 'rgba(22,163,74,0.22)' },
    { icon: '⏳', label: '待审核', value: pendingCount, color: '#ea580c', bg: 'rgba(234,88,12,0.08)', border: 'rgba(234,88,12,0.22)' },
    { icon: '👥', label: '旗下技师', value: totalTech, color: '#2563eb', bg: 'rgba(37,99,235,0.08)', border: 'rgba(37,99,235,0.22)' },
  ]

  const columns: ColumnsType<Merchant> = [
    {
      title: col(<ShopOutlined style={{ color: '#722ed1' }} />, '商户信息', 'left'),
      key: 'info',
      fixed: 'left',
      width: 240,
      render: (_, r) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, width: '100%' }}>
          <div style={{ position: 'relative', flexShrink: 0 }}>
            <Avatar size={46} icon={<ShopOutlined />}
              style={{ background: 'linear-gradient(135deg,#722ed1,#b37feb)', border: '2px solid #f5f0ff' }} />
            <div style={{
              position: 'absolute', bottom: -2, right: -2,
              width: 14, height: 14, borderRadius: '50%',
              background: r.status === 1 ? '#52c41a' : '#d9d9d9',
              border: '2px solid #fff',
            }} />
          </div>
          <div>
            <div style={{ fontWeight: 700, fontSize: 14 }}>{r.merchantNameZh}</div>
            <div style={{ fontSize: 11, color: '#999' }}>
              #{r.merchantNo} · {r.city || '—'}
            </div>
          </div>
        </div>
      ),
    },
    {
      title: '负责人',
      key: 'contact',
      width: 160,
      render: (_, r) => (
        <div>
          <div style={{ fontWeight: 600 }}>{r.contactPerson || '—'}</div>
          <div style={{ fontSize: 11, color: '#999' }}>
            <PhoneOutlined style={{ marginRight: 3 }} />
            {r.contactMobile || r.mobile}
          </div>
        </div>
      ),
    },
    {
      title: col(<EnvironmentOutlined style={{ color: '#f59e0b' }} />, '所在城市'),
      dataIndex: 'city',
      width: 100,
      render: v => v ? <Tag icon={<EnvironmentOutlined />} color="blue">{v}</Tag> : <Text type="secondary">—</Text>,
    },
    {
      title: col(<TeamOutlined style={{ color: '#1677ff' }} />, '旗下技师'),
      dataIndex: 'techCount',
      width: 100,
      align: 'center',
      sorter: (a, b) => a.techCount - b.techCount,
      render: v => (
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: 18, fontWeight: 800, color: '#1677ff' }}>{v}</div>
          <div style={{ fontSize: 11, color: '#999' }}>名技师</div>
        </div>
      ),
    },
    {
      title: col(<WalletOutlined style={{ color: '#52c41a' }} />, '钱包余额'),
      dataIndex: 'balance',
      width: 120,
      sorter: (a, b) => a.balance - b.balance,
      render: v => (
        <div>
          <div style={{ fontWeight: 700, color: '#52c41a', fontSize: 15 }}>
            ${Number(v).toLocaleString('en', { minimumFractionDigits: 2 })}
          </div>
        </div>
      ),
    },
    {
      title: col(<PercentageOutlined style={{ color: '#722ed1' }} />, '佣金比例'),
      dataIndex: 'commissionRate',
      width: 100,
      render: v => (
        <div style={{
          display: 'inline-flex', alignItems: 'center',
          padding: '2px 10px', borderRadius: 20,
          background: 'rgba(22,119,255,0.1)', color: '#1677ff', fontWeight: 700,
        }}>
          {v}%
        </div>
      ),
    },
    {
      title: col(<AuditOutlined style={{ color: '#fa8c16' }} />, '审核状态'),
      dataIndex: 'auditStatus',
      width: 100,
      render: v => {
        const s = AUDIT_MAP[v ?? 0]
        return (
          <span style={{
            padding: '2px 10px', borderRadius: 20, fontSize: 12, fontWeight: 600,
            background: s.bg, color: s.color,
          }}>{s.label}</span>
        )
      },
    },
    {
      title: col(<CheckCircleOutlined style={{ color: '#52c41a' }} />, '营业状态'),
      dataIndex: 'status',
      width: 100,
      render: (v, r) => (
        <Tooltip title={v === 1 ? '点击停业' : '点击开业'}>
          <Badge
            status={v === 1 ? 'success' : 'default'}
            text={
              <span
                style={{ cursor: 'pointer', color: v === 1 ? '#52c41a' : '#999', fontWeight: 600 }}
                onClick={() => handleStatusToggle(r)}
              >
                {v === 1 ? '营业中' : '已停业'}
              </span>
            }
          />
        </Tooltip>
      ),
    },
    {
      title: col(<ClockCircleOutlined style={{ color: '#64748b' }} />, '入驻时间'),
      dataIndex: 'createTime',
      width: 110,
      render: v => <Text type="secondary" style={{ fontSize: 12 }}>{v?.slice(0, 10)}</Text>,
    },
    {
      title: col(<SettingOutlined style={{ color: '#6366f1' }} />, '操作'),
      key: 'action',
      fixed: 'right',
      width: 240,
      render: (_, r) => (
        <Space size={[4, 4]} wrap>
          <Button size="small" type="primary" ghost icon={<EyeOutlined />}
            style={{ borderRadius: 6 }}
            onClick={() => { setSelected(r); setDrawerOpen(true) }}>查看</Button>
          <PermGuard code="merchant:commission">
            <Button size="small" icon={<EditOutlined />}
              style={{ borderRadius: 6, color: '#fa8c16', borderColor: '#ffd591' }}
              onClick={() => {
                setSelected(r)
                commForm.setFieldsValue({ rate: r.commissionRate })
                setCommModal(true)
              }}>佣金</Button>
          </PermGuard>
          <PermGuard code="merchant:toggle">
            {r.status === 1 ? (
              <Button size="small" icon={<StopOutlined />}
                style={{ borderRadius: 6, color: '#ff4d4f', borderColor: '#ffa39e' }}
                onClick={() => handleStatusToggle(r)}>停业</Button>
            ) : (
              <Button size="small" icon={<CheckCircleOutlined />}
                style={{ borderRadius: 6, color: '#52c41a', borderColor: '#b7eb8f' }}
                onClick={() => handleStatusToggle(r)}>开业</Button>
            )}
          </PermGuard>
          {r.auditStatus === 0 && (
            <PermGuard code="merchant:audit">
              <>
                <Button size="small" icon={<CheckCircleOutlined />}
                  style={{ borderRadius: 6, color: '#52c41a', borderColor: '#b7eb8f' }}
                  onClick={() => handleAudit(r.id, 1)}>通过</Button>
                <Button size="small" danger icon={<CloseCircleOutlined />}
                  style={{ borderRadius: 6 }}
                  onClick={() => handleAudit(r.id, 2)}>拒绝</Button>
              </>
            </PermGuard>
          )}
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
            width: 34, height: 34, borderRadius: 10,
            background: 'linear-gradient(135deg,#722ed1,#9d3fda)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 4px 14px rgba(114,46,209,0.35)', flexShrink: 0,
          }}>
            <ShopOutlined style={{ color: '#fff', fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1e293b', lineHeight: 1.2 }}>商户管理</div>
            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>管理平台入驻商户 · 审核资质 · 配置佣金 · 监控运营</div>
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
          <PermGuard code="merchant:add">
            <Button
              type="primary" size="middle" icon={<PlusOutlined />}
              onClick={() => setCreateOpen(true)}
              style={{
                borderRadius: 8, border: 'none',
                background: 'linear-gradient(135deg,#0ea5e9,#6366f1)',
                boxShadow: '0 2px 8px rgba(14,165,233,0.35)',
              }}
            >新增商户</Button>
          </PermGuard>
        </div>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', padding: '10px 24px 12px' }}>
          <Input
            placeholder="搜索商户名称 / 负责人 / 手机号"
            prefix={<SearchOutlined style={{ color: '#722ed1' }} />}
            allowClear value={keyword}
            size="middle"
            onChange={e => setKeyword(e.target.value)}
            onPressEnter={handleSearch}
            style={{ ...INPUT_STYLE, width: 200 }}
          />
          <Select
            placeholder={<Space size={4}><EnvironmentOutlined style={{ color: '#f59e0b', fontSize: 12 }} />所在城市</Space>} allowClear size="middle" style={{ width: 115 }}
            value={cityFilter} onChange={setCityFilter}
            options={CITIES.map(c => ({ value: c, label: c }))}
          />
          <Select
            placeholder={<Space size={4}><ShopOutlined style={{ color: '#10b981', fontSize: 12 }} />营业状态</Space>} allowClear size="middle" style={{ width: 115 }}
            value={statusFilter} onChange={setStatusFilter}
            options={[
              { value: 1, label: <Space size={4}><CheckCircleOutlined style={{ color: '#10b981' }} />营业中</Space> },
              { value: 0, label: <Space size={4}><MinusCircleOutlined style={{ color: '#9ca3af' }} />已停业</Space> },
            ]}
          />
          <Select
            placeholder={<Space size={4}><AuditOutlined style={{ color: '#6366f1', fontSize: 12 }} />审核状态</Space>} allowClear size="middle" style={{ width: 115 }}
            value={auditFilter} onChange={setAuditFilter}
            options={[
              { value: 0, label: <Space size={4}><ClockCircleOutlined style={{ color: '#f59e0b' }} />待审核</Space> },
              { value: 1, label: <Space size={4}><CheckCircleOutlined style={{ color: '#10b981' }} />已通过</Space> },
              { value: 2, label: <Space size={4}><CloseCircleOutlined style={{ color: '#ef4444' }} />已拒绝</Space> },
            ]}
          />
          <div style={{ flex: 1 }} />
          <Button icon={<ReloadOutlined />} size="middle" style={{ borderRadius: 8 }} onClick={handleReset}>重置</Button>
          <Tooltip title="刷新列表">
            <Button
              icon={<ReloadOutlined />} size="middle" loading={loading}
              style={{ borderRadius: 8, color: '#6366f1', borderColor: '#c7d2fe' }}
              onClick={() => fetchData()}
            />
          </Tooltip>
          <Button
            type="primary" icon={<SearchOutlined />}
            style={{
              borderRadius: 8, border: 'none',
              background: 'linear-gradient(135deg,#6366f1,#8b5cf6)',
              boxShadow: '0 2px 8px rgba(99,102,241,0.35)',
            }}
            onClick={handleSearch}
          >搜索</Button>
        </div>
      </div>

      <div ref={ref} style={{ marginLeft: -24, marginRight: -24, marginBottom: -24, background: '#fff', borderTop: '1px solid #eef0f8' }}>
        <Table
          rowKey="id"
          columns={columns}
          dataSource={data}
          loading={loading}
          size="middle"
          components={styledTableComponents}
          scroll={{ x: 'max-content', y: tableBodyH }}
          rowClassName={(_, idx) => idx % 2 === 1 ? 'table-row-stripe' : ''}
          pagination={false}
        />
        <PagePagination
          total={total}
          current={page}
          pageSize={pageSize}
          countLabel="家商户"
          pageSizeOptions={[10, 20, 50, 100]}
          onChange={p => { setPage(p); fetchData(p) }}
          onSizeChange={s => {
            pageSizeRef.current = s
            setPageSize(s)
            setPage(1)
          }}
        />
      </div>

      {/* 详情抽屉 */}
      <Drawer
        title={
          <Space>
            <Avatar size={36} icon={<ShopOutlined />}
              style={{ background: 'linear-gradient(135deg,#722ed1,#b37feb)' }} />
            <div>
              <div style={{ fontWeight: 700 }}>{selected?.merchantNameZh}</div>
              <div style={{ fontSize: 11, color: '#999', fontWeight: 400 }}>#{selected?.merchantNo}</div>
            </div>
          </Space>
        }
        width={880}
        styles={{ body: { maxHeight: 'calc(85vh - 150px)', overflowY: 'auto', overflowX: 'hidden' } }}
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
      >
        {selected && (
          <div>
            <div style={{
              background: 'linear-gradient(135deg,rgba(114,46,209,0.06),rgba(179,127,235,0.06))',
              borderRadius: 12, padding: '16px 20px', marginBottom: 20,
              display: 'flex', alignItems: 'center', gap: 16,
            }}>
              <Avatar size={60} icon={<ShopOutlined />}
                style={{ background: 'linear-gradient(135deg,#722ed1,#b37feb)', flexShrink: 0 }} />
              <div>
                <div style={{ fontSize: 18, fontWeight: 800 }}>{selected.merchantNameZh}</div>
                {selected.merchantNameEn && (
                  <div style={{ color: '#888', fontSize: 13 }}>{selected.merchantNameEn}</div>
                )}
                <Space style={{ marginTop: 6 }}>
                  <span style={{
                    padding: '2px 10px', borderRadius: 20, fontSize: 12, fontWeight: 600,
                    background: AUDIT_MAP[selected.auditStatus]?.bg,
                    color: AUDIT_MAP[selected.auditStatus]?.color,
                  }}>{AUDIT_MAP[selected.auditStatus]?.label}</span>
                  <Badge
                    status={selected.status === 1 ? 'success' : 'default'}
                    text={selected.status === 1 ? '营业中' : '已停业'}
                  />
                </Space>
              </div>
            </div>

            <Row gutter={12} style={{ marginBottom: 20 }}>
              {[
                { label: '旗下技师', value: `${selected.techCount}人`, color: '#1677ff', icon: '👥' },
                { label: '钱包余额', value: `$${Number(selected.balance).toFixed(2)}`, color: '#52c41a', icon: '💰' },
                { label: '佣金比例', value: `${selected.commissionRate}%`, color: '#722ed1', icon: '📊' },
              ].map(item => (
                <Col span={8} key={item.label}>
                  <div style={{ textAlign: 'center', padding: '12px 8px', background: '#fafafa', borderRadius: 10 }}>
                    <div style={{ fontSize: 20 }}>{item.icon}</div>
                    <div style={{ fontWeight: 800, color: item.color, fontSize: 16 }}>{item.value}</div>
                    <div style={{ color: '#999', fontSize: 12 }}>{item.label}</div>
                  </div>
                </Col>
              ))}
            </Row>

            <Divider style={{ margin: '12px 0' }} />

            <Descriptions column={2} size="small" bordered labelStyle={{ background: '#fafafa', fontWeight: 600 }}>
              <Descriptions.Item label="负责人">{selected.contactPerson || '—'}</Descriptions.Item>
              <Descriptions.Item label="联系电话">{selected.contactMobile || selected.mobile}</Descriptions.Item>
              <Descriptions.Item label="登录手机" span={2}>{selected.mobile}</Descriptions.Item>
              <Descriptions.Item label="所在城市">
                {selected.city ? <Tag icon={<EnvironmentOutlined />} color="blue">{selected.city}</Tag> : '—'}
              </Descriptions.Item>
              <Descriptions.Item label="入驻时间">{selected.createTime?.slice(0, 10)}</Descriptions.Item>
              <Descriptions.Item label="详细地址" span={2}>{selected.addressZh || '—'}</Descriptions.Item>
            </Descriptions>

            {selected.auditStatus === 0 && (
              <Row gutter={12} style={{ marginTop: 20 }}>
                <Col span={12}>
                  <Button block type="primary" icon={<CheckCircleOutlined />}
                    style={{ background: '#52c41a', borderColor: '#52c41a' }}
                    onClick={() => { setDrawerOpen(false); handleAudit(selected.id, 1) }}>
                    通过审核
                  </Button>
                </Col>
                <Col span={12}>
                  <Button block danger icon={<CloseCircleOutlined />}
                    onClick={() => { setDrawerOpen(false); handleAudit(selected.id, 2) }}>
                    拒绝申请
                  </Button>
                </Col>
              </Row>
            )}
          </div>
        )}
      </Drawer>

      {/* 佣金调整弹窗 */}
      <Modal
        title={
          <Space>
            <PercentageOutlined style={{ color: '#722ed1' }} />
            <span>调整佣金比例 — {selected?.merchantNameZh}</span>
          </Space>
        }
        open={commModal}
        onOk={handleCommSubmit}
        onCancel={() => setCommModal(false)}
        okText="确认调整"
        width={880}
        styles={{ body: { maxHeight: 'calc(85vh - 150px)', overflowY: 'auto', overflowX: 'hidden' } }}
      >
        <Form form={commForm} layout="vertical" style={{ marginTop: 16 }}>
          <Form.Item name="rate" label="佣金比例（%）"
            rules={[{ required: true, message: '请输入佣金比例' }]}>
            <InputNumber min={0} max={50} step={0.5} precision={2} addonAfter="%" style={{ width: '100%' }} />
          </Form.Item>
        </Form>
      </Modal>

      {/* 新增商户弹窗 */}
      <MerchantCreateModal
        open={createOpen}
        onClose={() => setCreateOpen(false)}
        onSuccess={() => { setPage(1); fetchData(1) }}
      />
    </div>
  )
}
