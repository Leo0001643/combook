/**
 * 权限配置页 — 三级可视化树形设计
 *
 * 层级结构：目录（紫）→ 菜单（蓝）→ 操作（橙）
 * 每一层在视觉上完全隔离，层次一目了然。
 */
import { useState, useEffect, useMemo, useRef } from 'react'
import { useTableBodyHeight } from '../../hooks/useTableBodyHeight'
import {
  Button, Space, Tag, Typography,
  Form, Input, InputNumber, message, Tooltip, Switch,
  Drawer, Segmented, Badge, Divider, Empty, Spin,
  Popconfirm, Collapse,
} from 'antd'
import {
  PlusOutlined, EditOutlined, DeleteOutlined,
  FolderOutlined, AppstoreOutlined, ThunderboltOutlined,
  ShopOutlined, DesktopOutlined, SearchOutlined, ReloadOutlined,
  CodeOutlined, LinkOutlined, SortAscendingOutlined,
  ApiOutlined, MenuOutlined, LockOutlined,
  EyeOutlined, EyeInvisibleOutlined, CheckCircleOutlined,
  FolderOpenOutlined, TagOutlined,
  RightOutlined,
  // ── 菜单节点实际使用的图标（按需引入）──────────────────────────────────
  DashboardOutlined, UserOutlined, TeamOutlined, OrderedListOutlined,
  DollarOutlined, TagsOutlined, SettingOutlined, CarOutlined,
  PictureOutlined, KeyOutlined, AuditOutlined, IdcardOutlined,
  BankOutlined, ApartmentOutlined, StarOutlined, SolutionOutlined,
  RocketOutlined, SoundOutlined, BellOutlined, SafetyOutlined,
  BookOutlined, NotificationOutlined, DatabaseOutlined, ClockCircleOutlined,
  FileTextOutlined, GiftOutlined, HomeOutlined, ReadOutlined,
  MessageOutlined, PhoneOutlined, CameraOutlined, CrownOutlined,
  FireOutlined, GlobalOutlined, HeartOutlined, ShoppingOutlined,
  TrophyOutlined, WalletOutlined, DeploymentUnitOutlined,
} from '@ant-design/icons'
import type React from 'react'
import { permissionApi, type PermissionVO } from '../../api/api'
import PermGuard from '../../components/common/PermGuard'

const { Text } = Typography

// ── 图标映射 ──────────────────────────────────────────────────────────────────
const ICON_MAP: Record<string, React.ReactNode> = {
  DashboardOutlined:    <DashboardOutlined />,
  UserOutlined:         <UserOutlined />,
  TeamOutlined:         <TeamOutlined />,
  ShopOutlined:         <ShopOutlined />,
  OrderedListOutlined:  <OrderedListOutlined />,
  DollarOutlined:       <DollarOutlined />,
  TagsOutlined:         <TagsOutlined />,
  SettingOutlined:      <SettingOutlined />,
  CarOutlined:          <CarOutlined />,
  PictureOutlined:      <PictureOutlined />,
  AppstoreOutlined:     <AppstoreOutlined />,
  KeyOutlined:          <KeyOutlined />,
  AuditOutlined:        <AuditOutlined />,
  IdcardOutlined:       <IdcardOutlined />,
  BankOutlined:         <BankOutlined />,
  LockOutlined:         <LockOutlined />,
  ApartmentOutlined:    <ApartmentOutlined />,
  StarOutlined:         <StarOutlined />,
  SolutionOutlined:     <SolutionOutlined />,
  RocketOutlined:       <RocketOutlined />,
  SoundOutlined:        <SoundOutlined />,
  BellOutlined:         <BellOutlined />,
  SafetyOutlined:       <SafetyOutlined />,
  BookOutlined:         <BookOutlined />,
  MenuOutlined:         <MenuOutlined />,
  NotificationOutlined: <NotificationOutlined />,
  DatabaseOutlined:     <DatabaseOutlined />,
  ClockCircleOutlined:  <ClockCircleOutlined />,
  FileTextOutlined:     <FileTextOutlined />,
  ApiOutlined:          <ApiOutlined />,
  GiftOutlined:         <GiftOutlined />,
  HomeOutlined:         <HomeOutlined />,
  ReadOutlined:         <ReadOutlined />,
  MessageOutlined:      <MessageOutlined />,
  PhoneOutlined:        <PhoneOutlined />,
  CameraOutlined:       <CameraOutlined />,
  CrownOutlined:        <CrownOutlined />,
  FireOutlined:         <FireOutlined />,
  GlobalOutlined:       <GlobalOutlined />,
  HeartOutlined:        <HeartOutlined />,
  ShoppingOutlined:     <ShoppingOutlined />,
  TrophyOutlined:       <TrophyOutlined />,
  WalletOutlined:       <WalletOutlined />,
  DeploymentUnitOutlined: <DeploymentUnitOutlined />,
  CodeOutlined:         <CodeOutlined />,
  FolderOutlined:       <FolderOutlined />,
  ThunderboltOutlined:  <ThunderboltOutlined />,
}

// ── 节点类型配置 ──────────────────────────────────────────────────────────────
const NODE_CFG = {
  1: {
    label: '目录',
    icon: (open?: boolean) => open ? <FolderOpenOutlined /> : <FolderOutlined />,
    gradient: 'linear-gradient(135deg,#667eea,#764ba2)',
    color: '#6366f1', bg: 'rgba(99,102,241,0.07)', border: 'rgba(99,102,241,0.18)',
    lightBg: '#f5f3ff',
  },
  2: {
    label: '菜单',
    icon: () => <AppstoreOutlined />,
    gradient: 'linear-gradient(135deg,#4facfe,#00f2fe)',
    color: '#0ea5e9', bg: 'rgba(14,165,233,0.06)', border: 'rgba(14,165,233,0.18)',
    lightBg: '#f0f9ff',
  },
  3: {
    label: '操作',
    icon: () => <ThunderboltOutlined />,
    gradient: 'linear-gradient(135deg,#f6d365,#fda085)',
    color: '#f59e0b', bg: 'rgba(245,158,11,0.07)', border: 'rgba(245,158,11,0.18)',
    lightBg: '#fffbeb',
  },
} as const
type NodeType = keyof typeof NODE_CFG
type Portal = 'admin' | 'merchant'

const ICON_SUGGESTIONS = [
  'DashboardOutlined','UserOutlined','TeamOutlined','ShopOutlined',
  'OrderedListOutlined','DollarOutlined','TagsOutlined','SettingOutlined',
  'CarOutlined','PictureOutlined','AppstoreOutlined','KeyOutlined',
  'AuditOutlined','IdcardOutlined','BankOutlined','LockOutlined',
  'ApartmentOutlined','StarOutlined','SolutionOutlined','RocketOutlined',
  'SoundOutlined','BellOutlined','SafetyOutlined','BookOutlined',
]

// ── 工具函数 ──────────────────────────────────────────────────────────────────
function countNodes(nodes: PermissionVO[]) {
  let dirs = 0, menus = 0, ops = 0
  const walk = (list: PermissionVO[]) => {
    for (const n of list) {
      if (n.type === 1) dirs++; else if (n.type === 2) menus++; else ops++
      if (n.children?.length) walk(n.children)
    }
  }
  walk(nodes)
  return { dirs, menus, ops, total: dirs + menus + ops }
}

function filterTree(nodes: PermissionVO[], kw: string): PermissionVO[] {
  if (!kw) return nodes
  const lk = kw.toLowerCase()
  const match = (n: PermissionVO): PermissionVO | null => {
    const children = n.children ? filterTree(n.children, kw) : []
    const self = [n.name, n.path, n.code].some(v => v?.toLowerCase().includes(lk))
    return (self || children.length) ? { ...n, children } : null
  }
  return nodes.map(match).filter(Boolean) as PermissionVO[]
}

function getNodeIcon(node: PermissionVO) {
  const cfg = NODE_CFG[node.type as NodeType] ?? NODE_CFG[2]
  return node.icon ? (ICON_MAP[node.icon] ?? cfg.icon()) : cfg.icon()
}

// ── 操作行（type=3）─────────────────────────────────────────────────────────

interface NodeActions {
  onAdd: (parent: PermissionVO) => void
  onEdit: (node: PermissionVO) => void
  onDelete: (node: PermissionVO) => void
  onToggle: (node: PermissionVO, field: 'visible' | 'status', val: boolean) => void
  togglingId: number | null
}

function OperationRow({ node, actions }: { node: PermissionVO; actions: NodeActions }) {
  const cfg = NODE_CFG[3]
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 10,
      padding: '7px 14px 7px 12px',
      borderBottom: '1px solid rgba(245,158,11,0.08)',
      background: 'transparent',
      transition: 'background 0.15s',
    }}
      onMouseEnter={e => (e.currentTarget.style.background = 'rgba(245,158,11,0.04)')}
      onMouseLeave={e => (e.currentTarget.style.background = 'transparent')}
    >
      {/* 连接线 */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 0, flexShrink: 0, marginLeft: 8 }}>
        <div style={{ width: 1, height: 20, background: 'rgba(245,158,11,0.3)' }} />
        <div style={{ width: 16, height: 1, background: 'rgba(245,158,11,0.3)' }} />
      </div>

      {/* 图标 */}
      <div style={{
        width: 24, height: 24, borderRadius: 6, flexShrink: 0,
        background: cfg.gradient,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 11, color: '#fff',
        boxShadow: `0 2px 6px ${cfg.color}30`,
      }}>
        {getNodeIcon(node)}
      </div>

      {/* 名称 */}
      <Text style={{ fontSize: 12, fontWeight: 500, color: '#78350f', flex: 0, whiteSpace: 'nowrap' }}>
        {node.name}
      </Text>

      {/* 权限码 */}
      {node.code && (
        <Text style={{ fontSize: 11, color: cfg.color, fontFamily: 'monospace', flex: 1 }}>
          <CodeOutlined style={{ marginRight: 3 }} />{node.code}
        </Text>
      )}

      <div style={{ flex: 1 }} />

      {/* 状态 */}
      <Tooltip title="已授权">
        <Switch
          size="small"
          checked={node.status !== 0}
          loading={actions.togglingId === node.id}
          onChange={val => actions.onToggle(node, 'status', val)}
          style={{ background: node.status !== 0 ? cfg.color : undefined }}
        />
      </Tooltip>

      {/* 操作 */}
      <Space size={4} style={{ flexShrink: 0 }}>
        <PermGuard code="permission:edit">
          <Button
            size="small" icon={<EditOutlined />}
            onClick={() => actions.onEdit(node)}
            style={{ borderRadius: 6, borderColor: '#fcd34d', color: '#d97706', fontSize: 11, height: 24 }}
          />
        </PermGuard>
        <PermGuard code="permission:delete">
          <Popconfirm
            title={`删除「${node.name}」`}
            description="操作权限删除后不可恢复"
            onConfirm={() => actions.onDelete(node)}
            okText="删除" okButtonProps={{ danger: true }}
            cancelText="取消"
          >
            <Button
              size="small" danger icon={<DeleteOutlined />}
              style={{ borderRadius: 6, fontSize: 11, height: 24 }}
            />
          </Popconfirm>
        </PermGuard>
      </Space>
    </div>
  )
}

// ── 菜单行（type=2）─────────────────────────────────────────────────────────

function MenuRow({ node, actions }: { node: PermissionVO; actions: NodeActions }) {
  const cfg = NODE_CFG[2]
  const ops    = (node.children ?? []).filter(c => c.type === 3)
  const nested = (node.children ?? []).filter(c => c.type !== 3)

  return (
    <div style={{
      background: '#fff',
      borderRadius: 10,
      border: `1px solid ${cfg.border}`,
      marginBottom: 8,
      overflow: 'hidden',
      boxShadow: '0 1px 4px rgba(14,165,233,0.06)',
    }}>
      {/* 菜单主行 */}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 10,
        padding: '10px 14px',
        background: cfg.bg,
        borderBottom: (ops.length || nested.length) ? `1px solid ${cfg.border}` : 'none',
      }}>
        {/* 左侧蓝色标 */}
        <div style={{ width: 3, height: 32, borderRadius: 2, background: cfg.gradient, flexShrink: 0 }} />

        {/* 图标 */}
        <div style={{
          width: 28, height: 28, borderRadius: 8, flexShrink: 0,
          background: cfg.gradient,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 13, color: '#fff',
          boxShadow: `0 3px 8px ${cfg.color}40`,
        }}>
          {getNodeIcon(node)}
        </div>

        {/* 名称 + 路径 */}
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontWeight: 600, fontSize: 13, color: '#0c4a6e' }}>
            {node.name}
          </div>
          {node.path && (
            <Text style={{ fontSize: 11, color: '#94a3b8', fontFamily: 'monospace' }}>
              <LinkOutlined style={{ marginRight: 3 }} />{node.path}
            </Text>
          )}
        </div>

        {/* 类型标签 */}
        <Tag style={{
          background: cfg.bg, border: `1px solid ${cfg.border}`,
          color: cfg.color, fontSize: 10, borderRadius: 5, margin: 0,
        }}>菜单</Tag>

        {/* 操作权限计数 */}
        {ops.length > 0 && (
          <Tag color="gold" style={{ fontSize: 10, margin: 0 }}>
            <ThunderboltOutlined /> {ops.length} 操作
          </Tag>
        )}

        {/* 侧边栏开关 */}
        <Tooltip title="侧边栏显示">
          <Switch
            size="small"
            checked={node.visible === 1}
            loading={actions.togglingId === node.id}
            onChange={val => actions.onToggle(node, 'visible', val)}
            style={{ background: node.visible === 1 ? cfg.color : undefined }}
          />
        </Tooltip>

        {/* 授权开关 */}
        <Tooltip title="已授权">
          <Switch
            size="small"
            checked={node.status !== 0}
            loading={actions.togglingId === node.id}
            onChange={val => actions.onToggle(node, 'status', val)}
            style={{ background: node.status !== 0 ? '#10b981' : undefined }}
          />
        </Tooltip>

        {/* 操作按钮 */}
        <Space size={4} style={{ flexShrink: 0 }}>
          <PermGuard code="permission:add">
            <Button
              size="small" icon={<PlusOutlined />}
              onClick={() => actions.onAdd(node)}
              style={{ borderRadius: 6, borderColor: '#bae6fd', color: cfg.color, fontSize: 11, height: 24 }}
            >
              操作权限
            </Button>
          </PermGuard>
          <PermGuard code="permission:edit">
            <Button
              size="small" icon={<EditOutlined />}
              onClick={() => actions.onEdit(node)}
              style={{ borderRadius: 6, borderColor: '#fcd34d', color: '#d97706', fontSize: 11, height: 24 }}
            />
          </PermGuard>
          <PermGuard code="permission:delete">
            <Popconfirm
              title={`删除「${node.name}」`}
              description={(node.children?.length ?? 0) > 0
                ? `该菜单含 ${node.children!.length} 个子节点，将一并删除！` : '确认删除？操作不可恢复。'}
              onConfirm={() => actions.onDelete(node)}
              okText="删除" okButtonProps={{ danger: true }}
              cancelText="取消"
            >
              <Button size="small" danger icon={<DeleteOutlined />} style={{ borderRadius: 6, fontSize: 11, height: 24 }} />
            </Popconfirm>
          </PermGuard>
        </Space>
      </div>

      {/* 操作权限列表（type=3 children） */}
      {ops.length > 0 && (
        <div style={{ background: '#fffdf7' }}>
          <div style={{
            padding: '5px 14px',
            fontSize: 10, color: '#d97706', fontWeight: 600, letterSpacing: '0.05em',
            borderBottom: '1px dashed rgba(245,158,11,0.2)',
            display: 'flex', alignItems: 'center', gap: 4,
          }}>
            <ThunderboltOutlined /> 操作权限
          </div>
          {ops.map(op => (
            <OperationRow key={op.id} node={op} actions={actions} />
          ))}
        </div>
      )}

      {/* 嵌套子菜单（罕见，递归处理） */}
      {nested.length > 0 && (
        <div style={{ padding: '8px 14px', background: '#f8faff' }}>
          {nested.map(child => (
            <MenuRow key={child.id} node={child} actions={actions} />
          ))}
        </div>
      )}
    </div>
  )
}

// ── 目录面板（type=1）───────────────────────────────────────────────────────

function DirectoryPanel({ node, actions }: { node: PermissionVO; actions: NodeActions }) {
  const cfg      = NODE_CFG[1]
  const children = node.children ?? []
  const menuCount = children.filter(c => c.type === 2).length
  const dirCount  = children.filter(c => c.type === 1).length
  const opsCount  = children.filter(c => c.type === 3).length +
    children.flatMap(c => c.children ?? []).filter(c => c.type === 3).length

  return (
    <div style={{ marginBottom: 16 }}>
      <Collapse
        defaultActiveKey={[String(node.id)]}
        style={{ border: `1px solid ${cfg.border}`, borderRadius: 14, overflow: 'hidden', boxShadow: '0 2px 16px rgba(99,102,241,0.08)' }}
        expandIcon={({ isActive }) => (
          <RightOutlined style={{ fontSize: 12, color: cfg.color, transform: isActive ? 'rotate(90deg)' : 'rotate(0deg)', transition: 'transform 0.2s' }} />
        )}
        items={[{
          key: String(node.id),
          style: { border: 'none' },
          label: (
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              {/* 目录图标 */}
              <div style={{
                width: 36, height: 36, borderRadius: 10, flexShrink: 0,
                background: cfg.gradient,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 16, color: '#fff',
                boxShadow: `0 4px 12px ${cfg.color}40`,
              }}>
                {getNodeIcon(node)}
              </div>

              {/* 名称 + 统计 */}
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 700, fontSize: 15, color: '#312e81' }}>
                  {node.name}
                </div>
                <Space size={6} style={{ marginTop: 2 }}>
                  {dirCount > 0   && <Tag color="purple"  style={{ fontSize: 10, margin: 0 }}>{dirCount} 子目录</Tag>}
                  {menuCount > 0  && <Tag color="blue"    style={{ fontSize: 10, margin: 0 }}>{menuCount} 菜单</Tag>}
                  {opsCount > 0   && <Tag color="gold"    style={{ fontSize: 10, margin: 0 }}>{opsCount} 操作</Tag>}
                </Space>
              </div>

              {/* 显示 + 授权 + 操作 */}
              <Space size={6} onClick={e => e.stopPropagation()}>
                <Tooltip title="侧边栏"><Switch size="small" checked={node.visible === 1} loading={actions.togglingId === node.id} onChange={val => actions.onToggle(node, 'visible', val)} style={{ background: node.visible === 1 ? cfg.color : undefined }} /></Tooltip>
                <Tooltip title="已授权"><Switch size="small" checked={node.status !== 0} loading={actions.togglingId === node.id} onChange={val => actions.onToggle(node, 'status', val)} style={{ background: node.status !== 0 ? '#10b981' : undefined }} /></Tooltip>
                <PermGuard code="permission:add">
                  <Button size="small" type="primary" ghost icon={<PlusOutlined />} onClick={() => actions.onAdd(node)} style={{ borderRadius: 7, height: 26, fontSize: 12 }}>新增子节点</Button>
                </PermGuard>
                <PermGuard code="permission:edit">
                  <Button size="small" icon={<EditOutlined />} onClick={() => actions.onEdit(node)} style={{ borderRadius: 7, borderColor: '#fcd34d', color: '#d97706', height: 26 }} />
                </PermGuard>
                <PermGuard code="permission:delete">
                  <Popconfirm
                    title={`删除「${node.name}」`}
                    description={children.length > 0 ? `该目录含 ${children.length} 个子节点，将一并删除！` : '确认删除？操作不可恢复。'}
                    onConfirm={() => actions.onDelete(node)}
                    okText="删除" okButtonProps={{ danger: true }} cancelText="取消"
                  >
                    <Button size="small" danger icon={<DeleteOutlined />} style={{ borderRadius: 7, height: 26 }} />
                  </Popconfirm>
                </PermGuard>
              </Space>
            </div>
          ),
          styles: { header: { background: cfg.lightBg, padding: '12px 16px' }, body: { padding: '14px 16px', background: '#fafbfe' } },
          children: (
            <div>
              {children.length === 0 ? (
                <div style={{ textAlign: 'center', padding: '24px 0', color: '#94a3b8', fontSize: 13 }}>
                  暂无子节点 — 点击「新增子节点」开始配置
                </div>
              ) : (
                <>
                  {/* 直接挂在目录下的操作权限 */}
                  {children.filter(c => c.type === 3).length > 0 && (
                    <div style={{ marginBottom: 10 }}>
                      <div style={{ fontSize: 11, color: '#d97706', fontWeight: 600, marginBottom: 6, display: 'flex', alignItems: 'center', gap: 4 }}>
                        <ThunderboltOutlined /> 目录级操作权限
                      </div>
                      <div style={{ background: '#fffdf7', borderRadius: 8, border: '1px dashed rgba(245,158,11,0.3)', overflow: 'hidden' }}>
                        {children.filter(c => c.type === 3).map(op => (
                          <OperationRow key={op.id} node={op} actions={actions} />
                        ))}
                      </div>
                    </div>
                  )}
                  {/* 菜单节点 */}
                  {children.filter(c => c.type !== 3).map(child => (
                    <TreeNodeRenderer key={child.id} node={child} actions={actions} />
                  ))}
                </>
              )}
            </div>
          ),
        }]}
      />
    </div>
  )
}

// ── 递归节点渲染器 ─────────────────────────────────────────────────────────

function TreeNodeRenderer({ node, actions }: { node: PermissionVO; actions: NodeActions }) {
  if (node.type === 1) return <DirectoryPanel node={node} actions={actions} />
  if (node.type === 2) return <MenuRow node={node} actions={actions} />
  return <OperationRow node={node} actions={actions} />
}

// ── 主组件 ────────────────────────────────────────────────────────────────────

export default function PermissionTreePage() {
  const [portal, setPortal]          = useState<Portal>('admin')
  const [tree, setTree]              = useState<PermissionVO[]>([])
  const [loading, setLoading]        = useState(false)
  const [drawerOpen, setDrawerOpen]  = useState(false)
  const [editing, setEditing]        = useState<PermissionVO | null>(null)
  const [parentNode, setParentNode]  = useState<PermissionVO | null>(null)
  const [keyword, setKeyword]        = useState('')
  const [togglingId, setTogglingId]  = useState<number | null>(null)
  const searchRef = useRef<any>(null)
  const [form] = Form.useForm()

  useEffect(() => { fetchTree(portal) }, [portal])

  const fetchTree = async (p: Portal) => {
    setLoading(true)
    try {
      const res = p === 'admin' ? await permissionApi.tree() : await permissionApi.merchantTree()
      setTree(res.data?.data ?? [])
    } finally { setLoading(false) }
  }

  const stats    = useMemo(() => countNodes(tree), [tree])
  const filtered = useMemo(() => filterTree(tree, keyword), [tree, keyword])

  // ── 表单动作 ───────────────────────────────────────────────────────────────
  const openAdd = (parent: PermissionVO | null = null) => {
    setEditing(null); setParentNode(parent)
    form.resetFields()
    // 智能预判类型：操作权限下新增→操作；目录下新增→菜单；根→目录
    const defaultType = parent?.type === 2 ? 3 : parent ? 2 : 1
    form.setFieldsValue({ type: defaultType, sort: 0, visible: 1 })
    setDrawerOpen(true)
  }
  const openEdit = (node: PermissionVO) => {
    setEditing(node); setParentNode(null)
    form.setFieldsValue(node)
    setDrawerOpen(true)
  }

  const handleSubmit = async () => {
    const values = await form.validateFields()
    try {
      if (editing) {
        await permissionApi.edit({ id: editing.id, ...values })
        message.success('节点已更新')
      } else {
        await permissionApi.add({ parentId: parentNode?.id ?? 0, portalType: portal === 'merchant' ? 1 : 0, ...values })
        message.success('节点已创建')
      }
      setDrawerOpen(false); fetchTree(portal)
    } catch { /* 拦截器已处理 */ }
  }

  const handleToggle = async (node: PermissionVO, field: 'visible' | 'status', val: boolean) => {
    setTogglingId(node.id)
    try {
      await permissionApi.edit({ ...node, [field]: val ? 1 : 0 } as any)
      message.success(`已${val ? '启用' : '停用'}`)
      fetchTree(portal)
    } catch { /* ignore */ } finally { setTogglingId(null) }
  }

  const handleDelete = async (node: PermissionVO) => {
    await permissionApi.delete(node.id)
    message.success('已删除')
    fetchTree(portal)
  }

  const nodeActions: NodeActions = {
    onAdd: openAdd,
    onEdit: openEdit,
    onDelete: handleDelete,
    onToggle: handleToggle,
    togglingId,
  }

  const isAdmin = portal === 'admin'
  const { ref: treeRef, height: treeH } = useTableBodyHeight(0, 0)

  const GRADIENT = isAdmin
    ? 'linear-gradient(135deg,#667eea,#764ba2)'
    : 'linear-gradient(135deg,#4facfe,#00f2fe)'

  return (
    <div style={{ marginTop: -24 }}>
      {/* ── 粘性页头 ── */}
      <div style={{
        position: 'sticky', top: 64, zIndex: 88,
        marginLeft: -24, marginRight: -24,
        background: 'rgba(255,255,255,0.97)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderBottom: '1px solid rgba(0,0,0,0.07)',
        boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
      }}>
        {/* 第一行：图标 + 标题 + 统计徽章 + 新增按钮 */}
        <div style={{ display: 'flex', alignItems: 'center', padding: '10px 24px 0', gap: 12 }}>
          <div style={{
            width: 34, height: 34, borderRadius: 10,
            background: GRADIENT,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: isAdmin ? '0 4px 12px rgba(102,126,234,0.35)' : '0 4px 12px rgba(79,172,254,0.35)',
            flexShrink: 0,
          }}>
            <LockOutlined style={{ color: '#fff', fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1e293b', lineHeight: 1.2 }}>权限配置</div>
            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>三级权限树：目录 → 菜单 → 操作权限，层级清晰，一目了然</div>
          </div>
          <div style={{ width: 1, height: 20, margin: '0 4px', background: '#e0e4ff', flexShrink: 0 }} />
          {/* 统计徽章 */}
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            {[
              { label: '节点总数', value: stats.total, color: '#6366f1', bg: 'rgba(99,102,241,0.08)', border: 'rgba(99,102,241,0.2)' },
              { label: '目录',     value: stats.dirs,  color: '#8b5cf6', bg: 'rgba(139,92,246,0.08)', border: 'rgba(139,92,246,0.2)' },
              { label: '菜单',     value: stats.menus, color: '#0ea5e9', bg: 'rgba(14,165,233,0.08)', border: 'rgba(14,165,233,0.2)' },
              { label: '操作',     value: stats.ops,   color: '#f59e0b', bg: 'rgba(245,158,11,0.08)', border: 'rgba(245,158,11,0.2)' },
            ].map(s => (
              <div key={s.label} style={{
                display: 'flex', alignItems: 'center', gap: 5,
                padding: '3px 10px', borderRadius: 20,
                background: s.bg, border: `1px solid ${s.border}`,
              }}>
                <span style={{ fontSize: 12, color: '#6b7280' }}>{s.label}</span>
                <span style={{ fontSize: 13, fontWeight: 700, color: s.color }}>{s.value}</span>
              </div>
            ))}
          </div>
          <div style={{ flex: 1 }} />
          <PermGuard code="permission:add">
            <Button
              type="primary"
              icon={<PlusOutlined />}
              onClick={() => openAdd(null)}
              style={{ background: GRADIENT, border: 'none', borderRadius: 8 }}
            >
              新增根节点
            </Button>
          </PermGuard>
        </div>

        {/* 第二行：门户切换 + 图例 + 搜索 + 刷新 */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '10px 24px 12px', flexWrap: 'wrap' }}>
          <Segmented
            value={portal}
            onChange={v => { setPortal(v as Portal); setKeyword('') }}
            options={[
              {
                value: 'admin',
                label: (
                  <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '1px 4px' }}>
                    <DesktopOutlined />
                    <span style={{ fontSize: 13 }}>管理端权限</span>
                    {portal === 'admin' && <Badge count={stats.total} color="#6366f1" size="small" />}
                  </div>
                ),
              },
              {
                value: 'merchant',
                label: (
                  <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '1px 4px' }}>
                    <ShopOutlined />
                    <span style={{ fontSize: 13 }}>商户端菜单</span>
                    {portal === 'merchant' && <Badge count={stats.total} color="#0ea5e9" size="small" />}
                  </div>
                ),
              },
            ]}
          />
          <div style={{ width: 1, height: 16, background: '#e2e8f0', flexShrink: 0 }} />
          {/* 节点类型图例 */}
          <Space size={10}>
            {Object.entries(NODE_CFG).map(([k, v]) => (
              <div key={k} style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                <div style={{ width: 16, height: 16, borderRadius: 4, background: v.gradient, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 8, color: '#fff' }}>
                  {v.icon(false)}
                </div>
                <Text style={{ fontSize: 12, color: '#64748b' }}>{v.label}</Text>
              </div>
            ))}
          </Space>
          <div style={{ flex: 1 }} />
          <Input
            ref={searchRef}
            placeholder="搜索名称 / 路径 / 权限码…"
            prefix={<SearchOutlined style={{ color: '#bbb' }} />}
            value={keyword}
            onChange={e => setKeyword(e.target.value)}
            allowClear
            style={{ width: 200, borderRadius: 8 }}
          />
          <Button icon={<ReloadOutlined />} style={{ borderRadius: 8 }} onClick={() => fetchTree(portal)}>刷新</Button>
        </div>
      </div>

      {/* ── 权限树 ── */}
      <div ref={treeRef} style={{ marginLeft: -24, marginRight: -24, marginBottom: -24, overflowY: 'auto', height: treeH, padding: '16px 24px' }}>
        {loading ? (
          <div style={{ textAlign: 'center', padding: '80px 0' }}>
            <Spin size="large" />
            <div style={{ marginTop: 16, color: '#94a3b8' }}>正在加载…</div>
          </div>
        ) : filtered.length === 0 ? (
          <Empty
            image={Empty.PRESENTED_IMAGE_SIMPLE}
            description={keyword ? `未找到包含「${keyword}」的节点` : '暂无节点，点击「新增根节点」开始配置'}
            style={{ padding: '60px 0', background: '#fff', borderRadius: 14 }}
          />
        ) : (
          filtered.map(node => <TreeNodeRenderer key={node.id} node={node} actions={nodeActions} />)
        )}
      </div>

      {/* ── 新增 / 编辑 抽屉 ── */}
      <Drawer
        title={
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{
              width: 34, height: 34, borderRadius: 9,
              background: editing
                ? 'linear-gradient(135deg,#f093fb,#f5576c)'
                : isAdmin ? 'linear-gradient(135deg,#667eea,#764ba2)' : 'linear-gradient(135deg,#4facfe,#00f2fe)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              {editing ? <EditOutlined style={{ color: '#fff' }} /> : <PlusOutlined style={{ color: '#fff' }} />}
            </div>
            <div>
              <div style={{ fontWeight: 600, fontSize: 15 }}>
                {editing
                  ? `编辑「${editing.name}」`
                  : parentNode
                    ? `在「${parentNode.name}」下新增${parentNode.type === 2 ? '操作权限' : '子节点'}`
                    : `新增${isAdmin ? '管理端' : '商户端'}根目录`}
              </div>
              <div style={{ fontSize: 12, color: '#94a3b8', fontWeight: 400 }}>
                {editing ? '修改权限节点配置' : '配置新的权限或菜单节点'}
              </div>
            </div>
          </div>
        }
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        width={500}
        footer={
          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 12 }}>
            <Button onClick={() => setDrawerOpen(false)} style={{ borderRadius: 10 }}>取消</Button>
            <Button
              type="primary" onClick={handleSubmit}
              style={{ background: 'linear-gradient(135deg,#667eea,#764ba2)', border: 'none', borderRadius: 10, boxShadow: '0 4px 12px rgba(102,126,234,0.4)' }}
            >
              {editing ? '保存修改' : '创建节点'}
            </Button>
          </div>
        }
        styles={{ body: { padding: 24 }, footer: { padding: '16px 24px', borderTop: '1px solid #f0f0f0' } }}
      >
        <Form form={form} layout="vertical" requiredMark={false}>

          {/* 父节点提示 */}
          {parentNode && !editing && (
            <div style={{
              marginBottom: 16, padding: '10px 14px', borderRadius: 10,
              background: NODE_CFG[parentNode.type as NodeType]?.lightBg ?? '#f5f3ff',
              border: `1px solid ${NODE_CFG[parentNode.type as NodeType]?.border ?? '#e0e7ff'}`,
              display: 'flex', alignItems: 'center', gap: 8,
            }}>
              <div style={{
                width: 24, height: 24, borderRadius: 6,
                background: NODE_CFG[parentNode.type as NodeType]?.gradient ?? '',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 11, color: '#fff',
              }}>{getNodeIcon(parentNode)}</div>
              <div>
                <Text style={{ fontSize: 11, color: '#6b7280' }}>上级节点</Text>
                <div style={{ fontSize: 13, fontWeight: 600, color: NODE_CFG[parentNode.type as NodeType]?.color }}>{parentNode.name}</div>
              </div>
            </div>
          )}

          {/* 节点类型选择 */}
          <Form.Item name="type" label={<span style={{ fontWeight: 600 }}><TagOutlined style={{ marginRight: 6 }} />节点类型</span>} rules={[{ required: true }]}>
            <div style={{ display: 'flex', gap: 10 }}>
              {(Object.entries(NODE_CFG) as [string, typeof NODE_CFG[1]][]).map(([k, v]) => {
                const t = Number(k) as NodeType
                return (
                  <Form.Item noStyle key={k} shouldUpdate={(a, b) => a.type !== b.type}>
                    {({ getFieldValue, setFieldValue }) => {
                      const active = getFieldValue('type') === t
                      return (
                        <div
                          onClick={() => setFieldValue('type', t)}
                          style={{
                            flex: 1, padding: '12px 8px', borderRadius: 12, cursor: 'pointer', textAlign: 'center',
                            border: `2px solid ${active ? v.color : 'rgba(0,0,0,0.08)'}`,
                            background: active ? v.bg : '#fafafa',
                            transition: 'all 0.2s',
                          }}
                        >
                          <div style={{
                            width: 36, height: 36, borderRadius: 10, margin: '0 auto 6px',
                            background: active ? v.gradient : 'rgba(0,0,0,0.06)',
                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                            fontSize: 16, color: active ? '#fff' : '#94a3b8', transition: 'all 0.2s',
                          }}>{v.icon(false)}</div>
                          <div style={{ fontSize: 13, fontWeight: active ? 600 : 400, color: active ? v.color : '#64748b' }}>
                            {v.label}
                          </div>
                          {active && <CheckCircleOutlined style={{ color: v.color, fontSize: 12, marginTop: 4 }} />}
                        </div>
                      )
                    }}
                  </Form.Item>
                )
              })}
            </div>
          </Form.Item>

          <Divider style={{ margin: '12px 0' }} />

          <Form.Item name="name" label={<span style={{ fontWeight: 600 }}><MenuOutlined style={{ marginRight: 6 }} />节点名称</span>} rules={[{ required: true, message: '请输入节点名称' }]}>
            <Input placeholder="如：技师列表、新增技师" style={{ borderRadius: 10 }} size="large" />
          </Form.Item>

          <Form.Item
            name="code"
            label={<Space><span style={{ fontWeight: 600 }}><CodeOutlined style={{ marginRight: 6 }} />权限标识码</span><Text type="secondary" style={{ fontSize: 11 }}>格式：module:action</Text></Space>}
          >
            <Input placeholder="technician:add（操作权限必填）" style={{ borderRadius: 10 }} prefix={<CodeOutlined style={{ color: '#cbd5e1' }} />} />
          </Form.Item>

          <Form.Item name="path" label={<span style={{ fontWeight: 600 }}><LinkOutlined style={{ marginRight: 6 }} />路由路径</span>}>
            <Input placeholder={portal === 'merchant' ? '/merchant/technicians' : '/technicians'} style={{ borderRadius: 10 }} prefix={<LinkOutlined style={{ color: '#cbd5e1' }} />} />
          </Form.Item>

          <Form.Item name="icon" label={<Space><span style={{ fontWeight: 600 }}>图标名称</span><Text type="secondary" style={{ fontSize: 11 }}>Ant Design Icons</Text></Space>}>
            <Input placeholder="TeamOutlined…" style={{ borderRadius: 10 }} prefix={<EyeOutlined style={{ color: '#cbd5e1' }} />} />
          </Form.Item>

          <div style={{ marginTop: -12, marginBottom: 16 }}>
            <Text style={{ fontSize: 11, color: '#94a3b8' }}>快速选择：</Text>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4, marginTop: 6 }}>
              {ICON_SUGGESTIONS.map(ic => (
                <Tag key={ic} onClick={() => form.setFieldValue('icon', ic)}
                  style={{ cursor: 'pointer', borderRadius: 6, fontSize: 11, border: '1px solid #e2e8f0', background: '#f8fafc' }}>
                  {ic.replace('Outlined', '')}
                </Tag>
              ))}
            </div>
          </div>

          <Divider style={{ margin: '4px 0 12px' }} />

          <div style={{ display: 'flex', gap: 12 }}>
            <Form.Item name="sort" label={<span style={{ fontWeight: 600 }}><SortAscendingOutlined style={{ marginRight: 6 }} />排序</span>} initialValue={0} style={{ flex: 1 }}>
              <InputNumber min={0} max={999} style={{ width: '100%', borderRadius: 10 }} addonAfter="越小越前" />
            </Form.Item>

            <Form.Item name="visible" label={<span style={{ fontWeight: 600 }}><EyeOutlined style={{ marginRight: 6 }} />侧边栏</span>} initialValue={1} style={{ flex: 1 }}>
              <div style={{ display: 'flex', gap: 8 }}>
                {[{ v: 1, label: '显示', icon: <EyeOutlined /> }, { v: 0, label: '隐藏', icon: <EyeInvisibleOutlined /> }].map(o => (
                  <Form.Item noStyle key={o.v} shouldUpdate={(a, b) => a.visible !== b.visible}>
                    {({ getFieldValue, setFieldValue }) => {
                      const active = getFieldValue('visible') === o.v
                      return (
                        <div onClick={() => setFieldValue('visible', o.v)} style={{
                          flex: 1, padding: '8px 4px', borderRadius: 10, cursor: 'pointer', textAlign: 'center',
                          border: `2px solid ${active ? '#6366f1' : 'rgba(0,0,0,0.08)'}`,
                          background: active ? 'rgba(99,102,241,0.06)' : '#fafafa',
                          color: active ? '#6366f1' : '#94a3b8', fontWeight: active ? 600 : 400,
                          fontSize: 12, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 4,
                          transition: 'all 0.2s',
                        }}>
                          {o.icon}{o.label}
                        </div>
                      )
                    }}
                  </Form.Item>
                ))}
              </div>
            </Form.Item>
          </div>
        </Form>
      </Drawer>
    </div>
  )
}
