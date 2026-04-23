import { useState, useEffect, useMemo, useRef } from 'react'
import {
  Table, Button, Space, Tag, Typography, Modal,
  Form, Input, InputNumber, Select, Row, Col, message, Tooltip, Badge,
  Divider, TreeSelect, Segmented, Popover,
} from 'antd'
import {
  MenuOutlined, PlusOutlined, EditOutlined, DeleteOutlined,
  FolderOutlined, AppstoreOutlined, ApiOutlined,
  CheckCircleOutlined, EyeInvisibleOutlined, ReloadOutlined,
  PlusSquareOutlined, MinusSquareOutlined, EyeOutlined,
  DragOutlined, ArrowRightOutlined, CheckOutlined, CloseOutlined,
  ShopOutlined, SettingOutlined, TagsOutlined, LinkOutlined,
  SortAscendingOutlined, KeyOutlined,
} from '@ant-design/icons'
import { permissionApi, type PermissionVO } from '../../api/api'
import PermGuard from '../../components/common/PermGuard'
import { col, styledTableComponents, INPUT_STYLE } from '../../components/common/tableComponents'
import { useTableBodyHeight } from '../../hooks/useTableBodyHeight'
import PagePagination from '../../components/common/PagePagination'

const { Text } = Typography
const { Option } = Select

// ─── 节点类型配置 ──────────────────────────────────────────────────────────────

const TYPE_CFG: Record<number, { label: string; color: string; icon: React.ReactNode; bg: string }> = {
  1: { label: '目录', color: '#1677ff', icon: <FolderOutlined />,    bg: 'linear-gradient(135deg,#4facfe,#00f2fe)' },
  2: { label: '菜单', color: '#52c41a', icon: <AppstoreOutlined />, bg: 'linear-gradient(135deg,#43e97b,#38f9d7)' },
  3: { label: '权限', color: '#faad14', icon: <ApiOutlined />,       bg: 'linear-gradient(135deg,#f093fb,#f5576c)' },
}

// ─── 工具函数 ─────────────────────────────────────────────────────────────────

function collectAllKeys(nodes: PermissionVO[]): (number | string)[] {
  const keys: (number | string)[] = []
  const traverse = (ns: PermissionVO[]) =>
    ns.forEach(n => { keys.push(n.id); n.children?.length && traverse(n.children) })
  traverse(nodes)
  return keys
}

function filterTree(nodes: PermissionVO[], keyword: string, statusFilter?: number): PermissionVO[] {
  if (!keyword && statusFilter === undefined) return nodes
  return nodes.reduce<PermissionVO[]>((acc, n) => {
    const children = n.children ? filterTree(n.children, keyword, statusFilter) : []
    const match = (!keyword || n.name.includes(keyword)) &&
                  (statusFilter === undefined || n.visible === statusFilter)
    if (match || children.length > 0) acc.push({ ...n, children })
    return acc
  }, [])
}

/** 构建 TreeSelect 数据，过滤掉不合法的目标父节点 */
function buildParentOptions(
  nodes: PermissionVO[],
  movingId: number,
  nodeType: number,
): any[] {
  const isValidParent = (parentType: number) => {
    if (nodeType === 1) return parentType === 1   // 目录→目录
    if (nodeType === 2) return parentType === 1   // 菜单→目录
    if (nodeType === 3) return parentType === 2   // 操作→菜单
    return false
  }
  const walk = (ns: PermissionVO[]): any[] =>
    ns.flatMap(n => {
      if (n.id === movingId) return []            // 排除自身及子树
      const children = n.children ? walk(n.children) : []
      const canBeParent = isValidParent(n.type)
      if (!canBeParent && children.length === 0) return []
      return [{
        title: (
          <span>
            <span style={{ color: TYPE_CFG[n.type]?.color, marginRight: 6 }}>
              {TYPE_CFG[n.type]?.icon}
            </span>
            {n.name}
          </span>
        ),
        value: n.id,
        disabled: !canBeParent,
        children: children.length > 0 ? children : undefined,
      }]
    })
  return walk(nodes)
}

/** 获取节点的面包屑路径 */
function getBreadcrumb(nodes: PermissionVO[], targetId: number, path: string[] = []): string[] | null {
  for (const n of nodes) {
    if (n.id === targetId) return [...path, n.name]
    if (n.children) {
      const result = getBreadcrumb(n.children, targetId, [...path, n.name])
      if (result) return result
    }
  }
  return null
}

// ─── 内联排序编辑单元格 ───────────────────────────────────────────────────────

interface SortCellProps {
  value: number
  node: PermissionVO
  onSave: (node: PermissionVO, sort: number) => void
}

function SortCell({ value, node, onSave }: SortCellProps) {
  const [editing, setEditing] = useState(false)
  const [inputVal, setInputVal] = useState(value)
  const inputRef = useRef<any>(null)

  const startEdit = () => { setInputVal(value); setEditing(true) }
  const cancel    = () => setEditing(false)
  const confirm   = () => {
    setEditing(false)
    if (inputVal !== value) onSave(node, inputVal)
  }

  useEffect(() => {
    if (editing && inputRef.current) inputRef.current.focus()
  }, [editing])

  if (editing) {
    return (
      <Space size={2}>
        <InputNumber
          ref={inputRef}
          value={inputVal}
          min={0}
          max={999}
          size="small"
          style={{ width: 64, borderRadius: 6 }}
          onChange={v => setInputVal(v ?? 0)}
          onPressEnter={confirm}
          onBlur={confirm}
        />
        <Button size="small" type="link" icon={<CheckOutlined />} onClick={confirm}
          style={{ color: '#52c41a', padding: 0, minWidth: 20 }} />
        <Button size="small" type="link" icon={<CloseOutlined />} onClick={cancel}
          style={{ color: '#ff4d4f', padding: 0, minWidth: 20 }} />
      </Space>
    )
  }

  return (
    <Tooltip title="点击修改排序">
      <span
        onClick={startEdit}
        style={{
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
          minWidth: 30, height: 26, lineHeight: '26px', textAlign: 'center',
          borderRadius: 6, background: '#f0f5ff', color: '#1890ff',
          fontWeight: 700, fontSize: 12, cursor: 'pointer',
          border: '1px dashed transparent',
          transition: 'all .2s',
          padding: '0 8px',
        }}
        onMouseEnter={e => {
          ;(e.currentTarget as HTMLElement).style.borderColor = '#1890ff'
          ;(e.currentTarget as HTMLElement).style.background = '#e6f4ff'
        }}
        onMouseLeave={e => {
          ;(e.currentTarget as HTMLElement).style.borderColor = 'transparent'
          ;(e.currentTarget as HTMLElement).style.background = '#f0f5ff'
        }}
      >
        {value}
      </span>
    </Tooltip>
  )
}

// ─── 移动节点弹窗 ─────────────────────────────────────────────────────────────

interface MoveModalProps {
  open: boolean
  node: PermissionVO | null
  tree: PermissionVO[]
  onCancel: () => void
  onOk: (targetParentId: number, sort: number) => void
  moving: boolean
}

function MoveModal({ open, node, tree, onCancel, onOk, moving }: MoveModalProps) {
  const [targetParentId, setTargetParentId] = useState<number | undefined>()
  const [sort, setSort] = useState<number>(0)
  const [form] = Form.useForm()

  useEffect(() => {
    if (open && node) {
      setTargetParentId(node.parentId ?? 0)
      setSort(node.sort ?? 0)
      form.setFieldsValue({ targetParentId: node.parentId ?? 0, sort: node.sort ?? 0 })
    }
  }, [open, node, form])

  if (!node) return null

  const cfg         = TYPE_CFG[node.type]
  const breadcrumb  = getBreadcrumb(tree, node.id)
  const treeOptions = buildParentOptions(tree, node.id, node.type)

  // 目录类型可以有"根节点"作为父
  const rootOption = node.type === 1 ? [{
    title: <span style={{ color: '#666', fontWeight: 600 }}>【根节点】顶层目录</span>,
    value: 0,
  }] : []

  const handleOk = async () => {
    if (targetParentId === undefined) { message.warning('请选择目标位置'); return }
    onOk(targetParentId, sort)
  }

  return (
    <Modal
      open={open}
      onCancel={onCancel}
      onOk={handleOk}
      confirmLoading={moving}
      title={
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{
            width: 34, height: 34, borderRadius: 10,
            background: 'linear-gradient(135deg,#667eea,#764ba2)',
            display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff',
          }}>
            <DragOutlined style={{ fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontWeight: 700, fontSize: 15 }}>移动节点</div>
            <div style={{ fontSize: 12, color: '#999', fontWeight: 400 }}>调整菜单在目录树中的位置</div>
          </div>
        </div>
      }
      okText="确认移动"
      cancelText="取消"
      okButtonProps={{ style: { borderRadius: 8, background: 'linear-gradient(135deg,#667eea,#764ba2)', border: 'none', fontWeight: 600 } }}
      cancelButtonProps={{ style: { borderRadius: 8 } }}
      width={540}
    >
      {/* 节点信息卡 */}
      <div style={{
        margin: '16px 0', padding: '14px 16px',
        background: 'linear-gradient(135deg,#f8f9ff,#eff2ff)',
        borderRadius: 10, border: '1px solid #e0e7ff',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{
            width: 32, height: 32, borderRadius: 8,
            background: cfg?.bg, display: 'flex', alignItems: 'center',
            justifyContent: 'center', color: '#fff', flexShrink: 0,
          }}>{cfg?.icon}</div>
          <div>
            <div style={{ fontWeight: 700, fontSize: 14 }}>{node.name}</div>
            <div style={{ fontSize: 12, color: '#999', marginTop: 2 }}>
              <Tag color={cfg?.color} style={{ borderRadius: 4, fontSize: 11, margin: 0 }}>{cfg?.label}</Tag>
              {node.code && (
                <code style={{ marginLeft: 6, background: '#fff7e6', padding: '1px 6px', borderRadius: 4, color: '#d46b08', fontSize: 11 }}>
                  {node.code}
                </code>
              )}
            </div>
          </div>
        </div>
        {breadcrumb && (
          <div style={{ marginTop: 10, padding: '6px 10px', background: '#fff', borderRadius: 6, border: '1px solid #e8eaf0' }}>
            <Text style={{ fontSize: 12, color: '#666' }}>
              <span style={{ color: '#999', marginRight: 6 }}>当前位置：</span>
              {breadcrumb.join(' › ')}
            </Text>
          </div>
        )}
      </div>

      <Divider style={{ margin: '8px 0 16px' }}>
        <Space style={{ fontSize: 12, color: '#999' }}>
          <ArrowRightOutlined />
          <span>选择目标位置</span>
        </Space>
      </Divider>

      <Form form={form} layout="vertical">
        <Form.Item
          label={<span style={{ fontWeight: 600 }}>目标父节点</span>}
          required
          extra={
            <span style={{ fontSize: 12, color: '#999' }}>
              {node.type === 1 && '目录可移动至根节点或其他目录下'}
              {node.type === 2 && '菜单只能移动至目录下'}
              {node.type === 3 && '操作权限只能移动至菜单下'}
            </span>
          }
        >
          <TreeSelect
            value={targetParentId}
            onChange={v => { setTargetParentId(v); form.setFieldsValue({ targetParentId: v }) }}
            treeData={[...rootOption, ...treeOptions]}
            treeDefaultExpandAll
            showSearch
            filterTreeNode={(input, node) =>
              String(node?.title ?? '').toLowerCase().includes(input.toLowerCase())
            }
            placeholder="请选择目标父节点"
            style={{ width: '100%', borderRadius: 8 }}
            dropdownStyle={{ maxHeight: 360, overflow: 'auto', borderRadius: 10 }}
            treeIcon
            notFoundContent={<Text type="secondary" style={{ padding: 16, display: 'block', textAlign: 'center' }}>无可用目标</Text>}
          />
        </Form.Item>

        <Form.Item label={<span style={{ fontWeight: 600 }}>排序值</span>}
          extra="数值越小越靠前，同级节点按此值排序">
          <InputNumber
            value={sort}
            min={0} max={999}
            onChange={v => setSort(v ?? 0)}
            style={{ width: '100%', borderRadius: 8 }}
            placeholder="0"
          />
        </Form.Item>
      </Form>
    </Modal>
  )
}

// ─── 主页面 ───────────────────────────────────────────────────────────────────

type PortalTab = 'admin' | 'merchant'

export default function MenuManagePage() {
  const { ref, height: tableBodyH } = useTableBodyHeight(46)
  const [rawTree,       setRawTree]       = useState<PermissionVO[]>([])
  const [loading,       setLoading]       = useState(false)
  const [expandedKeys,  setExpandedKeys]  = useState<(number | string)[]>([])
  const [allKeys,       setAllKeys]       = useState<(number | string)[]>([])
  const [modalOpen,     setModalOpen]     = useState(false)
  const [editing,       setEditing]       = useState<PermissionVO | null>(null)
  const [parentId,      setParentId]      = useState<number>(0)
  const [searchName,    setSearchName]    = useState('')
  const [searchVisible, setSearchVisible] = useState<number | undefined>()
  const [portalTab,     setPortalTab]     = useState<PortalTab>('admin')
  const [moveModalOpen, setMoveModalOpen] = useState(false)
  const [moveTarget,    setMoveTarget]    = useState<PermissionVO | null>(null)
  const [moving,        setMoving]        = useState(false)
  const [form] = Form.useForm()

  useEffect(() => { loadTree() }, [portalTab])

  const loadTree = async () => {
    setLoading(true)
    try {
      const res  = portalTab === 'admin'
        ? await permissionApi.tree()
        : await permissionApi.merchantTree()
      const tree = res.data?.data ?? []
      setRawTree(tree)
      const keys = collectAllKeys(tree)
      setAllKeys(keys)
      setExpandedKeys(keys)
    } finally {
      setLoading(false)
    }
  }

  const displayTree = useMemo(
    () => filterTree(rawTree, searchName, searchVisible),
    [rawTree, searchName, searchVisible],
  )

  // ── CRUD ──────────────────────────────────────────────────────────────────

  const openAdd = (parentNode?: PermissionVO) => {
    setEditing(null)
    setParentId(parentNode?.id ?? 0)
    form.resetFields()
    form.setFieldsValue({
      type:    parentNode ? (parentNode.type === 1 ? 2 : 3) : 1,
      sort:    0,
      visible: 1,
      portalType: portalTab === 'merchant' ? 1 : 0,
    })
    setModalOpen(true)
  }

  const openEdit = (node: PermissionVO) => {
    setEditing(node)
    form.setFieldsValue({
      name: node.name, code: node.code, type: node.type,
      path: node.path, component: node.component, icon: node.icon,
      sort: node.sort, visible: node.visible ?? 1,
    })
    setModalOpen(true)
  }

  const handleDelete = (node: PermissionVO) => {
    Modal.confirm({
      title: `确认删除「${node.name}」？`,
      content: node.children?.length
        ? '该节点存在子项，删除后子项也将一并删除！'
        : '删除后相关角色权限将同步更新。',
      okType: 'danger', okText: '确认删除', cancelText: '取消',
      onOk: async () => {
        await permissionApi.delete(node.id)
        message.success('删除成功')
        loadTree()
      },
    })
  }

  const handleSubmit = async () => {
    const values = await form.validateFields()
    if (editing) {
      await permissionApi.edit({ id: editing.id, ...values })
      message.success('修改成功')
    } else {
      await permissionApi.add({ parentId, ...values })
      message.success('新增成功')
    }
    setModalOpen(false)
    loadTree()
  }

  // ── 排序内联保存 ───────────────────────────────────────────────────────────

  const handleSortSave = async (node: PermissionVO, sort: number) => {
    try {
      await permissionApi.move({ id: node.id, targetParentId: node.parentId ?? 0, sort })
      message.success('排序已更新')
      loadTree()
    } catch { /* interceptor handles */ }
  }

  // ── 移动节点 ──────────────────────────────────────────────────────────────

  const openMove = (node: PermissionVO) => {
    setMoveTarget(node)
    setMoveModalOpen(true)
  }

  const handleMove = async (targetParentId: number, sort: number) => {
    if (!moveTarget) return
    setMoving(true)
    try {
      await permissionApi.move({ id: moveTarget.id, targetParentId, sort })
      message.success(`「${moveTarget.name}」已成功移动`)
      setMoveModalOpen(false)
      loadTree()
    } catch { /* interceptor handles */ } finally {
      setMoving(false)
    }
  }

  // ── 列定义 ────────────────────────────────────────────────────────────────

  const columns = [
    {
      title: col(<MenuOutlined style={{ color: '#1677ff' }} />, '节点名称'), dataIndex: 'name', key: 'name',
      render: (v: string, r: PermissionVO) => {
        const cfg = TYPE_CFG[r.type]
        return (
          <Space>
            <div style={{
              width: 26, height: 26, borderRadius: 6,
              background: cfg?.bg || '#ddd',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              color: '#fff', fontSize: 12, flexShrink: 0,
            }}>{cfg?.icon}</div>
            <Text strong={r.type === 1} style={{ fontSize: 14 }}>{v}</Text>
            {r.visible === 0 && (
              <Tooltip title="该节点已隐藏">
                <EyeInvisibleOutlined style={{ color: '#ccc', fontSize: 12 }} />
              </Tooltip>
            )}
          </Space>
        )
      },
    },
    {
      title: col(<SortAscendingOutlined style={{ color: '#9ca3af' }} />, '排序'),
      dataIndex: 'sort',
      key: 'sort',
      align: 'center' as const,
      width: 90,
      render: (v: number, r: PermissionVO) => (
        <SortCell value={v ?? 0} node={r} onSave={handleSortSave} />
      ),
    },
    {
      title: col(<LinkOutlined style={{ color: '#9ca3af' }} />, '路径/标识'), dataIndex: 'path', key: 'path',
      render: (v: string) => v
        ? <code style={{ background: '#f0f5ff', padding: '1px 8px', borderRadius: 4, color: '#1890ff', fontSize: 12 }}>{v}</code>
        : <Text type="secondary">-</Text>,
    },
    {
      title: col(<TagsOutlined style={{ color: '#fa8c16' }} />, '类型'), dataIndex: 'type', key: 'type', width: 80,
      render: (v: number) => {
        const cfg = TYPE_CFG[v]
        return cfg
          ? <Tag color={cfg.color} icon={cfg.icon} style={{ borderRadius: 6 }}>{cfg.label}</Tag>
          : '-'
      },
    },
    {
      title: col(<EyeOutlined style={{ color: '#52c41a' }} />, '可见性'), dataIndex: 'visible', key: 'visible', width: 80,
      render: (v: number) => v === 1
        ? <Badge status="success" text={<span style={{ color: '#52c41a', fontWeight: 600 }}>显示</span>} />
        : <Badge status="default" text={<span style={{ color: '#bbb' }}>隐藏</span>} />,
    },
    {
      title: col(<KeyOutlined style={{ color: '#9ca3af' }} />, '权限标识'), dataIndex: 'code', key: 'code',
      render: (v: string) => v
        ? <Tag style={{ borderRadius: 4, fontSize: 11, background: '#fff7e6', borderColor: '#ffd591', color: '#d46b08' }}>{v}</Tag>
        : <Text type="secondary">-</Text>,
    },
    {
      title: col(<SettingOutlined style={{ color: '#9ca3af' }} />, '操作'), key: 'action', width: 260,
      render: (_: any, r: PermissionVO) => (
        <Space size={4} wrap>
          <PermGuard code="menu:edit">
            <Tooltip title="编辑节点信息">
              <Button size="small" type="primary" ghost icon={<EditOutlined />} onClick={() => openEdit(r)}
                style={{ borderRadius: 6, fontSize: 12 }}>编辑</Button>
            </Tooltip>
          </PermGuard>
          <PermGuard code="menu:edit">
            <Tooltip title="移动到其他目录">
              <Button size="small" icon={<DragOutlined />} onClick={() => openMove(r)}
                style={{ borderRadius: 6, fontSize: 12, background: '#f5f0ff', borderColor: '#d3adf7', color: '#722ed1' }}>移动</Button>
            </Tooltip>
          </PermGuard>
          <PermGuard code="menu:add">
            <Tooltip title="新增子节点">
              <Button size="small" icon={<PlusOutlined />} onClick={() => openAdd(r)}
                style={{ borderRadius: 6, fontSize: 12, background: '#f6ffed', borderColor: '#b7eb8f', color: '#52c41a' }}>新增</Button>
            </Tooltip>
          </PermGuard>
          <PermGuard code="menu:delete">
            <Tooltip title="删除">
              <Button size="small" danger icon={<DeleteOutlined />} onClick={() => handleDelete(r)}
                style={{ borderRadius: 6, fontSize: 12 }}>删除</Button>
            </Tooltip>
          </PermGuard>
        </Space>
      ),
    },
  ]

  return (
    <div style={{ marginTop: -24 }}>
      {/* Sticky composite header */}
      <div style={{
        position: 'sticky', top: 64, zIndex: 88,
        marginLeft: -24, marginRight: -24,
        background: 'rgba(255,255,255,0.97)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderBottom: '1px solid rgba(0,0,0,0.07)',
        boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
      }}>
        {/* Title row */}
        <div style={{ display: 'flex', alignItems: 'center', padding: '10px 24px 0', gap: 12, flexWrap: 'wrap' }}>
          <div style={{ width: 34, height: 34, borderRadius: 10, background: 'linear-gradient(135deg,#4facfe,#00f2fe)', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 4px 12px rgba(79,172,254,0.4)', flexShrink: 0 }}>
            <MenuOutlined style={{ color: '#fff', fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1e293b', lineHeight: 1.2 }}>菜单管理</div>
            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>
              {portalTab === 'admin' ? '管理系统导航菜单结构与功能权限节点，支持移动与排序' : '管理商户端导航菜单结构，控制商户可见功能范围'}
            </div>
          </div>
          <div style={{ width: 1, height: 20, margin: '0 4px', background: '#e0e4ff', flexShrink: 0 }} />
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: 'rgba(79,172,254,0.1)', border: '1px solid rgba(79,172,254,0.25)' }}>
              <span style={{ fontSize: 13 }}>📋</span>
              <span style={{ fontSize: 12, color: '#6b7280' }}>节点总数</span>
              <span style={{ fontSize: 13, fontWeight: 700, color: '#4facfe' }}>{allKeys.length}</span>
            </div>
          </div>
          <div style={{ flex: 1 }} />
          <Space wrap>
            <Button icon={<ReloadOutlined />} onClick={loadTree} loading={loading} style={{ borderRadius: 8 }}>刷新</Button>
            <Button icon={<PlusSquareOutlined />} onClick={() => setExpandedKeys(allKeys)} style={{ borderRadius: 8 }}>展开全部</Button>
            <Button icon={<MinusSquareOutlined />} onClick={() => setExpandedKeys([])} style={{ borderRadius: 8 }}>折叠全部</Button>
            <PermGuard code="menu:add">
              <Button type="primary" icon={<PlusOutlined />} onClick={() => openAdd()} style={{ borderRadius: 8, background: 'linear-gradient(135deg,#4facfe,#00f2fe)', border: 'none', fontWeight: 600 }}>新增菜单</Button>
            </PermGuard>
          </Space>
        </div>

        {/* Second row: Segmented + filters */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 24px 12px', flexWrap: 'wrap' }}>
          <Segmented
            value={portalTab}
            onChange={v => { setPortalTab(v as PortalTab); setSearchName(''); setSearchVisible(undefined) }}
            options={[
              { label: (<Space style={{ padding: '2px 8px' }}><SettingOutlined style={{ color: '#1890ff' }} /><span style={{ fontWeight: 600 }}>管理端菜单</span></Space>), value: 'admin' },
              { label: (<Space style={{ padding: '2px 8px' }}><ShopOutlined style={{ color: '#52c41a' }} /><span style={{ fontWeight: 600 }}>商户端菜单</span></Space>), value: 'merchant' },
            ]}
            style={{ borderRadius: 10 }}
          />
          <div style={{ width: 1, height: 20, margin: '0 4px', background: '#e5e7eb', flexShrink: 0 }} />
          <Input placeholder="菜单名称" allowClear value={searchName} onChange={e => setSearchName(e.target.value)} style={{ width: 180, ...INPUT_STYLE }} prefix={<MenuOutlined style={{ color: '#9ca3af', fontSize: 12 }} />} size="middle" />
          <Select placeholder={<Space size={4}><EyeOutlined style={{ color: '#6366f1', fontSize: 12 }} />可见性</Space>} allowClear style={{ width: 100 }} size="middle" value={searchVisible} onChange={v => setSearchVisible(v)}>
            <Option value={1}><Space><EyeOutlined style={{ color: '#52c41a' }} />显示</Space></Option>
            <Option value={0}><Space><EyeInvisibleOutlined style={{ color: '#ccc' }} />隐藏</Space></Option>
          </Select>
          <Button onClick={() => { setSearchName(''); setSearchVisible(undefined) }} style={{ borderRadius: 8 }}>重置</Button>
        </div>
      </div>

      {/* Legend */}
      <div style={{ padding: '12px 0 8px', display: 'flex', gap: 12, alignItems: 'center', flexWrap: 'wrap' }}>
        {Object.entries(TYPE_CFG).map(([k, v]) => (
          <Tag key={k} icon={v.icon} color={v.color} style={{ borderRadius: 6, padding: '2px 10px', fontSize: 13 }}>{v.label}</Tag>
        ))}
        <Tag icon={<EyeInvisibleOutlined />} color="default" style={{ borderRadius: 6 }}>隐藏节点</Tag>
        <Popover content={
          <div style={{ maxWidth: 280, fontSize: 13, lineHeight: 2 }}>
            <div>• <b>编辑</b>：修改节点基本信息（名称/路径/图标等）</div>
            <div>• <b>移动</b>：将节点迁移到其他目录，并调整排序</div>
            <div>• <b>排序数字</b>：点击可直接在线修改排序值</div>
            <div>• <b>新增</b>：在该节点下添加子节点</div>
          </div>
        } title="操作说明" trigger="click">
          <Tag icon={<CheckCircleOutlined />} color="processing" style={{ borderRadius: 6, cursor: 'pointer' }}>操作说明</Tag>
        </Popover>
        <Text type="secondary" style={{ fontSize: 12 }}>共 {allKeys.length} 个节点</Text>
      </div>

      {/* Tree table - full width */}
      <div ref={ref} style={{ marginLeft: -24, marginRight: -24, marginBottom: -24, background: '#fff', borderTop: '1px solid #eef0f8' }}>
        <Table
          columns={columns}
          dataSource={displayTree}
          rowKey="id"
          loading={loading}
          pagination={false}
          size="small"
          components={styledTableComponents}
          scroll={{ x: 'max-content', y: tableBodyH }}
          expandable={{
            expandedRowKeys: expandedKeys as string[],
            onExpandedRowsChange: (keys) => setExpandedKeys(keys as number[]),
            indentSize: 22,
          }}
          rowClassName={(r: PermissionVO) =>
            r.type === 1 ? 'menu-row-dir' : r.type === 2 ? 'menu-row-menu' : 'menu-row-op'
          }
        />
        <PagePagination
          total={allKeys.length}
          current={1}
          pageSize={Math.max(allKeys.length, 1)}
          onChange={() => {}}
          showSizeChanger={false}
          countLabel="个节点"
        />
      </div>

      {/* ── 新增/编辑弹窗 ── */}
      <Modal
        open={modalOpen}
        onCancel={() => setModalOpen(false)}
        onOk={handleSubmit}
        title={
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{
              width: 32, height: 32, borderRadius: 8,
              background: 'linear-gradient(135deg,#4facfe,#00f2fe)',
              display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff',
            }}>
              {editing ? <EditOutlined /> : <PlusOutlined />}
            </div>
            <span>{editing ? `编辑 — ${editing.name}` : (parentId === 0 ? '新增顶级菜单' : '新增子节点')}</span>
          </div>
        }
        okText={editing ? '保存修改' : '确认新增'}
        okButtonProps={{ style: { borderRadius: 8, background: 'linear-gradient(135deg,#4facfe,#00f2fe)', border: 'none' } }}
        cancelButtonProps={{ style: { borderRadius: 8 } }}
        width={880}
        styles={{ body: { maxHeight: 'calc(85vh - 150px)', overflowY: 'auto', overflowX: 'hidden' } }}
      >
        <Divider style={{ margin: '12px 0' }} />
        <Form form={form} layout="vertical" size="large">
          <Row gutter={16}>
            <Col span={14}>
              <Form.Item name="name" label="菜单名称" rules={[{ required: true, message: '请输入菜单名称' }]}>
                <Input placeholder="如：会员管理" prefix={<MenuOutlined style={{ color: '#ccc' }} />} style={{ borderRadius: 8 }} />
              </Form.Item>
            </Col>
            <Col span={10}>
              <Form.Item name="type" label="节点类型" rules={[{ required: true }]}>
                <Select style={{ borderRadius: 8 }}>
                  {Object.entries(TYPE_CFG).map(([k, v]) => (
                    <Option key={k} value={Number(k)}>
                      <Space>{v.icon}<span style={{ color: v.color }}>{v.label}</span></Space>
                    </Option>
                  ))}
                </Select>
              </Form.Item>
            </Col>
          </Row>
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="icon" label="图标名称">
                <Input placeholder="如：UserOutlined" style={{ borderRadius: 8 }} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="sort" label="显示排序">
                <InputNumber min={0} style={{ width: '100%', borderRadius: 8 }} />
              </Form.Item>
            </Col>
          </Row>
          <Form.Item name="path" label="路由地址">
            <Input placeholder="如：/users（菜单类型必填）"
              prefix={<span style={{ color: '#ccc', fontSize: 12 }}>/</span>}
              style={{ borderRadius: 8 }} />
          </Form.Item>
          <Form.Item name="component" label="组件路径">
            <Input placeholder="如：user/UserListPage" style={{ borderRadius: 8 }} />
          </Form.Item>
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="code" label="权限标识">
                <Input placeholder="如：member:list" style={{ borderRadius: 8 }} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="visible" label="是否显示">
                <Select style={{ borderRadius: 8 }}>
                  <Option value={1}><Space><CheckCircleOutlined style={{ color: '#52c41a' }} />显示</Space></Option>
                  <Option value={0}><Space><EyeInvisibleOutlined style={{ color: '#bbb' }} />隐藏</Space></Option>
                </Select>
              </Form.Item>
            </Col>
          </Row>
          {/* 新增时显示门户类型（由 tab 预设，可覆盖） */}
          {!editing && (
            <Form.Item name="portalType" label="所属门户" extra="控制此节点显示在哪个门户的菜单中">
              <Select style={{ borderRadius: 8 }}>
                <Option value={0}><Space><SettingOutlined style={{ color: '#1890ff' }} />管理端</Space></Option>
                <Option value={1}><Space><ShopOutlined style={{ color: '#52c41a' }} />商户端</Space></Option>
              </Select>
            </Form.Item>
          )}
        </Form>
      </Modal>

      {/* ── 移动节点弹窗 ── */}
      <MoveModal
        open={moveModalOpen}
        node={moveTarget}
        tree={rawTree}
        onCancel={() => setMoveModalOpen(false)}
        onOk={handleMove}
        moving={moving}
      />
    </div>
  )
}
