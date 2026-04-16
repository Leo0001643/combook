import { useState, useEffect } from 'react'
import {
  Table, Button, Space, Typography, message, Modal, Form,
  Input, InputNumber, Select, Badge, Row, Col, Tag, Tooltip, Popconfirm, Divider,
} from 'antd'
import type { ColumnsType } from 'antd/es/table'
import {
  PlusOutlined, EditOutlined, DeleteOutlined, ReloadOutlined,
  ApartmentOutlined, CheckCircleOutlined, StopOutlined,
  UserOutlined, PhoneOutlined, MailOutlined, SettingOutlined,
  TeamOutlined, FileTextOutlined, NumberOutlined, BranchesOutlined,
  SortAscendingOutlined, SafetyCertificateOutlined, ClockCircleOutlined,
} from '@ant-design/icons'
import { merchantPortalApi } from '../../api/api'
import PermDrawer, { type PermTarget } from '../../components/merchant/PermDrawer'
import RichTextInput from '../../components/common/RichTextInput'
import PermGuard from '../../components/common/PermGuard'
import { col, styledTableComponents } from '../../components/common/tableComponents'
import { useTableBodyHeight } from '../../hooks/useTableBodyHeight'
import PagePagination from '../../components/common/PagePagination'

const { Text } = Typography
const { Option } = Select

const PAGE_GRADIENT = 'linear-gradient(135deg,#06b6d4,#0891b2)'

interface DeptVO {
  id: number
  merchantId: number
  parentId: number
  name: string
  type?: string
  sort: number
  headcount?: number
  leader?: string
  phone?: string
  email?: string
  description?: string
  status: number
  createTime?: string
}

const STATUS_CFG: Record<number, { label: string; color: string; badge: 'success' | 'default' }> = {
  1: { label: '启用', color: '#52c41a', badge: 'success' },
  0: { label: '停用', color: '#ff4d4f', badge: 'default' },
}

export default function MerchantDeptPage() {
  const { ref, height: tableBodyH } = useTableBodyHeight(46)
  const [data, setData]           = useState<DeptVO[]>([])
  const [loading, setLoading]     = useState(false)
  const [modalOpen, setModalOpen] = useState(false)
  const [editing, setEditing]     = useState<DeptVO | null>(null)
  const [form] = Form.useForm()
  const [permTarget, setPermTarget] = useState<PermTarget | null>(null)

  useEffect(() => { loadData() }, [])

  const loadData = async () => {
    setLoading(true)
    try {
      const res = await merchantPortalApi.deptList()
      setData(res.data?.data ?? [])
    } finally { setLoading(false) }
  }

  const openAdd = () => {
    setEditing(null)
    form.resetFields()
    form.setFieldsValue({ parentId: 0, sort: 0, status: 1 })
    setModalOpen(true)
  }

  const openEdit = (record: DeptVO) => {
    setEditing(record)
    form.setFieldsValue(record)
    setModalOpen(true)
  }

  const handleDelete = (id: number) => {
    Modal.confirm({
      title: '确认删除该部门？',
      content: '删除后不可恢复，存在子部门时无法删除。',
      okType: 'danger',
      okText: '确认删除',
      cancelText: '取消',
      onOk: async () => {
        try {
          await merchantPortalApi.deptDelete(id)
          message.success('删除成功')
          loadData()
        } catch (e: any) {
          message.error(e?.response?.data?.message ?? '删除失败')
        }
      },
    })
  }

  const handleStatusToggle = async (record: DeptVO) => {
    try {
      await merchantPortalApi.deptStatus(record.id, record.status === 1 ? 0 : 1)
      message.success('状态已更新')
      loadData()
    } catch (e: any) {
      message.error(e?.response?.data?.message ?? '操作失败')
    }
  }

  const handleSubmit = async () => {
    try {
      const values = await form.validateFields()
      if (editing) {
        await merchantPortalApi.deptEdit({ id: editing.id, ...values })
        message.success('部门已更新')
      } else {
        await merchantPortalApi.deptAdd(values)
        message.success('部门创建成功')
      }
      setModalOpen(false)
      loadData()
    } catch (e: any) {
      if (e?.response?.data?.message) message.error(e.response.data.message)
    }
  }

  // Build parent options (exclude self when editing)
  const parentOptions = [
    { value: 0, label: '顶级部门（无上级）' },
    ...data
      .filter(d => !editing || d.id !== editing.id)
      .map(d => ({ value: d.id, label: d.name })),
  ]

  const getParentName = (parentId: number) =>
    parentId === 0 ? '—' : data.find(d => d.id === parentId)?.name ?? parentId

  const columns: ColumnsType<DeptVO> = [
    {
      title: col(<ApartmentOutlined style={{ color: '#06b6d4' }} />, '部门名称', 'left'), dataIndex: 'name', key: 'name',
      render: (name, r) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, width: '100%' }}>
          <div style={{
            width: 34, height: 34, borderRadius: 8, flexShrink: 0,
            background: r.parentId === 0
              ? 'linear-gradient(135deg,#6366f1,#8b5cf6)'
              : 'linear-gradient(135deg,#e0e7ff,#ede9fe)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <ApartmentOutlined style={{ color: r.parentId === 0 ? '#fff' : '#6366f1', fontSize: 14 }} />
          </div>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
              <span style={{ fontWeight: 600, color: '#1a1a2e' }}>{name}</span>
              {r.type && (
                <Tag color={r.type === '业务部门' ? 'blue' : r.type === '技术部门' ? 'purple' : r.type === '职能部门' ? 'green' : 'orange'}
                  style={{ borderRadius: 6, fontSize: 10, padding: '0 6px', lineHeight: '18px' }}>{r.type}</Tag>
              )}
            </div>
            <div style={{ fontSize: 11, color: '#999' }}>
              上级：{getParentName(r.parentId)}
            </div>
          </div>
        </div>
      ),
    },
    {
      title: col(<UserOutlined style={{ color: '#06b6d4' }} />, '负责人'), key: 'leader',
      render: (_, r) => r.leader ? (
        <Space direction="vertical" size={0}>
          <Space size={4}><UserOutlined style={{ color: '#6366f1' }} /><Text>{r.leader}</Text></Space>
          {r.phone && <Space size={4}><PhoneOutlined style={{ color: '#52c41a', fontSize: 11 }} /><Text type="secondary" style={{ fontSize: 11 }}>{r.phone}</Text></Space>}
          {r.email && <Space size={4}><MailOutlined style={{ color: '#1677ff', fontSize: 11 }} /><Text type="secondary" style={{ fontSize: 11 }}>{r.email}</Text></Space>}
        </Space>
      ) : <Text type="secondary">—</Text>,
    },
    {
      title: col(<TeamOutlined style={{ color: '#06b6d4' }} />, '编制人数'), dataIndex: 'headcount', key: 'headcount', width: 90,
      render: v => v ? <Space size={4}><TeamOutlined style={{ color: '#6366f1' }} /><Text strong>{v}</Text></Space> : <Text type="secondary">—</Text>,
    },
    {
      title: col(<SortAscendingOutlined style={{ color: '#06b6d4' }} />, '排序'), dataIndex: 'sort', key: 'sort', width: 70,
      render: v => <Tag style={{ borderRadius: 6 }}>{v}</Tag>,
    },
    {
      title: col(<SafetyCertificateOutlined style={{ color: '#06b6d4' }} />, '状态'), dataIndex: 'status', key: 'status', width: 90,
      render: v => {
        const cfg = STATUS_CFG[v] ?? STATUS_CFG[0]
        return <Badge status={cfg.badge} text={<span style={{ color: cfg.color, fontWeight: 600 }}>{cfg.label}</span>} />
      },
    },
    {
      title: col(<ClockCircleOutlined style={{ color: '#06b6d4' }} />, '创建时间'), dataIndex: 'createTime', key: 'createTime', width: 160,
      render: v => (
        <Space size={4}>
          <ClockCircleOutlined style={{ color: '#d1d5db', fontSize: 11 }} />
          <Text type="secondary" style={{ fontSize: 12 }}>{v?.slice(0, 16) ?? '—'}</Text>
        </Space>
      ),
    },
    {
      title: col(<SettingOutlined style={{ color: '#06b6d4' }} />, '操作'), key: 'action', width: 240, fixed: 'right',
      render: (_, r) => (
        <Space size={[4, 4]} wrap>
          <PermGuard code="dept:edit">
            <Button size="small" icon={<EditOutlined />}
              style={{ borderRadius: 6, color: '#fa8c16', borderColor: '#ffd591' }}
              onClick={() => openEdit(r)}>编辑</Button>
          </PermGuard>
          <PermGuard code="dept:edit">
            <Button size="small" icon={<SettingOutlined />}
              style={{ borderRadius: 6, color: '#6366f1', borderColor: '#c7d2fe' }}
              onClick={() => setPermTarget({ type: 'dept', id: r.id, name: r.name })}>权限</Button>
          </PermGuard>
          <PermGuard code="dept:toggle">
            {r.status === 1 ? (
              <Button size="small" icon={<StopOutlined />}
                style={{ borderRadius: 6, color: '#ff4d4f', borderColor: '#ffa39e' }}
                onClick={() => handleStatusToggle(r)}>停用</Button>
            ) : (
              <Button size="small" icon={<CheckCircleOutlined />}
                style={{ borderRadius: 6, color: '#52c41a', borderColor: '#b7eb8f' }}
                onClick={() => handleStatusToggle(r)}>启用</Button>
            )}
          </PermGuard>
          <PermGuard code="dept:delete">
            <Popconfirm title="确认删除该部门？" onConfirm={() => handleDelete(r.id)} okText="删除" cancelText="取消" okButtonProps={{ danger: true }}>
              <Button size="small" danger icon={<DeleteOutlined />} style={{ borderRadius: 6 }}>删除</Button>
            </Popconfirm>
          </PermGuard>
        </Space>
      ),
    },
  ]

  const enabledCount = data.filter(d => d.status === 1).length

  return (
    <div style={{ marginTop: -24 }}>
      <div style={{ position: 'sticky', top: 64, zIndex: 88, marginLeft: -24, marginRight: -24, background: 'rgba(255,255,255,0.97)', backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)', borderBottom: '1px solid rgba(0,0,0,0.07)', boxShadow: '0 4px 20px rgba(0,0,0,0.06)' }}>
        <div style={{ display: 'flex', alignItems: 'center', padding: '10px 24px 0', gap: 12 }}>
          <div style={{ width: 34, height: 34, borderRadius: 10, background: PAGE_GRADIENT, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 4px 12px rgba(6,182,212,0.35)', flexShrink: 0 }}>
            <ApartmentOutlined style={{ color: '#fff', fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1e293b', lineHeight: 1.2 }}>部门管理</div>
            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>管理商户组织架构 · 配置部门权限</div>
          </div>
          <Divider type="vertical" style={{ height: 20, margin: '0 4px', borderColor: '#cffafe' }} />
          <div style={{ display: 'flex', gap: 8 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: 'rgba(6,182,212,0.1)', border: '1px solid rgba(6,182,212,0.25)' }}>
              <span>🏢</span>
              <span style={{ fontSize: 12, color: '#6b7280' }}>部门</span>
              <span style={{ fontSize: 13, fontWeight: 700, color: '#0891b2' }}>{data.length}</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: 'rgba(6,182,212,0.1)', border: '1px solid rgba(6,182,212,0.25)' }}>
              <span>✅</span>
              <span style={{ fontSize: 12, color: '#6b7280' }}>启用</span>
              <span style={{ fontSize: 13, fontWeight: 700, color: '#0891b2' }}>{enabledCount}</span>
            </div>
          </div>
          <div style={{ flex: 1 }} />
          <PermGuard code="dept:add">
            <Button type="primary" icon={<PlusOutlined />} style={{ borderRadius: 8, background: 'linear-gradient(135deg,#06b6d4,#0891b2)', border: 'none' }} onClick={openAdd}>新增部门</Button>
          </PermGuard>
        </div>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', padding: '10px 24px 12px' }}>
          <div style={{ flex: 1 }} />
          <Tooltip title="刷新"><Button icon={<ReloadOutlined />} size="middle" loading={loading} style={{ borderRadius: 8, color: '#0891b2', borderColor: '#a5f3fc' }} onClick={loadData} /></Tooltip>
        </div>
      </div>
      <div ref={ref} style={{ marginLeft: -24, marginRight: -24, marginBottom: -24, background: '#fff', borderTop: '1px solid #eef0f8' }}>
        <Table
          rowKey="id"
          columns={columns}
          dataSource={data}
          loading={loading}
          pagination={false}
          components={styledTableComponents}
          scroll={{ x: 'max-content', y: tableBodyH }}
          size="middle"
          rowClassName={() => 'table-row-hover'}
        />
        <PagePagination
          total={data.length}
          current={1}
          pageSize={Math.max(data.length, 1)}
          onChange={() => {}}
          showSizeChanger={false}
          countLabel="个部门"
        />
      </div>

      {/* 新增/编辑 Modal */}
      <Modal
        title={
          <div style={{
            background: 'linear-gradient(135deg,#667eea,#764ba2)',
            margin: '-20px -24px 20px',
            padding: '18px 24px',
            borderRadius: '8px 8px 0 0',
            display: 'flex', alignItems: 'center', gap: 12,
          }}>
            <div style={{ width: 40, height: 40, borderRadius: 10, background: 'rgba(255,255,255,0.2)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <ApartmentOutlined style={{ color: '#fff', fontSize: 20 }} />
            </div>
            <div>
              <div style={{ color: '#fff', fontWeight: 800, fontSize: 16 }}>{editing ? '编辑部门' : '新增部门'}</div>
              <div style={{ color: 'rgba(255,255,255,0.82)', fontSize: 12, marginTop: 2 }}>
                {editing ? '修改部门信息，优化组织架构' : '🏢 完善组织架构，高效协作管理！'}
              </div>
            </div>
          </div>
        }
        open={modalOpen}
        onCancel={() => setModalOpen(false)}
        onOk={handleSubmit}
        okText={editing ? '保存修改' : '确认新增'}
        cancelText="取消"
        okButtonProps={{ style: { background: 'linear-gradient(135deg,#667eea,#764ba2)', border: 'none', borderRadius: 8 } }}
        cancelButtonProps={{ style: { borderRadius: 8 } }}
        width={880}
        styles={{ body: { maxHeight: 'calc(85vh - 160px)', overflowY: 'auto', overflowX: 'hidden' } }}
      >
        <Form form={form} layout="vertical">
          <Row gutter={16}>
            <Col span={8}>
              <Form.Item name="name" label={<Space size={4}><ApartmentOutlined style={{ color: '#667eea' }} /><span>部门名称</span></Space>} rules={[{ required: true, message: '请输入部门名称' }]}>
                <Input prefix={<ApartmentOutlined style={{ color: '#667eea' }} />} placeholder="如：技术部" />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="type" label={<Space size={4}><BranchesOutlined style={{ color: '#8b5cf6' }} /><span>部门类型</span></Space>}>
                <Select placeholder="选择部门类型" allowClear>
                  <Option value="业务部门">🏢 业务部门</Option>
                  <Option value="技术部门">💻 技术部门</Option>
                  <Option value="职能部门">⚙️ 职能部门</Option>
                  <Option value="管理部门">👑 管理部门</Option>
                </Select>
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="parentId" label={<Space size={4}><ApartmentOutlined style={{ color: '#10b981' }} /><span>上级部门</span></Space>}>
                <Select options={parentOptions} />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="leader" label={<Space size={4}><UserOutlined style={{ color: '#6366f1' }} /><span>部门负责人</span></Space>}>
                <Input prefix={<UserOutlined style={{ color: '#6366f1' }} />} placeholder="负责人姓名" />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="phone" label={<Space size={4}><PhoneOutlined style={{ color: '#52c41a' }} /><span>联系电话</span></Space>}>
                <Input prefix={<PhoneOutlined style={{ color: '#52c41a' }} />} placeholder="+855xxxxxxxx" />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="email" label={<Space size={4}><MailOutlined style={{ color: '#1677ff' }} /><span>部门邮箱</span></Space>}>
                <Input prefix={<MailOutlined style={{ color: '#1677ff' }} />} placeholder="dept@example.com" />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="headcount" label={<Space size={4}><TeamOutlined style={{ color: '#f59e0b' }} /><span>编制人数</span></Space>}>
                <InputNumber min={1} max={9999} style={{ width: '100%' }} placeholder="部门最大人员数量" prefix={<TeamOutlined style={{ color: '#f59e0b' }} />} />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="sort" label={<Space size={4}><NumberOutlined style={{ color: '#94a3b8' }} /><span>排序权重</span></Space>}>
                <InputNumber min={0} style={{ width: '100%' }} />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="status" label={<Space size={4}><CheckCircleOutlined style={{ color: '#10b981' }} /><span>状态</span></Space>}>
                <Select>
                  <Option value={1}><Space><CheckCircleOutlined style={{ color: '#52c41a' }} />启用</Space></Option>
                  <Option value={0}><Space><StopOutlined style={{ color: '#ff4d4f' }} />停用</Space></Option>
                </Select>
              </Form.Item>
            </Col>
            <Col span={24}>
              <Form.Item name="description" label={<Space size={4}><FileTextOutlined style={{ color: '#6b7280' }} /><span>部门描述</span></Space>}>
                <RichTextInput placeholder="描述部门职能、工作范围、核心目标等，方便员工了解部门定位..." minHeight={130} />
              </Form.Item>
            </Col>
          </Row>
        </Form>
      </Modal>

      <PermDrawer target={permTarget} onClose={() => setPermTarget(null)} />
    </div>
  )
}
