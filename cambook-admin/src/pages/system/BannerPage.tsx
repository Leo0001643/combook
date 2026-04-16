import { useState } from 'react'
import {
  Row, Col, Card, Table, Input, Button, Space, Typography, Tag, Modal,
  Form, InputNumber, Switch, message, Popconfirm, Tabs, Divider, Tooltip,
} from 'antd'
import {
  PlusOutlined, EditOutlined, DeleteOutlined, PictureOutlined,
  LinkOutlined, ReloadOutlined, SettingOutlined, AppstoreOutlined,
  SortAscendingOutlined, FileTextOutlined, SafetyCertificateOutlined,
  CalendarOutlined,
} from '@ant-design/icons'
import type { ColumnsType } from 'antd/es/table'
import dayjs from 'dayjs'
import { type BannerVO } from '../../api/api'
import { usePortalScope } from '../../hooks/usePortalScope'
import PermGuard from '../../components/common/PermGuard'
import { col, styledTableComponents } from '../../components/common/tableComponents'

const { Text } = Typography

const PAGE_GRADIENT = 'linear-gradient(135deg,#475569,#64748b)'

const MOCK_BANNERS: BannerVO[] = [
  { id: 1, title: '限时特惠 · 首单立减 $20', imageUrl: '', linkUrl: '/promotion/first', sort: 1, status: 1, createdAt: '2026-04-01' },
  { id: 2, title: '精油 SPA 新品上线', imageUrl: '', linkUrl: '/service/spa', sort: 2, status: 1, createdAt: '2026-04-05' },
  { id: 3, title: '邀请好友赚佣金', imageUrl: '', linkUrl: '/invite', sort: 3, status: 0, createdAt: '2026-04-08' },
]

const GRADIENT_PRESETS = [
  { label: '暖橙', value: 'linear-gradient(135deg,#F5A623,#F97316)' },
  { label: '靛紫', value: 'linear-gradient(135deg,#5B5BD6,#8B5CF6)' },
  { label: '翠绿', value: 'linear-gradient(135deg,#0D9488,#059669)' },
  { label: '玫红', value: 'linear-gradient(135deg,#EC4899,#DC2626)' },
]

function BannerPreview({ title, gradient }: { title: string; gradient: string }) {
  return (
    <div style={{
      background: gradient, borderRadius: 12, padding: '20px 24px',
      display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      color: '#fff', minHeight: 90,
    }}>
      <div>
        <div style={{ fontSize: 16, fontWeight: 800, marginBottom: 4 }}>{title || 'Banner 标题'}</div>
        <div style={{ fontSize: 12, opacity: 0.8 }}>点击查看详情</div>
        <div style={{
          marginTop: 10, display: 'inline-block',
          background: 'rgba(255,255,255,0.25)', borderRadius: 20,
          padding: '4px 14px', fontSize: 12, border: '1px solid rgba(255,255,255,0.4)',
        }}>立即了解 →</div>
      </div>
      <PictureOutlined style={{ fontSize: 48, opacity: 0.3 }} />
    </div>
  )
}

export default function BannerPage() {
  const { bannerAdd, bannerEdit, bannerDelete } = usePortalScope()
  const [data, setData]           = useState<BannerVO[]>(MOCK_BANNERS)
  const [loading, setLoading]     = useState(false)
  const [modalOpen, setModalOpen] = useState(false)
  const [editing, setEditing]     = useState<BannerVO | null>(null)
  const [previewGrad, setPreviewGrad] = useState(GRADIENT_PRESETS[0].value)
  const [form] = Form.useForm()

  const fetchBanners = async () => {
    setLoading(true)
    // TODO: replace with real list API when backend provides GET /admin/banner/list
    setTimeout(() => setLoading(false), 300)
  }

  const openAdd = () => {
    setEditing(null)
    form.resetFields()
    form.setFieldsValue({ sort: data.length + 1, status: true })
    setPreviewGrad(GRADIENT_PRESETS[0].value)
    setModalOpen(true)
  }

  const openEdit = (record: BannerVO) => {
    setEditing(record)
    form.setFieldsValue({ ...record, status: record.status === 1 })
    setModalOpen(true)
  }

  const handleDelete = async (id: number) => {
    try {
      await bannerDelete(id)
      setData(prev => prev.filter(b => b.id !== id))
      message.success('删除成功')
    } catch {
      // 拦截器处理
    }
  }

  const handleSubmit = async (values: any) => {
    const payload = { ...values, status: values.status ? 1 : 0, imageUrl: values.imageUrl || '' }
    try {
      if (editing) {
        await bannerEdit({ ...payload, id: editing.id })
        setData(prev => prev.map(b => b.id === editing.id ? { ...b, ...payload } : b))
        message.success('修改成功')
      } else {
        await bannerAdd(payload)
        setData(prev => [...prev, { ...payload, id: Date.now(), createdAt: dayjs().format('YYYY-MM-DD') }])
        message.success('新增成功')
      }
      setModalOpen(false)
    } catch {
      // 拦截器处理
    }
  }

  const columns: ColumnsType<BannerVO> = [
    {
      title: col(<SortAscendingOutlined style={{ color: '#6366f1' }} />, '排序'),
      dataIndex: 'sort',
      width: 70,
      render: (v: number) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, justifyContent: 'center' }}>
          <SortAscendingOutlined style={{ color: '#d1d5db' }} />
          <Tag>{v}</Tag>
        </div>
      ),
    },
    {
      title: col(<PictureOutlined style={{ color: '#6366f1' }} />, '预览'),
      key: 'preview',
      width: 200,
      render: (_, r) => (
        <div style={{
          background: GRADIENT_PRESETS[r.id % GRADIENT_PRESETS.length].value,
          borderRadius: 8, height: 50, display: 'flex', alignItems: 'center',
          justifyContent: 'center', color: '#fff', fontSize: 12, fontWeight: 600,
          padding: '0 12px', overflow: 'hidden',
        }}>
          {r.title}
        </div>
      ),
    },
    {
      title: col(<FileTextOutlined style={{ color: '#6366f1' }} />, '标题'),
      dataIndex: 'title',
      render: (v: string) => <Text strong style={{ fontSize: 13 }}>{v}</Text>,
    },
    {
      title: col(<LinkOutlined style={{ color: '#6366f1' }} />, '链接'),
      dataIndex: 'linkUrl',
      ellipsis: true,
      render: (v: string) => v ? (
        <Space>
          <LinkOutlined style={{ color: '#6366f1' }} />
          <Text type="secondary" style={{ fontSize: 12 }}>{v}</Text>
        </Space>
      ) : <Text type="secondary">—</Text>,
    },
    {
      title: col(<SafetyCertificateOutlined style={{ color: '#6366f1' }} />, '状态'),
      dataIndex: 'status',
      width: 90,
      render: (v: number) => <Tag color={v === 1 ? 'green' : 'default'}>{v === 1 ? '已上线' : '已下线'}</Tag>,
    },
    {
      title: col(<CalendarOutlined style={{ color: '#6366f1' }} />, '时间'),
      dataIndex: 'createdAt',
      width: 110,
      render: (v: string) => <Text type="secondary" style={{ fontSize: 12 }}>{dayjs(v).format('YYYY-MM-DD')}</Text>,
    },
    {
      title: col(<SettingOutlined style={{ color: '#6366f1' }} />, '操作'),
      key: 'action',
      width: 145,
      render: (_, r) => (
        <Space size={4}>
          <PermGuard code="banner:edit">
            <Button size="small" icon={<EditOutlined />}
              style={{ borderRadius: 6, color: '#fa8c16', borderColor: '#ffd591' }}
              onClick={() => openEdit(r)}>编辑</Button>
          </PermGuard>
          <PermGuard code="banner:delete">
            <Popconfirm title="确认删除该 Banner？" onConfirm={() => handleDelete(r.id)} okText="删除" cancelText="取消" okButtonProps={{ danger: true }}>
              <Button size="small" danger icon={<DeleteOutlined />} style={{ borderRadius: 6 }}>删除</Button>
            </Popconfirm>
          </PermGuard>
        </Space>
      ),
    },
  ]

  const tabItems = [
    {
      key: 'banner',
      label: <Space><PictureOutlined />Banner 管理</Space>,
      children: (
        <div>
          <div style={{ marginBottom: 16, display: 'flex', justifyContent: 'flex-end' }}>
            <PermGuard code="banner:add">
              <Button type="primary" icon={<PlusOutlined />} onClick={openAdd}
                style={{ borderRadius: 8, background: 'linear-gradient(135deg,#6366f1,#8b5cf6)', border: 'none' }}>
                新增 Banner
              </Button>
            </PermGuard>
          </div>
          <Table
            rowKey="id"
            dataSource={data}
            columns={columns}
            loading={loading}
            pagination={false}
            size="middle"
            components={styledTableComponents}
            scroll={{ x: 'max-content', y: 'calc(100vh - 320px)' }}
          />
        </div>
      ),
    },
    {
      key: 'category',
      label: <Space><AppstoreOutlined />服务类目</Space>,
      children: (
        <div>
          <Row gutter={[16, 16]}>
            {[
              { emoji: '💆', name: '全身推拿',  color: '#5B5BD6', count: 128 },
              { emoji: '🌸', name: '精油SPA',   color: '#D97706', count: 86 },
              { emoji: '🦶', name: '足疗足浴',  color: '#0D9488', count: 72 },
              { emoji: '🤰', name: '产后护理',  color: '#EC4899', count: 35 },
              { emoji: '🏢', name: '商户合作',  color: '#8B5CF6', count: 18 },
            ].map(cat => (
              <Col xs={12} sm={8} md={6} key={cat.name}>
                <Card className="stat-card"
                  style={{ borderRadius: 12, textAlign: 'center', border: `1px solid ${cat.color}20`, cursor: 'pointer' }}
                  styles={{ body: { padding: '20px 16px' } }}>
                  <div style={{ fontSize: 36, marginBottom: 8 }}>{cat.emoji}</div>
                  <div style={{ fontWeight: 700, color: cat.color, marginBottom: 4 }}>{cat.name}</div>
                  <Tag color={cat.color + '20'} style={{ color: cat.color, border: 'none', fontSize: 11 }}>
                    {cat.count} 位技师
                  </Tag>
                </Card>
              </Col>
            ))}
            <Col xs={12} sm={8} md={6}>
              <Card style={{ borderRadius: 12, textAlign: 'center', border: '2px dashed #e5e7eb', cursor: 'pointer' }}
                styles={{ body: { padding: '20px 16px' } }} className="stat-card">
                <PlusOutlined style={{ fontSize: 32, color: '#d1d5db', marginBottom: 8 }} />
                <div style={{ color: '#9ca3af', fontSize: 13 }}>新增类目</div>
              </Card>
            </Col>
          </Row>
        </div>
      ),
    },
    {
      key: 'config',
      label: <Space><SettingOutlined />系统配置</Space>,
      children: (
        <Row gutter={[16, 16]}>
          {[
            { key: 'APP_VERSION',    label: 'APP 最低版本',   value: '3.0.0',  desc: 'App 强更版本号' },
            { key: 'ORDER_TIMEOUT',  label: '订单超时（分钟）', value: '30',    desc: '未支付自动取消' },
            { key: 'SMS_EXPIRE',     label: '短信过期（秒）',  value: '300',    desc: '验证码有效期' },
            { key: 'WITHDRAW_MIN',   label: '最小提现金额 ($)', value: '10',   desc: '技师最低提现额' },
            { key: 'SERVICE_RADIUS', label: '服务半径（km）',  value: '15',    desc: '技师派单范围' },
            { key: 'COMMISSION_RATE',label: '平台佣金率 (%)',  value: '15',    desc: '技师收入分成后' },
          ].map(cfg => (
            <Col xs={24} sm={12} lg={8} key={cfg.key}>
              <Card style={{ borderRadius: 10, border: 'none', boxShadow: '0 2px 10px rgba(0,0,0,0.06)' }}
                styles={{ body: { padding: 16 } }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <div>
                    <Text type="secondary" style={{ fontSize: 11 }}>{cfg.key}</Text>
                    <div style={{ fontWeight: 600, fontSize: 14, marginTop: 2 }}>{cfg.label}</div>
                    <Text type="secondary" style={{ fontSize: 11 }}>{cfg.desc}</Text>
                  </div>
                  <Tag color="blue" style={{ fontSize: 13, fontWeight: 700, padding: '2px 10px' }}>{cfg.value}</Tag>
                </div>
              </Card>
            </Col>
          ))}
        </Row>
      ),
    },
  ]

  return (
    <div style={{ marginTop: -24 }}>
      <div style={{ position: 'sticky', top: 64, zIndex: 88, marginLeft: -24, marginRight: -24, background: 'rgba(255,255,255,0.97)', backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)', borderBottom: '1px solid rgba(0,0,0,0.07)', boxShadow: '0 4px 20px rgba(0,0,0,0.06)' }}>
        <div style={{ display: 'flex', alignItems: 'center', padding: '10px 24px 0', gap: 12 }}>
          <div style={{ width: 34, height: 34, borderRadius: 10, background: PAGE_GRADIENT, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 4px 12px rgba(71,85,105,0.35)', flexShrink: 0 }}>
            <SettingOutlined style={{ color: '#fff', fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1e293b', lineHeight: 1.2 }}>系统设置</div>
            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>Banner管理 · 服务类目 · 系统配置</div>
          </div>
          <Divider type="vertical" style={{ height: 20, margin: '0 4px', borderColor: '#e0e4ff' }} />
          <div style={{ flex: 1 }} />
          <Tooltip title="刷新 Banner 列表">
            <Button icon={<ReloadOutlined />} size="middle" loading={loading} style={{ borderRadius: 8, color: '#6366f1', borderColor: '#c7d2fe' }} onClick={fetchBanners} />
          </Tooltip>
        </div>
      </div>
      <div style={{ marginLeft: -24, marginRight: -24, marginBottom: -24, background: '#fff', borderTop: '1px solid #eef0f8' }}>
        <div style={{ padding: '12px 24px 24px' }}>
          <Tabs items={tabItems} />
        </div>
      </div>
      <Modal
        title={
          <div style={{
            background: 'linear-gradient(135deg,#F5A623,#F97316)',
            margin: '-20px -24px 20px',
            padding: '18px 24px',
            borderRadius: '8px 8px 0 0',
            display: 'flex',
            alignItems: 'center',
            gap: 12,
          }}>
            <div style={{
              width: 40, height: 40, borderRadius: 10,
              background: 'rgba(255,255,255,0.2)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}>
              <PictureOutlined style={{ color: '#fff', fontSize: 20 }} />
            </div>
            <div>
              <div style={{ color: '#fff', fontWeight: 800, fontSize: 16 }}>
                {editing ? '编辑 Banner' : '新增 Banner'}
              </div>
              <div style={{ color: 'rgba(255,255,255,0.85)', fontSize: 12, marginTop: 2 }}>
                {editing ? '更新轮播图内容，打造更好的视觉体验' : '✨ 打造精彩轮播，第一眼就让顾客爱上你！'}
              </div>
            </div>
          </div>
        }
        open={modalOpen}
        onCancel={() => setModalOpen(false)}
        footer={null}
        width={880}
        styles={{ body: { maxHeight: 'calc(85vh - 150px)', overflowY: 'auto', overflowX: 'hidden' } }}
      >
        <div style={{ marginBottom: 16 }}>
          <BannerPreview title={form.getFieldValue('title')} gradient={previewGrad} />
        </div>

        <Row gutter={8} style={{ marginBottom: 16 }}>
          {GRADIENT_PRESETS.map(g => (
            <Col key={g.value}>
              <div
                onClick={() => setPreviewGrad(g.value)}
                style={{
                  width: 48, height: 28, borderRadius: 6, background: g.value,
                  cursor: 'pointer', border: previewGrad === g.value ? '2px solid #333' : '2px solid transparent',
                }}
              />
            </Col>
          ))}
        </Row>

        <Form form={form} layout="vertical" onFinish={handleSubmit}>
          <Row gutter={16}>
            <Col span={24}>
              <Form.Item name="title" label="Banner 标题" rules={[{ required: true, message: '请输入标题' }]}>
                <Input prefix={<PictureOutlined style={{ color: '#F5A623' }} />} placeholder="如：限时特惠 · 首单立减 $20"
                  onChange={() => setPreviewGrad(prev => prev)} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="imageUrl" label="图片链接（可选）">
                <Input prefix={<PictureOutlined style={{ color: '#F97316' }} />} placeholder="https://cdn.example.com/banner.jpg" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="linkUrl" label="跳转链接（可选）">
                <Input prefix={<LinkOutlined style={{ color: '#6366f1' }} />} placeholder="/service/xxx 或 https://..." />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="sort" label="排序（数字越小越靠前）">
                <InputNumber min={1} style={{ width: '100%' }} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="status" label="上线状态" valuePropName="checked">
                <Switch checkedChildren="已上线" unCheckedChildren="已下线" />
              </Form.Item>
            </Col>
          </Row>
          <Row justify="end" gutter={12}>
            <Col><Button onClick={() => setModalOpen(false)} style={{ borderRadius: 8 }}>取消</Button></Col>
            <Col>
              <Button type="primary" htmlType="submit" style={{ background: 'linear-gradient(135deg,#F5A623,#F97316)', border: 'none', borderRadius: 8 }}>
                {editing ? '保存修改' : '确认新增'}
              </Button>
            </Col>
          </Row>
        </Form>
      </Modal>
    </div>
  )
}
