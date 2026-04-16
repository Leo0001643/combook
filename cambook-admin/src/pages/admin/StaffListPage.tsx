import { useState, useEffect, useCallback } from 'react'
import {
  Row, Col, Table, Input, Select, Space, Tag, Avatar,
  Button, Typography, message, Modal, Form, Drawer,
  Badge, Popconfirm, Divider,
} from 'antd'
import type { ColumnsType } from 'antd/es/table'
import {
  SearchOutlined, PlusOutlined, EditOutlined, DeleteOutlined,
  UserOutlined, ReloadOutlined, IdcardOutlined,
  LockOutlined, CheckCircleOutlined, StopOutlined,
  MailOutlined, PhoneOutlined, ApartmentOutlined,
  SafetyCertificateOutlined, SolutionOutlined,
  ClockCircleOutlined, SettingOutlined, KeyOutlined,
} from '@ant-design/icons'
import dayjs from 'dayjs'
import { staffApi, positionApi, roleApi, type StaffVO, type PositionVO, type RoleVO } from '../../api/api'
import PermGuard from '../../components/common/PermGuard'
import { col, styledTableComponents, INPUT_STYLE } from '../../components/common/tableComponents'
import PagePagination from '../../components/common/PagePagination'

const { Text } = Typography
const { Option } = Select

const GRADIENT = 'linear-gradient(135deg,#6366f1,#8b5cf6)'

const AVATAR_COLORS = [
  'linear-gradient(135deg,#667eea,#764ba2)',
  'linear-gradient(135deg,#f093fb,#f5576c)',
  'linear-gradient(135deg,#4facfe,#00f2fe)',
  'linear-gradient(135deg,#43e97b,#38f9d7)',
  'linear-gradient(135deg,#fa709a,#fee140)',
]

export default function StaffListPage() {
  const [data, setData]               = useState<StaffVO[]>([])
  const [total, setTotal]             = useState(0)
  const [loading, setLoading]         = useState(false)
  const [positions, setPositions]     = useState<PositionVO[]>([])
  const [roles, setRoles]             = useState<RoleVO[]>([])
  const [keyword, setKeyword]         = useState('')
  const [keywordDraft, setKeywordDraft] = useState('')
  const [status, setStatus]           = useState<number | undefined>()
  const [positionId, setPositionId]   = useState<number | undefined>()
  const [current, setCurrent]         = useState(1)
  const [pageSize, setPageSize]       = useState(20)
  const [drawerOpen, setDrawerOpen]   = useState(false)
  const [editing, setEditing]         = useState<StaffVO | null>(null)
  const [form] = Form.useForm()

  useEffect(() => { loadPositions(); loadRoles() }, [])
  useEffect(() => { loadData() }, [current, keyword, status, positionId, pageSize])

  const loadData = useCallback(async () => {
    setLoading(true)
    try {
      const res = await staffApi.page({ current, size: pageSize, keyword, status, positionId })
      const page = res.data?.data ?? { records: [], total: 0 }
      setData(page.records ?? [])
      setTotal(page.total ?? 0)
    } finally { setLoading(false) }
  }, [current, keyword, status, positionId, pageSize])

  const loadPositions = async () => {
    try { const r = await positionApi.list(); setPositions(r.data?.data ?? []) } catch { /**/ }
  }
  const loadRoles = async () => {
    try { const r = await roleApi.list(); setRoles(r.data?.data ?? []) } catch { /**/ }
  }

  const handleSearch = () => {
    setKeyword(keywordDraft)
    setCurrent(1)
  }

  const handleReset = () => {
    setKeywordDraft('')
    setKeyword('')
    setStatus(undefined)
    setPositionId(undefined)
    setCurrent(1)
  }

  const openAdd = () => {
    setEditing(null); form.resetFields()
    form.setFieldsValue({ status: 1 }); setDrawerOpen(true)
  }
  const openEdit = (r: StaffVO) => {
    setEditing(r)
    form.setFieldsValue({ username: r.username, realName: r.realName, email: r.email, mobile: r.mobile, positionId: r.positionId, status: r.status, roleIds: r.roleIds })
    setDrawerOpen(true)
  }

  const handleSubmit = async () => {
    const values = await form.validateFields()
    try {
      if (editing) { await staffApi.edit({ id: editing.id, ...values }); message.success('修改成功') }
      else { await staffApi.add(values); message.success('员工已添加') }
      setDrawerOpen(false); loadData()
    } catch { /**/ }
  }

  const handleDelete = (r: StaffVO) => {
    Modal.confirm({
      title: `确认删除员工账号 "${r.realName || r.username}"？`,
      icon: <DeleteOutlined style={{ color: '#ff4d4f' }} />,
      content: '删除后该账号将无法登录系统，且不可恢复。',
      okType: 'danger', okText: '确认删除',
      onOk: async () => { await staffApi.delete(r.id); message.success('已删除'); loadData() },
    })
  }

  const handleStatusToggle = async (r: StaffVO) => {
    const next = r.status === 1 ? 0 : 1
    await staffApi.updateStatus(r.id, next)
    message.success(next === 1 ? '账号已启用' : '账号已停用')
    loadData()
  }

  const activeCount = data.filter(d => d.status === 1).length

  const columns: ColumnsType<StaffVO> = [
    {
      title: col(<UserOutlined style={{ color: '#a855f7' }} />, '员工信息', 'left'),
      key: 'info',
      width: 230,
      fixed: 'left',
      render: (_, r) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, width: '100%' }}>
          <Avatar
            size={46}
            icon={<UserOutlined />}
            style={{ background: AVATAR_COLORS[r.id % AVATAR_COLORS.length], flexShrink: 0 }}
          />
          <div>
            <div style={{ fontWeight: 700, fontSize: 14, lineHeight: 1.3 }}>{r.realName || '—'}</div>
            <Text type="secondary" style={{ fontSize: 12 }}>
              <UserOutlined style={{ marginRight: 3 }} />@{r.username}
            </Text>
          </div>
        </div>
      ),
    },
    {
      title: col(<PhoneOutlined style={{ color: '#3b82f6' }} />, '联系方式'),
      key: 'contact',
      width: 190,
      render: (_, r) => (
        <Space orientation="vertical" size={2}>
          <Space size={4}>
            <PhoneOutlined style={{ color: '#3b82f6', fontSize: 11 }} />
            <Text style={{ fontSize: 12 }}>{r.mobile || <Text type="secondary">未填写</Text>}</Text>
          </Space>
          <Space size={4}>
            <MailOutlined style={{ color: '#8b5cf6', fontSize: 11 }} />
            <Text style={{ fontSize: 12 }}>{r.email || <Text type="secondary">未填写</Text>}</Text>
          </Space>
        </Space>
      ),
    },
    {
      title: col(<SolutionOutlined style={{ color: '#14b8a6' }} />, '所属职位'),
      dataIndex: 'positionName',
      width: 130,
      render: v => v
        ? (
          <Tag icon={<ApartmentOutlined />} style={{
            borderRadius: 20, padding: '3px 10px',
            background: '#eff6ff', border: '1px solid #bfdbfe',
            color: '#2563eb', fontWeight: 600,
          }}>
            {v}
          </Tag>
        )
        : <Text type="secondary" style={{ fontSize: 12 }}>未设置</Text>,
    },
    {
      title: col(<SafetyCertificateOutlined style={{ color: '#f97316' }} />, '分配角色'),
      dataIndex: 'roleNames',
      render: (names: string[]) => names?.length
        ? names.map(n => (
          <Tag key={n} icon={<KeyOutlined />} style={{
            borderRadius: 20, padding: '2px 8px', margin: '2px',
            background: '#f5f3ff', border: '1px solid #ddd6fe',
            color: '#7c3aed', fontWeight: 500, fontSize: 11,
          }}>
            {n}
          </Tag>
        ))
        : <Text type="secondary" style={{ fontSize: 12 }}>无角色</Text>,
    },
    {
      title: col(<CheckCircleOutlined style={{ color: '#22c55e' }} />, '账号状态'),
      dataIndex: 'status',
      width: 100,
      render: s => (
        <Badge
          status={s === 1 ? 'success' : 'error'}
          text={
            <Text style={{ color: s === 1 ? '#10b981' : '#ef4444', fontWeight: 600, fontSize: 12 }}>
              {s === 1 ? '正常' : '已停用'}
            </Text>
          }
        />
      ),
    },
    {
      title: col(<ClockCircleOutlined style={{ color: '#94a3b8' }} />, '创建时间'),
      dataIndex: 'createTime',
      width: 130,
      render: v => (
        <Space size={4}>
          <ClockCircleOutlined style={{ color: '#d1d5db', fontSize: 11 }} />
          <Text type="secondary" style={{ fontSize: 12 }}>
            {v ? dayjs(v).format('YYYY-MM-DD') : '—'}
          </Text>
        </Space>
      ),
    },
    {
      title: col(<SettingOutlined style={{ color: '#94a3b8' }} />, '操作'),
      width: 225,
      fixed: 'right',
      render: (_, r) => (
        <Space size={4}>
          <PermGuard code="staff:edit">
            <Button size="small" icon={<EditOutlined />}
              style={{ borderRadius: 6, color: '#fa8c16', borderColor: '#ffd591' }}
              onClick={() => openEdit(r)}>编辑</Button>
          </PermGuard>
          {r.status === 1 ? (
            <PermGuard code="staff:toggle">
              <Button size="small" icon={<StopOutlined />}
                style={{ borderRadius: 6, color: '#ff4d4f', borderColor: '#ffa39e' }}
                onClick={() => handleStatusToggle(r)}>停用</Button>
            </PermGuard>
          ) : (
            <PermGuard code="staff:toggle">
              <Button size="small" icon={<CheckCircleOutlined />}
                style={{ borderRadius: 6, color: '#52c41a', borderColor: '#b7eb8f' }}
                onClick={() => handleStatusToggle(r)}>启用</Button>
            </PermGuard>
          )}
          <PermGuard code="staff:delete">
            <Popconfirm title="确认删除该员工？" onConfirm={() => handleDelete(r)} okText="删除" cancelText="取消" okButtonProps={{ danger: true }}>
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
          <div style={{ width: 34, height: 34, borderRadius: 10, background: GRADIENT, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 4px 12px rgba(99,102,241,0.3)', flexShrink: 0 }}>
            <IdcardOutlined style={{ color: '#fff', fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1e293b', lineHeight: 1.2 }}>员工管理</div>
            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>管理系统员工账号 · 分配职位 · 权限控制</div>
          </div>
          <Divider type="vertical" style={{ height: 20, margin: '0 4px', borderColor: '#e0e4ff' }} />
          <div style={{ display: 'flex', gap: 8 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: 'rgba(99,102,241,0.1)', border: '1px solid rgba(99,102,241,0.25)' }}>
              <span style={{ fontSize: 13 }}>👥</span>
              <span style={{ fontSize: 12, color: '#6b7280' }}>总数</span>
              <span style={{ fontSize: 13, fontWeight: 700, color: '#6366f1' }}>{total}</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: 'rgba(16,185,129,0.1)', border: '1px solid rgba(16,185,129,0.25)' }}>
              <span style={{ fontSize: 13 }}>✓</span>
              <span style={{ fontSize: 12, color: '#6b7280' }}>在职</span>
              <span style={{ fontSize: 13, fontWeight: 700, color: '#10b981' }}>{activeCount}</span>
            </div>
          </div>
          <div style={{ flex: 1 }} />
          <PermGuard code="staff:add">
            <Button type="primary" icon={<PlusOutlined />} style={{ borderRadius: 8, background: GRADIENT, border: 'none' }} onClick={openAdd}>新增员工</Button>
          </PermGuard>
        </div>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', padding: '10px 24px 12px' }}>
          <Input
            placeholder="搜索账号 / 姓名 / 手机"
            prefix={<SearchOutlined style={{ color: '#bbb' }} />}
            allowClear
            style={{ ...INPUT_STYLE, width: 180 }}
            value={keywordDraft}
            onChange={e => {
              setKeywordDraft(e.target.value)
              if (!e.target.value) { setKeyword(''); setCurrent(1) }
            }}
            onPressEnter={handleSearch}
          />
          <Select
            placeholder={<><CheckCircleOutlined /> 账号状态</>}
            allowClear
            style={{ ...INPUT_STYLE, width: 110 }}
            value={status}
            onChange={v => { setStatus(v); setCurrent(1) }}>
            <Option value={1}><Space><CheckCircleOutlined style={{ color: '#10b981' }} />正常</Space></Option>
            <Option value={0}><Space><StopOutlined style={{ color: '#ef4444' }} />停用</Space></Option>
          </Select>
          <Select
            placeholder={<><ApartmentOutlined /> 所属职位</>}
            allowClear
            style={{ ...INPUT_STYLE, width: 130 }}
            value={positionId}
            onChange={v => { setPositionId(v); setCurrent(1) }}>
            {positions.map(p => (
              <Option key={p.id} value={p.id}><Space><ApartmentOutlined />{p.name}</Space></Option>
            ))}
          </Select>
          <div style={{ flex: 1 }} />
          <Button icon={<ReloadOutlined />} size="middle" style={{ borderRadius: 8 }} onClick={loadData}>刷新</Button>
          <Button icon={<ReloadOutlined />} size="middle" style={{ borderRadius: 8 }} onClick={handleReset}>重置</Button>
          <Button type="primary" icon={<SearchOutlined />} style={{ borderRadius: 8, border: 'none', background: GRADIENT }} onClick={handleSearch}>搜索</Button>
        </div>
      </div>
      <div style={{ marginLeft: -24, marginRight: -24, marginBottom: -24, background: '#fff', borderTop: '1px solid #eef0f8' }}>
        <Table
          rowKey="id"
          columns={columns}
          dataSource={data}
          loading={loading}
          size="middle"
          pagination={false}
          components={styledTableComponents}
          scroll={{ x: 'max-content', y: 'calc(100vh - 272px)' }}
        />
        <PagePagination
          total={total}
          current={current}
          pageSize={pageSize}
          onChange={setCurrent}
          onSizeChange={s => { setPageSize(s); setCurrent(1) }}
          countLabel="条"
        />
      </div>

      <Drawer
        title={
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{
              width: 40, height: 40, borderRadius: 10,
              background: 'rgba(255,255,255,0.25)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              {editing
                ? <EditOutlined style={{ color: '#fff', fontSize: 18 }} />
                : <PlusOutlined style={{ color: '#fff', fontSize: 18 }} />}
            </div>
            <div>
              <div style={{ fontWeight: 800, fontSize: 15, color: '#fff' }}>
                {editing ? `编辑员工 — ${editing.realName || editing.username}` : '新增员工账号'}
              </div>
              <div style={{ fontSize: 12, color: 'rgba(255,255,255,0.82)', marginTop: 2 }}>
                {editing ? '修改员工信息及权限配置' : '👋 欢迎新成员加入，共筑卓越管理团队！'}
              </div>
            </div>
          </div>
        }
        styles={{
          header: {
            background: 'linear-gradient(135deg,#667eea,#764ba2)',
            padding: '14px 20px',
          },
          wrapper: { width: 880 },
        }}
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        extra={
          <Space>
            <Button onClick={() => setDrawerOpen(false)} style={{ borderRadius: 8 }}>取消</Button>
            <Button type="primary" onClick={handleSubmit}
              style={{ background: 'linear-gradient(135deg,#667eea,#764ba2)', border: 'none', borderRadius: 8 }}>
              保存员工
            </Button>
          </Space>
        }
      >
        <Form form={form} layout="vertical">
          <Row gutter={16}>
            <Col span={8}>
              <Form.Item name="username" label="登录账号"
                rules={[{ required: true, message: '请输入账号' },
                  { pattern: /^[a-zA-Z0-9_]{4,32}$/, message: '4-32位字母/数字/下划线' }]}>
                <Input prefix={<UserOutlined style={{ color: '#667eea' }} />}
                  placeholder="login_name" disabled={!!editing} />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="realName" label="真实姓名">
                <Input prefix={<IdcardOutlined style={{ color: '#667eea' }} />} placeholder="张三" />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="password" label={editing ? '登录密码（留空不修改）' : '登录密码'}
                rules={editing ? [] : [{ required: true, message: '请输入密码' }, { min: 6, message: '至少6位' }]}>
                <Input.Password prefix={<LockOutlined style={{ color: '#667eea' }} />}
                  placeholder={editing ? '留空则不修改密码' : '至少6位字符'} />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="mobile" label="手机号码">
                <Input prefix={<PhoneOutlined style={{ color: '#667eea' }} />} placeholder="13800138000" />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="email" label="电子邮箱"
                rules={[{ type: 'email', message: '邮箱格式不正确' }]}>
                <Input prefix={<MailOutlined style={{ color: '#667eea' }} />} placeholder="user@example.com" />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="positionId" label="所属职位">
                <Select placeholder="请选择职位" allowClear>
                  {positions.filter(p => p.status === 1).map(p => (
                    <Option key={p.id} value={p.id}>
                      <Space><ApartmentOutlined style={{ color: '#3b82f6' }} />{p.name}</Space>
                    </Option>
                  ))}
                </Select>
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="status" label="账号状态">
                <Select>
                  <Option value={1}><Space><CheckCircleOutlined style={{ color: '#10b981' }} />正常</Space></Option>
                  <Option value={0}><Space><StopOutlined style={{ color: '#ef4444' }} />停用</Space></Option>
                </Select>
              </Form.Item>
            </Col>
            <Col span={16}>
              <Form.Item name="roleIds" label="分配角色">
                <Select mode="multiple" placeholder="选择该员工拥有的角色" allowClear>
                  {roles.map(r => (
                    <Option key={r.id} value={r.id}>
                      <Space><KeyOutlined style={{ color: '#7c3aed' }} />{r.roleName}</Space>
                    </Option>
                  ))}
                </Select>
              </Form.Item>
            </Col>
          </Row>
        </Form>
      </Drawer>
    </div>
  )
}
