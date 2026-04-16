import { useState, useEffect } from 'react'
import {
  Table, Input, Select, Space, Tag, Avatar,
  Button, Typography, message, Badge,
  Tooltip,
} from 'antd'
import DateTimeRangePicker from '../../components/common/DateTimeRangePicker'
import type { ColumnsType } from 'antd/es/table'
import {
  SearchOutlined, UserOutlined, StopOutlined, CheckCircleOutlined,
  EyeOutlined, ReloadOutlined, TeamOutlined,
  PhoneOutlined,   CalendarOutlined, ShoppingOutlined, DollarOutlined,
  ManOutlined, WomanOutlined, StarOutlined,
  CrownOutlined, GlobalOutlined, EnvironmentOutlined,
  WalletOutlined, SafetyCertificateOutlined,
  ClockCircleOutlined, SettingOutlined,
} from '@ant-design/icons'
import dayjs from 'dayjs'
import type { Dayjs } from 'dayjs'
import { usePortalScope } from '../../hooks/usePortalScope'
import PermGuard from '../../components/common/PermGuard'
import ContactCell from '../../components/common/ContactCell'
import ContactFilter, { type ContactFilterType } from '../../components/common/ContactFilter'
import MemberDetailDrawer, { type MemberDetailVO } from '../../components/common/MemberDetailDrawer'
import DangerModal from '../../components/common/DangerModal'
import { styledTableComponents, col as colHelper } from '../../components/common/tableComponents'
import PagePagination from '../../components/common/PagePagination'
import { useTableBodyHeight } from '../../hooks/useTableBodyHeight'

const { Text } = Typography
const { Option } = Select
// MemberVO 使用统一的 MemberDetailVO 类型，额外加上 wechat 字段
type MemberVO = MemberDetailVO

const LEVEL_CFG: Record<number, { label: string; color: string; bg: string }> = {
  0: { label: '普通', color: '#9ca3af', bg: '#f9fafb' },
  1: { label: '银牌', color: '#6b7280', bg: '#f3f4f6' },
  2: { label: '金牌', color: '#d97706', bg: '#fffbeb' },
  3: { label: '铂金', color: '#7c3aed', bg: '#f5f3ff' },
  4: { label: '钻石', color: '#0891b2', bg: '#ecfeff' },
}

const LANG_FLAG: Record<string, { flag: string; label: string }> = {
  zh: { flag: '🇨🇳', label: '中文' },
  km: { flag: '🇰🇭', label: 'Khmer' },
  vi: { flag: '🇻🇳', label: 'Tiếng Việt' },
  en: { flag: '🇬🇧', label: 'English' },
}

const STATUS_MAP: Record<number, { badge: 'success' | 'error' | 'warning'; color: string; label: string }> = {
  1: { badge: 'success', color: '#10b981', label: '正常'  },
  2: { badge: 'error',   color: '#ef4444', label: '已封禁' },
  3: { badge: 'warning', color: '#f59e0b', label: '注销中' },
}

const INPUT_STYLE: React.CSSProperties = {
  borderRadius: 8,
  background: '#f5f7fa',
  border: '1px solid #eaecf0',
  fontSize: 13,
}

const col = colHelper  // shared column title helper

export default function UserListPage() {
  const { ref, height: tableBodyH } = useTableBodyHeight()
  const { isAdmin, memberList, memberUpdateStatus } = usePortalScope()

  const [loading,      setLoading]      = useState(false)
  const [data,         setData]         = useState<MemberVO[]>([])
  const [total,        setTotal]        = useState(0)
  const [page,         setPage]         = useState(1)
  const [keyword,      setKeyword]      = useState('')
  const [status,       setStatus]       = useState<number | undefined>()
  const [level,        setLevel]        = useState<number | undefined>()
  const [gender,       setGender]       = useState<number | undefined>()
  const [lang,         setLang]         = useState<string | undefined>()
  const [contactType,  setContactType]  = useState<ContactFilterType>('telegram')
  const [contactValue, setContactValue] = useState('')
  const [address,      setAddress]      = useState('')
  const [dateRange,    setDateRange]    = useState<[Dayjs, Dayjs] | null>(null)
  const [pageSize,     setPageSize]     = useState(20)

  // 详情抽屉
  const [detail,     setDetail]     = useState<MemberVO | null>(null)
  const [drawerOpen, setDrawer]     = useState(false)

  // 封禁/解封确认弹窗
  const [banTarget,  setBanTarget]  = useState<MemberVO | null>(null)
  const [banLoading, setBanLoading] = useState(false)

  useEffect(() => { fetchList() }, [page, pageSize, keyword, status, level, gender, lang, contactType, contactValue, address, dateRange])

  /** 所有过滤条件均由后端处理，不做客户端二次过滤 */
  const fetchList = async () => {
    setLoading(true)
    try {
      const res = await memberList({
        page,
        size:      pageSize,
        keyword:   keyword   || undefined,
        status,
        gender,
        level,
        lang,
        telegram:  (contactType === 'telegram' && contactValue) ? contactValue : undefined,
        address:   address   || undefined,
        startDate: dateRange?.[0]?.format('YYYY-MM-DD HH:mm:ss'),
        endDate:   dateRange?.[1]?.format('YYYY-MM-DD HH:mm:ss'),
      })
      const d = res.data?.data
      setData(d?.list ?? [])
      setTotal(d?.total ?? 0)
    } catch { setData([]) } finally { setLoading(false) }
  }

  const handleReset = () => {
    setKeyword(''); setStatus(undefined); setLevel(undefined)
    setGender(undefined); setLang(undefined)
    setContactType('telegram'); setContactValue('')
    setAddress(''); setDateRange(null); setPage(1)
  }

  const handleBanConfirm = async () => {
    if (!banTarget) return
    setBanLoading(true)
    try {
      const next = banTarget.status === 1 ? 2 : 1
      await memberUpdateStatus(banTarget.id, next)
      message.success(next === 2 ? '封禁成功' : '解封成功')
      setBanTarget(null)
      fetchList()
    } finally {
      setBanLoading(false)
    }
  }

  // ── 统计数据 ───────────────────────────────────────────────────────────────
  const stats = [
    { label: '注册会员', value: total,                                                            color: '#6366f1', bg: 'rgba(99,102,241,0.1)',  border: 'rgba(99,102,241,0.25)',  icon: '👥' },
    { label: '活跃',     value: data.filter(d => d.status === 1).length,                         color: '#10b981', bg: 'rgba(16,185,129,0.1)',  border: 'rgba(16,185,129,0.25)',  icon: '🟢' },
    { label: '已封禁',   value: data.filter(d => d.status !== 1).length,                         color: '#ef4444', bg: 'rgba(239,68,68,0.1)',   border: 'rgba(239,68,68,0.25)',   icon: '🔴' },
    { label: '近7天新增', value: data.filter(d => dayjs(d.createdAt).isAfter(dayjs().subtract(7,'day'))).length, color: '#f59e0b', bg: 'rgba(245,158,11,0.1)', border: 'rgba(245,158,11,0.25)', icon: '🆕' },
  ]

  const columns: ColumnsType<MemberVO> = [
    {
      title: col(<UserOutlined style={{ color: '#6366f1' }} />, '会员信息', 'left'),
      key: 'info', width: 185, fixed: 'left', align: 'left',
      render: (_, r) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, width: '100%' }}>
          <Avatar
            src={r.avatar || undefined} size={40} icon={<UserOutlined />}
            style={{ background: `linear-gradient(135deg,${r.gender === 2 ? '#f093fb,#f5576c' : '#4facfe,#00f2fe'})`, flexShrink: 0 }}
          />
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
              <Text strong style={{ fontSize: 13 }}>{r.nickname}</Text>
              {r.gender === 1
                ? <ManOutlined style={{ color: '#3b82f6', fontSize: 11 }} />
                : <WomanOutlined style={{ color: '#ec4899', fontSize: 11 }} />}
            </div>
            <div style={{ fontSize: 11, color: '#9ca3af', marginTop: 1 }}>
              <PhoneOutlined style={{ marginRight: 3 }} />{r.mobile}
            </div>
          </div>
        </div>
      ),
    },
    {
      title: col(<PhoneOutlined style={{ color: '#3b82f6' }} />, '联系方式'),
      key: 'contact', width: 158, align: 'center',
      render: (_, r) => (
        <ContactCell mobile={r.mobile} telegram={r.telegram} wechat={r.wechat} />
      ),
    },
    {
      title: col(<CrownOutlined style={{ color: '#d97706' }} />, '会员等级'),
      dataIndex: 'level', width: 82, align: 'center',
      render: (v: number) => {
        const cfg = LEVEL_CFG[v] ?? LEVEL_CFG[0]
        return (
          <Tag icon={<CrownOutlined />} style={{
            borderRadius: 20, padding: '2px 8px',
            background: cfg.bg, border: `1px solid ${cfg.color}40`,
            color: cfg.color, fontWeight: 600, fontSize: 12,
          }}>{cfg.label}</Tag>
        )
      },
    },
    {
      title: col(<StarOutlined style={{ color: '#f59e0b' }} />, '积分'),
      dataIndex: 'points', width: 78, align: 'center',
      sorter: (a, b) => a.points - b.points,
      render: (v: number) => (
        <Space size={3}>
          <StarOutlined style={{ color: '#f59e0b', fontSize: 12 }} />
          <Text strong style={{ fontSize: 12 }}>{(v ?? 0).toLocaleString()}</Text>
        </Space>
      ),
    },
    {
      title: col(<WalletOutlined style={{ color: '#10b981' }} />, '钱包余额'),
      dataIndex: 'balance', width: 86, align: 'center',
      sorter: (a, b) => (a.balance ?? 0) - (b.balance ?? 0),
      render: (v: number) => (
        <Text strong style={{ color: '#10b981', fontSize: 12 }}>
          <DollarOutlined style={{ marginRight: 2 }} />{(v ?? 0).toFixed(2)}
        </Text>
      ),
    },
    {
      title: col(<DollarOutlined style={{ color: '#6366f1' }} />, '累计消费'),
      dataIndex: 'totalAmount', width: 86, align: 'center',
      sorter: (a, b) => (a.totalAmount ?? 0) - (b.totalAmount ?? 0),
      render: (v: number) => (
        <Text strong style={{ color: '#6366f1', fontSize: 12 }}>${(v ?? 0).toFixed(2)}</Text>
      ),
    },
    {
      title: col(<ShoppingOutlined style={{ color: '#3b82f6' }} />, '订单数'),
      dataIndex: 'orderCount', width: 68, align: 'center',
      sorter: (a, b) => (a.orderCount ?? 0) - (b.orderCount ?? 0),
      render: (v: number) => (
        <Space size={4}>
          <ShoppingOutlined style={{ color: '#3b82f6' }} />
          <Text strong style={{ fontSize: 12 }}>{v ?? 0}</Text>
        </Space>
      ),
    },
    {
      title: col(<GlobalOutlined style={{ color: '#0891b2' }} />, '语言'),
      dataIndex: 'lang', width: 76, align: 'center',
      render: (v: string) => {
        const cfg = LANG_FLAG[v] ?? { flag: '🌐', label: v }
        return (
          <Space size={4}>
            <span style={{ fontSize: 15 }}>{cfg.flag}</span>
            <Text style={{ fontSize: 12 }}>{cfg.label}</Text>
          </Space>
        )
      },
    },
    {
      title: col(<SafetyCertificateOutlined style={{ color: '#10b981' }} />, '状态'),
      dataIndex: 'status', width: 72, align: 'center',
      render: (v: number) => {
        const s = STATUS_MAP[v] ?? STATUS_MAP[2]
        return (
          <Badge status={s.badge} text={
            <Text style={{ color: s.color, fontSize: 12, fontWeight: 600 }}>{s.label}</Text>
          } />
        )
      },
    },
    {
      title: col(<ClockCircleOutlined style={{ color: '#9ca3af' }} />, '注册时间'),
      dataIndex: 'createdAt', width: 100, align: 'center',
      render: (v: string) => (
        <Text type="secondary" style={{ fontSize: 11 }}>
          <CalendarOutlined style={{ marginRight: 4, color: '#d1d5db' }} />
          {dayjs(v).format('YYYY-MM-DD')}
        </Text>
      ),
    },
    {
      title: col(<EnvironmentOutlined style={{ color: '#f59e0b' }} />, '会员地址'),
      dataIndex: 'address', width: 160, align: 'left',
      render: (v: string) => v
        ? (
          <Space size={5}>
            <EnvironmentOutlined style={{ color: '#f59e0b', fontSize: 11, flexShrink: 0 }} />
            <Text style={{ fontSize: 12, color: '#374151' }} ellipsis={{ tooltip: v }}>{v}</Text>
          </Space>
        )
        : <Text type="secondary" style={{ fontSize: 11 }}>—</Text>,
    },
    {
      title: col(<SettingOutlined style={{ color: '#6b7280' }} />, '操作'),
      key: 'action', fixed: 'right', width: 118, align: 'center',
      render: (_, r) => (
        <Space size={4}>
          <Button size="small" type="primary" ghost icon={<EyeOutlined />}
            style={{ borderRadius: 6, fontSize: 12 }}
            onClick={() => { setDetail(r); setDrawer(true) }}>查看</Button>
          {isAdmin && (
            r.status === 1 ? (
              <PermGuard code="member:ban">
                <Button size="small" icon={<StopOutlined />}
                  style={{ borderRadius: 6, fontSize: 12, color: '#ff4d4f', borderColor: '#ffa39e' }}
                  onClick={() => setBanTarget(r)}>封禁</Button>
              </PermGuard>
            ) : (
              <PermGuard code="member:ban">
                <Button size="small" icon={<CheckCircleOutlined />}
                  style={{ borderRadius: 6, fontSize: 12, color: '#52c41a', borderColor: '#b7eb8f' }}
                  onClick={() => setBanTarget(r)}>解封</Button>
              </PermGuard>
            )
          )}
        </Space>
      ),
    },
  ]

  const isBanning  = banTarget?.status === 1
  const banVariant = isBanning ? 'ban' : 'unban'

  return (
    <div style={{ marginTop: -24 }}>

      {/*
       * ═══════════════════════════════════════════════════════════════════════
       *  粘性复合头部：页面标题栏 + 筛选栏
       * ═══════════════════════════════════════════════════════════════════════
       */}
      <div style={{
        position: 'sticky', top: 64, zIndex: 88,
        marginLeft: -24, marginRight: -24, marginBottom: 0,
        background: 'rgba(255,255,255,0.97)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderBottom: '1px solid rgba(0,0,0,0.07)',
        boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
      }}>

        {/* ── 第一行：页面标题 + 统计徽章 ────────────────────────────────── */}
        <div style={{ display: 'flex', alignItems: 'center', padding: '10px 24px 0', gap: 16 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, flex: '0 0 auto' }}>
            <div style={{
              width: 34, height: 34, borderRadius: 10,
              background: 'linear-gradient(135deg,#6366f1,#8b5cf6)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: '0 4px 12px rgba(99,102,241,0.35)', flexShrink: 0,
            }}>
              <TeamOutlined style={{ color: '#fff', fontSize: 16 }} />
            </div>
            <div>
              <div style={{ fontWeight: 700, fontSize: 15, color: '#111827', lineHeight: 1.2 }}>会员管理</div>
              <div style={{ fontSize: 11, color: '#9ca3af', lineHeight: 1.3, marginTop: 1 }}>
                {isAdmin ? '管理平台注册会员 · 查看消费记录 · 封禁解封' : '查看在您商户消费过的会员 · 消费记录'}
              </div>
            </div>
          </div>

          <div style={{ width: 1, height: 28, margin: '0 4px', background: '#e5e7eb', flexShrink: 0 }} />

          <div style={{ display: 'flex', gap: 8, flex: 1, flexWrap: 'wrap', alignItems: 'center' }}>
            {stats.map(s => (
              <div key={s.label} style={{
                display: 'flex', alignItems: 'center', gap: 6,
                padding: '5px 12px', borderRadius: 20,
                background: s.bg, border: `1px solid ${s.border}`,
              }}>
                <span style={{ fontSize: 12 }}>{s.icon}</span>
                <Text style={{ color: s.color, fontWeight: 700, fontSize: 13, lineHeight: 1 }}>{s.value}</Text>
                <Text style={{ color: s.color, fontSize: 11, opacity: 0.8 }}>{s.label}</Text>
              </div>
            ))}
          </div>
        </div>

        {/* ── 第二行：筛选条件 ──────────────────────────────────────────── */}
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', padding: '10px 24px 12px' }}>
          {/* 手机号/昵称 */}
          <Input
            placeholder="手机号 / 昵称"
            prefix={<SearchOutlined style={{ color: '#6366f1', fontSize: 12 }} />}
            allowClear size="middle"
            style={{ ...INPUT_STYLE, width: 172 }}
            value={keyword}
            onChange={e => { setKeyword(e.target.value); if (!e.target.value) setPage(1) }}
            onPressEnter={() => setPage(1)}
          />

          {/* 联系方式单框筛选（前缀 ICON 点击切换 Telegram / 微信） */}
          <ContactFilter
            contactType={contactType}
            value={contactValue}
            onTypeChange={t => { setContactType(t); setContactValue(''); setPage(1) }}
            onChange={v => setContactValue(v)}
            onSearch={() => setPage(1)}
            style={INPUT_STYLE}
          />

          {/* 地址模糊查询 */}
          <Input
            placeholder="地址查询"
            prefix={<EnvironmentOutlined style={{ color: '#f59e0b', fontSize: 12 }} />}
            allowClear size="middle"
            style={{ ...INPUT_STYLE, width: 140 }}
            value={address}
            onChange={e => { setAddress(e.target.value); if (!e.target.value) setPage(1) }}
            onPressEnter={() => setPage(1)}
          />

          <div style={{ width: 1, height: 22, margin: '0 2px', background: '#e5e7eb', flexShrink: 0 }} />

          {/* 账号状态 */}
          <Select placeholder={<Space size={4}><SafetyCertificateOutlined style={{ color: '#6366f1', fontSize: 12 }} />账号状态</Space>} allowClear size="middle"
            style={{ width: 115 }} value={status}
            onChange={v => { setStatus(v); setPage(1) }}
          >
            <Option value={1}><Space size={4}><CheckCircleOutlined style={{ color: '#10b981' }} />正常</Space></Option>
            <Option value={2}><Space size={4}><StopOutlined style={{ color: '#ef4444' }} />已封禁</Space></Option>
            <Option value={3}><Space size={4}><ClockCircleOutlined style={{ color: '#f59e0b' }} />注销中</Space></Option>
          </Select>

          {/* 会员等级 */}
          <Select placeholder={<Space size={4}><CrownOutlined style={{ color: '#d97706', fontSize: 12 }} />会员等级</Space>} allowClear size="middle"
            style={{ width: 115 }} value={level}
            onChange={v => { setLevel(v); setPage(1) }}
          >
            {Object.entries(LEVEL_CFG).map(([k, v]) => (
              <Option key={k} value={Number(k)}>
                <Tag color={v.color} style={{ margin: 0, borderRadius: 20, fontSize: 11 }}>{v.label}</Tag>
              </Option>
            ))}
          </Select>

          {/* 性别 */}
          <Select placeholder={<Space size={4}><UserOutlined style={{ color: '#ec4899', fontSize: 12 }} />性别</Space>} allowClear size="middle"
            style={{ width: 90 }} value={gender}
            onChange={v => { setGender(v); setPage(1) }}
          >
            <Option value={1}><Space size={4}><ManOutlined style={{ color: '#3b82f6' }} />男</Space></Option>
            <Option value={2}><Space size={4}><WomanOutlined style={{ color: '#ec4899' }} />女</Space></Option>
          </Select>

          {/* 语言 */}
          <Select placeholder={<Space size={4}><GlobalOutlined style={{ color: '#0891b2', fontSize: 12 }} />语言</Space>} allowClear size="middle"
            style={{ width: 90 }} value={lang}
            onChange={v => { setLang(v); setPage(1) }}
          >
            {Object.entries(LANG_FLAG).map(([k, v]) => (
              <Option key={k} value={k}>{v.flag} {v.label}</Option>
            ))}
          </Select>

          <div style={{ width: 1, height: 22, margin: '0 2px', background: '#e5e7eb', flexShrink: 0 }} />

          {/* 注册时间区间 */}
          <DateTimeRangePicker
            placeholder={['注册开始时间', '注册结束时间']}
            value={dateRange}
            onChange={dates => { setDateRange(dates); setPage(1) }}
          />

          <div style={{ flex: 1 }} />

          <Button icon={<ReloadOutlined />} size="middle"
            style={{ borderRadius: 8, fontSize: 13 }}
            onClick={handleReset}
          >重置</Button>

          <Tooltip title="刷新列表">
            <Button icon={<ReloadOutlined />} size="middle" loading={loading}
              style={{ borderRadius: 8, color: '#6366f1', borderColor: '#c7d2fe' }}
              onClick={() => { setPage(1); fetchList() }}
            />
          </Tooltip>

          <Button
            type="primary" icon={<SearchOutlined />}
            style={{
              borderRadius: 8, border: 'none', fontSize: 13,
              background: 'linear-gradient(135deg,#6366f1,#8b5cf6)',
              boxShadow: '0 2px 8px rgba(99,102,241,0.35)',
            }}
            onClick={() => { setPage(1); fetchList() }}
          >搜索</Button>
        </div>
      </div>

      {/* ── 数据表格 ─────────────────────────────────────────────────────── */}
      <div ref={ref} style={{
        marginLeft: -24, marginRight: -24, marginBottom: -24,
        background: '#fff', borderTop: '1px solid #eef0f8',
        /* overflow:hidden 不能设置，否则会破坏 Ant Design sticky 固定列 */
      }}>
        <Table
          rowKey="id"
          dataSource={data}
          columns={columns}
          loading={loading}
          size="middle"
          scroll={{ x: 1440, y: tableBodyH }}
          pagination={false}
          components={styledTableComponents}
        />

        <PagePagination
          total={total} current={page} pageSize={pageSize}
          onChange={p => setPage(p)}
          onSizeChange={s => { setPageSize(s); setPage(1) }}
          countLabel="位会员"
        />
      </div>

      {/* ── 会员详情抽屉（全局组件） ──────────────────────────────────────── */}
      <MemberDetailDrawer
        open={drawerOpen}
        detail={detail}
        isAdmin={isAdmin}
        onClose={() => setDrawer(false)}
        onBanToggle={member => { setDrawer(false); setBanTarget(member) }}
      />

      {/* ── 封禁/解封确认弹窗（全局组件） ────────────────────────────────── */}
      <DangerModal
        open={!!banTarget}
        variant={banVariant}
        title={isBanning ? '确认封禁该会员账号？' : '确认解封该会员账号？'}
        description={banTarget && (
          <Space orientation="vertical" size={6} style={{ width: '100%' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <Avatar size={36} icon={<UserOutlined />}
                style={{ background: 'linear-gradient(135deg,#6366f1,#8b5cf6)', flexShrink: 0 }} />
              <div>
                <div style={{ fontWeight: 700, fontSize: 14, color: '#111827' }}>{banTarget.nickname}</div>
                <div style={{ fontSize: 12, color: '#9ca3af' }}>{banTarget.mobile}</div>
              </div>
            </div>
          </Space>
        )}
        warning={isBanning ? '封禁后该用户将无法登录和下单' : undefined}
        confirmText={isBanning ? '确认封禁' : '确认解封'}
        loading={banLoading}
        onConfirm={handleBanConfirm}
        onCancel={() => setBanTarget(null)}
      />
    </div>
  )
}
