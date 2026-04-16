import { useState, useEffect } from 'react'
import {
  Table, Button, Space, Typography, message, Modal, Form,
  Input, InputNumber, Select, Badge, Row, Col, Tag, Switch, Tooltip, Popconfirm, Divider,
} from 'antd'
import type { ColumnsType } from 'antd/es/table'
import {
  PlusOutlined, EditOutlined, DeleteOutlined, ReloadOutlined,
  ApartmentOutlined, CheckCircleOutlined, StopOutlined,
  TagOutlined, SortAscendingOutlined, CrownOutlined, ThunderboltOutlined, SettingOutlined,
  FileTextOutlined, SolutionOutlined, SafetyCertificateOutlined, CheckSquareOutlined, ClockCircleOutlined,
} from '@ant-design/icons'
import { merchantPortalApi, type PositionVO } from '../../api/api'
import PermDrawer, { type PermTarget } from '../../components/merchant/PermDrawer'
import RichTextInput from '../../components/common/RichTextInput'
import PermGuard from '../../components/common/PermGuard'
import { col, styledTableComponents } from '../../components/common/tableComponents'

interface DeptOption { id: number; name: string }

const { Text } = Typography
const { Option } = Select

const PAGE_GRADIENT = 'linear-gradient(135deg,#0891b2,#0ea5e9)'

const COLORS = ['#6366f1','#8b5cf6','#ec4899','#ef4444','#f59e0b','#10b981','#3b82f6','#06b6d4']

const STATUS_CFG: Record<number, { label: string; badge: 'success' | 'default' }> = {
  1: { label: '启用', badge: 'success' },
  0: { label: '停用', badge: 'default' },
}

export default function MerchantPositionPage() {
  const [data, setData]           = useState<PositionVO[]>([])
  const [loading, setLoading]     = useState(false)
  const [modalOpen, setModalOpen] = useState(false)
  const [editing, setEditing]     = useState<PositionVO | null>(null)
  const [form] = Form.useForm()

  const [depts, setDepts]           = useState<DeptOption[]>([])
  const [permTarget, setPermTarget] = useState<PermTarget | null>(null)

  useEffect(() => { loadData() }, [])

  useEffect(() => {
    merchantPortalApi.deptList().then(res => {
      setDepts((res.data?.data ?? []).map((d: any) => ({ id: d.id, name: d.name })))
    })
  }, [])

  const loadData = async () => {
    setLoading(true)
    try {
      const res = await merchantPortalApi.positionList()
      setData((res.data?.data ?? []).sort((a: PositionVO, b: PositionVO) => a.sort - b.sort))
    } finally { setLoading(false) }
  }

  const openAdd = () => {
    setEditing(null)
    form.resetFields()
    form.setFieldsValue({ sort: 0, status: 1, fullAccess: false })
    setModalOpen(true)
  }

  const openEdit = (record: PositionVO) => {
    setEditing(record)
    form.setFieldsValue({ ...record, fullAccess: record.fullAccess === 1 })
    setModalOpen(true)
  }

  const handleDelete = (id: number) => {
    Modal.confirm({
      title: '确认删除该职位？',
      content: '删除后不可恢复。',
      okType: 'danger',
      okText: '确认删除',
      cancelText: '取消',
      onOk: async () => {
        try {
          await merchantPortalApi.positionDelete(id)
          message.success('删除成功')
          loadData()
        } catch (e: any) {
          message.error(e?.response?.data?.message ?? '删除失败')
        }
      },
    })
  }

  const handleStatusToggle = async (record: PositionVO) => {
    try {
      await merchantPortalApi.positionStatus(record.id, record.status === 1 ? 0 : 1)
      message.success('状态已更新')
      loadData()
    } catch (e: any) {
      message.error(e?.response?.data?.message ?? '操作失败')
    }
  }

  const handleSubmit = async () => {
    try {
      const raw = await form.validateFields()
      // Convert boolean Switch → 0/1 integer
      const values = { ...raw, fullAccess: raw.fullAccess ? 1 : 0 }
      if (editing) {
        await merchantPortalApi.positionEdit({ id: editing.id, ...values })
        message.success('职位已更新')
      } else {
        await merchantPortalApi.positionAdd(values)
        message.success('职位创建成功')
      }
      setModalOpen(false)
      loadData()
    } catch (e: any) {
      if (e?.response?.data?.message) message.error(e.response.data.message)
    }
  }

  const columns: ColumnsType<PositionVO> = [
    {
      title: col(<SolutionOutlined style={{ color: '#0891b2' }} />, '职位名称', 'left'), dataIndex: 'name', key: 'name',
      render: (name, r, idx) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, width: '100%' }}>
          <div style={{
            width: 34, height: 34, borderRadius: 8, flexShrink: 0,
            background: `linear-gradient(135deg,${COLORS[idx % COLORS.length]}cc,${COLORS[(idx + 2) % COLORS.length]}cc)`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <SolutionOutlined style={{ color: '#fff', fontSize: 15 }} />
          </div>
          <div>
            <div style={{ fontWeight: 600, color: '#1a1a2e' }}>{name}</div>
            {r.deptId && (
              <div style={{ fontSize: 11, color: '#999' }}>
                {depts.find(d => d.id === r.deptId)?.name ?? `部门${r.deptId}`}
              </div>
            )}
          </div>
        </div>
      ),
    },
    {
      title: col(<TagOutlined style={{ color: '#0891b2' }} />, '职位编码'), dataIndex: 'code', key: 'code',
      render: v => <Tag color="purple" style={{ borderRadius: 6, fontFamily: 'monospace' }}>{v}</Tag>,
    },
    {
      title: col(<FileTextOutlined style={{ color: '#0891b2' }} />, '备注'), dataIndex: 'remark', key: 'remark',
      render: v => <Text type="secondary">{v || '—'}</Text>,
    },
    {
      title: col(<SortAscendingOutlined style={{ color: '#0891b2' }} />, '排序'), dataIndex: 'sort', key: 'sort', width: 80,
      render: v => <Tag style={{ borderRadius: 6 }}>{v}</Tag>,
    },
    {
      title: col(<SafetyCertificateOutlined style={{ color: '#0891b2' }} />, '状态'), dataIndex: 'status', key: 'status', width: 100,
      render: v => {
        const cfg = STATUS_CFG[v] ?? STATUS_CFG[0]
        return <Badge status={cfg.badge} text={cfg.label} />
      },
    },
    {
      title: col(<CheckSquareOutlined style={{ color: '#0891b2' }} />, '全量权限'), dataIndex: 'fullAccess', key: 'fullAccess', width: 110,
      render: (v: number) => v === 1
        ? (
          <Tooltip title="该职位拥有所有菜单权限（如总裁）">
            <Tag icon={<CrownOutlined />} color="gold" style={{ borderRadius: 6, fontWeight: 600 }}>
              全量权限
            </Tag>
          </Tooltip>
        )
        : <Tag style={{ borderRadius: 6, color: '#aaa', borderColor: '#eee' }}>按分配</Tag>,
    },
    {
      title: col(<ClockCircleOutlined style={{ color: '#0891b2' }} />, '创建时间'), dataIndex: 'createTime', key: 'createTime', width: 160,
      render: v => (
        <Space size={4}>
          <ClockCircleOutlined style={{ color: '#d1d5db', fontSize: 11 }} />
          <Text type="secondary" style={{ fontSize: 12 }}>{v?.slice(0, 16) ?? '—'}</Text>
        </Space>
      ),
    },
    {
      title: col(<SettingOutlined style={{ color: '#0891b2' }} />, '操作'), key: 'action', width: 240, fixed: 'right',
      render: (_, r) => (
        <Space size={[4, 4]} wrap>
          <PermGuard code="position:edit">
            <Button size="small" icon={<EditOutlined />}
              style={{ borderRadius: 6, color: '#fa8c16', borderColor: '#ffd591' }}
              onClick={() => openEdit(r)}>编辑</Button>
          </PermGuard>
          <PermGuard code="position:edit">
            <Button size="small" icon={<SettingOutlined />}
              style={{ borderRadius: 6, color: '#6366f1', borderColor: '#c7d2fe' }}
              onClick={() => setPermTarget({
                type: 'position', id: r.id, name: r.name,
                deptName: depts.find(d => d.id === r.deptId)?.name,
              })}>权限</Button>
          </PermGuard>
          <PermGuard code="position:toggle">
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
          <PermGuard code="position:delete">
            <Popconfirm title="确认删除该岗位？" onConfirm={() => handleDelete(r.id)} okText="删除" cancelText="取消" okButtonProps={{ danger: true }}>
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
          <div style={{ width: 34, height: 34, borderRadius: 10, background: PAGE_GRADIENT, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 4px 12px rgba(8,145,178,0.35)', flexShrink: 0 }}>
            <SolutionOutlined style={{ color: '#fff', fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1e293b', lineHeight: 1.2 }}>职位管理</div>
            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>管理商户职位体系 · 分配权限范围</div>
          </div>
          <Divider type="vertical" style={{ height: 20, margin: '0 4px', borderColor: '#bae6fd' }} />
          <div style={{ display: 'flex', gap: 8 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: 'rgba(14,165,233,0.1)', border: '1px solid rgba(14,165,233,0.25)' }}>
              <span>💼</span>
              <span style={{ fontSize: 12, color: '#6b7280' }}>职位</span>
              <span style={{ fontSize: 13, fontWeight: 700, color: '#0891b2' }}>{data.length}</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: 'rgba(14,165,233,0.1)', border: '1px solid rgba(14,165,233,0.25)' }}>
              <span>✅</span>
              <span style={{ fontSize: 12, color: '#6b7280' }}>启用</span>
              <span style={{ fontSize: 13, fontWeight: 700, color: '#0891b2' }}>{enabledCount}</span>
            </div>
          </div>
          <div style={{ flex: 1 }} />
          <PermGuard code="position:add">
            <Button type="primary" icon={<PlusOutlined />} style={{ borderRadius: 8, background: 'linear-gradient(135deg,#0891b2,#0ea5e9)', border: 'none' }} onClick={openAdd}>新增职位</Button>
          </PermGuard>
        </div>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', padding: '10px 24px 12px' }}>
          <div style={{ flex: 1 }} />
          <Tooltip title="刷新"><Button icon={<ReloadOutlined />} size="middle" loading={loading} style={{ borderRadius: 8, color: '#0891b2', borderColor: '#bae6fd' }} onClick={loadData} /></Tooltip>
        </div>
      </div>
      <div style={{ marginLeft: -24, marginRight: -24, marginBottom: -24, background: '#fff', borderTop: '1px solid #eef0f8' }}>
        <Table
          rowKey="id"
          columns={columns}
          dataSource={data}
          loading={loading}
          pagination={false}
          components={styledTableComponents}
          scroll={{ x: 'max-content', y: 'calc(100vh - 272px)' }}
          size="middle"
          rowClassName={() => 'table-row-hover'}
        />
      </div>

      {/* 新增/编辑 Modal */}
      <Modal
        title={
          <div style={{
            background: 'linear-gradient(135deg,#f093fb,#f5576c)',
            margin: '-20px -24px 20px',
            padding: '18px 24px',
            borderRadius: '8px 8px 0 0',
            display: 'flex', alignItems: 'center', gap: 12,
          }}>
            <div style={{ width: 40, height: 40, borderRadius: 10, background: 'rgba(255,255,255,0.2)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <ApartmentOutlined style={{ color: '#fff', fontSize: 20 }} />
            </div>
            <div>
              <div style={{ color: '#fff', fontWeight: 800, fontSize: 16 }}>{editing ? '编辑职位' : '新增职位'}</div>
              <div style={{ color: 'rgba(255,255,255,0.82)', fontSize: 12, marginTop: 2 }}>
                {editing ? '更新职位信息，完善职责定义' : '💼 新增职位，明确职责分工！'}
              </div>
            </div>
          </div>
        }
        open={modalOpen}
        onCancel={() => setModalOpen(false)}
        onOk={handleSubmit}
        okText={editing ? '保存修改' : '确认新增'}
        cancelText="取消"
        okButtonProps={{ style: { background: 'linear-gradient(135deg,#f093fb,#f5576c)', border: 'none', borderRadius: 8 } }}
        cancelButtonProps={{ style: { borderRadius: 8 } }}
        width={880}
        styles={{ body: { maxHeight: 'calc(85vh - 160px)', overflowY: 'auto', overflowX: 'hidden' } }}
      >
        <Form form={form} layout="vertical">
          <Row gutter={16}>
            <Col span={8}>
              <Form.Item name="deptId" label={<Space size={4}><ApartmentOutlined style={{ color: '#667eea' }} /><span>所属部门</span></Space>}>
                <Select allowClear placeholder="选择归属部门"
                  options={depts.map(d => ({ value: d.id, label: d.name }))} />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="name" label={<Space size={4}><ApartmentOutlined style={{ color: '#f093fb' }} /><span>职位名称</span></Space>}
                rules={[{ required: true, message: '请输入职位名称' }]}>
                <Input prefix={<ApartmentOutlined style={{ color: '#f093fb' }} />} placeholder="如：前台经理" />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="code" label={<Space size={4}><TagOutlined style={{ color: '#f5576c' }} /><span>职位编码</span></Space>} rules={[
                { required: true, message: '请输入职位编码' },
                { pattern: /^[A-Z][A-Z0-9_]{1,29}$/, message: '大写字母开头，仅含大写字母/数字/下划线，2-30位' },
              ]}>
                <Input prefix={<TagOutlined style={{ color: '#f5576c' }} />} placeholder="如：FRONT_MANAGER" />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="level" label={<Space size={4}><CrownOutlined style={{ color: '#f59e0b' }} /><span>职位级别</span></Space>}>
                <Select allowClear placeholder="选择职位级别">
                  <Option value="P1">P1 — 初级</Option>
                  <Option value="P2">P2 — 中级</Option>
                  <Option value="P3">P3 — 高级</Option>
                  <Option value="P4">P4 — 资深</Option>
                  <Option value="P5">P5 — 专家</Option>
                  <Option value="M1">M1 — 主管</Option>
                  <Option value="M2">M2 — 经理</Option>
                  <Option value="M3">M3 — 总监</Option>
                  <Option value="M4">M4 — 副总裁</Option>
                  <Option value="M5">M5 — 总裁/CEO</Option>
                </Select>
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="sort" label={<Space size={4}><SortAscendingOutlined style={{ color: '#6366f1' }} /><span>排序</span></Space>}>
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
              <Form.Item name="remark" label={<Space size={4}><FileTextOutlined style={{ color: '#6b7280' }} /><span>职位职责描述</span></Space>}>
                <RichTextInput placeholder="请描述该职位的主要职责、工作范围、任职要求等，便于员工了解岗位定位..." minHeight={140} />
              </Form.Item>
            </Col>
            <Col span={24}>
              <Form.Item
                name="fullAccess"
                valuePropName="checked"
                label={
                  <Space>
                    <CrownOutlined style={{ color: '#f59e0b' }} />
                    <span>全量权限</span>
                    <Tooltip title="开启后该职位将自动拥有商户所有菜单权限（适用于总裁、董事长等高层职位），无需单独分配菜单">
                      <ThunderboltOutlined style={{ color: '#6366f1', cursor: 'pointer' }} />
                    </Tooltip>
                  </Space>
                }
              >
                <Switch
                  checkedChildren={<><CrownOutlined /> 全量权限</>}
                  unCheckedChildren="按分配"
                />
              </Form.Item>
              <div style={{
                background: 'linear-gradient(135deg,#fef3c7,#fde68a)',
                border: '1px solid #f59e0b',
                borderRadius: 8,
                padding: '8px 12px',
                marginTop: -8,
                marginBottom: 16,
                fontSize: 12,
                color: '#92400e',
              }}>
                <CrownOutlined style={{ marginRight: 6 }} />
                开启全量权限后，该职位下的所有员工将自动获得商户全部菜单访问权限，常用于<strong>总裁、董事长、CEO</strong>等高层职位。
              </div>
            </Col>
          </Row>
        </Form>
      </Modal>

      <PermDrawer target={permTarget} onClose={() => setPermTarget(null)} />
    </div>
  )
}
