import { useState, useEffect, useMemo } from 'react'
import {
  Table, Button, Space, Tag, Typography, Modal,
  Form, Input, message, Drawer, Spin, Row, Col, Popconfirm, Tree, Badge, Divider,
} from 'antd'
import type { ColumnsType } from 'antd/es/table'
import type { DataNode } from 'antd/es/tree'
import type { Key } from 'react'
import {
  KeyOutlined, PlusOutlined, EditOutlined, DeleteOutlined,
  SafetyOutlined, FolderOutlined, AppstoreOutlined, ThunderboltOutlined,
  SearchOutlined, CheckSquareOutlined, MinusSquareOutlined, ReloadOutlined,
  LockOutlined, ApiOutlined, MenuOutlined, FolderOpenOutlined,
  UserSwitchOutlined, CodeOutlined, FileTextOutlined, ClockCircleOutlined, SettingOutlined,
} from '@ant-design/icons'
import { roleApi, permissionApi, type RoleVO, type PermissionVO } from '../../api/api'
import request from '../../api/request'
import RichTextInput from '../../components/common/RichTextInput'
import PermGuard from '../../components/common/PermGuard'
import { col, styledTableComponents } from '../../components/common/tableComponents'
import { useTableBodyHeight } from '../../hooks/useTableBodyHeight'
import PagePagination from '../../components/common/PagePagination'

const { Text } = Typography

const ROLE_HEADER_GRADIENT = 'linear-gradient(135deg,#7c3aed,#a78bfa)'

// ── 节点类型配置 ─────────────────────────────────────────────────────────────
const TYPE_CFG = {
  1: { label: '目录', color: '#6366f1', bg: 'rgba(99,102,241,0.1)',  icon: <FolderOutlined />,      gradient: 'linear-gradient(135deg,#667eea,#764ba2)' },
  2: { label: '菜单', color: '#0ea5e9', bg: 'rgba(14,165,233,0.08)', icon: <AppstoreOutlined />,    gradient: 'linear-gradient(135deg,#4facfe,#00f2fe)' },
  3: { label: '操作', color: '#f59e0b', bg: 'rgba(245,158,11,0.08)', icon: <ThunderboltOutlined />, gradient: 'linear-gradient(135deg,#f093fb,#f5576c)' },
} as const

/** 收集树中所有节点 key */
function collectAllKeys(nodes: PermissionVO[]): string[] {
  return nodes.flatMap(n => [
    String(n.id),
    ...(n.children?.length ? collectAllKeys(n.children) : []),
  ])
}

/** 根据关键字过滤权限树（保留命中节点及其祖先） */
function filterPermTree(nodes: PermissionVO[], kw: string): PermissionVO[] {
  if (!kw) return nodes
  const lk = kw.toLowerCase()
  const match = (n: PermissionVO): PermissionVO | null => {
    const children = n.children?.length ? filterPermTree(n.children, kw) : []
    const self = [n.name, n.code, n.path].some(v => v?.toLowerCase().includes(lk))
    return (self || children.length) ? { ...n, children } : null
  }
  return nodes.map(match).filter(Boolean) as PermissionVO[]
}

/** 将 PermissionVO 树转换为 antd Tree 所需的 DataNode 格式 */
function buildTreeData(nodes: PermissionVO[]): DataNode[] {
  return nodes.map(n => {
    const cfg = TYPE_CFG[n.type as 1 | 2 | 3] ?? TYPE_CFG[2]
    return {
      key: String(n.id),
      icon: ({ expanded }: { expanded: boolean }) =>
        n.type === 1 ? (expanded ? <FolderOpenOutlined style={{ color: cfg.color }} /> : <FolderOutlined style={{ color: cfg.color }} />) : cfg.icon,
      title: (
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
          <Tag
            style={{
              background: cfg.bg, border: `1px solid ${cfg.color}30`,
              color: cfg.color, fontSize: 10, padding: '0 5px', borderRadius: 4,
              lineHeight: '16px', margin: 0,
            }}
          >{cfg.label}</Tag>
          <span style={{ fontSize: 13, fontWeight: n.type === 1 ? 600 : 400 }}>{n.name}</span>
          {n.code && (
            <code style={{
              fontSize: 10, color: '#94a3b8', background: '#f8fafc',
              padding: '0 4px', borderRadius: 3, border: '1px solid #e2e8f0',
            }}>{n.code}</code>
          )}
        </div>
      ),
      children: n.children?.length ? buildTreeData(n.children) : undefined,
    }
  })
}

export default function RoleListPage() {
  const { ref, height: tableBodyH } = useTableBodyHeight(46)
  const [list, setList]               = useState<RoleVO[]>([])
  const [page, setPage]               = useState(1)
  const [pageSize, setPageSize]       = useState(20)
  const [loading, setLoading]         = useState(false)
  const [modalOpen, setModalOpen]     = useState(false)
  const [editing, setEditing]         = useState<RoleVO | null>(null)
  const [drawerOpen, setDrawerOpen]   = useState(false)
  const [activeRole, setActiveRole]   = useState<RoleVO | null>(null)

  // 权限树数据（保留原始树结构）
  const [permTree, setPermTree]       = useState<PermissionVO[]>([])
  // 勾选的节点 ID（完全勾选 + 半选父节点，用于保存）
  const [checkedKeys, setCheckedKeys] = useState<string[]>([])
  // 半选节点（父节点部分选中），仅影响保存时是否包含父节点 ID
  const [halfKeys, setHalfKeys]       = useState<string[]>([])

  const [assignLoading, setAssignLoading] = useState(false)
  const [permSearch, setPermSearch]   = useState('')
  const [form] = Form.useForm()

  useEffect(() => { fetchList() }, [])

  const fetchList = async () => {
    setLoading(true)
    try {
      const res = await roleApi.list()
      setList(res.data?.data ?? [])
    } finally { setLoading(false) }
  }

  const openAdd = () => { setEditing(null); form.resetFields(); setModalOpen(true) }
  const openEdit = (row: RoleVO) => {
    setEditing(row)
    form.setFieldsValue({ roleName: row.roleName, roleCode: row.roleCode, remark: row.remark })
    setModalOpen(true)
  }

  const handleSubmit = async () => {
    const values = await form.validateFields()
    try {
      if (editing) {
        await roleApi.edit({ id: editing.id, ...values })
        message.success('修改成功')
      } else {
        await roleApi.add(values)
        message.success('添加成功')
      }
      setModalOpen(false)
      fetchList()
    } catch { /* 拦截器已处理 */ }
  }

  const handleDelete = async (id: number) => {
    await roleApi.delete(id)
    message.success('已删除')
    fetchList()
  }

  const openPermDrawer = async (role: RoleVO) => {
    setActiveRole(role)
    setDrawerOpen(true)
    setPermSearch('')
    setAssignLoading(true)
    try {
      const [treeRes, assignedRes] = await Promise.all([
        permissionApi.tree(),
        request.get<any>(`/admin/role/${role.id}/permissions`),
      ])
      setPermTree(treeRes.data?.data ?? [])
      const assigned: string[] = (assignedRes.data?.data ?? []).map((id: number) => String(id))
      setCheckedKeys(assigned)
      setHalfKeys([])
    } finally { setAssignLoading(false) }
  }

  const handleAssign = async () => {
    if (!activeRole) return
    setAssignLoading(true)
    try {
      // 提交完全勾选 + 半选父节点，确保父级菜单 ID 也被保存
      const allIds = [...new Set([...checkedKeys, ...halfKeys])].join(',')
      await request.post(`/admin/role/${activeRole.id}/permissions`, {
        permissionIds: allIds,
      })
      message.success('权限分配成功')
      setDrawerOpen(false)
    } finally { setAssignLoading(false) }
  }

  // ── 统计 ─────────────────────────────────────────────────────────────────
  const allKeys = useMemo(() => collectAllKeys(permTree), [permTree])
  const filteredTree = useMemo(() => filterPermTree(permTree, permSearch), [permTree, permSearch])
  const treeData     = useMemo(() => buildTreeData(filteredTree), [filteredTree])

  const typeCounts = useMemo(() => {
    const count = { dirs: 0, menus: 0, ops: 0 }
    const walk = (nodes: PermissionVO[]) => {
      for (const n of nodes) {
        if (n.type === 1) count.dirs++
        else if (n.type === 2) count.menus++
        else count.ops++
        if (n.children?.length) walk(n.children)
      }
    }
    walk(permTree)
    return count
  }, [permTree])

  // ── 列定义 ──────────────────────────────────────────────────────────────
  const columns: ColumnsType<RoleVO> = [
    {
      title: col(<UserSwitchOutlined style={{ color: '#a855f7' }} />, '角色名称'),
      dataIndex: 'roleName', key: 'roleName',
      render: (v: string) => <Text strong>{v}</Text>,
    },
    {
      title: col(<CodeOutlined style={{ color: '#94a3b8' }} />, '角色编码'),
      dataIndex: 'roleCode', key: 'roleCode',
      render: (v: string) => (
        <Tag color={v === 'SUPER_ADMIN' ? 'gold' : 'blue'}
          icon={v === 'SUPER_ADMIN' ? <LockOutlined /> : <KeyOutlined />}>
          {v}
        </Tag>
      ),
    },
    {
      title: col(<FileTextOutlined style={{ color: '#94a3b8' }} />, '备注'),
      dataIndex: 'remark', key: 'remark',
      render: (v: string) => v || <Text type="secondary">—</Text>,
    },
    {
      title: col(<ClockCircleOutlined style={{ color: '#94a3b8' }} />, '创建时间'),
      dataIndex: 'createTime', key: 'createTime',
      render: (v: string) => v?.slice(0, 10),
    },
    {
      title: col(<SettingOutlined style={{ color: '#94a3b8' }} />, '操作'),
      key: 'action', width: 235,
      render: (_: any, row: RoleVO) => (
        <Space size={4}>
          <PermGuard code="role:permission">
            <Button size="small" type="primary" ghost icon={<SafetyOutlined />}
              style={{ borderRadius: 6 }}
              onClick={() => openPermDrawer(row)}>分配权限</Button>
          </PermGuard>
          <PermGuard code="role:edit">
            <Button size="small" icon={<EditOutlined />}
              style={{ borderRadius: 6, color: '#fa8c16', borderColor: '#ffd591' }}
              onClick={() => openEdit(row)}>编辑</Button>
          </PermGuard>
          {row.roleCode !== 'SUPER_ADMIN' && (
            <PermGuard code="role:delete">
              <Popconfirm title="确认删除该角色？" onConfirm={() => handleDelete(row.id)}
                okText="删除" cancelText="取消" okButtonProps={{ danger: true }}>
                <Button size="small" danger icon={<DeleteOutlined />} style={{ borderRadius: 6 }}>删除</Button>
              </Popconfirm>
            </PermGuard>
          )}
        </Space>
      ),
    },
  ]

  return (
    <div style={{ marginTop: -24 }}>
      <div style={{ position: 'sticky', top: 64, zIndex: 88, marginLeft: -24, marginRight: -24, background: 'rgba(255,255,255,0.97)', backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)', borderBottom: '1px solid rgba(0,0,0,0.07)', boxShadow: '0 4px 20px rgba(0,0,0,0.06)' }}>
        <div style={{ display: 'flex', alignItems: 'center', padding: '10px 24px 12px', gap: 12 }}>
          <div style={{ width: 34, height: 34, borderRadius: 10, background: ROLE_HEADER_GRADIENT, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 4px 12px rgba(124,58,237,0.35)', flexShrink: 0 }}>
            <KeyOutlined style={{ color: '#fff', fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1e293b', lineHeight: 1.2 }}>角色管理</div>
            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>管理系统角色 · 分配权限树</div>
          </div>
          <Divider type="vertical" style={{ height: 20, margin: '0 4px', borderColor: '#ede9fe' }} />
          <div style={{ display: 'flex', gap: 8 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: 'rgba(124,58,237,0.1)', border: '1px solid rgba(124,58,237,0.25)' }}>
              <span style={{ fontSize: 13 }}>🔑</span>
              <span style={{ fontSize: 12, color: '#6b7280' }}>角色总数</span>
              <span style={{ fontSize: 13, fontWeight: 700, color: '#7c3aed' }}>{list.length}</span>
            </div>
          </div>
          <div style={{ flex: 1 }} />
          <PermGuard code="role:add">
            <Button type="primary" icon={<PlusOutlined />} onClick={openAdd}
              style={{ borderRadius: 8, background: ROLE_HEADER_GRADIENT, border: 'none' }}>
              新增角色
            </Button>
          </PermGuard>
        </div>
      </div>

      <div ref={ref} style={{ marginLeft: -24, marginRight: -24, marginBottom: -24, background: '#fff', borderTop: '1px solid #eef0f8' }}>
        <Table
          rowKey="id"
          loading={loading}
          columns={columns}
          dataSource={list.slice((page - 1) * pageSize, page * pageSize)}
          pagination={false}
          size="middle"
          components={styledTableComponents}
          scroll={{ x: 'max-content', y: tableBodyH }}
        />
        <PagePagination
          total={list.length}
          current={page}
          pageSize={pageSize}
          onChange={setPage}
          onSizeChange={s => { setPageSize(s); setPage(1) }}
          countLabel="个角色"
        />
      </div>

      {/* 新增/编辑角色 */}
      <Modal
        title={
          <div style={{
            background: 'linear-gradient(135deg,#7c3aed,#4f46e5)',
            margin: '-20px -24px 20px',
            padding: '18px 24px',
            borderRadius: '8px 8px 0 0',
            display: 'flex', alignItems: 'center', gap: 12,
          }}>
            <div style={{
              width: 40, height: 40, borderRadius: 10,
              background: 'rgba(255,255,255,0.2)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <SafetyOutlined style={{ color: '#fff', fontSize: 20 }} />
            </div>
            <div>
              <div style={{ color: '#fff', fontWeight: 800, fontSize: 16 }}>
                {editing ? '编辑角色' : '新增角色'}
              </div>
              <div style={{ color: 'rgba(255,255,255,0.82)', fontSize: 12, marginTop: 2 }}>
                {editing ? '更新角色权限，精细化管控系统访问' : '🔑 设定职责权限，构建高效管理体系！'}
              </div>
            </div>
          </div>
        }
        open={modalOpen}
        onCancel={() => setModalOpen(false)}
        onOk={handleSubmit}
        okText="确认"
        cancelText="取消"
        okButtonProps={{ style: { background: 'linear-gradient(135deg,#7c3aed,#4f46e5)', border: 'none', borderRadius: 8 } }}
        cancelButtonProps={{ style: { borderRadius: 8 } }}
        width={880}
        styles={{ body: { maxHeight: 'calc(85vh - 150px)', overflowY: 'auto', overflowX: 'hidden' } }}
      >
        <Form form={form} layout="vertical">
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="roleName" label="角色名称" rules={[{ required: true, message: '请输入角色名称' }]}>
                <Input prefix={<SafetyOutlined style={{ color: '#7c3aed' }} />} placeholder="如：运营人员" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="roleCode" label="角色编码"
                rules={[
                  { required: true, message: '请输入角色编码（大写字母+下划线）' },
                  { pattern: /^[A-Z_]+$/, message: '仅支持大写字母和下划线' },
                ]}>
                <Input prefix={<KeyOutlined style={{ color: '#4f46e5' }} />} placeholder="如：OPERATOR" />
              </Form.Item>
            </Col>
          </Row>
          <Form.Item name="remark" label="备注">
            <RichTextInput placeholder="角色职责描述，如：负责日常订单处理、会员服务管理等..." minHeight={120} />
          </Form.Item>
        </Form>
      </Modal>

      {/* ── 分配权限抽屉 ── */}
      <Drawer
        title={
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{
              width: 36, height: 36, borderRadius: 10,
              background: 'linear-gradient(135deg,#667eea,#764ba2)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              flexShrink: 0,
            }}>
              <SafetyOutlined style={{ color: '#fff', fontSize: 16 }} />
            </div>
            <div>
              <div style={{ fontWeight: 700, fontSize: 15 }}>
                分配权限
                {activeRole && (
                  <Tag color={activeRole.roleCode === 'SUPER_ADMIN' ? 'gold' : 'blue'} style={{ marginLeft: 8 }}>
                    {activeRole.roleName}
                  </Tag>
                )}
              </div>
              <div style={{ fontSize: 12, color: '#94a3b8', fontWeight: 400 }}>
                勾选需要授予该角色的菜单与操作权限
              </div>
            </div>
          </div>
        }
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        width={680}
        footer={
          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 12 }}>
            <Button onClick={() => setDrawerOpen(false)} style={{ borderRadius: 8 }}>取消</Button>
            <Button
              type="primary" loading={assignLoading} onClick={handleAssign}
              style={{
                background: 'linear-gradient(135deg,#667eea,#764ba2)',
                border: 'none', borderRadius: 8,
                boxShadow: '0 4px 12px rgba(102,126,234,0.35)',
              }}
            >
              保存权限配置
            </Button>
          </div>
        }
        styles={{ footer: { padding: '14px 24px', borderTop: '1px solid #f0f0f0' } }}
      >
        {assignLoading ? (
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '80px 0', gap: 16 }}>
            <Spin size="large" />
            <Text type="secondary">加载权限数据中…</Text>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 14, height: '100%' }}>

            {/* ── 统计 + 快捷操作 ── */}
            <div style={{
              display: 'flex', alignItems: 'center', gap: 10,
              background: 'linear-gradient(135deg,rgba(99,102,241,0.04),rgba(14,165,233,0.03))',
              border: '1px solid rgba(99,102,241,0.12)',
              borderRadius: 12, padding: '10px 16px',
            }}>
              {/* 类型统计 */}
              <div style={{ display: 'flex', gap: 8, flex: 1 }}>
                {[
                  { label: '目录', count: typeCounts.dirs,  color: '#6366f1', icon: <FolderOutlined /> },
                  { label: '菜单', count: typeCounts.menus, color: '#0ea5e9', icon: <MenuOutlined /> },
                  { label: '操作', count: typeCounts.ops,   color: '#f59e0b', icon: <ApiOutlined /> },
                ].map(item => (
                  <div key={item.label} style={{
                    display: 'flex', alignItems: 'center', gap: 4,
                    padding: '3px 10px', borderRadius: 8,
                    background: `${item.color}12`, border: `1px solid ${item.color}30`,
                  }}>
                    <span style={{ color: item.color, fontSize: 12 }}>{item.icon}</span>
                    <span style={{ color: item.color, fontSize: 12, fontWeight: 600 }}>{item.count}</span>
                    <span style={{ color: item.color, fontSize: 11 }}>{item.label}</span>
                  </div>
                ))}
              </div>

              <Divider type="vertical" style={{ height: 24, margin: 0 }} />

              {/* 已选计数 */}
              <Badge
                count={checkedKeys.length}
                overflowCount={999}
                style={{ background: 'linear-gradient(135deg,#667eea,#764ba2)' }}
              >
                <div style={{
                  padding: '3px 12px', borderRadius: 8, fontSize: 12,
                  background: 'rgba(99,102,241,0.08)', border: '1px solid rgba(99,102,241,0.2)',
                  color: '#6366f1', fontWeight: 600, cursor: 'default',
                  display: 'flex', alignItems: 'center', gap: 4,
                }}>
                  <CheckSquareOutlined />已选
                </div>
              </Badge>

              {/* 全选 / 清空 */}
              <Button
                size="small" type="text"
                icon={<CheckSquareOutlined />}
                style={{ color: '#6366f1', borderRadius: 6, fontSize: 12 }}
                onClick={() => { setCheckedKeys(allKeys); setHalfKeys([]) }}
              >全选</Button>
              <Button
                size="small" type="text"
                icon={<MinusSquareOutlined />}
                style={{ color: '#ef4444', borderRadius: 6, fontSize: 12 }}
                onClick={() => { setCheckedKeys([]); setHalfKeys([]) }}
              >清空</Button>
              <Button
                size="small" type="text"
                icon={<ReloadOutlined />}
                style={{ color: '#64748b', borderRadius: 6, fontSize: 12 }}
                onClick={() => openPermDrawer(activeRole!)}
              >重置</Button>
            </div>

            {/* ── 搜索 ── */}
            <Input
              placeholder="搜索权限名称 / 权限码…"
              prefix={<SearchOutlined style={{ color: '#cbd5e1' }} />}
              value={permSearch}
              onChange={e => setPermSearch(e.target.value)}
              allowClear
              style={{ borderRadius: 10 }}
            />

            {/* ── 图例 ── */}
            <div style={{ display: 'flex', gap: 16, padding: '4px 0' }}>
              {Object.entries(TYPE_CFG).map(([k, cfg]) => (
                <div key={k} style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
                  <div style={{
                    width: 18, height: 18, borderRadius: 4, background: cfg.gradient,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    fontSize: 9, color: '#fff',
                  }}>{cfg.icon}</div>
                  <Text style={{ fontSize: 11, color: '#64748b' }}>{cfg.label}</Text>
                </div>
              ))}
              <Text style={{ fontSize: 11, color: '#cbd5e1' }}>— 勾选父节点可一键选中所有子权限</Text>
            </div>

            {/* ── 权限树 ── */}
            <div style={{
              flex: 1,
              border: '1px solid #f0f4ff',
              borderRadius: 12,
              padding: '8px 4px',
              overflowY: 'auto',
              maxHeight: 'calc(100vh - 360px)',
              background: '#fafbff',
            }}>
              <style>{`
                .perm-assign-tree .ant-tree-node-content-wrapper { border-radius: 6px; padding: 2px 6px; }
                .perm-assign-tree .ant-tree-node-content-wrapper:hover { background: rgba(99,102,241,0.06) !important; }
                .perm-assign-tree .ant-tree-node-selected { background: rgba(99,102,241,0.1) !important; }
                .perm-assign-tree .ant-tree-treenode { padding-bottom: 2px; }
                .perm-assign-tree .ant-tree-switcher { color: #94a3b8; }
              `}</style>
              {treeData.length === 0 ? (
                <div style={{ textAlign: 'center', padding: '40px 0', color: '#94a3b8' }}>
                  {permSearch ? `未找到「${permSearch}」相关权限` : '暂无权限数据'}
                </div>
              ) : (
                <Tree
                  className="perm-assign-tree"
                  checkable
                  showIcon
                  defaultExpandAll
                  checkedKeys={checkedKeys}
                  onCheck={(checkedKeysValue, info) => {
                    const keys = Array.isArray(checkedKeysValue)
                      ? checkedKeysValue as string[]
                      : (checkedKeysValue as { checked: Key[] }).checked.map(String)
                    const half = (info.halfCheckedKeys ?? []).map(String)
                    setCheckedKeys(keys)
                    setHalfKeys(half)
                  }}
                  treeData={treeData}
                  style={{ background: 'transparent' }}
                />
              )}
            </div>
          </div>
        )}
      </Drawer>
    </div>
  )
}
