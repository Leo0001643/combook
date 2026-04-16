/**
 * 权限分配抽屉 — 支持部门 / 职位 / 员工三种粒度
 *
 * 设计亮点：
 *  - 菜单按功能模块分组，一键全选/取消
 *  - 每个菜单项下方展示操作权限（新增/编辑/删除等），勾选即授权
 *  - 操作权限与菜单路径统一存储，RBAC 链无缝继承
 *  - 底部实时统计已选菜单数 + 已选操作权限数
 */
import { useEffect, useState } from 'react'
import { Drawer, Button, Space, Checkbox, Badge, Tag, message, Spin, Divider, Tooltip } from 'antd'
import {
  LockOutlined, CheckCircleOutlined, SaveOutlined,
  DashboardOutlined, UserOutlined, TeamOutlined, OrderedListOutlined,
  CarOutlined, AppstoreOutlined, PictureOutlined, StarOutlined,
  BellOutlined, TagsOutlined, DollarOutlined, BankOutlined,
  AuditOutlined, IdcardOutlined, KeyOutlined, ApartmentOutlined,
  SolutionOutlined, SettingOutlined, InfoCircleOutlined,
  PlusOutlined, EditOutlined, DeleteOutlined, StopOutlined,
  EyeInvisibleOutlined, MessageOutlined, ThunderboltOutlined,
} from '@ant-design/icons'
import { merchantPortalApi } from '../../api/api'

// ── 操作权限定义（菜单路径 → 操作权限码列表）────────────────────────────────
export interface OpDef {
  label: string
  code: string
  icon: React.ReactNode
  color: string
}

export const MENU_OPERATIONS: Record<string, OpDef[]> = {
  '/merchant/members': [
    { label: '封禁', code: 'member:ban', icon: <StopOutlined />, color: '#f59e0b' },
  ],
  '/merchant/technicians': [
    { label: '新增', code: 'technician:add',    icon: <PlusOutlined />,          color: '#10b981' },
    { label: '编辑', code: 'technician:edit',   icon: <EditOutlined />,          color: '#3b82f6' },
    { label: '删除', code: 'technician:delete', icon: <DeleteOutlined />,        color: '#ef4444' },
    { label: '审核', code: 'technician:audit',  icon: <AuditOutlined />,         color: '#8b5cf6' },
    { label: '状态', code: 'technician:toggle', icon: <ThunderboltOutlined />,   color: '#f59e0b' },
    { label: '推荐', code: 'technician:feature',icon: <StarOutlined />,          color: '#ec4899' },
  ],
  '/merchant/orders': [
    { label: '取消', code: 'order:cancel', icon: <StopOutlined />,    color: '#f59e0b' },
    { label: '删除', code: 'order:delete', icon: <DeleteOutlined />,  color: '#ef4444' },
  ],
  '/merchant/vehicles': [
    { label: '新增', code: 'vehicle:add',    icon: <PlusOutlined />,         color: '#10b981' },
    { label: '编辑', code: 'vehicle:edit',   icon: <EditOutlined />,         color: '#3b82f6' },
    { label: '删除', code: 'vehicle:delete', icon: <DeleteOutlined />,       color: '#ef4444' },
    { label: '状态', code: 'vehicle:status', icon: <ThunderboltOutlined />,  color: '#f59e0b' },
  ],
  '/merchant/coupons': [
    { label: '新增', code: 'coupon:add',    icon: <PlusOutlined />,   color: '#10b981' },
    { label: '编辑', code: 'coupon:edit',   icon: <EditOutlined />,   color: '#3b82f6' },
    { label: '删除', code: 'coupon:delete', icon: <DeleteOutlined />, color: '#ef4444' },
  ],
  '/merchant/operation/reviews': [
    { label: '隐藏', code: 'review:toggle', icon: <EyeInvisibleOutlined />, color: '#f59e0b' },
    { label: '回复', code: 'review:reply',  icon: <MessageOutlined />,      color: '#3b82f6' },
    { label: '删除', code: 'review:delete', icon: <DeleteOutlined />,       color: '#ef4444' },
  ],
  '/merchant/operation/banner': [
    { label: '新增', code: 'banner:add',    icon: <PlusOutlined />,   color: '#10b981' },
    { label: '编辑', code: 'banner:edit',   icon: <EditOutlined />,   color: '#3b82f6' },
    { label: '删除', code: 'banner:delete', icon: <DeleteOutlined />, color: '#ef4444' },
  ],
  '/merchant/operation/notices': [
    { label: '新增', code: 'announce:add',    icon: <PlusOutlined />,   color: '#10b981' },
    { label: '编辑', code: 'announce:edit',   icon: <EditOutlined />,   color: '#3b82f6' },
    { label: '删除', code: 'announce:delete', icon: <DeleteOutlined />, color: '#ef4444' },
  ],
  '/merchant/operation/category': [
    { label: '新增', code: 'category:add',    icon: <PlusOutlined />,   color: '#10b981' },
    { label: '编辑', code: 'category:edit',   icon: <EditOutlined />,   color: '#3b82f6' },
    { label: '删除', code: 'category:delete', icon: <DeleteOutlined />, color: '#ef4444' },
  ],
  '/merchant/perm/staff': [
    { label: '新增', code: 'staff:add',    icon: <PlusOutlined />,        color: '#10b981' },
    { label: '编辑', code: 'staff:edit',   icon: <EditOutlined />,        color: '#3b82f6' },
    { label: '删除', code: 'staff:delete', icon: <DeleteOutlined />,      color: '#ef4444' },
    { label: '状态', code: 'staff:toggle', icon: <ThunderboltOutlined />, color: '#f59e0b' },
  ],
  '/merchant/perm/dept': [
    { label: '新增', code: 'dept:add',    icon: <PlusOutlined />,   color: '#10b981' },
    { label: '编辑', code: 'dept:edit',   icon: <EditOutlined />,   color: '#3b82f6' },
    { label: '删除', code: 'dept:delete', icon: <DeleteOutlined />, color: '#ef4444' },
  ],
  '/merchant/perm/positions': [
    { label: '新增', code: 'position:add',    icon: <PlusOutlined />,   color: '#10b981' },
    { label: '编辑', code: 'position:edit',   icon: <EditOutlined />,   color: '#3b82f6' },
    { label: '删除', code: 'position:delete', icon: <DeleteOutlined />, color: '#ef4444' },
  ],
}

// ── 菜单定义（与后端 ALL_MENU_KEYS 及 MERCHANT_MENUS 完全对应）──────────────────
export interface MenuDef {
  key: string
  label: string
  icon: React.ReactNode
  color: string
}

export interface MenuGroup {
  title: string
  color: string
  bg: string
  icon: React.ReactNode
  items: MenuDef[]
}

export const MENU_GROUPS: MenuGroup[] = [
  {
    title: '核心功能', color: '#6366f1', bg: '#f5f3ff',
    icon: <DashboardOutlined />,
    items: [
      { key: '/merchant/dashboard',   label: '数据看板',  icon: <DashboardOutlined />,    color: '#6366f1' },
      { key: '/merchant/members',     label: '会员管理',  icon: <UserOutlined />,         color: '#8b5cf6' },
      { key: '/merchant/technicians', label: '技师管理',  icon: <TeamOutlined />,         color: '#a855f7' },
      { key: '/merchant/orders',      label: '订单管理',  icon: <OrderedListOutlined />,  color: '#7c3aed' },
      { key: '/merchant/vehicles',    label: '车辆管理',  icon: <CarOutlined />,          color: '#6d28d9' },
    ],
  },
  {
    title: '运营管理', color: '#0ea5e9', bg: '#f0f9ff',
    icon: <AppstoreOutlined />,
    items: [
      { key: '/merchant/operation/category', label: '服务类目',  icon: <AppstoreOutlined />, color: '#0ea5e9' },
      { key: '/merchant/operation/banner',   label: '轮播图管理', icon: <PictureOutlined />,  color: '#38bdf8' },
      { key: '/merchant/operation/reviews',  label: '评价管理',  icon: <StarOutlined />,     color: '#0284c7' },
      { key: '/merchant/operation/notices',  label: '通知公告',  icon: <BellOutlined />,     color: '#0369a1' },
    ],
  },
  {
    title: '优惠管理', color: '#ec4899', bg: '#fdf2f8',
    icon: <TagsOutlined />,
    items: [
      { key: '/merchant/coupons', label: '优惠管理', icon: <TagsOutlined />, color: '#ec4899' },
    ],
  },
  {
    title: '财务管理', color: '#f59e0b', bg: '#fffbeb',
    icon: <DollarOutlined />,
    items: [
      { key: '/merchant/finance',          label: '收入统计', icon: <BankOutlined />,  color: '#f59e0b' },
      { key: '/merchant/finance/withdraw', label: '提现审核', icon: <AuditOutlined />, color: '#d97706' },
    ],
  },
  {
    title: '权限管理', color: '#10b981', bg: '#f0fdf4',
    icon: <LockOutlined />,
    items: [
      { key: '/merchant/perm/staff',     label: '员工管理', icon: <IdcardOutlined />,    color: '#10b981' },
      { key: '/merchant/perm/roles',     label: '角色权限', icon: <KeyOutlined />,       color: '#059669' },
      { key: '/merchant/perm/dept',      label: '部门管理', icon: <ApartmentOutlined />, color: '#047857' },
      { key: '/merchant/perm/positions', label: '职位管理', icon: <SolutionOutlined />,  color: '#065f46' },
    ],
  },
  {
    title: '系统设置', color: '#64748b', bg: '#f8fafc',
    icon: <SettingOutlined />,
    items: [
      { key: '/merchant/profile', label: '商户设置', icon: <SettingOutlined />, color: '#64748b' },
    ],
  },
]

const ALL_MENU_KEYS = MENU_GROUPS.flatMap(g => g.items.map(i => i.key))
const ALL_OP_CODES  = Object.values(MENU_OPERATIONS).flatMap(ops => ops.map(op => op.code))

// ── Props ──────────────────────────────────────────────────────────────────────

export type PermTarget =
  | { type: 'dept';     id: number; name: string }
  | { type: 'position'; id: number; name: string; deptName?: string }
  | { type: 'staff';    id: number; name: string; posName?: string; deptName?: string }

interface Props {
  target: PermTarget | null
  onClose: () => void
  parentKeys?: string[]
}

// ── Component ──────────────────────────────────────────────────────────────────

export default function PermDrawer({ target, onClose, parentKeys }: Props) {
  const [selected, setSelected] = useState<string[]>([])
  const [loading, setLoading]   = useState(false)
  const [saving, setSaving]     = useState(false)
  const [isCustom, setIsCustom] = useState(false)

  const open = !!target

  useEffect(() => {
    if (!target) return
    setLoading(true)
    const load = async () => {
      try {
        let res: any
        if (target.type === 'dept')     res = await merchantPortalApi.deptMenuGet(target.id)
        if (target.type === 'position') res = await merchantPortalApi.positionMenuGet(target.id)
        if (target.type === 'staff')    res = await merchantPortalApi.staffMenuGet(target.id)
        const keys: string[] = res?.data?.data ?? []
        setSelected(keys)
        setIsCustom(keys.length > 0)
      } finally { setLoading(false) }
    }
    load()
  }, [target])

  const toggleKey = (key: string) => {
    setSelected(prev => prev.includes(key) ? prev.filter(k => k !== key) : [...prev, key])
  }

  const toggleGroup = (group: MenuGroup) => {
    const groupKeys = group.items.map(i => i.key)
    const allGroupOps = group.items.flatMap(i => (MENU_OPERATIONS[i.key] ?? []).map(op => op.code))
    const allKeys = [...groupKeys, ...allGroupOps]
    const allChecked = groupKeys.every(k => selected.includes(k))
    if (allChecked) {
      setSelected(prev => prev.filter(k => !allKeys.includes(k)))
    } else {
      setSelected(prev => Array.from(new Set([...prev, ...allKeys])))
    }
  }

  /** 切换菜单：取消时同步清除其所有操作权限码 */
  const toggleMenu = (key: string) => {
    const ops = (MENU_OPERATIONS[key] ?? []).map(op => op.code)
    if (selected.includes(key)) {
      setSelected(prev => prev.filter(k => k !== key && !ops.includes(k)))
    } else {
      setSelected(prev => [...prev, key])
    }
  }

  const selectAll = () => setSelected([...ALL_MENU_KEYS, ...ALL_OP_CODES])
  const clearAll  = () => setSelected([])

  const handleSave = async () => {
    if (!target) return
    setSaving(true)
    try {
      if (target.type === 'dept')     await merchantPortalApi.deptMenuSet(target.id, selected)
      if (target.type === 'position') await merchantPortalApi.positionMenuSet(target.id, selected)
      if (target.type === 'staff')    await merchantPortalApi.staffMenuSet(target.id, selected)
      message.success('权限保存成功！')
      onClose()
    } catch (e: any) {
      message.error(e?.response?.data?.message ?? '保存失败')
    } finally { setSaving(false) }
  }

  const typeGrad = target?.type === 'dept'
    ? 'linear-gradient(135deg,#667eea,#764ba2)'
    : target?.type === 'position'
      ? 'linear-gradient(135deg,#f093fb,#f5576c)'
      : 'linear-gradient(135deg,#4facfe,#00f2fe)'

  const typeName = target?.type === 'dept' ? '部门' : target?.type === 'position' ? '职位' : '员工'

  const breadcrumb = target?.type === 'staff'
    ? `${(target as any).deptName ?? ''} › ${(target as any).posName ?? ''} › ${target.name}`
    : target?.type === 'position'
      ? `${(target as any).deptName ?? ''} › ${target.name}`
      : target?.name ?? ''

  const selectedMenuCount = ALL_MENU_KEYS.filter(k => selected.includes(k)).length
  const selectedOpCount   = ALL_OP_CODES.filter(k => selected.includes(k)).length

  return (
    <Drawer
      open={open}
      onClose={onClose}
      title={
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <div style={{
            width: 42, height: 42, borderRadius: 10,
            background: 'rgba(255,255,255,0.22)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <LockOutlined style={{ color: '#fff', fontSize: 20 }} />
          </div>
          <div>
            <div style={{ color: '#fff', fontWeight: 800, fontSize: 16 }}>
              {typeName}权限分配
            </div>
            <div style={{ color: 'rgba(255,255,255,0.82)', fontSize: 12, marginTop: 2 }}>
              {breadcrumb}
            </div>
          </div>
        </div>
      }
      styles={{
        wrapper: { width: 660 },
        header:  { background: typeGrad, padding: '14px 20px' },
        body:    { padding: '16px 20px', background: '#fafbfe' },
      }}
      footer={
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '4px 0' }}>
          <Space wrap>
            <Tag color="blue">{selectedMenuCount} / {ALL_MENU_KEYS.length} 菜单</Tag>
            <Tag color="purple">{selectedOpCount} / {ALL_OP_CODES.length} 操作权限</Tag>
            {isCustom && <Tag color="orange">已自定义</Tag>}
          </Space>
          <Space>
            <Button onClick={onClose} style={{ borderRadius: 8 }}>取消</Button>
            <Button type="primary" loading={saving} icon={<SaveOutlined />} onClick={handleSave}
              style={{ background: typeGrad, border: 'none', borderRadius: 8, minWidth: 110 }}>
              保存权限
            </Button>
          </Space>
        </div>
      }
    >
      <Spin spinning={loading}>
        {/* ── 快捷操作 ── */}
        <div style={{
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          marginBottom: 14, padding: '10px 14px',
          background: '#fff', borderRadius: 10,
          boxShadow: '0 1px 6px rgba(0,0,0,0.06)',
        }}>
          <Space>
            <InfoCircleOutlined style={{ color: '#6366f1' }} />
            <span style={{ fontSize: 12, color: '#666' }}>
              {target?.type === 'dept'
                ? '部门权限为该部门下所有职位的默认权限基础'
                : target?.type === 'position'
                  ? '职位权限继承所属部门，此处可进一步限制'
                  : '员工权限继承所属职位，此处为个人专属覆盖'}
            </span>
          </Space>
          <Space>
            <Button size="small" onClick={selectAll}
              style={{ borderRadius: 6, color: '#6366f1', borderColor: '#e0e7ff', background: '#f5f3ff' }}>
              全选
            </Button>
            <Button size="small" onClick={clearAll}
              style={{ borderRadius: 6, color: '#dc2626', borderColor: '#fee2e2', background: '#fff5f5' }}>
              清空
            </Button>
          </Space>
        </div>

        {/* ── 菜单分组 ── */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {MENU_GROUPS.map(group => {
            const groupMenuKeys = group.items.map(i => i.key)
            const checkedCount  = groupMenuKeys.filter(k => selected.includes(k)).length
            const allChecked    = checkedCount === groupMenuKeys.length
            const partial       = checkedCount > 0 && !allChecked

            return (
              <div key={group.title} style={{
                background: '#fff', borderRadius: 12,
                border: `1px solid ${checkedCount > 0 ? group.color + '33' : '#f0f0f0'}`,
                overflow: 'hidden',
                boxShadow: checkedCount > 0 ? `0 2px 12px ${group.color}15` : '0 1px 4px rgba(0,0,0,0.04)',
                transition: 'all 0.2s',
              }}>
                {/* Group header */}
                <div style={{
                  display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                  padding: '10px 14px',
                  background: checkedCount > 0 ? group.bg : '#fafafa',
                  borderBottom: `1px solid ${group.color}22`,
                  cursor: 'pointer',
                }} onClick={() => toggleGroup(group)}>
                  <Space>
                    <div style={{
                      width: 28, height: 28, borderRadius: 7,
                      background: checkedCount > 0
                        ? `linear-gradient(135deg,${group.color},${group.color}cc)`
                        : '#e5e7eb',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      transition: 'all 0.2s',
                    }}>
                      <span style={{ color: checkedCount > 0 ? '#fff' : '#9ca3af', fontSize: 13 }}>
                        {group.icon}
                      </span>
                    </div>
                    <span style={{ fontWeight: 700, fontSize: 13, color: checkedCount > 0 ? group.color : '#6b7280' }}>
                      {group.title}
                    </span>
                    {checkedCount > 0 && (
                      <Badge count={checkedCount} style={{ backgroundColor: group.color }} />
                    )}
                  </Space>
                  <Checkbox
                    checked={allChecked}
                    indeterminate={partial}
                    onChange={() => toggleGroup(group)}
                    onClick={e => e.stopPropagation()}
                  />
                </div>

                {/* Menu items — full width rows */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: 0 }}>
                  {group.items.map((item, idx) => {
                    const menuChecked = selected.includes(item.key)
                    const ops         = MENU_OPERATIONS[item.key] ?? []
                    const inherited   = parentKeys?.includes(item.key) ?? true
                    const isLast      = idx === group.items.length - 1

                    return (
                      <div key={item.key} style={{
                        borderBottom: isLast ? 'none' : `1px solid ${item.color}11`,
                        background: menuChecked ? `${item.color}07` : 'transparent',
                        transition: 'all 0.15s',
                      }}>
                        {/* ── 菜单行 ── */}
                        <div
                          onClick={() => toggleMenu(item.key)}
                          style={{
                            display: 'flex', alignItems: 'center', gap: 8,
                            padding: '9px 14px', cursor: 'pointer', userSelect: 'none',
                          }}
                        >
                          <Checkbox
                            checked={menuChecked}
                            onChange={() => toggleMenu(item.key)}
                            onClick={e => e.stopPropagation()}
                          />
                          <div style={{
                            width: 26, height: 26, borderRadius: 6, flexShrink: 0,
                            background: menuChecked
                              ? `linear-gradient(135deg,${item.color},${item.color}cc)`
                              : '#e5e7eb',
                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                            transition: 'all 0.15s',
                          }}>
                            <span style={{ color: menuChecked ? '#fff' : '#9ca3af', fontSize: 12 }}>
                              {item.icon}
                            </span>
                          </div>
                          <span style={{
                            fontSize: 13, fontWeight: menuChecked ? 600 : 400,
                            color: menuChecked ? item.color : '#6b7280',
                            flex: 1, transition: 'all 0.15s',
                          }}>
                            {item.label}
                          </span>
                          {parentKeys && !inherited && (
                            <Tooltip title="父级未授权此菜单">
                              <span style={{ fontSize: 10, color: '#f59e0b' }}>⚠</span>
                            </Tooltip>
                          )}
                          {menuChecked && <CheckCircleOutlined style={{ color: item.color, fontSize: 12 }} />}
                        </div>

                        {/* ── 操作权限行（仅当有操作权限定义时显示）── */}
                        {ops.length > 0 && (
                          <div style={{
                            padding: '4px 14px 10px 48px',
                            display: 'flex', flexWrap: 'wrap', gap: 6,
                            opacity: menuChecked ? 1 : 0.35,
                            transition: 'opacity 0.2s',
                          }}>
                            <span style={{ fontSize: 11, color: '#9ca3af', marginRight: 2, lineHeight: '22px' }}>
                              操作：
                            </span>
                            {ops.map(op => {
                              const opChecked = menuChecked && selected.includes(op.code)
                              return (
                                <div
                                  key={op.code}
                                  onClick={e => {
                                    e.stopPropagation()
                                    if (!menuChecked) return
                                    toggleKey(op.code)
                                  }}
                                  style={{
                                    display: 'inline-flex', alignItems: 'center', gap: 3,
                                    padding: '2px 8px', borderRadius: 6, cursor: menuChecked ? 'pointer' : 'not-allowed',
                                    fontSize: 11, fontWeight: opChecked ? 600 : 400,
                                    border: `1px solid ${opChecked ? op.color + '80' : '#e5e7eb'}`,
                                    background: opChecked ? `${op.color}15` : '#f9fafb',
                                    color: opChecked ? op.color : '#9ca3af',
                                    transition: 'all 0.15s',
                                    userSelect: 'none',
                                  }}
                                >
                                  <span style={{ fontSize: 10 }}>{op.icon}</span>
                                  {op.label}
                                </div>
                              )
                            })}
                          </div>
                        )}
                      </div>
                    )
                  })}
                </div>
              </div>
            )
          })}
        </div>

        {/* ── 摘要统计 ── */}
        <Divider style={{ margin: '16px 0 10px' }} />
        <div style={{ fontSize: 12, color: '#888', textAlign: 'center' }}>
          已选 <strong style={{ color: '#6366f1' }}>{selectedMenuCount}</strong> 个菜单，
          <strong style={{ color: '#8b5cf6' }}>{selectedOpCount}</strong> 个操作权限
        </div>
      </Spin>
    </Drawer>
  )
}
