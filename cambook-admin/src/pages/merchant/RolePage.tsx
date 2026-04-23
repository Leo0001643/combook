/**
 * 商户端 - 权限体系管理
 *
 * 完整功能页：展示部门 → 职位两级权限架构，支持对任意节点配置菜单 + 操作权限。
 */
import { useEffect, useState } from 'react'
import {
  Button, Space, Tag, Typography, Spin,
  Empty, Collapse, Tooltip, Row, Col,
} from 'antd'
import {
  ApartmentOutlined, SolutionOutlined,
  UnlockOutlined, EditOutlined,
  TeamOutlined, CheckCircleOutlined, InfoCircleOutlined,
  SafetyCertificateOutlined, SettingOutlined, ReloadOutlined,
} from '@ant-design/icons'
import PermDrawer, { type PermTarget, MENU_GROUPS, MENU_OPERATIONS } from '../../components/merchant/PermDrawer'
import { merchantPortalApi } from '../../api/api'
import PermGuard from '../../components/common/PermGuard'

const { Text, Title } = Typography

const PAGE_GRADIENT = 'linear-gradient(135deg,#7c3aed,#a78bfa)'

const ALL_MENU_KEYS = MENU_GROUPS.flatMap(g => g.items.map(i => i.key))
const ALL_OP_CODES  = Object.values(MENU_OPERATIONS).flatMap(ops => ops.map(op => op.code))

interface Dept {
  id: number
  name: string
  status: number
  remark?: string
}

interface Position {
  id: number
  name: string
  deptId: number
  deptName?: string
  fullAccess?: number
  status: number
}

interface PermSummary {
  menuCount: number
  opCount: number
  isFullAccess: boolean
}

function usePermSummary(keys: string[]): PermSummary {
  const menuCount    = ALL_MENU_KEYS.filter(k => keys.includes(k)).length
  const opCount      = ALL_OP_CODES.filter(k => keys.includes(k)).length
  const isFullAccess = keys.length === 0 // 未配置 = 继承/全量
  return { menuCount, opCount, isFullAccess }
}

export default function MerchantRolePage() {
  const [depts, setDepts]             = useState<Dept[]>([])
  const [positions, setPositions]     = useState<Position[]>([])
  const [deptKeys, setDeptKeys]       = useState<Record<number, string[]>>({})
  const [posKeys, setPosKeys]         = useState<Record<number, string[]>>({})
  const [loading, setLoading]         = useState(false)
  const [keysLoading, setKeysLoading] = useState(false)
  const [drawerTarget, setDrawerTarget] = useState<PermTarget | null>(null)
  const [activeKeys, setActiveKeys]   = useState<string[]>([])

  const loadData = async () => {
    setLoading(true)
    try {
      const [deptRes, posRes] = await Promise.all([
        merchantPortalApi.deptList(),
        merchantPortalApi.positionList(),
      ])
      const deptList: Dept[]     = deptRes.data?.data ?? []
      const posList: Position[]  = posRes.data?.data ?? []
      setDepts(deptList.filter(d => d.status === 1))
      setPositions(posList)
    } finally {
      setLoading(false)
    }
  }

  const loadPermKeys = async (deptList: Dept[], posList: Position[]) => {
    if (!deptList.length && !posList.length) return
    setKeysLoading(true)
    try {
      const deptResults = await Promise.all(
        deptList.map(d =>
          merchantPortalApi.deptMenuGet(d.id)
            .then(r => ({ id: d.id, keys: r.data?.data ?? [] }))
            .catch(() => ({ id: d.id, keys: [] }))
        )
      )
      const posResults = await Promise.all(
        posList.map(p =>
          merchantPortalApi.positionMenuGet(p.id)
            .then(r => ({ id: p.id, keys: r.data?.data ?? [] }))
            .catch(() => ({ id: p.id, keys: [] }))
        )
      )
      setDeptKeys(Object.fromEntries(deptResults.map(r => [r.id, r.keys])))
      setPosKeys(Object.fromEntries(posResults.map(r => [r.id, r.keys])))
    } finally {
      setKeysLoading(false)
    }
  }

  useEffect(() => { loadData() }, [])
  useEffect(() => {
    if (depts.length > 0 || positions.length > 0) {
      loadPermKeys(depts, positions)
    }
  }, [depts, positions])

  const handlePermSaved = () => {
    loadPermKeys(depts, positions)
  }

  const openPerm = (target: PermTarget) => {
    setDrawerTarget(target)
  }

  return (
    <div style={{ marginTop: -24 }}>
      <div style={{ position: 'sticky', top: 64, zIndex: 88, marginLeft: -24, marginRight: -24, background: 'rgba(255,255,255,0.97)', backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)', borderBottom: '1px solid rgba(0,0,0,0.07)', boxShadow: '0 4px 20px rgba(0,0,0,0.06)' }}>
        {/* 第一行：图标 + 标题 + 四项统计徽章 + 刷新 */}
        <div style={{ display: 'flex', alignItems: 'center', padding: '10px 24px 0', gap: 12 }}>
          <div style={{ width: 34, height: 34, borderRadius: 10, background: PAGE_GRADIENT, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 4px 12px rgba(124,58,237,0.35)', flexShrink: 0 }}>
            <SafetyCertificateOutlined style={{ color: '#fff', fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1e293b', lineHeight: 1.2 }}>权限体系</div>
            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>管理商户权限 · 按部门职位分配</div>
          </div>
          <div style={{ width: 1, height: 20, margin: '0 4px', background: '#e9d5ff', flexShrink: 0 }} />
          {/* 四项统计徽章 */}
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            {[
              { label: '可分配菜单', value: ALL_MENU_KEYS.length, color: '#6366f1', bg: 'rgba(99,102,241,0.08)',   border: 'rgba(99,102,241,0.22)' },
              { label: '操作权限数', value: ALL_OP_CODES.length,  color: '#8b5cf6', bg: 'rgba(139,92,246,0.08)',  border: 'rgba(139,92,246,0.22)' },
              { label: '已启用部门', value: depts.length,          color: '#0ea5e9', bg: 'rgba(14,165,233,0.08)',  border: 'rgba(14,165,233,0.22)' },
              { label: '职位总数',   value: positions.length,      color: '#10b981', bg: 'rgba(16,185,129,0.08)',  border: 'rgba(16,185,129,0.22)' },
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
          <Tooltip title="刷新权限数据">
            <Button icon={<ReloadOutlined />} size="middle" loading={keysLoading} style={{ borderRadius: 8, color: '#7c3aed', borderColor: '#e9d5ff' }} onClick={() => loadPermKeys(depts, positions)} />
          </Tooltip>
        </div>
        {/* 第二行：权限继承链说明（内联紧凑版） */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '8px 24px 10px', flexWrap: 'wrap' }}>
          <InfoCircleOutlined style={{ color: '#a78bfa', fontSize: 13, flexShrink: 0 }} />
          <Text style={{ fontSize: 12, color: '#6b7280' }}>
            权限按
          </Text>
          <Tag color="purple"  style={{ margin: 0, fontSize: 11, padding: '0 6px' }}>部门</Tag>
          <Text style={{ fontSize: 12, color: '#94a3b8' }}>→</Text>
          <Tag color="blue"    style={{ margin: 0, fontSize: 11, padding: '0 6px' }}>职位</Tag>
          <Text style={{ fontSize: 12, color: '#94a3b8' }}>→</Text>
          <Tag color="cyan"    style={{ margin: 0, fontSize: 11, padding: '0 6px' }}>员工</Tag>
          <Text style={{ fontSize: 12, color: '#6b7280' }}>逐级继承，支持</Text>
          <Tag color="orange"  style={{ margin: 0, fontSize: 11, padding: '0 6px' }}>菜单权限</Tag>
          <Text style={{ fontSize: 12, color: '#6b7280' }}>和</Text>
          <Tag color="red"     style={{ margin: 0, fontSize: 11, padding: '0 6px' }}>操作权限</Tag>
          <Text style={{ fontSize: 12, color: '#6b7280' }}>独立配置，下级未配置时自动继承上级。</Text>
        </div>
      </div>

      <div style={{ marginLeft: -24, marginRight: -24, marginBottom: -24, background: '#f8fafc', padding: 24 }}>
        {/* ── 部门列表 ── */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
          <Title level={5} style={{ margin: 0 }}>
            <ApartmentOutlined style={{ color: '#7c3aed', marginRight: 6 }} />
            部门权限配置
          </Title>
        </div>

        <Spin spinning={loading || keysLoading}>
          {depts.length === 0 ? (
            <Empty description="暂无部门数据，请先在部门管理中创建部门" />
          ) : (
            <Collapse
              activeKey={activeKeys}
              onChange={keys => setActiveKeys(keys as string[])}
              style={{ background: 'transparent', border: 'none' }}
              items={depts.map(dept => {
                const keys     = deptKeys[dept.id] ?? []
                const summary  = usePermSummary(keys)
                const deptPos  = positions.filter(p => p.deptId === dept.id)

                return {
                  key: String(dept.id),
                  style: {
                    marginBottom: 10, borderRadius: 12, overflow: 'hidden',
                    border: '1px solid #e5e7eb',
                    boxShadow: '0 1px 6px rgba(0,0,0,0.04)',
                  },
                  label: (
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', width: '100%' }}>
                      <Space size={10}>
                        <div style={{
                          width: 34, height: 34, borderRadius: 9,
                          background: 'linear-gradient(135deg,#667eea,#764ba2)',
                          display: 'flex', alignItems: 'center', justifyContent: 'center',
                        }}>
                          <ApartmentOutlined style={{ color: '#fff', fontSize: 16 }} />
                        </div>
                        <div>
                          <div style={{ fontWeight: 700, fontSize: 14, color: '#1f2937' }}>{dept.name}</div>
                          <div style={{ fontSize: 11, color: '#9ca3af', marginTop: 1 }}>
                            {deptPos.length} 个职位
                          </div>
                        </div>
                        <DeptPermBadge summary={summary} keysLength={keys.length} />
                      </Space>
                      <PermGuard code={['dept:edit', 'dept:add']}>
                        <Button
                          size="small"
                          icon={<SettingOutlined />}
                          onClick={e => { e.stopPropagation(); openPerm({ type: 'dept', id: dept.id, name: dept.name }) }}
                          style={{ borderRadius: 7, borderColor: '#e0e7ff', color: '#6366f1', background: '#f5f3ff' }}
                        >
                          配置权限
                        </Button>
                      </PermGuard>
                    </div>
                  ),
                  children: (
                    <div style={{ padding: '4px 0' }}>
                      {deptPos.length === 0 ? (
                        <div style={{ textAlign: 'center', padding: '20px 0', color: '#9ca3af', fontSize: 13 }}>
                          该部门暂无职位
                        </div>
                      ) : (
                        <Row gutter={[10, 10]}>
                          {deptPos.map(pos => {
                            const pkeys   = posKeys[pos.id] ?? []
                            const psummary = usePermSummary(pkeys)
                            return (
                              <Col key={pos.id} xs={24} sm={12} md={8}>
                                <PositionCard
                                  pos={pos}
                                  keys={pkeys}
                                  summary={psummary}
                                  parentKeys={keys}
                                  onConfig={() => openPerm({
                                    type: 'position',
                                    id: pos.id,
                                    name: pos.name,
                                    deptName: dept.name,
                                  })}
                                />
                              </Col>
                            )
                          })}
                        </Row>
                      )}
                    </div>
                  ),
                }
              })}
            />
          )}
        </Spin>

      </div>

      {/* ── 权限分配抽屉 ── */}
      <PermDrawer
        target={drawerTarget}
        onClose={() => {
          setDrawerTarget(null)
          handlePermSaved()
        }}
      />
    </div>
  )
}

// ── 子组件 ──────────────────────────────────────────────────────────────────────

function DeptPermBadge({ summary, keysLength }: { summary: PermSummary; keysLength: number }) {
  if (keysLength === 0) {
    return <Tag color="default" icon={<UnlockOutlined />}>全量继承</Tag>
  }
  return (
    <Space size={4}>
      <Tag color="purple" style={{ fontSize: 11 }}>{summary.menuCount} 菜单</Tag>
      {summary.opCount > 0 && <Tag color="orange" style={{ fontSize: 11 }}>{summary.opCount} 操作</Tag>}
    </Space>
  )
}

interface PositionCardProps {
  pos: Position
  keys: string[]
  summary: PermSummary
  parentKeys: string[]
  onConfig: () => void
}

function PositionCard({ pos, keys, summary, onConfig }: PositionCardProps) {
  const isFullAccess = pos.fullAccess === 1
  const isCustom     = keys.length > 0 && !isFullAccess

  return (
    <div style={{
      padding: '12px 14px', borderRadius: 10,
      border: '1px solid #e5e7eb',
      background: isFullAccess ? 'linear-gradient(135deg,#f0fdf4,#dcfce7)' : '#fff',
      transition: 'all 0.2s',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
        <Space size={8}>
          <div style={{
            width: 28, height: 28, borderRadius: 7,
            background: isFullAccess
              ? 'linear-gradient(135deg,#10b981,#059669)'
              : 'linear-gradient(135deg,#3b82f6,#2563eb)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <SolutionOutlined style={{ color: '#fff', fontSize: 13 }} />
          </div>
          <span style={{ fontWeight: 600, fontSize: 13, color: '#1f2937' }}>{pos.name}</span>
        </Space>
        {isFullAccess && (
          <Tooltip title="该职位拥有全量权限">
            <SafetyCertificateOutlined style={{ color: '#10b981', fontSize: 16 }} />
          </Tooltip>
        )}
      </div>

      {/* 权限统计 */}
      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 10 }}>
        {isFullAccess ? (
          <Tag color="success" icon={<CheckCircleOutlined />}>全量权限</Tag>
        ) : isCustom ? (
          <>
            <Tag color="blue" style={{ fontSize: 11 }}>{summary.menuCount} 菜单</Tag>
            {summary.opCount > 0 && <Tag color="orange" style={{ fontSize: 11 }}>{summary.opCount} 操作</Tag>}
            <Tag color="cyan" style={{ fontSize: 11 }}>已自定义</Tag>
          </>
        ) : (
          <Tag color="default" icon={<TeamOutlined />} style={{ fontSize: 11 }}>继承部门</Tag>
        )}
      </div>

      <PermGuard code={['position:edit', 'position:add']}>
        <Button
          size="small"
          icon={<EditOutlined />}
          onClick={onConfig}
          disabled={isFullAccess}
          style={{ borderRadius: 7, width: '100%', fontSize: 12 }}
        >
          {isFullAccess ? '全量权限无需配置' : '配置权限'}
        </Button>
      </PermGuard>
    </div>
  )
}
