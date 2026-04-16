import { useEffect, useState, useCallback } from 'react'
import {
  Table, Button, Space, Tag, Modal, Form, Input, Select, message,
  Popconfirm, Tooltip, Badge, Divider, Drawer, Row, Col,
} from 'antd'
import {
  BellOutlined, PlusOutlined, EditOutlined, DeleteOutlined,
  ReloadOutlined, SearchOutlined, EyeOutlined, WarningOutlined,
  NotificationOutlined, InfoCircleOutlined, TagOutlined,
  SafetyCertificateOutlined, CalendarOutlined, SettingOutlined,
  CheckCircleOutlined, StopOutlined,
} from '@ant-design/icons'
import { usePortalScope } from '../../hooks/usePortalScope'
import RichTextInput from '../../components/common/RichTextInput'
import PermGuard from '../../components/common/PermGuard'
import { col, styledTableComponents, INPUT_STYLE } from '../../components/common/tableComponents'
import PagePagination from '../../components/common/PagePagination'
import { useTableBodyHeight } from '../../hooks/useTableBodyHeight'

interface Notice {
  id: number
  title: string
  type: number
  content?: string
  status: number
  createBy?: string
  createTime?: string
}

const PAGE_GRADIENT = 'linear-gradient(135deg,#f59e0b,#d97706)'

const TYPE_CFG: Record<number, { label: string; color: string; icon: React.ReactNode }> = {
  1: { label: '通知', color: 'blue', icon: <InfoCircleOutlined /> },
  2: { label: '公告', color: 'green', icon: <NotificationOutlined /> },
  3: { label: '警告', color: 'red', icon: <WarningOutlined /> },
}

export default function NoticePage() {
  const { ref, height: tableBodyH } = useTableBodyHeight()
  const { noticeList, noticeAdd, noticeEdit, noticeDelete } = usePortalScope()
  const [notices, setNotices] = useState<Notice[]>([])
  const [loading, setLoading] = useState(false)
  const [current, setCurrent] = useState(1)
  const [pageSize, setPageSize] = useState(10)
  const [total, setTotal] = useState(0)
  const [modalOpen, setModalOpen] = useState(false)
  const [editing, setEditing] = useState<Notice | null>(null)
  const [form] = Form.useForm()
  const [searchTitle, setSearchTitle] = useState('')
  const [searchType, setSearchType] = useState<number | undefined>()
  const [searchStatus, setSearchStatus] = useState<number | undefined>()
  const [viewDrawer, setViewDrawer] = useState(false)
  const [viewing, setViewing] = useState<Notice | null>(null)

  const fetchList = useCallback(async () => {
    setLoading(true)
    try {
      const res = await noticeList({ current, size: pageSize, keyword: searchTitle || undefined, type: searchType, status: searchStatus })
      const d = res.data?.data
      setNotices(d?.list ?? d?.records ?? [])
      setTotal(d?.total ?? 0)
    } finally {
      setLoading(false)
    }
  }, [current, pageSize, searchTitle, searchType, searchStatus])

  useEffect(() => { fetchList() }, [fetchList])

  const openModal = (record?: Notice) => {
    setEditing(record ?? null)
    if (record) form.setFieldsValue({ ...record })
    else { form.resetFields(); form.setFieldsValue({ type: 1, status: 1 }) }
    setModalOpen(true)
  }

  const handleOk = async () => {
    const values = await form.validateFields()
    if (editing) {
      await noticeEdit({ id: editing.id, ...values })
      message.success('修改成功')
    } else {
      await noticeAdd(values)
      message.success('发布成功')
    }
    setModalOpen(false)
    fetchList()
  }

  const handleDelete = async (id: number) => {
    await noticeDelete(id)
    message.success('删除成功')
    fetchList()
  }

  const handleSearch = () => {
    if (current === 1) fetchList()
    else setCurrent(1)
  }

  const handleReset = () => {
    setSearchTitle('')
    setSearchType(undefined)
    setSearchStatus(undefined)
    setCurrent(1)
  }

  const columns = [
    {
      title: col(<BellOutlined style={{ color: '#6366f1' }} />, '标题', 'left'), dataIndex: 'title', key: 'title',
      render: (v: string, r: Notice) => {
        const cfg = TYPE_CFG[r.type]
        return (
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, width: '100%' }}>
            <div style={{
              width: 32, height: 32, borderRadius: 8, flexShrink: 0,
              background: r.type === 1 ? 'linear-gradient(135deg,#4facfe,#00f2fe)' : r.type === 2 ? 'linear-gradient(135deg,#43e97b,#38f9d7)' : 'linear-gradient(135deg,#f093fb,#f5576c)',
              display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', fontSize: 14,
            }}>{cfg?.icon}</div>
            <div>
              <div style={{ fontWeight: 600, color: '#222' }}>{v}</div>
              <div style={{ fontSize: 12, color: '#999' }}>发布人：{r.createBy || '-'}</div>
            </div>
          </div>
        )
      },
    },
    {
      title: col(<TagOutlined style={{ color: '#6366f1' }} />, '类型'), dataIndex: 'type', key: 'type',
      render: (v: number) => {
        const cfg = TYPE_CFG[v]
        return cfg ? <Tag color={cfg.color} icon={cfg.icon} style={{ borderRadius: 6 }}>{cfg.label}</Tag> : '-'
      },
    },
    {
      title: col(<SafetyCertificateOutlined style={{ color: '#6366f1' }} />, '状态'), dataIndex: 'status', key: 'status',
      render: (v: number) => v === 1
        ? <Badge status="success" text={<span style={{ color: '#52c41a', fontWeight: 600 }}>正常</span>} />
        : <Badge status="default" text={<span style={{ color: '#999' }}>关闭</span>} />,
    },
    {
      title: col(<CalendarOutlined style={{ color: '#6366f1' }} />, '发布时间'), dataIndex: 'createTime', key: 'createTime',
      render: (v: string) => v ? <span style={{ color: '#666', fontSize: 13 }}>{v.substring(0, 16)}</span> : '-',
    },
    {
      title: col(<SettingOutlined style={{ color: '#6366f1' }} />, '操作'), key: 'action', width: 225,
      render: (_: any, r: Notice) => (
        <Space size={4}>
          <Button size="small" type="primary" ghost icon={<EyeOutlined />}
            style={{ borderRadius: 6 }}
            onClick={() => { setViewing(r); setViewDrawer(true) }}>查看</Button>
          <PermGuard code="notice:edit">
            <Button size="small" icon={<EditOutlined />}
              style={{ borderRadius: 6, color: '#fa8c16', borderColor: '#ffd591' }}
              onClick={() => openModal(r)}>编辑</Button>
          </PermGuard>
          <PermGuard code="notice:delete">
            <Popconfirm title="确认删除该公告？" onConfirm={() => handleDelete(r.id)} okText="删除" cancelText="取消" okButtonProps={{ danger: true }}>
              <Button size="small" danger icon={<DeleteOutlined />} style={{ borderRadius: 6 }}>删除</Button>
            </Popconfirm>
          </PermGuard>
        </Space>
      ),
    },
  ]

  return (
    <div style={{ marginTop: -24 }}>
      <div style={{ position: 'sticky', top: 64, zIndex: 88, marginLeft: -24, marginRight: -24, background: 'rgba(255,255,255,0.97)', backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)', borderBottom: '1px solid rgba(0,0,0,0.07)', boxShadow: '0 4px 20px rgba(0,0,0,0.06)' }}>
        <div style={{ display: 'flex', alignItems: 'center', padding: '10px 24px 0', gap: 12 }}>
          <div style={{ width: 34, height: 34, borderRadius: 10, background: PAGE_GRADIENT, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 4px 12px rgba(245,158,11,0.35)', flexShrink: 0 }}>
            <BellOutlined style={{ color: '#fff', fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1e293b', lineHeight: 1.2 }}>通知公告</div>
            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>发布 · 管理平台公告</div>
          </div>
          <div style={{ width: 1, height: 20, margin: '0 4px', background: '#e0e4ff', flexShrink: 0 }} />
          <div style={{ display: 'flex', gap: 8 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: 'rgba(99,102,241,0.1)', border: '1px solid rgba(99,102,241,0.25)' }}>
              <span>📋</span><span style={{ fontSize: 12, color: '#6b7280' }}>总数</span><span style={{ fontSize: 13, fontWeight: 700, color: '#6366f1' }}>{total}</span>
            </div>
          </div>
          <div style={{ flex: 1 }} />
          <PermGuard code="notice:add">
            <Button type="primary" icon={<PlusOutlined />} onClick={() => openModal()} style={{ borderRadius: 8, background: 'linear-gradient(135deg,#6366f1,#8b5cf6)', border: 'none' }}>新增</Button>
          </PermGuard>
        </div>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', padding: '10px 24px 12px' }}>
          <Input placeholder="公告标题" prefix={<BellOutlined style={{ color: '#f59e0b', fontSize: 12 }} />} value={searchTitle} onChange={e => setSearchTitle(e.target.value)} allowClear size="middle" style={{ width: 180, ...INPUT_STYLE }} />
          <Select placeholder={<Space size={4}><TagOutlined style={{ color: '#f59e0b', fontSize: 12 }} />公告类型</Space>} allowClear style={{ width: 115 }} value={searchType} onChange={v => setSearchType(v)}>
            <Select.Option value={1}><Space size={4}><BellOutlined style={{ color: '#3b82f6' }} />通知</Space></Select.Option>
            <Select.Option value={2}><Space size={4}><NotificationOutlined style={{ color: '#10b981' }} />公告</Space></Select.Option>
            <Select.Option value={3}><Space size={4}><WarningOutlined style={{ color: '#ef4444' }} />警告</Space></Select.Option>
          </Select>
          <Select placeholder={<Space size={4}><CheckCircleOutlined style={{ color: '#10b981', fontSize: 12 }} />公告状态</Space>} allowClear style={{ width: 115 }} value={searchStatus} onChange={v => setSearchStatus(v)}>
            <Select.Option value={1}><Space size={4}><CheckCircleOutlined style={{ color: '#10b981' }} />正常</Space></Select.Option>
            <Select.Option value={0}><Space size={4}><StopOutlined style={{ color: '#ef4444' }} />关闭</Space></Select.Option>
          </Select>
          <div style={{ flex: 1 }} />
          <Button icon={<ReloadOutlined />} size="middle" style={{ borderRadius: 8 }} onClick={handleReset}>重置</Button>
          <Tooltip title="刷新"><Button icon={<ReloadOutlined />} size="middle" loading={loading} style={{ borderRadius: 8, color: '#6366f1', borderColor: '#c7d2fe' }} onClick={fetchList} /></Tooltip>
          <Button type="primary" icon={<SearchOutlined />} style={{ borderRadius: 8, border: 'none', background: 'linear-gradient(135deg,#6366f1,#8b5cf6)' }} onClick={handleSearch}>搜索</Button>
        </div>
      </div>
      <div ref={ref} style={{ marginLeft: -24, marginRight: -24, marginBottom: -24, background: '#fff', borderTop: '1px solid #eef0f8' }}>
        <Table columns={columns} dataSource={notices} rowKey="id" loading={loading} pagination={false} components={styledTableComponents} scroll={{ x: 'max-content', y: tableBodyH }} size="middle" />
        <PagePagination total={total} current={current} pageSize={pageSize} onChange={p => setCurrent(p)} onSizeChange={setPageSize} countLabel="条公告" pageSizeOptions={[10, 20, 50, 100]} />
      </div>

      <Modal open={modalOpen} onCancel={() => setModalOpen(false)} onOk={handleOk}
        title={
          <div style={{
            background: editing
              ? 'linear-gradient(135deg,#38f9d7,#43e97b)'
              : 'linear-gradient(135deg,#43e97b,#38f9d7)',
            margin: '-20px -24px 20px',
            padding: '18px 24px',
            borderRadius: '8px 8px 0 0',
            display: 'flex',
            alignItems: 'center',
            gap: 12,
          }}>
            <div style={{
              width: 40, height: 40, borderRadius: 10,
              background: 'rgba(255,255,255,0.25)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}>
              <BellOutlined style={{ color: '#fff', fontSize: 20 }} />
            </div>
            <div>
              <div style={{ color: '#fff', fontWeight: 800, fontSize: 16 }}>
                {editing ? '编辑公告' : '发布新公告'}
              </div>
              <div style={{ color: 'rgba(255,255,255,0.85)', fontSize: 12, marginTop: 2 }}>
                {editing ? '修改公告内容，确保信息准确及时' : '📢 发布重要通知，让消息精准触达每位用户！'}
              </div>
            </div>
          </div>
        }
        okText={editing ? '保存修改' : '立即发布'}
        okButtonProps={{ style: { background: 'linear-gradient(135deg,#43e97b,#38f9d7)', border: 'none', borderRadius: 8, color: '#fff' } }}
        cancelButtonProps={{ style: { borderRadius: 8 } }}
        width={880}
        styles={{ body: { maxHeight: 'calc(85vh - 150px)', overflowY: 'auto', overflowX: 'hidden' } }}>
        <Form form={form} layout="vertical">
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="type" label="公告类型" rules={[{ required: true }]}>
                <Select style={{ borderRadius: 8 }}>
                  <Select.Option value={1}><Tag color="blue"><InfoCircleOutlined /> 通知</Tag></Select.Option>
                  <Select.Option value={2}><Tag color="green"><NotificationOutlined /> 公告</Tag></Select.Option>
                  <Select.Option value={3}><Tag color="red"><WarningOutlined /> 警告</Tag></Select.Option>
                </Select>
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="status" label="公告状态">
                <Select style={{ borderRadius: 8 }}>
                  <Select.Option value={1}><Badge status="success" text="立即发布" /></Select.Option>
                  <Select.Option value={0}><Badge status="default" text="暂不发布" /></Select.Option>
                </Select>
              </Form.Item>
            </Col>
            <Col span={24}>
              <Form.Item name="title" label="公告标题" rules={[{ required: true, message: '请输入公告标题' }]}>
                <Input prefix={<BellOutlined style={{ color: '#43e97b' }} />} placeholder="请输入公告标题（50字以内）" maxLength={50} showCount style={{ borderRadius: 8 }} />
              </Form.Item>
            </Col>
          </Row>
          <Form.Item name="content" label="公告内容">
            <RichTextInput placeholder="请输入公告内容，支持富文本格式（加粗、列表、链接等）..." minHeight={200} />
          </Form.Item>
        </Form>
      </Modal>

      <Drawer open={viewDrawer} onClose={() => setViewDrawer(false)} styles={{ wrapper: { width: 560 } }}
        title={
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            {viewing && (
              <div style={{
                width: 32, height: 32, borderRadius: 8,
                background: viewing.type === 1 ? 'linear-gradient(135deg,#4facfe,#00f2fe)' : viewing.type === 2 ? 'linear-gradient(135deg,#43e97b,#38f9d7)' : 'linear-gradient(135deg,#f093fb,#f5576c)',
                display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff',
              }}>{TYPE_CFG[viewing.type]?.icon}</div>
            )}
            <span>查看公告</span>
          </div>
        }>
        {viewing && (
          <div>
            <div style={{ background: 'linear-gradient(135deg,#f5f7fa,#c3cfe2)', borderRadius: 12, padding: 20, marginBottom: 20 }}>
              <div style={{ fontSize: 20, fontWeight: 700, marginBottom: 8 }}>{viewing.title}</div>
              <Space>
                {TYPE_CFG[viewing.type] && <Tag color={TYPE_CFG[viewing.type].color} icon={TYPE_CFG[viewing.type].icon}>{TYPE_CFG[viewing.type].label}</Tag>}
                {viewing.status === 1 ? <Badge status="success" text="正常发布" /> : <Badge status="default" text="已关闭" />}
              </Space>
              <div style={{ marginTop: 8, color: '#666', fontSize: 13 }}>发布时间：{viewing.createTime?.substring(0, 16)} | 发布人：{viewing.createBy}</div>
            </div>
            <Divider />
            <div style={{ fontSize: 15, lineHeight: 1.8, color: '#333', whiteSpace: 'pre-line' }}>
              {viewing.content || '（无内容）'}
            </div>
          </div>
        )}
      </Drawer>
    </div>
  )
}
