import { useState, useEffect } from 'react'
import {
  Table, Button, Space, Typography, message, Modal, Form,
  Input, InputNumber, Select, Badge, Row, Col, Tag,
  Tooltip, Divider, Popconfirm,
} from 'antd'
import type { ColumnsType } from 'antd/es/table'
import {
  PlusOutlined, EditOutlined, DeleteOutlined,
  CheckCircleOutlined, StopOutlined, ReloadOutlined,
  ApartmentOutlined, SearchOutlined, SolutionOutlined,
  SortAscendingOutlined, FileTextOutlined, SafetyCertificateOutlined,
  ClockCircleOutlined, SettingOutlined,
} from '@ant-design/icons'
import { positionApi, type PositionVO } from '../../api/api'
import RichTextInput from '../../components/common/RichTextInput'
import PermGuard from '../../components/common/PermGuard'
import { col, styledTableComponents, INPUT_STYLE } from '../../components/common/tableComponents'
import { useTableBodyHeight } from '../../hooks/useTableBodyHeight'
import PagePagination from '../../components/common/PagePagination'
import { fmtDate } from '../../utils/time'

const { Text } = Typography
const { Option } = Select

const GRADIENT = 'linear-gradient(135deg,#0891b2,#0ea5e9)'

const POSITION_COLORS = [
  '#6366f1', '#8b5cf6', '#ec4899', '#ef4444',
  '#f59e0b', '#10b981', '#3b82f6', '#06b6d4',
]

export default function PositionListPage() {
  const { ref, height: tableBodyH } = useTableBodyHeight(46)
  const [allData, setAllData]     = useState<PositionVO[]>([])
  const [data, setData]           = useState<PositionVO[]>([])
  const [page, setPage]           = useState(1)
  const [pageSize, setPageSize]   = useState(20)
  const [loading, setLoading]     = useState(false)
  const [modalOpen, setModalOpen] = useState(false)
  const [editing, setEditing]     = useState<PositionVO | null>(null)
  const [keyword, setKeyword]     = useState('')
  const [keywordDraft, setKeywordDraft] = useState('')
  const [status, setStatus]       = useState<number | undefined>()
  const [form] = Form.useForm()

  useEffect(() => { loadData() }, [])
  useEffect(() => {
    let filtered = allData
    if (keyword) filtered = filtered.filter(p => p.name.includes(keyword) || p.code.includes(keyword.toUpperCase()))
    if (status !== undefined) filtered = filtered.filter(p => p.status === status)
    setData(filtered)
    setPage(1)
  }, [allData, keyword, status])

  const loadData = async () => {
    setLoading(true)
    try {
      const res = await positionApi.list()
      const list: PositionVO[] = res.data?.data ?? []
      setAllData(list.sort((a, b) => a.sort - b.sort))
    } finally { setLoading(false) }
  }

  const handleSearch = () => {
    setKeyword(keywordDraft)
  }

  const handleReset = () => {
    setKeywordDraft('')
    setKeyword('')
    setStatus(undefined)
  }

  const openAdd = () => {
    setEditing(null); form.resetFields()
    form.setFieldsValue({ status: 1, sort: allData.length + 1 })
    setModalOpen(true)
  }
  const openEdit = (r: PositionVO) => {
    setEditing(r); form.setFieldsValue(r); setModalOpen(true)
  }

  const handleSubmit = async () => {
    const values = await form.validateFields()
    try {
      if (editing) { await positionApi.edit({ id: editing.id, ...values }); message.success('职位信息已更新') }
      else { await positionApi.add(values); message.success('新职位已创建') }
      setModalOpen(false); loadData()
    } catch { /**/ }
  }

  const handleDelete = (r: PositionVO) => {
    Modal.confirm({
      title: `确认删除职位「${r.name}」？`,
      icon: <DeleteOutlined style={{ color: '#ff4d4f' }} />,
      content: '关联该职位的员工将失去职位信息，但不影响其角色权限。',
      okType: 'danger', okText: '确认删除',
      onOk: async () => { await positionApi.delete(r.id); message.success('已删除'); loadData() },
    })
  }

  const handleStatusToggle = async (r: PositionVO) => {
    const next = r.status === 1 ? 0 : 1
    await positionApi.updateStatus(r.id, next)
    message.success(next === 1 ? '职位已启用' : '职位已停用')
    loadData()
  }

  const totalPositions = allData.length
  const activeCount = allData.filter(d => d.status === 1).length

  const columns: ColumnsType<PositionVO> = [
    {
      title: col(<SortAscendingOutlined style={{ color: '#94a3b8' }} />, '排序'),
      dataIndex: 'sort',
      width: 72,
      render: (v, _, i) => (
        <div style={{
          width: 32, height: 32, borderRadius: 10,
          background: `linear-gradient(135deg, ${POSITION_COLORS[i % POSITION_COLORS.length]}, ${POSITION_COLORS[(i + 1) % POSITION_COLORS.length]})`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: '#fff', fontWeight: 800, fontSize: 13,
          boxShadow: '0 2px 8px rgba(0,0,0,0.15)',
        }}>
          {v}
        </div>
      ),
    },
    {
      title: col(<SolutionOutlined style={{ color: '#14b8a6' }} />, '职位信息', 'left'),
      key: 'info',
      render: (_, r, i) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, width: '100%' }}>
          <div style={{
            width: 44, height: 44, borderRadius: 12, flexShrink: 0,
            background: r.status === 1
              ? `${POSITION_COLORS[i % POSITION_COLORS.length]}18`
              : '#f5f5f5',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            border: `1px solid ${r.status === 1 ? POSITION_COLORS[i % POSITION_COLORS.length] + '30' : '#eee'}`,
          }}>
            <ApartmentOutlined style={{
              color: r.status === 1 ? POSITION_COLORS[i % POSITION_COLORS.length] : '#ccc',
              fontSize: 18,
            }} />
          </div>
          <div>
            <div style={{ fontWeight: 700, fontSize: 14, color: r.status === 1 ? '#1a1f2e' : '#9ca3af' }}>
              {r.name}
            </div>
            <Text type="secondary" style={{ fontSize: 11, fontFamily: 'monospace' }}>
              {r.code}
            </Text>
          </div>
        </div>
      ),
    },
    {
      title: col(<FileTextOutlined style={{ color: '#94a3b8' }} />, '职责说明'),
      dataIndex: 'remark',
      ellipsis: true,
      render: v => v
        ? <Tooltip title={v}><Text type="secondary" style={{ fontSize: 12 }}>{v}</Text></Tooltip>
        : <Text type="secondary" style={{ fontSize: 12 }}>—</Text>,
    },
    {
      title: col(<SafetyCertificateOutlined style={{ color: '#22c55e' }} />, '状态'),
      dataIndex: 'status',
      width: 100,
      render: s => (
        <Badge
          status={s === 1 ? 'success' : 'default'}
          text={
            <Text style={{ color: s === 1 ? '#10b981' : '#9ca3af', fontWeight: 600, fontSize: 12 }}>
              {s === 1 ? '启用中' : '已停用'}
            </Text>
          }
        />
      ),
    },
    {
      title: col(<ClockCircleOutlined style={{ color: '#94a3b8' }} />, '创建时间'),
      dataIndex: 'createTime',
      width: 120,
      render: v => <Text type="secondary" style={{ fontSize: 12 }}>{v ? fmtDate(v) : '—'}</Text>,
    },
    {
      title: col(<SettingOutlined style={{ color: '#94a3b8' }} />, '操作'),
      width: 225,
      render: (_, r) => (
        <Space size={4}>
          <PermGuard code="position:edit">
            <Button size="small" icon={<EditOutlined />}
              style={{ borderRadius: 6, color: '#fa8c16', borderColor: '#ffd591' }}
              onClick={() => openEdit(r)}>编辑</Button>
          </PermGuard>
          {r.status === 1 ? (
            <PermGuard code="position:toggle">
              <Button size="small" icon={<StopOutlined />}
                style={{ borderRadius: 6, color: '#ff4d4f', borderColor: '#ffa39e' }}
                onClick={() => handleStatusToggle(r)}>停用</Button>
            </PermGuard>
          ) : (
            <PermGuard code="position:toggle">
              <Button size="small" icon={<CheckCircleOutlined />}
                style={{ borderRadius: 6, color: '#52c41a', borderColor: '#b7eb8f' }}
                onClick={() => handleStatusToggle(r)}>启用</Button>
            </PermGuard>
          )}
          <PermGuard code="position:delete">
            <Popconfirm title="确认删除该岗位？" onConfirm={() => handleDelete(r)} okText="删除" cancelText="取消" okButtonProps={{ danger: true }}>
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
          <div style={{ width: 34, height: 34, borderRadius: 10, background: GRADIENT, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 4px 12px rgba(8,145,178,0.35)', flexShrink: 0 }}>
            <SolutionOutlined style={{ color: '#fff', fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1e293b', lineHeight: 1.2 }}>职位管理</div>
            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>管理系统职位体系 · 配置职责说明</div>
          </div>
          <div style={{ width: 1, height: 20, margin: '0 4px', background: '#e0f2fe', flexShrink: 0 }} />
          <div style={{ display: 'flex', gap: 8 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: 'rgba(8,145,178,0.1)', border: '1px solid rgba(8,145,178,0.25)' }}>
              <span style={{ fontSize: 13 }}>📋</span>
              <span style={{ fontSize: 12, color: '#6b7280' }}>职位总数</span>
              <span style={{ fontSize: 13, fontWeight: 700, color: '#0891b2' }}>{totalPositions}</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: 'rgba(16,185,129,0.1)', border: '1px solid rgba(16,185,129,0.25)' }}>
              <span style={{ fontSize: 13 }}>✓</span>
              <span style={{ fontSize: 12, color: '#6b7280' }}>启用</span>
              <span style={{ fontSize: 13, fontWeight: 700, color: '#10b981' }}>{activeCount}</span>
            </div>
          </div>
          <div style={{ flex: 1 }} />
          <Button icon={<ReloadOutlined />} size="middle" style={{ borderRadius: 8 }} onClick={loadData}>刷新</Button>
          <PermGuard code="position:add">
            <Button type="primary" icon={<PlusOutlined />} style={{ borderRadius: 8, background: GRADIENT, border: 'none' }} onClick={openAdd}>新增职位</Button>
          </PermGuard>
        </div>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', padding: '10px 24px 12px' }}>
          <Input
            placeholder="搜索职位名称 / 编码"
            prefix={<SearchOutlined style={{ color: '#bbb' }} />}
            allowClear
            style={{ ...INPUT_STYLE, width: 180 }}
            value={keywordDraft}
            onChange={e => {
              setKeywordDraft(e.target.value)
              if (!e.target.value) setKeyword('')
            }}
            onPressEnter={handleSearch}
          />
          <Select
            placeholder={<><CheckCircleOutlined /> 状态</>}
            allowClear
            style={{ ...INPUT_STYLE, width: 110 }}
            value={status}
            onChange={v => setStatus(v)}>
            <Option value={1}><Space><CheckCircleOutlined style={{ color: '#10b981' }} />启用</Space></Option>
            <Option value={0}><Space><StopOutlined style={{ color: '#9ca3af' }} />停用</Space></Option>
          </Select>
          <div style={{ flex: 1 }} />
          <Button icon={<ReloadOutlined />} size="middle" style={{ borderRadius: 8 }} onClick={handleReset}>重置</Button>
          <Button type="primary" icon={<SearchOutlined />} style={{ borderRadius: 8, border: 'none', background: GRADIENT }} onClick={handleSearch}>搜索</Button>
        </div>
      </div>
      {allData.filter(p => p.status === 1).length > 0 && (
        <div style={{ marginLeft: -24, marginRight: -24, padding: '10px 24px', borderBottom: '1px solid #f0f4ff', background: '#fafbff' }}>
          <Space size={8} wrap>
            <Text type="secondary" style={{ fontSize: 12 }}>启用职位：</Text>
            {allData.filter(p => p.status === 1).map((p, i) => (
              <Tag key={p.id} style={{
                borderRadius: 20, padding: '3px 12px',
                background: `${POSITION_COLORS[i % POSITION_COLORS.length]}12`,
                border: `1px solid ${POSITION_COLORS[i % POSITION_COLORS.length]}30`,
                color: POSITION_COLORS[i % POSITION_COLORS.length],
                fontWeight: 600, cursor: 'pointer',
              }}
                onClick={() => setStatus(1)}>
                <ApartmentOutlined style={{ marginRight: 4 }} />{p.name}
              </Tag>
            ))}
          </Space>
        </div>
      )}
      <div ref={ref} style={{ marginLeft: -24, marginRight: -24, marginBottom: -24, background: '#fff', borderTop: '1px solid #eef0f8' }}>
        <Table
          rowKey="id"
          columns={columns}
          dataSource={data.slice((page - 1) * pageSize, page * pageSize)}
          loading={loading}
          pagination={false}
          size="middle"
          components={styledTableComponents}
          scroll={{ x: 'max-content', y: tableBodyH }}
          locale={{ emptyText: '暂无职位数据，点击右上角新增职位' }}
        />
        <PagePagination
          total={data.length}
          current={page}
          pageSize={pageSize}
          onChange={setPage}
          onSizeChange={s => { setPageSize(s); setPage(1) }}
          countLabel="个职位"
        />
      </div>

      <Modal
        title={
          <Space>
            <div style={{
              width: 32, height: 32, borderRadius: 8,
              background: GRADIENT,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <SolutionOutlined style={{ color: '#fff', fontSize: 14 }} />
            </div>
            <span>{editing ? `编辑职位 — ${editing.name}` : '新增职位'}</span>
          </Space>
        }
        open={modalOpen}
        onCancel={() => setModalOpen(false)}
        onOk={handleSubmit}
        okText="保存职位"
        cancelText="取消"
        okButtonProps={{ style: { background: GRADIENT, border: 'none' } }}
        width={880}
        styles={{ body: { maxHeight: 'calc(85vh - 150px)', overflowY: 'auto', overflowX: 'hidden' } }}
        destroyOnHidden
      >
        <Divider style={{ margin: '16px 0' }} />
        <Form form={form} layout="vertical">
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="name" label="职位名称"
                rules={[{ required: true, message: '请输入职位名称' }]}>
                <Input prefix={<ApartmentOutlined style={{ color: '#0891b2' }} />}
                  placeholder="如：运营总监" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="code" label="职位编码"
                rules={[{ required: !editing, message: '请输入职位编码' },
                  { pattern: /^[A-Z][A-Z0-9_]{1,29}$/, message: '大写字母开头' }]}>
                <Input placeholder="如：OP_DIRECTOR" disabled={!!editing}
                  style={{ fontFamily: 'monospace' }} />
              </Form.Item>
            </Col>
          </Row>
          <Form.Item name="remark" label="职责说明">
            <RichTextInput
              placeholder="描述该职位的主要职责、权限范围、任职要求等..." minHeight={120} />
          </Form.Item>
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="sort" label="显示排序">
                <InputNumber min={0} max={999} style={{ width: '100%' }} placeholder="数字越小越靠前" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="status" label="启用状态">
                <Select>
                  <Option value={1}>
                    <Space><CheckCircleOutlined style={{ color: '#10b981' }} />启用</Space>
                  </Option>
                  <Option value={0}>
                    <Space><StopOutlined style={{ color: '#9ca3af' }} />停用</Space>
                  </Option>
                </Select>
              </Form.Item>
            </Col>
          </Row>
        </Form>
      </Modal>
    </div>
  )
}
