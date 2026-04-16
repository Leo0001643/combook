/**
 * AnnouncePage — 公告管理页（内部公告 / 客户公告）
 *
 * Props:
 *   type = 1 → 内部公告（员工可见）
 *   type = 2 → 客户公告（会员可见）
 */
import { useState, useEffect, useCallback } from 'react'
import {
  Input, Select, Button, Table, Tag, Badge, Space,
  Modal, Form, message, Tooltip, Typography, Popconfirm, Switch,
  Divider,
} from 'antd'
import type { ColumnsType } from 'antd/es/table'
import {
  PlusOutlined, SearchOutlined, ReloadOutlined, EditOutlined,
  DeleteOutlined, SoundOutlined, TeamOutlined, GlobalOutlined,
  ClockCircleOutlined, UserOutlined, EyeOutlined, FileTextOutlined,
  TagOutlined, SafetyCertificateOutlined, SettingOutlined,
  BellOutlined, CheckCircleOutlined,
} from '@ant-design/icons'
import RichTextInput from '../../components/common/RichTextInput'
import { merchantPortalApi, type AnnouncementVO } from '../../api/api'
import dayjs from 'dayjs'
import PermGuard from '../../components/common/PermGuard'
import { styledTableComponents, col, INPUT_STYLE } from '../../components/common/tableComponents'
import PagePagination from '../../components/common/PagePagination'
import { useTableBodyHeight } from '../../hooks/useTableBodyHeight'

const { Text } = Typography

interface Props {
  type: 1 | 2
}

const TARGET_OPTS = [
  { label: '全部', value: 2 },
  { label: '本部门', value: 1 },
]

const STATUS_MAP: Record<number, { label: string; color: string }> = {
  0: { label: '草稿', color: 'default' },
  1: { label: '已发布', color: 'success' },
}

export default function AnnouncePage({ type }: Props) {
  const { ref, height: tableBodyH } = useTableBodyHeight()
  const isInternal  = type === 1
  const pageTitle   = isInternal ? '内部公告' : '客户公告'
  const pageSubtitle = isInternal
    ? '面向员工发布的内部通知、政策文件、工作安排等'
    : '面向会员发布的活动资讯、优惠公告、服务通知等'
  const gradientFrom = isInternal ? '#667eea' : '#f093fb'
  const gradientTo   = isInternal ? '#764ba2' : '#f5576c'

  const [list,     setList]     = useState<AnnouncementVO[]>([])
  const [total,    setTotal]    = useState(0)
  const [page,     setPage]     = useState(1)
  const [pageSize, setPageSize] = useState(15)
  const [loading,  setLoading]  = useState(false)
  const [keyword,  setKeyword]  = useState('')
  const [status,   setStatus]   = useState<number | undefined>()

  const [modalOpen,   setModalOpen]   = useState(false)
  const [editing,     setEditing]     = useState<AnnouncementVO | null>(null)
  const [viewItem,    setViewItem]    = useState<AnnouncementVO | null>(null)
  const [saving,      setSaving]      = useState(false)

  const [form] = Form.useForm()

  const fetchList = useCallback(async () => {
    setLoading(true)
    try {
      const res = await merchantPortalApi.announceList({ type, status, keyword, page, size: pageSize })
      if (res.data?.code === 200) {
        const d = res.data.data
        setList(d.records ?? [])
        setTotal(d.total  ?? 0)
      }
    } finally {
      setLoading(false)
    }
  }, [type, status, keyword, page, pageSize])

  useEffect(() => { fetchList() }, [fetchList])

  const openAdd = () => {
    setEditing(null)
    form.resetFields()
    form.setFieldsValue({ targetType: 2, status: true })
    setModalOpen(true)
  }

  const openEdit = (row: AnnouncementVO) => {
    setEditing(row)
    form.setFieldsValue({
      title:      row.title,
      content:    row.content,
      targetType: row.targetType,
      status:     row.status === 1,
    })
    setModalOpen(true)
  }

  const handleSubmit = async () => {
    const vals = await form.validateFields()
    setSaving(true)
    try {
      const payload = {
        ...vals,
        status:     vals.status ? 1 : 0,
        type,
      }
      if (editing) {
        await merchantPortalApi.announceEdit({ id: editing.id, ...payload })
        message.success('更新成功')
      } else {
        await merchantPortalApi.announceAdd(payload)
        message.success('发布成功')
      }
      setModalOpen(false)
      fetchList()
    } finally {
      setSaving(false)
    }
  }

  const handleDelete = async (id: number) => {
    await merchantPortalApi.announceDelete(id)
    message.success('已删除')
    fetchList()
  }

  const handleToggleStatus = async (row: AnnouncementVO) => {
    await merchantPortalApi.announceStatus(row.id, row.status === 1 ? 0 : 1)
    message.success(row.status === 1 ? '已撤回为草稿' : '已发布')
    fetchList()
  }

  const columns: ColumnsType<AnnouncementVO> = [
    {
      title: col(<SoundOutlined style={{ color: '#f97316' }} />, '公告标题'),
      dataIndex: 'title',
      ellipsis: true,
      render: (title: string, row) => (
        <Space orientation="vertical" size={2}>
          <Space size={6}>
            {row.targetType === 2
              ? <GlobalOutlined style={{ color: '#6366f1', fontSize: 13 }} />
              : <TeamOutlined   style={{ color: '#f59e0b', fontSize: 13 }} />}
            <Text
              strong
              style={{ cursor: 'pointer', color: '#1d1d1f' }}
              onClick={() => setViewItem(row)}
            >
              {title}
            </Text>
          </Space>
          <Text type="secondary" style={{ fontSize: 12 }}>
            <ClockCircleOutlined style={{ marginRight: 4 }} />
            {dayjs(row.createTime).format('MM-DD HH:mm')}
            {row.createBy && (
              <span style={{ marginLeft: 8 }}>
                <UserOutlined style={{ marginRight: 3 }} />{row.createBy}
              </span>
            )}
          </Text>
        </Space>
      ),
    },
    {
      title: col(<GlobalOutlined style={{ color: '#3b82f6' }} />, '发送范围'),
      dataIndex: 'targetType',
      width: 100,
        render: (v: number) => (
        <Tag color={v === 2 ? 'blue' : 'orange'} style={{ borderRadius: 6 }}>
          {v === 2 ? '全部' : '本部门'}
        </Tag>
      ),
    },
    {
      title: col(<SafetyCertificateOutlined style={{ color: '#10b981' }} />, '状态'),
      dataIndex: 'status',
      width: 100,
      render: (v: number, row) => (
        <Tooltip title={v === 1 ? '点击撤回为草稿' : '点击发布'}>
          <Badge
            status={STATUS_MAP[v]?.color as any ?? 'default'}
            text={
              <Text
                style={{ cursor: 'pointer', fontSize: 13,
                  color: v === 1 ? '#22c55e' : '#9ca3af' }}
                onClick={() => handleToggleStatus(row)}
              >
                {STATUS_MAP[v]?.label}
              </Text>
            }
          />
        </Tooltip>
      ),
    },
    {
      title: col(<SettingOutlined style={{ color: '#9ca3af' }} />, '操作'),
      width: 225,
      render: (_: unknown, row: AnnouncementVO) => (
        <Space size={4}>
          <Button size="small" type="primary" ghost icon={<EyeOutlined />}
            style={{ borderRadius: 6 }} onClick={() => setViewItem(row)}>查看</Button>
          <PermGuard code="announce:edit">
            <Button size="small" icon={<EditOutlined />}
              style={{ borderRadius: 6, color: '#fa8c16', borderColor: '#ffd591' }}
              onClick={() => openEdit(row)}>编辑</Button>
          </PermGuard>
          <PermGuard code="announce:delete">
            <Popconfirm title="确认删除该公告？" onConfirm={() => handleDelete(row.id)} okText="删除" cancelText="取消" okButtonProps={{ danger: true }}>
              <Button size="small" danger icon={<DeleteOutlined />} style={{ borderRadius: 6 }}>删除</Button>
            </Popconfirm>
          </PermGuard>
        </Space>
      ),
    },
  ]

  // ── modal gradient header ────────────────────────────────────────────────
  const modalTitle = (
    <div style={{
      background: `linear-gradient(135deg, ${gradientFrom} 0%, ${gradientTo} 100%)`,
      margin: '-20px -24px 0',
      padding: '20px 24px 18px',
      borderRadius: '8px 8px 0 0',
      display: 'flex', alignItems: 'center', gap: 10,
    }}>
      <div style={{
        width: 36, height: 36, borderRadius: 10, background: 'rgba(255,255,255,0.25)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <SoundOutlined style={{ color: '#fff', fontSize: 18 }} />
      </div>
      <div>
        <div style={{ color: '#fff', fontWeight: 700, fontSize: 15 }}>
          {editing ? '编辑公告' : `发布${pageTitle}`}
        </div>
        <div style={{ color: 'rgba(255,255,255,0.72)', fontSize: 12, marginTop: 2 }}>
          {editing ? '修改公告内容后重新发布' : '填写公告信息并选择发送范围'}
        </div>
      </div>
    </div>
  )

  return (
    <div style={{ marginTop: -24 }}>
      {/* Sticky composite header */}
      <div style={{ position: 'sticky', top: 64, zIndex: 88, marginLeft: -24, marginRight: -24, background: 'rgba(255,255,255,0.97)', backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)', borderBottom: '1px solid rgba(0,0,0,0.07)', boxShadow: '0 4px 20px rgba(0,0,0,0.06)' }}>
        {/* Title row */}
        <div style={{ display: 'flex', alignItems: 'center', padding: '10px 24px 0', gap: 12 }}>
          <div style={{ width: 34, height: 34, borderRadius: 10, background: isInternal ? 'linear-gradient(135deg,#667eea,#764ba2)' : 'linear-gradient(135deg,#f093fb,#f5576c)', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 4px 12px rgba(99,102,241,0.3)', flexShrink: 0 }}>
            <SoundOutlined style={{ color: '#fff', fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1e293b', lineHeight: 1.2 }}>{pageTitle}</div>
            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>{pageSubtitle}</div>
          </div>
          <Divider type="vertical" style={{ height: 20, margin: '0 4px', borderColor: '#e0e4ff' }} />
          <div style={{ display: 'flex', gap: 8 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: 'rgba(99,102,241,0.1)', border: '1px solid rgba(99,102,241,0.25)' }}>
              <span style={{ fontSize: 13 }}>📢</span>
              <span style={{ fontSize: 12, color: '#6b7280' }}>公告总数</span>
              <span style={{ fontSize: 13, fontWeight: 700, color: '#6366f1' }}>{total}</span>
            </div>
          </div>
          <div style={{ flex: 1 }} />
          <PermGuard code="announce:add">
            <Button type="primary" icon={<PlusOutlined />} onClick={openAdd} style={{ borderRadius: 8, border: 'none', background: isInternal ? 'linear-gradient(135deg,#667eea,#764ba2)' : 'linear-gradient(135deg,#f093fb,#f5576c)' }}>发布{pageTitle}</Button>
          </PermGuard>
        </div>
        {/* Filter row */}
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', padding: '10px 24px 12px' }}>
          <Input prefix={<SearchOutlined style={{ color: '#6366f1', fontSize: 12 }} />} placeholder="搜索标题或内容..." value={keyword} onChange={e => { setKeyword(e.target.value); setPage(1) }} allowClear size="middle" style={{ ...INPUT_STYLE, width: 220 }} />
          <Select placeholder={<Space size={4}><BellOutlined style={{ color: '#f59e0b', fontSize: 12 }} />发布状态</Space>} allowClear size="middle" style={{ width: 115 }} options={[
            { label: <Space size={4}><EditOutlined style={{ color: '#f59e0b' }} />草稿</Space>, value: 0 },
            { label: <Space size={4}><CheckCircleOutlined style={{ color: '#10b981' }} />已发布</Space>, value: 1 },
          ]} value={status} onChange={v => { setStatus(v); setPage(1) }} />
          <div style={{ flex: 1 }} />
          <Button icon={<ReloadOutlined />} size="middle" style={{ borderRadius: 8 }} onClick={() => { setKeyword(''); setStatus(undefined); setPage(1) }}>重置</Button>
          <Tooltip title="刷新列表"><Button icon={<ReloadOutlined />} size="middle" loading={loading} style={{ borderRadius: 8, color: '#6366f1', borderColor: '#c7d2fe' }} onClick={() => fetchList()} /></Tooltip>
          <Button type="primary" icon={<SearchOutlined />} size="middle" style={{ borderRadius: 8, border: 'none', background: 'linear-gradient(135deg,#6366f1,#8b5cf6)', boxShadow: '0 2px 8px rgba(99,102,241,0.35)' }} onClick={() => { if (page !== 1) setPage(1); else void fetchList() }}>搜索</Button>
        </div>
      </div>
      {/* Table area */}
      <div ref={ref} style={{ marginLeft: -24, marginRight: -24, marginBottom: -24, background: '#fff', borderTop: '1px solid #eef0f8' }}>
        <Table<AnnouncementVO> rowKey="id" columns={columns} dataSource={list} loading={loading} size="middle" pagination={false} components={styledTableComponents} scroll={{ x: 'max-content', y: tableBodyH }} />
        <PagePagination total={total} current={page} pageSize={pageSize} onChange={p => setPage(p)} onSizeChange={s => { setPageSize(s); setPage(1) }} countLabel="条公告" pageSizeOptions={[15, 20, 50, 100]} />
      </div>

      {/* ── 新增/编辑 Modal ── */}
      <Modal
        open={modalOpen}
        onCancel={() => setModalOpen(false)}
        onOk={handleSubmit}
        confirmLoading={saving}
        width={880}
        title={modalTitle}
        okText={editing ? '保存更新' : '立即发布'}
        cancelText="取消"
        style={{ top: '5vh' }}
        styles={{ body: { paddingTop: 24, maxHeight: 'calc(85vh - 160px)', overflowY: 'auto', overflowX: 'hidden' } }}
        okButtonProps={{ style: { background: `linear-gradient(135deg, ${gradientFrom}, ${gradientTo})`, border: 'none', borderRadius: 8 } }}
      >
        <Form form={form} layout="vertical">
          <div style={{ display: 'grid', gridTemplateColumns: 'minmax(0,2fr) minmax(0,1fr)', gap: 16 }}>
            <Form.Item
              name="title"
              label={<Space size={4}><TagOutlined style={{ color: '#6366f1' }} /><span>公告标题</span></Space>}
              rules={[{ required: true, message: '请输入公告标题' }]}
            >
              <Input placeholder="请输入公告标题（50字以内）" maxLength={50} showCount style={{ borderRadius: 8 }} />
            </Form.Item>
            <Form.Item
              name="targetType"
              label={<Space size={4}><GlobalOutlined style={{ color: '#3b82f6' }} /><span>发送范围</span></Space>}
            >
              <Select options={TARGET_OPTS} style={{ borderRadius: 8 }} />
            </Form.Item>
          </div>
          <Form.Item
            name="status"
            label={<Space size={4}><SoundOutlined style={{ color: '#10b981' }} /><span>发布状态</span></Space>}
            valuePropName="checked"
          >
            <Switch checkedChildren="立即发布" unCheckedChildren="存为草稿" />
          </Form.Item>
          <Form.Item
            name="content"
            label={<Space size={4}><FileTextOutlined style={{ color: '#f59e0b' }} /><span>公告内容</span></Space>}
            rules={[{ required: true, message: '请输入公告内容' }]}
          >
            <RichTextInput placeholder="请输入公告内容，支持富文本格式..." minHeight={200} />
          </Form.Item>
        </Form>
      </Modal>

      {/* ── 查看详情 Modal ── */}
      <Modal
        open={!!viewItem}
        onCancel={() => setViewItem(null)}
        footer={<Button onClick={() => setViewItem(null)}>关闭</Button>}
        width={880}
        title={
          <div style={{
            background: `linear-gradient(135deg, ${gradientFrom} 0%, ${gradientTo} 100%)`,
            margin: '-20px -24px 0',
            padding: '20px 24px 18px',
            borderRadius: '8px 8px 0 0',
          }}>
            <Text strong style={{ color: '#fff', fontSize: 16, display: 'block', margin: 0 }}>
              <EyeOutlined style={{ marginRight: 8 }} />
              {viewItem?.title}
            </Text>
            <div style={{ color: 'rgba(255,255,255,0.7)', fontSize: 12, marginTop: 6, display: 'flex', gap: 16 }}>
              <span><ClockCircleOutlined style={{ marginRight: 4 }} />{dayjs(viewItem?.createTime).format('YYYY-MM-DD HH:mm')}</span>
              {viewItem?.createBy && <span><UserOutlined style={{ marginRight: 4 }} />{viewItem.createBy}</span>}
              <span>
                {viewItem?.targetType === 2
                  ? <><GlobalOutlined style={{ marginRight: 4 }} />全部</>
                  : <><TeamOutlined   style={{ marginRight: 4 }} />本部门</>}
              </span>
            </div>
          </div>
        }
        styles={{ body: { paddingTop: 20, maxHeight: 'calc(85vh - 120px)', overflowY: 'auto', overflowX: 'hidden' } }}
      >
        {viewItem && (
          <div
            className="ql-editor"
            style={{ padding: 0, minHeight: 120 }}
            dangerouslySetInnerHTML={{ __html: viewItem.content }}
          />
        )}
      </Modal>
    </div>
  )
}
