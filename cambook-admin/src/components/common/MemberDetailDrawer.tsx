import {
  Drawer, Avatar, Tag, Progress, Space, Typography,
  Button, Badge, Divider, Grid,
} from 'antd'
import {
  UserOutlined, ManOutlined, WomanOutlined, CalendarOutlined,
  StarOutlined, WalletOutlined, ShoppingOutlined, GiftOutlined,
  CrownOutlined, GlobalOutlined, StopOutlined, CheckCircleOutlined,
  CloseOutlined, EnvironmentOutlined, SafetyCertificateOutlined,
  IdcardOutlined,
} from '@ant-design/icons'
import dayjs from 'dayjs'
import ContactCell from './ContactCell'

const { Text, Title } = Typography
const { useBreakpoint } = Grid

// ── 级别配置 ──────────────────────────────────────────────────────────────────
const LEVEL_CFG: Record<number, {
  label:    string
  color:    string
  gradient: string
  start:    string
  end:      string
  maxPts:   number   // 本级满分（升级所需积分）
}> = {
  0: { label: '普通', color: '#9ca3af', gradient: 'linear-gradient(135deg,#9ca3af,#6b7280)', start: '#d1d5db', end: '#9ca3af', maxPts: 100  },
  1: { label: '银牌', color: '#78909c', gradient: 'linear-gradient(135deg,#b0bec5,#78909c)', start: '#cfd8dc', end: '#78909c', maxPts: 500  },
  2: { label: '金牌', color: '#d97706', gradient: 'linear-gradient(135deg,#fbbf24,#d97706)', start: '#fde68a', end: '#d97706', maxPts: 2000 },
  3: { label: '铂金', color: '#7c3aed', gradient: 'linear-gradient(135deg,#a78bfa,#7c3aed)', start: '#c4b5fd', end: '#7c3aed', maxPts: 8000 },
  4: { label: '钻石', color: '#0891b2', gradient: 'linear-gradient(135deg,#38bdf8,#0891b2)', start: '#7dd3fc', end: '#0891b2', maxPts: 99999 },
}

const STATUS_MAP: Record<number, { badge: 'success' | 'error' | 'warning'; color: string; label: string }> = {
  1: { badge: 'success', color: '#10b981', label: '正常'  },
  2: { badge: 'error',   color: '#ef4444', label: '已封禁' },
  3: { badge: 'warning', color: '#f59e0b', label: '注销中' },
}

const LANG_FLAG: Record<string, { flag: string; label: string }> = {
  zh: { flag: '🇨🇳', label: '中文' },
  km: { flag: '🇰🇭', label: 'Khmer' },
  vi: { flag: '🇻🇳', label: 'Tiếng Việt' },
  en: { flag: '🇬🇧', label: 'English' },
}

// ── 公共数据类型（可在其他页面引用） ─────────────────────────────────────────
export interface MemberDetailVO {
  id:          number
  mobile:      string
  telegram?:   string
  wechat?:     string
  nickname:    string
  avatar?:     string
  gender:      number
  status:      number
  level:       number
  points:      number
  balance:     number
  totalAmount: number
  orderCount:  number
  createdAt:   string
  lang:        string
  address?:    string
}

interface Props {
  open:           boolean
  detail:         MemberDetailVO | null
  isAdmin?:       boolean
  onClose:        () => void
  onBanToggle?:   (member: MemberDetailVO) => void
}

/**
 * 会员详情抽屉 —— 全局可复用
 * 展示头像、等级、统计、联系方式、基本信息，管理员可执行封禁/解封
 */
export default function MemberDetailDrawer({ open, detail, isAdmin, onClose, onBanToggle }: Props) {
  const screens = useBreakpoint()
  if (!detail) return null

  const level  = LEVEL_CFG[detail.level]  ?? LEVEL_CFG[0]
  const status = STATUS_MAP[detail.status] ?? STATUS_MAP[2]
  const lang   = LANG_FLAG[detail.lang]

  const pct = Math.min(100, Math.round((detail.points / level.maxPts) * 100))

  const stats = [
    { label: '积分',  value: (detail.points ?? 0).toLocaleString(),           color: '#f59e0b', icon: <StarOutlined />,    bg: 'rgba(245,158,11,0.08)'  },
    { label: '余额',  value: `$${(detail.balance ?? 0).toFixed(2)}`,          color: '#10b981', icon: <WalletOutlined />,   bg: 'rgba(16,185,129,0.08)' },
    { label: '订单',  value: String(detail.orderCount ?? 0),                  color: '#3b82f6', icon: <ShoppingOutlined />, bg: 'rgba(59,130,246,0.08)' },
    { label: '消费',  value: `$${(detail.totalAmount ?? 0).toFixed(2)}`,      color: '#6366f1', icon: <GiftOutlined />,     bg: 'rgba(99,102,241,0.08)' },
  ]

  const infoItems: { label: string; icon: React.ReactNode; value: React.ReactNode }[] = [
    {
      label: '性别',
      icon: detail.gender === 1 ? <ManOutlined style={{ color: '#3b82f6' }} /> : <WomanOutlined style={{ color: '#ec4899' }} />,
      value: detail.gender === 1
        ? <Space size={4}><ManOutlined style={{ color: '#3b82f6' }} /><Text style={{ fontSize: 13 }}>男</Text></Space>
        : <Space size={4}><WomanOutlined style={{ color: '#ec4899' }} /><Text style={{ fontSize: 13 }}>女</Text></Space>,
    },
    {
      label: '语言',
      icon: <GlobalOutlined style={{ color: '#0891b2' }} />,
      value: <Space size={4}>
        <span style={{ fontSize: 15 }}>{lang?.flag ?? '🌐'}</span>
        <Text style={{ fontSize: 13 }}>{lang?.label ?? detail.lang}</Text>
      </Space>,
    },
    {
      label: '等级',
      icon: <CrownOutlined style={{ color: level.color }} />,
      value: <Tag icon={<CrownOutlined />} style={{
        borderRadius: 20, margin: 0, fontSize: 11, fontWeight: 600,
        background: `${level.color}15`, border: `1px solid ${level.color}40`, color: level.color,
      }}>{level.label}</Tag>,
    },
    {
      label: '状态',
      icon: <SafetyCertificateOutlined style={{ color: status.color }} />,
      value: <Badge status={status.badge} text={
        <Text style={{ color: status.color, fontSize: 12, fontWeight: 600 }}>{status.label}</Text>
      } />,
    },
    {
      label: '注册时间',
      icon: <CalendarOutlined style={{ color: '#9ca3af' }} />,
      value: <Text style={{ fontSize: 12, color: '#6b7280' }}>
        {dayjs(detail.createdAt).format('YYYY-MM-DD HH:mm')}
      </Text>,
    },
    {
      label: '会员 ID',
      icon: <IdcardOutlined style={{ color: '#d1d5db' }} />,
      value: <Text style={{ fontSize: 12, color: '#9ca3af', fontFamily: 'monospace' }}>#{detail.id}</Text>,
    },
  ]

  return (
    <Drawer
      open={open}
      onClose={onClose}
      width={screens.lg ? 460 : '100%'}
      closeIcon={null}
      styles={{
        header: { display: 'none' },
        body:   { padding: 0, overflowX: 'hidden' },
      }}
    >
      {/* ═══ 渐变头部 ════════════════════════════════════════════════════════ */}
      <div style={{
        background: level.gradient,
        padding: '28px 24px 32px',
        position: 'relative',
        overflow: 'hidden',
        textAlign: 'center',
      }}>
        {/* 装饰圆 */}
        <div style={{ position: 'absolute', right: -32, top: -32, width: 130, height: 130, borderRadius: '50%', background: 'rgba(255,255,255,0.1)', pointerEvents: 'none' }} />
        <div style={{ position: 'absolute', left: -20, bottom: -30, width: 90,  height: 90,  borderRadius: '50%', background: 'rgba(255,255,255,0.07)', pointerEvents: 'none' }} />

        {/* 关闭按钮 */}
        <Button
          type="text" size="small"
          icon={<CloseOutlined style={{ fontSize: 13, color: 'rgba(255,255,255,0.7)' }} />}
          onClick={onClose}
          style={{ position: 'absolute', top: 12, right: 12, width: 28, height: 28, borderRadius: 8 }}
        />

        {/* 头像（带彩色光圈） */}
        <div style={{
          display: 'inline-block', padding: 3, borderRadius: '50%',
          background: 'rgba(255,255,255,0.3)', marginBottom: 12,
          boxShadow: '0 4px 20px rgba(0,0,0,0.2)',
        }}>
          <Avatar
            src={detail.avatar || undefined} size={76} icon={<UserOutlined />}
            style={{
              background: `linear-gradient(135deg,${detail.gender === 2 ? '#f093fb,#f5576c' : '#4facfe,#00f2fe'})`,
              border: '3px solid rgba(255,255,255,0.65)',
            }}
          />
        </div>

        {/* 名字 + 性别图标 */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, marginBottom: 8 }}>
          <Title level={4} style={{ margin: 0, color: '#fff', textShadow: '0 2px 8px rgba(0,0,0,0.15)', letterSpacing: 0.5 }}>
            {detail.nickname}
          </Title>
          {detail.gender === 1
            ? <ManOutlined   style={{ color: 'rgba(255,255,255,0.8)', fontSize: 14 }} />
            : <WomanOutlined style={{ color: 'rgba(255,255,255,0.8)', fontSize: 14 }} />}
        </div>

        {/* 标签行 */}
        <Space size={6} wrap style={{ justifyContent: 'center', marginBottom: 10 }}>
          <Tag icon={<CrownOutlined />} style={{
            background: 'rgba(255,255,255,0.25)', border: '1px solid rgba(255,255,255,0.4)',
            color: '#fff', borderRadius: 20, fontWeight: 700, fontSize: 11, padding: '1px 10px',
          }}>{level.label}</Tag>
          <Badge status={status.badge} text={
            <Text style={{ color: 'rgba(255,255,255,0.9)', fontSize: 12 }}>{status.label}</Text>
          } />
        </Space>

        {/* 注册时间 */}
        <div>
          <Text style={{ color: 'rgba(255,255,255,0.6)', fontSize: 11 }}>
            <CalendarOutlined style={{ marginRight: 4 }} />
            注册于 {dayjs(detail.createdAt).format('YYYY年MM月DD日')}
          </Text>
        </div>
      </div>

      {/* ═══ 4 项统计（无边框网格） ══════════════════════════════════════════ */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: 1, background: '#eef0f8' }}>
        {stats.map(s => (
          <div key={s.label} style={{ background: '#fff', padding: '14px 6px', textAlign: 'center' }}>
            <div style={{
              width: 32, height: 32, borderRadius: 10, background: s.bg,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              margin: '0 auto 6px', color: s.color, fontSize: 15,
            }}>{s.icon}</div>
            <div style={{ fontWeight: 700, color: s.color, fontSize: 14, lineHeight: 1.2 }}>{s.value}</div>
            <Text type="secondary" style={{ fontSize: 10 }}>{s.label}</Text>
          </div>
        ))}
      </div>

      {/* ═══ 详情内容区 ══════════════════════════════════════════════════════ */}
      <div style={{ padding: '20px 24px 28px' }}>

        {/* 等级进度条 */}
        <div style={{ marginBottom: 20 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 7 }}>
            <Text style={{ fontSize: 12, fontWeight: 600, color: '#374151' }}>
              <CrownOutlined style={{ color: level.color, marginRight: 5 }} />
              等级进度
            </Text>
            <Text type="secondary" style={{ fontSize: 11 }}>
              {(detail.points ?? 0).toLocaleString()} / {level.maxPts.toLocaleString()} 积分
            </Text>
          </div>
          <Progress
            percent={pct}
            strokeColor={{ '0%': level.start, '100%': level.end }}
            trailColor="#f0f0f0"
            strokeLinecap="round"
            size={{ height: 7 }}
            showInfo={false}
          />
          <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 4 }}>
            <Text type="secondary" style={{ fontSize: 10 }}>{level.label}</Text>
            {detail.level < 4 && (
              <Text type="secondary" style={{ fontSize: 10 }}>
                {LEVEL_CFG[detail.level + 1]?.label}
              </Text>
            )}
          </div>
        </div>

        <Divider style={{ margin: '4px 0 16px' }} />

        {/* 联系方式 */}
        <div style={{ marginBottom: 18 }}>
          <Text style={{ fontSize: 12, fontWeight: 700, color: '#374151', display: 'block', marginBottom: 10 }}>
            联系方式
          </Text>
          <div style={{
            background: '#f8f9ff', borderRadius: 12, padding: '12px 16px',
            border: '1px solid #eef0ff',
          }}>
            <ContactCell
              mobile={detail.mobile}
              telegram={detail.telegram}
              wechat={detail.wechat}
              align="left"
            />
          </div>
        </div>

        <Divider style={{ margin: '4px 0 16px' }} />

        {/* 基本信息网格 */}
        <div style={{ marginBottom: 18 }}>
          <Text style={{ fontSize: 12, fontWeight: 700, color: '#374151', display: 'block', marginBottom: 12 }}>
            基本信息
          </Text>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px 24px' }}>
            {infoItems.map(item => (
              <div key={item.label}>
                <Text type="secondary" style={{ fontSize: 11, display: 'flex', alignItems: 'center', gap: 4, marginBottom: 3 }}>
                  <span style={{ fontSize: 11, opacity: 0.75, lineHeight: 1 }}>{item.icon}</span>
                  {item.label}
                </Text>
                {item.value}
              </div>
            ))}
          </div>
        </div>

        {/* 会员地址（始终显示，无地址时显示占位文字） */}
        <Divider style={{ margin: '4px 0 16px' }} />
        <div style={{ marginBottom: 20 }}>
          <Text style={{ fontSize: 12, fontWeight: 700, color: '#374151', display: 'block', marginBottom: 10 }}>
            <EnvironmentOutlined style={{ color: '#f59e0b', marginRight: 6 }} />
            会员地址
          </Text>
          <div style={{
            background: detail.address ? '#f8f9ff' : '#fafafa',
            borderRadius: 12, padding: '12px 16px',
            border: `1px solid ${detail.address ? '#eef0ff' : '#f0f0f0'}`,
            display: 'flex', alignItems: 'flex-start', gap: 10,
          }}>
            <div style={{
              width: 28, height: 28, borderRadius: 8, flexShrink: 0,
              background: detail.address
                ? 'linear-gradient(135deg,#f59e0b,#d97706)'
                : 'linear-gradient(135deg,#d1d5db,#9ca3af)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: detail.address ? '0 2px 8px rgba(245,158,11,0.2)' : 'none',
            }}>
              <EnvironmentOutlined style={{ color: '#fff', fontSize: 13 }} />
            </div>
            {detail.address
              ? <Text style={{ fontSize: 13, color: '#374151', lineHeight: 1.6, paddingTop: 4 }}>{detail.address}</Text>
              : <Text type="secondary" style={{ fontSize: 12, paddingTop: 5 }}>暂未填写</Text>
            }
          </div>
        </div>

        {/* 封禁 / 解封 按钮 */}
        {isAdmin && (
          <>
            <Divider style={{ margin: '4px 0 16px' }} />
            <Button
              block size="large"
              icon={detail.status === 1 ? <StopOutlined /> : <CheckCircleOutlined />}
              onClick={() => onBanToggle?.(detail)}
              style={{
                borderRadius: 14, fontWeight: 700, height: 46, fontSize: 14,
                border: 'none', color: '#fff',
                background: detail.status === 1
                  ? 'linear-gradient(135deg,#ef4444,#dc2626)'
                  : 'linear-gradient(135deg,#10b981,#059669)',
                boxShadow: detail.status === 1
                  ? '0 4px 14px rgba(239,68,68,0.3)'
                  : '0 4px 14px rgba(16,185,129,0.3)',
              }}
            >
              {detail.status === 1 ? '封禁此账号' : '解封此账号'}
            </Button>
          </>
        )}
      </div>
    </Drawer>
  )
}
