import { useEffect, useState, useCallback } from 'react'
import {
  Table, Button, Space, Modal, Form, Input, Select, TreeSelect,
  message, Popconfirm, Tooltip, Badge, Row, Col, Typography, Divider,
} from 'antd'
import type { ColumnsType } from 'antd/es/table'
import {
  ApartmentOutlined, PlusOutlined, EditOutlined, DeleteOutlined,
  ReloadOutlined, UserOutlined, PhoneOutlined, MailOutlined,
  CheckCircleOutlined, StopOutlined, SortAscendingOutlined,
  SafetyCertificateOutlined, SearchOutlined, SettingOutlined,
} from '@ant-design/icons'
import { deptApi } from '../../api/api'
import PermGuard from '../../components/common/PermGuard'
import { col, styledTableComponents, INPUT_STYLE } from '../../components/common/tableComponents'
import { useTableBodyHeight } from '../../hooks/useTableBodyHeight'
import PagePagination from '../../components/common/PagePagination'

const { Text } = Typography

const GRADIENT = 'linear-gradient(135deg,#06b6d4,#0891b2)'

interface Dept {
  id: number
  parentId: number
  name: string
  sort: number
  leader?: string
  phone?: string
  email?: string
  status: number
  createTime?: string
  children?: Dept[]
}

function buildTree(list: Dept[]): Dept[] {
  const map = new Map<number, Dept>()
  list.forEach(d => map.set(d.id, { ...d, children: [] }))
  const roots: Dept[] = []
  map.forEach(d => {
    if (d.parentId === 0) {
      roots.push(d)
    } else {
      const parent = map.get(d.parentId)
      if (parent) parent.children!.push(d)
    }
  })
  return roots
}

function toTreeSelect(nodes: Dept[]): any[] {
  return nodes.map(n => ({
    title: n.name,
    value: n.id,
    children: n.children && n.children.length > 0 ? toTreeSelect(n.children) : undefined,
  }))
}

const GRADIENT_COLORS = [
  'linear-gradient(135deg,#667eea,#764ba2)',
  'linear-gradient(135deg,#f093fb,#f5576c)',
  'linear-gradient(135deg,#4facfe,#00f2fe)',
  'linear-gradient(135deg,#43e97b,#38f9d7)',
  'linear-gradient(135deg,#fa709a,#fee140)',
]

export default function DeptManagePage() {
  const { ref, height: tableBodyH } = useTableBodyHeight(46)
  const [list, setList] = useState<Dept[]>([])
  const [tree, setTree] = useState<Dept[]>([])
  const [loading, setLoading] = useState(false)
  const [modalOpen, setModalOpen] = useState(false)
  const [editing, setEditing] = useState<Dept | null>(null)
  const [form] = Form.useForm()
  const [searchName, setSearchName] = useState('')
  const [searchStatus, setSearchStatus] = useState<number | undefined>()

  const loadData = useCallback(async () => {
    setLoading(true)
    try {
      const res = await deptApi.list({ name: searchName || undefined, status: searchStatus })
      const flat: Dept[] = res.data?.data ?? []
      setList(flat)
      setTree(buildTree(flat))
    } finally {
      setLoading(false)
    }
  }, [searchName, searchStatus])

  useEffect(() => { loadData() }, [loadData])

  const openAdd = (parentId = 0) => {
    setEditing(null)
    form.resetFields()
    form.setFieldsValue({ parentId, sort: 0, status: 1 })
    setModalOpen(true)
  }

  const openEdit = (record: Dept) => {
    setEditing(record)
    form.setFieldsValue({ ...record })
    setModalOpen(true)
  }

  const handleOk = async () => {
    const values = await form.validateFields()
    if (editing) {
      await deptApi.edit({ id: editing.id, ...values })
      message.success('修改成功')
    } else {
      await deptApi.add(values)
      message.success('新增成功')
    }
    setModalOpen(false)
    loadData()
  }

  const handleDelete = async (id: number) => {
    await deptApi.delete(id)
    message.success('删除成功')
    loadData()
  }

  const toggleStatus = async (r: Dept) => {
    await deptApi.updateStatus(r.id, r.status === 1 ? 0 : 1)
    loadData()
  }

  const total = list.length

  const handleSearch = () => {
    loadData()
  }

  const handleReset = () => {
    setSearchName('')
    setSearchStatus(undefined)
  }

  const columns: ColumnsType<Dept> = [
    {
      title: col(<ApartmentOutlined style={{ color: '#14b8a6' }} />, '部门名称', 'left'),
      dataIndex: 'name', key: 'name',
      render: (v: string, r: Dept) => {
        const colorIdx = r.id % GRADIENT_COLORS.length
        return (
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, width: '100%' }}>
            <span style={{
              display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
              width: 28, height: 28, borderRadius: 6, flexShrink: 0,
              background: GRADIENT_COLORS[colorIdx], color: '#fff', fontSize: 12, fontWeight: 700,
            }}>{v.charAt(0)}</span>
            <Text strong>{v}</Text>
          </div>
        )
      },
    },
    {
      title: col(<SortAscendingOutlined style={{ color: '#94a3b8' }} />, '排序'),
      dataIndex: 'sort', key: 'sort',
      render: (v: number) => (
        <span style={{
          display: 'inline-block', height: 28, lineHeight: '28px', textAlign: 'center',
          borderRadius: '50%', background: '#f0f5ff', color: '#1890ff', fontWeight: 600, fontSize: 13,
        }}>{v}</span>
      ),
    },
    {
      title: col(<UserOutlined style={{ color: '#3b82f6' }} />, '负责人'),
      dataIndex: 'leader', key: 'leader',
      render: (v: string) => v ? <Space><UserOutlined style={{ color: '#1890ff' }} />{v}</Space> : <Text type="secondary">-</Text>,
    },
    {
      title: col(<PhoneOutlined style={{ color: '#22c55e' }} />, '联系电话'),
      dataIndex: 'phone', key: 'phone',
      render: (v: string) => v ? <Space><PhoneOutlined style={{ color: '#52c41a' }} />{v}</Space> : <Text type="secondary">-</Text>,
    },
    {
      title: col(<MailOutlined style={{ color: '#f97316' }} />, '邮箱'),
      dataIndex: 'email', key: 'email',
      render: (v: string) => v ? <Space><MailOutlined style={{ color: '#722ed1' }} />{v}</Space> : <Text type="secondary">-</Text>,
    },
    {
      title: col(<SafetyCertificateOutlined style={{ color: '#22c55e' }} />, '状态'),
      dataIndex: 'status', key: 'status',
      render: (v: number) => v === 1
        ? <Badge status="success" text={<span style={{ color: '#52c41a', fontWeight: 600 }}>正常</span>} />
        : <Badge status="error" text={<span style={{ color: '#ff4d4f', fontWeight: 600 }}>停用</span>} />,
    },
    {
      title: col(<SettingOutlined style={{ color: '#94a3b8' }} />, '操作'),
      key: 'action', width: 240,
      render: (_: unknown, r: Dept) => (
        <Space size={[4, 4]} wrap>
          <PermGuard code="dept:add">
            <Tooltip title="新增子部门">
              <Button size="small" type="primary" ghost icon={<PlusOutlined />}
                onClick={() => openAdd(r.id)} style={{ borderRadius: 6 }}>新增</Button>
            </Tooltip>
          </PermGuard>
          <PermGuard code="dept:edit">
            <Tooltip title="编辑">
              <Button size="small" icon={<EditOutlined />} onClick={() => openEdit(r)}
                style={{ borderRadius: 6, color: '#fa8c16', borderColor: '#ffd591' }}>编辑</Button>
            </Tooltip>
          </PermGuard>
          <PermGuard code="dept:toggle">
            <Tooltip title={r.status === 1 ? '停用' : '启用'}>
              <Button size="small" icon={r.status === 1 ? <StopOutlined /> : <CheckCircleOutlined />}
                onClick={() => toggleStatus(r)}
                style={{ borderRadius: 6, color: r.status === 1 ? '#ff4d4f' : '#52c41a', borderColor: r.status === 1 ? '#ff4d4f' : '#52c41a' }}>
                {r.status === 1 ? '停用' : '启用'}
              </Button>
            </Tooltip>
          </PermGuard>
          <PermGuard code="dept:delete">
            <Popconfirm title="确认删除该部门？" onConfirm={() => handleDelete(r.id)} okText="删除" cancelText="取消" okButtonProps={{ danger: true }}>
              <Tooltip title="删除">
                <Button size="small" danger icon={<DeleteOutlined />} style={{ borderRadius: 6 }}>删除</Button>
              </Tooltip>
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
          <div style={{ width: 34, height: 34, borderRadius: 10, background: GRADIENT, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 4px 12px rgba(6,182,212,0.35)', flexShrink: 0 }}>
            <ApartmentOutlined style={{ color: '#fff', fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1e293b', lineHeight: 1.2 }}>部门管理</div>
            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>管理组织架构 · 配置部门负责人</div>
          </div>
          <div style={{ width: 1, height: 20, margin: '0 4px', background: '#cffafe', flexShrink: 0 }} />
          <div style={{ display: 'flex', gap: 8 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: 'rgba(6,182,212,0.1)', border: '1px solid rgba(6,182,212,0.25)' }}>
              <span style={{ fontSize: 13 }}>🏢</span>
              <span style={{ fontSize: 12, color: '#6b7280' }}>部门总数</span>
              <span style={{ fontSize: 13, fontWeight: 700, color: '#0891b2' }}>{total}</span>
            </div>
          </div>
          <div style={{ flex: 1 }} />
          <Button icon={<ReloadOutlined />} size="middle" style={{ borderRadius: 8 }} onClick={loadData}>刷新</Button>
          <PermGuard code="dept:add">
            <Button type="primary" icon={<PlusOutlined />} onClick={() => openAdd(0)} style={{ borderRadius: 8, background: GRADIENT, border: 'none' }}>新增部门</Button>
          </PermGuard>
        </div>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', padding: '10px 24px 12px' }}>
          <Input
            placeholder="部门名称"
            prefix={<SearchOutlined style={{ color: '#bbb' }} />}
            allowClear
            style={{ ...INPUT_STYLE, width: 180 }}
            value={searchName}
            onChange={e => setSearchName(e.target.value)}
          />
          <Select
            placeholder="部门状态"
            allowClear
            style={{ ...INPUT_STYLE, width: 110 }}
            value={searchStatus}
            onChange={v => setSearchStatus(v)}>
            <Select.Option value={1}>正常</Select.Option>
            <Select.Option value={0}>停用</Select.Option>
          </Select>
          <div style={{ flex: 1 }} />
          <Button icon={<ReloadOutlined />} size="middle" style={{ borderRadius: 8 }} onClick={handleReset}>重置</Button>
          <Button type="primary" icon={<SearchOutlined />} style={{ borderRadius: 8, border: 'none', background: GRADIENT }} onClick={handleSearch}>搜索</Button>
        </div>
      </div>

      <div ref={ref} style={{ marginLeft: -24, marginRight: -24, marginBottom: -24, background: '#fff', borderTop: '1px solid #eef0f8' }}>
        <Table
          columns={columns}
          dataSource={tree}
          rowKey="id"
          loading={loading}
          defaultExpandAllRows
          pagination={false}
          size="middle"
          rowClassName={() => 'dept-row'}
          components={styledTableComponents}
          scroll={{ x: 'max-content', y: tableBodyH }}
        />
        <PagePagination
          total={list.length}
          current={1}
          pageSize={Math.max(list.length, 1)}
          onChange={() => {}}
          showSizeChanger={false}
          countLabel="个部门"
        />
      </div>

      <Modal
        open={modalOpen}
        onCancel={() => setModalOpen(false)}
        onOk={handleOk}
        title={
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{ width: 32, height: 32, borderRadius: 8, background: 'linear-gradient(135deg,#667eea,#764ba2)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff' }}>
              <ApartmentOutlined />
            </div>
            <span>{editing ? '编辑部门' : '新增部门'}</span>
          </div>
        }
        okText={editing ? '保存修改' : '确认新增'}
        width={880}
        styles={{ body: { maxHeight: 'calc(85vh - 150px)', overflowY: 'auto', overflowX: 'hidden' } }}
        okButtonProps={{ style: { borderRadius: 8, background: 'linear-gradient(135deg,#667eea,#764ba2)', border: 'none' } }}
      >
        <Divider style={{ margin: '12px 0' }} />
        <Form form={form} layout="vertical" size="large">
          <Form.Item name="parentId" label="上级部门" rules={[{ required: true, message: '请选择上级部门' }]}>
            <TreeSelect
              placeholder="请选择上级部门"
              treeData={[{ title: '顶级部门（无上级）', value: 0 }, ...toTreeSelect(tree)]}
              style={{ borderRadius: 8 }}
              allowClear={false}
            />
          </Form.Item>
          <Row gutter={16}>
            <Col span={16}>
              <Form.Item name="name" label="部门名称" rules={[{ required: true, message: '请输入部门名称' }]}>
                <Input prefix={<ApartmentOutlined />} placeholder="请输入部门名称" style={{ borderRadius: 8 }} />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="sort" label="显示排序">
                <Input type="number" placeholder="0" style={{ borderRadius: 8 }} />
              </Form.Item>
            </Col>
          </Row>
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="leader" label="负责人">
                <Input prefix={<UserOutlined />} placeholder="负责人姓名" style={{ borderRadius: 8 }} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="phone" label="联系电话">
                <Input prefix={<PhoneOutlined />} placeholder="联系电话" style={{ borderRadius: 8 }} />
              </Form.Item>
            </Col>
          </Row>
          <Row gutter={16}>
            <Col span={14}>
              <Form.Item name="email" label="邮箱">
                <Input prefix={<MailOutlined />} placeholder="邮箱地址" style={{ borderRadius: 8 }} />
              </Form.Item>
            </Col>
            <Col span={10}>
              <Form.Item name="status" label="部门状态">
                <Select style={{ borderRadius: 8 }}>
                  <Select.Option value={1}><Badge status="success" text="正常" /></Select.Option>
                  <Select.Option value={0}><Badge status="error" text="停用" /></Select.Option>
                </Select>
              </Form.Item>
            </Col>
          </Row>
        </Form>
      </Modal>
    </div>
  )
}
