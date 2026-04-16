import React, { useState, useMemo, useEffect } from 'react'
import { Outlet, useNavigate, useLocation } from 'react-router-dom'
import { Layout, Menu, Avatar, Dropdown, Badge, Button, Typography } from 'antd'
import type { ItemType } from 'antd/es/menu/interface'
import {
  DashboardOutlined, UserOutlined, TeamOutlined, ShopOutlined,
  OrderedListOutlined, DollarOutlined, TagsOutlined, SettingOutlined,
  MenuFoldOutlined, MenuUnfoldOutlined, BellOutlined, LogoutOutlined,
  SafetyOutlined, CarOutlined, PictureOutlined, AppstoreOutlined,
  FileTextOutlined, KeyOutlined, AuditOutlined, IdcardOutlined,
  BankOutlined, MenuOutlined, LockOutlined, ApartmentOutlined,
  BookOutlined, NotificationOutlined, DesktopOutlined, ClockCircleOutlined,
  DatabaseOutlined, StarOutlined, SolutionOutlined, RocketOutlined, SoundOutlined,
  GiftOutlined, HomeOutlined, ReadOutlined, MessageOutlined,
} from '@ant-design/icons'
import { useAuthStore } from '../../store/authStore'
import type { PermissionVO } from '../../api/api'
import { merchantPortalApi } from '../../api/api'
import AnnouncementBell from '../common/AnnouncementBell'

const { Sider, Header, Content } = Layout
const { Text } = Typography

// ── 图标映射 ──────────────────────────────────────────────────────────────────
const ICON_MAP: Record<string, React.ReactNode> = {
  DashboardOutlined:   <DashboardOutlined />,
  UserOutlined:        <UserOutlined />,
  TeamOutlined:        <TeamOutlined />,
  ShopOutlined:        <ShopOutlined />,
  OrderedListOutlined: <OrderedListOutlined />,
  DollarOutlined:      <DollarOutlined />,
  TagsOutlined:        <TagsOutlined />,
  SettingOutlined:     <SettingOutlined />,
  CarOutlined:         <CarOutlined />,
  PictureOutlined:     <PictureOutlined />,
  AppstoreOutlined:    <AppstoreOutlined />,
  FileTextOutlined:    <FileTextOutlined />,
  KeyOutlined:         <KeyOutlined />,
  AuditOutlined:       <AuditOutlined />,
  SafetyOutlined:      <SafetyOutlined />,
  IdcardOutlined:      <IdcardOutlined />,
  BankOutlined:        <BankOutlined />,
  MenuOutlined:        <MenuOutlined />,
  LockOutlined:        <LockOutlined />,
  ApartmentOutlined:   <ApartmentOutlined />,
  BookOutlined:        <BookOutlined />,
  BellOutlined:        <BellOutlined />,
  NotificationOutlined: <NotificationOutlined />,
  DesktopOutlined:     <DesktopOutlined />,
  ClockCircleOutlined: <ClockCircleOutlined />,
  DatabaseOutlined:    <DatabaseOutlined />,
  StarOutlined:        <StarOutlined />,
  SolutionOutlined:    <SolutionOutlined />,
  RocketOutlined:      <RocketOutlined />,
  SoundOutlined:       <SoundOutlined />,
  GiftOutlined:        <GiftOutlined />,
  HomeOutlined:        <HomeOutlined />,
  ReadOutlined:        <ReadOutlined />,
  MessageOutlined:     <MessageOutlined />,
}

const getIcon = (name?: string | null): React.ReactNode | undefined =>
  (name && ICON_MAP[name]) || undefined

// ── PermissionVO → antd ItemType ─────────────────────────────────────────────
function toMenuItems(nodes: PermissionVO[]): ItemType[] {
  return [...nodes]
    .sort((a, b) => a.sort - b.sort)
    .flatMap((n): ItemType[] => {
      if (n.type === 1) {
        const children = n.children ? toMenuItems(n.children) : []
        if (!children.length) return []
        return [{ key: `dir-${n.id}`, icon: getIcon(n.icon), label: n.name, children }]
      }
      if (n.type === 2 && n.path) {
        return [{ key: n.path, icon: getIcon(n.icon), label: n.name }]
      }
      return []
    })
}

function hasPath(nodes: PermissionVO[], target: string): boolean {
  return nodes.some(n =>
    (n.type === 2 && n.path === target) ||
    (n.children ? hasPath(n.children, target) : false)
  )
}

function calcOpenKeys(nodes: PermissionVO[], currentPath: string): string[] {
  const keys: string[] = []
  for (const n of nodes) {
    if (n.type === 1 && n.children && hasPath(n.children, currentPath)) {
      keys.push(`dir-${n.id}`)
      keys.push(...calcOpenKeys(n.children, currentPath))
    }
  }
  return keys
}

// ──────────────────────────────────────────────────────────────────────────────
// MainLayout Component
// ──────────────────────────────────────────────────────────────────────────────

export default function MainLayout() {
  const navigate    = useNavigate()
  const location    = useLocation()
  const { user, merchant, menus, isMerchant, setLogout } = useAuthStore()
  const [collapsed, setCollapsed] = useState(false)

  // ── 实时时钟（每秒刷新）────────────────────────────────────────────────────
  const [now, setNow] = useState(new Date())
  useEffect(() => {
    const t = setInterval(() => setNow(new Date()), 1000)
    return () => clearInterval(t)
  }, [])
  const pad = (n: number) => String(n).padStart(2, '0')
  const clockStr = `${now.getFullYear()}-${pad(now.getMonth()+1)}-${pad(now.getDate())} ${pad(now.getHours())}:${pad(now.getMinutes())}:${pad(now.getSeconds())}`

  // ── 当前员工信息（职位、部门）───────────────────────────────────────────────
  const [staffInfo, setStaffInfo] = useState<{
    username?: string; positionName?: string; deptName?: string
  }>({})
  useEffect(() => {
    if (!isMerchant) return
    merchantPortalApi.me().then(res => {
      if (res.data?.data) setStaffInfo(res.data.data)
    }).catch(() => {/* ignore */})
  }, [isMerchant])

  // 同步侧边栏宽度到 CSS 变量，让弹窗在内容区居中
  useEffect(() => {
    document.documentElement.style.setProperty(
      '--sidebar-width',
      collapsed ? '80px' : '220px',
    )
  }, [collapsed])

  const menuItems  = useMemo(() => toMenuItems(menus), [menus])
  const openKeys   = useMemo(() => calcOpenKeys(menus, location.pathname), [menus, location.pathname])

  const handleLogout = () => {
    setLogout()
    navigate(isMerchant ? '/merchant/login' : '/login')
  }

  const userDropdownItems = [
    { key: 'logout', icon: <LogoutOutlined />, label: '退出登录', danger: true },
  ]

  // ── 侧边栏品牌区 ──────────────────────────────────────────────────────────
  const logoSection = isMerchant ? (
    <div style={{
      height: 64,
      display: 'flex', alignItems: 'center',
      justifyContent: collapsed ? 'center' : 'flex-start',
      padding: collapsed ? 0 : '0 16px',
      borderBottom: '1px solid rgba(255,255,255,0.06)',
      cursor: 'pointer',
      gap: 10,
    }} onClick={() => navigate('/merchant/dashboard')}>
      <Avatar
        size={34}
        src={merchant?.merchantLogo || undefined}
        icon={<ShopOutlined style={{ fontSize: 15 }} />}
        style={{
          flexShrink: 0,
          background: 'linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%)',
          boxShadow: '0 4px 14px rgba(99,102,241,0.5)',
          border: 'none',
        }}
      />
      {!collapsed && (
        <div style={{ overflow: 'hidden' }}>
          <div style={{
            color: '#fff', fontSize: 13, fontWeight: 700,
            lineHeight: 1.3, letterSpacing: 0.3,
            whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
            maxWidth: 130,
          }}>
            {merchant?.merchantName || '商户后台'}
          </div>
          <div style={{ color: 'rgba(255,255,255,0.35)', fontSize: 10, marginTop: 2 }}>
            商户管理平台
          </div>
        </div>
      )}
    </div>
  ) : (
    <div style={{
      height: 64,
      display: 'flex', alignItems: 'center',
      justifyContent: collapsed ? 'center' : 'flex-start',
      padding: collapsed ? 0 : '0 20px',
      borderBottom: '1px solid rgba(255,255,255,0.06)',
      cursor: 'pointer',
    }} onClick={() => navigate('/dashboard')}>
      <div style={{
        width: 34, height: 34,
        background: 'linear-gradient(135deg, #f59e0b 0%, #f97316 100%)',
        borderRadius: 10,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        color: '#fff', fontWeight: 900, fontSize: 17, flexShrink: 0,
        boxShadow: '0 4px 14px rgba(249,115,22,0.45)',
        userSelect: 'none',
      }}>
        C
      </div>
      {!collapsed && (
        <div style={{ marginLeft: 10, overflow: 'hidden' }}>
          <div style={{ color: '#fff', fontSize: 15, fontWeight: 700, lineHeight: 1.2, letterSpacing: 0.5 }}>
            CamBook
          </div>
          <div style={{ color: 'rgba(255,255,255,0.35)', fontSize: 10, marginTop: 2 }}>
            运营管理系统
          </div>
        </div>
      )}
    </div>
  )

  // 商户端侧边栏背景色
  const siderBg = isMerchant ? '#111827' : '#0f1117'

  return (
    <Layout style={{ minHeight: '100vh' }}>
      {/* ── 侧边栏 ─────────────────────────────────────────────────────────── */}
      <Sider
        trigger={null}
        collapsible
        collapsed={collapsed}
        width={220}
        style={{
          position: 'fixed', left: 0, top: 0, bottom: 0, zIndex: 100,
          background: siderBg,
          boxShadow: '2px 0 16px rgba(0,0,0,0.45)',
          borderRight: '1px solid rgba(255,255,255,0.04)',
        }}
      >
        {logoSection}

        {/* 商户身份标识条 */}
        {isMerchant && !collapsed && (
          <div style={{
            margin: '8px 12px',
            padding: '6px 12px',
            background: 'linear-gradient(135deg, rgba(99,102,241,0.18), rgba(139,92,246,0.12))',
            borderRadius: 8,
            border: '1px solid rgba(139,92,246,0.22)',
            display: 'flex', alignItems: 'center', gap: 6,
          }}>
            <div style={{ width: 6, height: 6, borderRadius: '50%', background: '#a78bfa', flexShrink: 0 }} />
            <Text style={{ color: 'rgba(167,139,250,0.9)', fontSize: 11, lineHeight: 1.4 }}>
              商户专属管理模式
            </Text>
          </div>
        )}

        <Menu
          theme="dark"
          mode="inline"
          selectedKeys={[location.pathname]}
          defaultOpenKeys={openKeys}
          items={menuItems}
          onClick={({ key }) => navigate(key)}
          style={{
            background: 'transparent',
            borderRight: 'none',
            marginTop: 4,
            overflowY: 'auto',
            height: `calc(100vh - ${isMerchant ? 100 : 72}px)`,
            paddingBottom: 24,
          }}
        />
      </Sider>

      <Layout style={{ marginLeft: collapsed ? 80 : 220, transition: 'margin-left 0.2s' }}>
        {/* ── 顶部导航 ──────────────────────────────────────────────────────── */}
        <Header style={{
          position: 'sticky', top: 0, zIndex: 99,
          height: 64, lineHeight: '64px',
          padding: '0 20px 0 12px',
          display: 'flex', alignItems: 'center',
          overflow: 'hidden',
          background: isMerchant
            ? 'linear-gradient(135deg, #0f1117 0%, #131929 50%, #1a1f35 100%)'
            : 'linear-gradient(135deg, #0f1117 0%, #131929 100%)',
          borderBottom: '1px solid rgba(255,255,255,0.06)',
          boxShadow: '0 2px 20px rgba(0,0,0,0.35)',
        }}>
          {/* 动画：icon 呼吸光效 */}
          <style>{`
            @keyframes icon-breathe {
              0%,100% { box-shadow: 0 0 8px rgba(99,102,241,0.5); }
              50%      { box-shadow: 0 0 18px rgba(139,92,246,0.85), 0 0 36px rgba(99,102,241,0.3); }
            }
            .merchant-icon-pulse { animation: icon-breathe 3s ease-in-out infinite; }
          `}</style>

          {/* ── 折叠按钮 ── */}
          <Button
            type="text"
            icon={collapsed ? <MenuUnfoldOutlined /> : <MenuFoldOutlined />}
            onClick={() => setCollapsed(c => !c)}
            style={{ fontSize: 15, color: 'rgba(255,255,255,0.5)', flexShrink: 0, width: 36 }}
          />

          {/* ── 中间弹性空白 ── */}
          <div style={{ flex: 1 }} />

          {/* ── 右侧：商户名 + 信息 + 铃铛 + 头像 ── */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, flexShrink: 0 }}>

            {/* 商户信息块（仅商户端） */}
            {isMerchant && (
              <div style={{
                display: 'flex', flexDirection: 'column', alignItems: 'flex-end',
                gap: 1, paddingRight: 14,
                borderRight: '1px solid rgba(255,255,255,0.07)',
              }}>
                {/* 第1行：时钟 */}
                <div style={{
                  fontSize: 11, color: 'rgba(167,139,250,0.8)',
                  fontFamily: "'SF Mono','Consolas','Courier New',monospace",
                  fontVariantNumeric: 'tabular-nums', letterSpacing: 0.3,
                  lineHeight: '16px', whiteSpace: 'nowrap',
                }}>
                  {clockStr}
                </div>
   
                {/* 第3行：职位 */}
                {staffInfo.positionName && (
                  <div style={{ fontSize: 11, lineHeight: '15px', whiteSpace: 'nowrap' }}>
                    <span style={{ color: 'rgba(255,255,255,0.38)' }}>职位&nbsp;</span>
                    <span style={{ color: 'rgba(255,255,255,0.72)' }}>{staffInfo.positionName}</span>
                  </div>
                )}
                {/* 第4行：账号 */}
                {staffInfo.username && (
                  <div style={{ fontSize: 11, lineHeight: '15px', whiteSpace: 'nowrap' }}>
                    <span style={{ color: 'rgba(255,255,255,0.38)' }}>账号&nbsp;</span>
                    <span style={{ color: 'rgba(255,255,255,0.72)' }}>{staffInfo.username}</span>
                  </div>
                )}
              </div>
            )}

            {/* 铃铛 */}
            {isMerchant ? (
              <AnnouncementBell />
            ) : (
              <Badge count={0} size="small">
                <Button type="text" icon={<BellOutlined style={{ fontSize: 17, color: 'rgba(255,255,255,0.5)' }} />} />
              </Badge>
            )}

            {/* 用户头像 + 下拉 */}
            <Dropdown
              menu={{
                items: userDropdownItems,
                onClick: ({ key }) => { if (key === 'logout') handleLogout() },
              }}
              placement="bottomRight"
              arrow
            >
              <div style={{
                display: 'flex', alignItems: 'center', gap: 7,
                cursor: 'pointer', padding: '4px 8px', borderRadius: 8,
                transition: 'background 0.18s',
              }}
                onMouseEnter={e => (e.currentTarget.style.background = 'rgba(255,255,255,0.07)')}
                onMouseLeave={e => (e.currentTarget.style.background = 'transparent')}
              >
                <Avatar
                  size={30}
                  src={isMerchant ? (merchant?.merchantLogo || undefined) : undefined}
                  icon={isMerchant
                    ? <ShopOutlined style={{ fontSize: 13 }} />
                    : <UserOutlined style={{ fontSize: 13 }} />}
                  className={isMerchant ? 'merchant-icon-pulse' : undefined}
                  style={{
                    background: isMerchant
                      ? 'linear-gradient(135deg,#6366f1,#8b5cf6)'
                      : 'linear-gradient(135deg,#f59e0b,#f97316)',
                    flexShrink: 0, border: 'none',
                  }}
                />
                {!isMerchant && (
                  <Text style={{
                    fontSize: 13, color: 'rgba(255,255,255,0.7)',
                    maxWidth: 110, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
                  }}>
                    {user?.username || '管理员'}
                  </Text>
                )}
              </div>
            </Dropdown>
          </div>
        </Header>

        {/* ── 主内容区 ─────────────────────────────────────────────────── */}
        <Content style={{ margin: '24px', minHeight: 'calc(100vh - 112px)' }}>
          <Outlet />
        </Content>
      </Layout>
    </Layout>
  )
}
