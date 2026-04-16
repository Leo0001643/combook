import { useState, useEffect, useCallback } from 'react'
import {
  Row, Col, Table, Input, Select, Space, Avatar,
  Button, Typography, message, Modal, Form, Tooltip, Badge, Popconfirm, Divider,
} from 'antd'
import type { ColumnsType } from 'antd/es/table'
import {
  SearchOutlined, PlusOutlined, EditOutlined, DeleteOutlined, ReloadOutlined,
  UserOutlined, IdcardOutlined, LockOutlined, CheckCircleOutlined, StopOutlined,
  PhoneOutlined, MailOutlined, SettingOutlined,
  ApartmentOutlined, SolutionOutlined,
  SendOutlined, FileTextOutlined,
  SafetyCertificateOutlined, ClockCircleOutlined,
} from '@ant-design/icons'
import dayjs from 'dayjs'
import { merchantPortalApi } from '../../api/api'
import PermDrawer, { type PermTarget } from '../../components/merchant/PermDrawer'
import RichTextInput from '../../components/common/RichTextInput'
import PermGuard from '../../components/common/PermGuard'
import { col, styledTableComponents, INPUT_STYLE } from '../../components/common/tableComponents'
import PagePagination from '../../components/common/PagePagination'

const { Text } = Typography

const PAGE_GRADIENT = 'linear-gradient(135deg,#6366f1,#8b5cf6)'

const AVATAR_COLORS = [
  'linear-gradient(135deg,#667eea,#764ba2)',
  'linear-gradient(135deg,#f093fb,#f5576c)',
  'linear-gradient(135deg,#4facfe,#00f2fe)',
  'linear-gradient(135deg,#43e97b,#38f9d7)',
  'linear-gradient(135deg,#fa709a,#fee140)',
]

interface StaffVO {
  id: number
  merchantId: number
  username: string
  realName: string
  mobile: string
  telegram?: string
  email: string
  avatar: string
  status: number
  remark: string
  createTime: string
  deptId?: number
  positionId?: number
}

interface DeptOption { id: number; name: string }
interface PositionOption { id: number; name: string; deptId?: number }

export default function MerchantStaffPage() {
  const [data, setData]           = useState<StaffVO[]>([])
  const [total, setTotal]         = useState(0)
  const [loading, setLoading]     = useState(false)
  const [keyword, setKeyword]     = useState('')
  const [filterStatus, setFilterStatus]     = useState<number | undefined>()
  const [filterDeptId, setFilterDeptId]     = useState<number | undefined>()
  const [filterPositionId, setFilterPositionId] = useState<number | undefined>()
  const [page, setPage]           = useState(1)
  const [pageSize, setPageSize]   = useState(20)
  const [modalOpen, setModalOpen] = useState(false)
  const [editing, setEditing]     = useState<StaffVO | null>(null)
  const [form] = Form.useForm()

  const [depts, setDepts]               = useState<DeptOption[]>([])
  const [allPositions, setAllPositions] = useState<PositionOption[]>([])
  const [formDeptId, setFormDeptId]     = useState<number | undefined>()
  const [permTarget, setPermTarget]     = useState<PermTarget | null>(null)

  // ── 数据加载 ──────────────────────────────────────────────────────────────

  const loadData = useCallback(async () => {
    setLoading(true)
    try {
      const res = await merchantPortalApi.staffList({
        page, size: pageSize,
        keyword:    keyword || undefined,
        status:     filterStatus,
        deptId:     filterDeptId,
        positionId: filterPositionId,
      })
      const d = res.data?.data
      setData(d?.list ?? d?.records ?? [])
      setTotal(d?.total ?? 0)
    } finally { setLoading(false) }
  }, [page, pageSize, keyword, filterStatus, filterDeptId, filterPositionId])

  useEffect(() => { loadData() }, [loadData])

  // 初始化：同时加载部门 + 全量职位
  useEffect(() => {
    merchantPortalApi.deptList().then(res => {
      setDepts((res.data?.data ?? []).filter((d: any) => d.status === 1).map((d: any) => ({ id: d.id, name: d.name })))
    })
    merchantPortalApi.positionList().then(res => {
      setAllPositions((res.data?.data ?? []).map((p: any) => ({ id: p.id, name: p.name, deptId: p.deptId })))
    })
  }, [])

  // 当前表单选中部门对应的职位（未选部门则显示全量）
  const formPositions = formDeptId
    ? allPositions.filter(p => p.deptId === formDeptId)
    : allPositions

  // 筛选栏部门对应职位
  const filterPositions = filterDeptId
    ? allPositions.filter(p => p.deptId === filterDeptId)
    : allPositions

  // ── 辅助查找名称 ──────────────────────────────────────────────────────────
  const getDeptName     = (id?: number) => depts.find(d => d.id === id)?.name
  const getPositionName = (id?: number) => allPositions.find(p => p.id === id)?.name

  // ── 打开新增/编辑 ────────────────────────────────────────────────────────
  const openAdd = () => {
    setEditing(null); form.resetFields()
    form.setFieldsValue({ status: 1, password: '123456' })
    setFormDeptId(undefined)
    setModalOpen(true)
  }

  const openEdit = (r: StaffVO) => {
    setEditing(r)
    form.setFieldsValue({
      realName: r.realName, mobile: r.mobile, telegram: r.telegram,
      email: r.email, status: r.status, remark: r.remark,
      deptId: r.deptId, positionId: r.positionId,
    })
    setFormDeptId(r.deptId)
    setModalOpen(true)
  }

  const handleDeptChange = (deptId: number | undefined) => {
    setFormDeptId(deptId)
    form.setFieldValue('positionId', undefined)
  }

  const handleSubmit = async () => {
    const values = await form.validateFields()
    try {
      if (editing) {
        await merchantPortalApi.staffEdit({ id: editing.id, ...values })
        message.success('员工信息已更新')
      } else {
        await merchantPortalApi.staffAdd(values)
        message.success('员工账号已创建')
      }
      setModalOpen(false); loadData()
    } catch {/* interceptor handled */}
  }

  const handleStatusToggle = async (r: StaffVO) => {
    const next = r.status === 1 ? 0 : 1
    await merchantPortalApi.staffStatus(r.id, next)
    message.success(next === 1 ? '账号已启用' : '账号已停用')
    loadData()
  }

  const handleReset = () => {
    setKeyword(''); setFilterStatus(undefined)
    setFilterDeptId(undefined); setFilterPositionId(undefined); setPage(1)
  }

  const activeCount = data.filter(d => d.status === 1).length

  // ── 表格列 ───────────────────────────────────────────────────────────────
  const columns: ColumnsType<StaffVO> = [
    {
      title: col(<UserOutlined style={{ color: '#6366f1' }} />, '员工信息'), key: 'info', width: 220, fixed: 'left',
      render: (_, r) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, width: '100%' }}>
          <Avatar size={46} icon={<UserOutlined />}
            style={{ background: AVATAR_COLORS[r.id % AVATAR_COLORS.length], flexShrink: 0 }} />
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
      title: col(<PhoneOutlined style={{ color: '#6366f1' }} />, '联系方式'), key: 'contact', width: 200,
      render: (_, r) => (
        <Space direction="vertical" size={2}>
          <Space size={4}><PhoneOutlined style={{ color: '#3b82f6', fontSize: 11 }} /><Text style={{ fontSize: 12 }}>{r.mobile || <Text type="secondary">未填写</Text>}</Text></Space>
          {r.telegram && <Space size={4}><SendOutlined style={{ color: '#229ED9', fontSize: 11 }} /><Text style={{ fontSize: 12, color: '#229ED9' }}>@{r.telegram}</Text></Space>}
          <Space size={4}><MailOutlined style={{ color: '#8b5cf6', fontSize: 11 }} /><Text style={{ fontSize: 12 }}>{r.email || <Text type="secondary">未填写</Text>}</Text></Space>
        </Space>
      ),
    },
    {
      title: col(<ApartmentOutlined style={{ color: '#6366f1' }} />, '部门'), key: 'dept', width: 110,
      render: (_, r) => {
        const name = getDeptName(r.deptId)
        return name
          ? <Space size={4}><ApartmentOutlined style={{ color: '#6366f1', fontSize: 11 }} /><Text style={{ fontSize: 12, color: '#6366f1' }}>{name}</Text></Space>
          : <Text type="secondary" style={{ fontSize: 12 }}>未分配</Text>
      },
    },
    {
      title: col(<SolutionOutlined style={{ color: '#6366f1' }} />, '职位'), key: 'position', width: 110,
      render: (_, r) => {
        const name = getPositionName(r.positionId)
        return name
          ? <Space size={4}><SolutionOutlined style={{ color: '#764ba2', fontSize: 11 }} /><Text style={{ fontSize: 12, color: '#764ba2' }}>{name}</Text></Space>
          : <Text type="secondary" style={{ fontSize: 12 }}>未分配</Text>
      },
    },
    {
      title: col(<SafetyCertificateOutlined style={{ color: '#6366f1' }} />, '状态'), dataIndex: 'status', width: 90,
      render: s => (
        <Badge
          status={s === 1 ? 'success' : 'error'}
          text={<Text style={{ color: s === 1 ? '#10b981' : '#ef4444', fontWeight: 600, fontSize: 12 }}>
            {s === 1 ? '正常' : '已停用'}
          </Text>}
        />
      ),
    },
    {
      title: col(<ClockCircleOutlined style={{ color: '#6366f1' }} />, '创建时间'), dataIndex: 'createTime', width: 120,
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
      title: col(<SettingOutlined style={{ color: '#6366f1' }} />, '操作'), width: 264, fixed: 'right',
      render: (_, r) => (
        <Space size={[4, 4]} wrap>
          <PermGuard code="staff:edit">
            <Button size="small" icon={<EditOutlined />}
              style={{ borderRadius: 6, color: '#fa8c16', borderColor: '#ffd591' }}
              onClick={() => openEdit(r)}>编辑</Button>
          </PermGuard>
          <PermGuard code="staff:edit">
            <Button size="small" icon={<SettingOutlined />}
              style={{ borderRadius: 6, color: '#6366f1', borderColor: '#c7d2fe' }}
              onClick={() => {
                const deptName = getDeptName(r.deptId)
                const posName  = getPositionName(r.positionId)
                setPermTarget({ type: 'staff', id: r.id, name: r.realName || r.username, deptName, posName })
              }}>权限</Button>
          </PermGuard>
          <PermGuard code="staff:toggle">
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
          <PermGuard code="staff:delete">
            <Popconfirm title="确认删除该员工？" onConfirm={async () => { await merchantPortalApi.staffDelete(r.id); message.success('已删除'); loadData() }} okText="删除" cancelText="取消" okButtonProps={{ danger: true }}>
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
          <div style={{ width: 34, height: 34, borderRadius: 10, background: PAGE_GRADIENT, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 4px 12px rgba(99,102,241,0.3)', flexShrink: 0 }}>
            <IdcardOutlined style={{ color: '#fff', fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1e293b', lineHeight: 1.2 }}>员工管理</div>
            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>管理商户员工账号 · 分配部门职位</div>
          </div>
          <Divider type="vertical" style={{ height: 20, margin: '0 4px', borderColor: '#e0e4ff' }} />
          <div style={{ display: 'flex', gap: 8 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: 'rgba(99,102,241,0.1)', border: '1px solid rgba(99,102,241,0.25)' }}>
              <span>👥</span>
              <span style={{ fontSize: 12, color: '#6b7280' }}>总数</span>
              <span style={{ fontSize: 13, fontWeight: 700, color: '#6366f1' }}>{total}</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: 'rgba(99,102,241,0.1)', border: '1px solid rgba(99,102,241,0.25)' }}>
              <span>✅</span>
              <span style={{ fontSize: 12, color: '#6b7280' }}>启用</span>
              <span style={{ fontSize: 13, fontWeight: 700, color: '#6366f1' }}>{activeCount}</span>
            </div>
          </div>
          <div style={{ flex: 1 }} />
          <PermGuard code="staff:add">
            <Button type="primary" icon={<PlusOutlined />} style={{ borderRadius: 8, background: 'linear-gradient(135deg,#6366f1,#8b5cf6)', border: 'none' }} onClick={openAdd}>新增员工</Button>
          </PermGuard>
        </div>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', padding: '10px 24px 12px' }}>
          <Input
            allowClear
            prefix={<SearchOutlined style={{ color: '#bbb' }} />}
            placeholder="搜索账号 / 姓名 / 手机 / Telegram"
            style={{ ...INPUT_STYLE, width: 180 }}
            value={keyword}
            onChange={e => { if (!e.target.value) { setKeyword(''); setPage(1) } else setKeyword(e.target.value) }}
            onPressEnter={() => { setPage(1); loadData() }}
          />
          <Select placeholder={<Space size={4}><SafetyCertificateOutlined style={{ color: '#10b981', fontSize: 12 }} />账号状态</Space>} allowClear style={{ ...INPUT_STYLE, width: 115 }} value={filterStatus}
            onChange={v => { setFilterStatus(v); setPage(1) }}>
            <Select.Option value={1}><Space><CheckCircleOutlined style={{ color: '#10b981' }} />正常</Space></Select.Option>
            <Select.Option value={0}><Space><StopOutlined style={{ color: '#ef4444' }} />停用</Space></Select.Option>
          </Select>
          <Select placeholder={<Space size={4}><ApartmentOutlined style={{ color: '#6366f1', fontSize: 12 }} />按部门筛选</Space>} allowClear style={{ ...INPUT_STYLE, width: 128 }} value={filterDeptId}
            onChange={v => { setFilterDeptId(v); setFilterPositionId(undefined); setPage(1) }}
            options={depts.map(d => ({ value: d.id, label: d.name }))} />
          <Select placeholder={<Space size={4}><SolutionOutlined style={{ color: '#8b5cf6', fontSize: 12 }} />按职位筛选</Space>} allowClear style={{ ...INPUT_STYLE, width: 128 }} value={filterPositionId}
            onChange={v => { setFilterPositionId(v); setPage(1) }}
            options={filterPositions.map(p => ({ value: p.id, label: p.name }))} />
          <div style={{ flex: 1 }} />
          <Button icon={<ReloadOutlined />} size="middle" style={{ borderRadius: 8 }} onClick={handleReset}>重置</Button>
          <Tooltip title="刷新"><Button icon={<ReloadOutlined />} size="middle" loading={loading} style={{ borderRadius: 8, color: '#6366f1', borderColor: '#c7d2fe' }} onClick={loadData} /></Tooltip>
          <Button type="primary" icon={<SearchOutlined />} style={{ borderRadius: 8, border: 'none', background: 'linear-gradient(135deg,#6366f1,#8b5cf6)' }} onClick={() => { setPage(1); loadData() }}>搜索</Button>
        </div>
      </div>
      <div style={{ marginLeft: -24, marginRight: -24, marginBottom: -24, background: '#fff', borderTop: '1px solid #eef0f8' }}>
        <Table
          rowKey="id" columns={columns} dataSource={data}
          loading={loading} pagination={false} components={styledTableComponents}
          scroll={{ x: 'max-content', y: 'calc(100vh - 272px)' }} size="middle"
        />
        <PagePagination total={total} current={page} pageSize={pageSize} onChange={p => setPage(p)} onSizeChange={s => { setPageSize(s); setPage(1) }} countLabel="位员工" />
      </div>

      {/* ── 新增/编辑 Modal ── */}
      <Modal
        open={modalOpen}
        onCancel={() => setModalOpen(false)}
        onOk={handleSubmit}
        okText={editing ? '保存修改' : '确认创建'}
        cancelText="取消"
        width={860}
        okButtonProps={{ style: { background: 'linear-gradient(135deg,#667eea,#764ba2)', border: 'none', borderRadius: 8 } }}
        cancelButtonProps={{ style: { borderRadius: 8 } }}
        styles={{ body: { maxHeight: 'calc(85vh - 160px)', overflowY: 'auto', overflowX: 'hidden' } }}
        title={
          <div style={{
            background: 'linear-gradient(135deg,#667eea,#764ba2)',
            margin: '-20px -24px 20px',
            padding: '18px 24px',
            borderRadius: '8px 8px 0 0',
            display: 'flex', alignItems: 'center', gap: 12,
          }}>
            <div style={{ width: 44, height: 44, borderRadius: 12, background: 'rgba(255,255,255,0.2)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
              {editing ? <EditOutlined style={{ color: '#fff', fontSize: 22 }} /> : <PlusOutlined style={{ color: '#fff', fontSize: 22 }} />}
            </div>
            <div>
              <div style={{ color: '#fff', fontWeight: 800, fontSize: 17 }}>
                {editing ? `编辑员工 — ${editing.realName || editing.username}` : '新增员工账号'}
              </div>
              <div style={{ color: 'rgba(255,255,255,0.82)', fontSize: 12, marginTop: 3 }}>
                {editing ? '修改员工基本信息，权限请点击「权限」按钮配置' : '填写账号信息后，可在员工列表中为其分配权限'}
              </div>
            </div>
          </div>
        }
      >
        <Form form={form} layout="vertical">
          <Row gutter={16}>
            {/* ── 账号（仅新增）── */}
            {!editing && (
              <Col span={8}>
                <Form.Item
                  name="username"
                  label={<Space size={4}><UserOutlined style={{ color: '#667eea' }} /><span>登录账号</span></Space>}
                  rules={[{ required: true, message: '请输入账号' }, { pattern: /^[a-zA-Z0-9_]{4,32}$/, message: '4-32位字母/数字/下划线' }]}
                >
                  <Input prefix={<UserOutlined style={{ color: '#667eea' }} />} placeholder="login_name" />
                </Form.Item>
              </Col>
            )}

            {/* ── 真实姓名 ── */}
            <Col span={8}>
              <Form.Item name="realName" label={<Space size={4}><IdcardOutlined style={{ color: '#6366f1' }} /><span>真实姓名</span></Space>}>
                <Input prefix={<IdcardOutlined style={{ color: '#6366f1' }} />} placeholder="张三" />
              </Form.Item>
            </Col>

            {/* ── 手机号 ── */}
            <Col span={8}>
              <Form.Item name="mobile" label={<Space size={4}><PhoneOutlined style={{ color: '#10b981' }} /><span>手机号码</span></Space>}>
                <Input prefix={<PhoneOutlined style={{ color: '#10b981' }} />} placeholder="+85512345678" />
              </Form.Item>
            </Col>

            {/* ── Telegram ── */}
            <Col span={8}>
              <Form.Item name="telegram" label={<Space size={4}><SendOutlined style={{ color: '#229ED9' }} /><span>Telegram</span></Space>}>
                <Input addonBefore={<span style={{ color: '#229ED9', fontWeight: 600 }}>@</span>} placeholder="不含@，如：username" />
              </Form.Item>
            </Col>

            {/* ── 邮箱 ── */}
            <Col span={8}>
              <Form.Item name="email" label={<Space size={4}><MailOutlined style={{ color: '#8b5cf6' }} /><span>邮箱地址</span></Space>}>
                <Input prefix={<MailOutlined style={{ color: '#8b5cf6' }} />} placeholder="example@email.com" />
              </Form.Item>
            </Col>

            {/* ── 密码 ── */}
            <Col span={8}>
              <Form.Item
                name="password"
                label={<Space size={4}><LockOutlined style={{ color: '#f59e0b' }} /><span>{editing ? '密码（留空不修改）' : '初始密码'}</span></Space>}
                rules={editing ? [] : [{ required: true, message: '请输入密码' }, { min: 6, message: '至少6位' }]}
              >
                <Input.Password prefix={<LockOutlined style={{ color: '#f59e0b' }} />}
                  placeholder={editing ? '留空则不修改密码' : '默认 123456'} />
              </Form.Item>
            </Col>

            {/* ── 所属部门 ── */}
            <Col span={8}>
              <Form.Item name="deptId" label={<Space size={4}><ApartmentOutlined style={{ color: '#667eea' }} /><span>所属部门</span></Space>}>
                <Select
                  allowClear placeholder="选择部门（可选）"
                  onChange={handleDeptChange}
                  options={depts.map(d => ({ value: d.id, label: d.name }))}
                />
              </Form.Item>
            </Col>

            {/* ── 所属职位（动态过滤）── */}
            <Col span={8}>
              <Form.Item
                name="positionId"
                label={
                  <Space size={4}>
                    <SolutionOutlined style={{ color: '#764ba2' }} />
                    <span>所属职位</span>
                    {formPositions.length === 0 && allPositions.length > 0 && formDeptId && (
                      <Tooltip title="该部门下暂无职位，请先在职位管理中创建">
                        <span style={{ color: '#f59e0b', fontSize: 11 }}>（暂无职位）</span>
                      </Tooltip>
                    )}
                  </Space>
                }
              >
                <Select
                  allowClear showSearch
                  placeholder={allPositions.length === 0 ? '暂无职位，请先创建职位' : formDeptId ? '选择该部门下的职位' : '选择职位（可不限部门）'}
                  optionFilterProp="label"
                  options={formPositions.map(p => {
                    const deptName = getDeptName(p.deptId)
                    return {
                      value: p.id,
                      label: deptName ? `${p.name}（${deptName}）` : p.name,
                    }
                  })}
                  notFoundContent={
                    <div style={{ padding: '8px 0', textAlign: 'center', color: '#94a3b8', fontSize: 12 }}>
                      {allPositions.length === 0 ? '还没有职位，请前往「职位管理」创建' : '该部门下暂无职位'}
                    </div>
                  }
                />
              </Form.Item>
            </Col>

            {/* ── 状态 ── */}
            <Col span={8}>
              <Form.Item name="status" label={<Space size={4}><CheckCircleOutlined style={{ color: '#10b981' }} /><span>账号状态</span></Space>}>
                <Select>
                  <Select.Option value={1}><Space><CheckCircleOutlined style={{ color: '#10b981' }} />正常</Space></Select.Option>
                  <Select.Option value={0}><Space><StopOutlined style={{ color: '#ef4444' }} />停用</Space></Select.Option>
                </Select>
              </Form.Item>
            </Col>

            {/* ── 备注 ── */}
            <Col span={24}>
              <Form.Item name="remark" label={<Space size={4}><FileTextOutlined style={{ color: '#94a3b8' }} /><span>备注信息</span></Space>}>
                <RichTextInput placeholder="选填备注，如：职责描述、入职信息、特殊技能等..." minHeight={100} />
              </Form.Item>
            </Col>
          </Row>
        </Form>
      </Modal>

      <PermDrawer target={permTarget} onClose={() => setPermTarget(null)} />
    </div>
  )
}
