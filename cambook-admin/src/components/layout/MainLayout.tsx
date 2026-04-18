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
  BarChartOutlined, MinusCircleOutlined, GlobalOutlined,
} from '@ant-design/icons'
import { useAuthStore } from '../../store/authStore'
import type { PermissionVO } from '../../api/api'
import { merchantPortalApi, authApi } from '../../api/api'
import AnnouncementBell from '../common/AnnouncementBell'

const { Sider, Header, Content } = Layout
const { Text } = Typography

// ── 彩色图标映射 ───────────────────────────────────────────────────────────────
// 颜色策略：明亮的宝石色系，在深色侧边栏上高对比度，语义化分类
const ic = (node: React.ReactNode, color: string) => (
  <span style={{ color, fontSize: 15, display: 'inline-flex', alignItems: 'center', lineHeight: 1 }}>
    {node}
  </span>
)

const ICON_MAP: Record<string, React.ReactNode> = {
  // ── 核心功能 ──
  DashboardOutlined:    ic(<DashboardOutlined />,    '#818cf8'),  // 靛紫 — 仪表盘
  HomeOutlined:         ic(<HomeOutlined />,          '#93c5fd'),  // 天蓝 — 首页
  // ── 用户体系 ──
  UserOutlined:         ic(<UserOutlined />,          '#38bdf8'),  // 亮蓝 — 会员
  TeamOutlined:         ic(<TeamOutlined />,          '#c084fc'),  // 紫罗兰 — 技师团队
  IdcardOutlined:       ic(<IdcardOutlined />,        '#a78bfa'),  // 紫色 — 员工/身份
  SolutionOutlined:     ic(<SolutionOutlined />,      '#d8b4fe'),  // 淡紫 — 人员方案
  // ── 商业核心 ──
  ShopOutlined:         ic(<ShopOutlined />,          '#fb923c'),  // 橙色 — 商户
  OrderedListOutlined:  ic(<OrderedListOutlined />,   '#34d399'),  // 翠绿 — 订单
  DollarOutlined:       ic(<DollarOutlined />,        '#4ade80'),  // 绿色 — 财务
  BankOutlined:         ic(<BankOutlined />,          '#86efac'),  // 浅绿 — 银行/提现
  // ── 运营营销 ──
  TagsOutlined:         ic(<TagsOutlined />,          '#f472b6'),  // 亮粉 — 优惠券
  GiftOutlined:         ic(<GiftOutlined />,          '#f0abfc'),  // 洋红 — 礼物/活动
  RocketOutlined:       ic(<RocketOutlined />,        '#f97316'),  // 橙红 — 推广
  StarOutlined:         ic(<StarOutlined />,          '#fcd34d'),  // 金黄 — 评价/收藏
  // ── 内容与通知 ──
  PictureOutlined:      ic(<PictureOutlined />,       '#e879f9'),  // 品红 — 横幅/图片
  NotificationOutlined: ic(<NotificationOutlined />,  '#fdba74'),  // 橙黄 — 公告
  BellOutlined:         ic(<BellOutlined />,          '#fbbf24'),  // 蜂蜜黄 — 通知铃
  MessageOutlined:      ic(<MessageOutlined />,       '#67e8f9'),  // 青色 — 消息
  SoundOutlined:        ic(<SoundOutlined />,         '#22d3ee'),  // 青蓝 — 广播
  ReadOutlined:         ic(<ReadOutlined />,          '#6ee7b7'),  // 薄荷 — 阅读/内容
  BookOutlined:         ic(<BookOutlined />,          '#86efac'),  // 淡绿 — 文章
  // ── 资源管理 ──
  CarOutlined:          ic(<CarOutlined />,           '#7dd3fc'),  // 天蓝 — 车辆
  AppstoreOutlined:     ic(<AppstoreOutlined />,      '#fba4a4'),  // 珊瑚 — 分类/应用
  ClockCircleOutlined:  ic(<ClockCircleOutlined />,   '#6ee7b7'),  // 薄荷绿 — 时间/排班
  FileTextOutlined:     ic(<FileTextOutlined />,      '#bfdbfe'),  // 浅蓝 — 文档/报告
  // ── 系统管理 ──
  ApartmentOutlined:    ic(<ApartmentOutlined />,     '#818cf8'),  // 靛蓝 — 部门组织
  MenuOutlined:         ic(<MenuOutlined />,          '#93c5fd'),  // 天蓝 — 菜单配置
  DesktopOutlined:      ic(<DesktopOutlined />,       '#7dd3fc'),  // 蓝色 — 监控/桌面
  DatabaseOutlined:     ic(<DatabaseOutlined />,      '#60a5fa'),  // 中蓝 — 数据管理
  // ── 权限安全 ──
  KeyOutlined:          ic(<KeyOutlined />,           '#fbbf24'),  // 金黄 — 权限/密钥
  LockOutlined:         ic(<LockOutlined />,          '#f87171'),  // 红色 — 锁定/安全
  SafetyOutlined:       ic(<SafetyOutlined />,        '#2dd4bf'),  // 青绿 — 安全证书
  AuditOutlined:        ic(<AuditOutlined />,         '#fb7185'),  // 玫瑰 — 审核日志
  SettingOutlined:      ic(<SettingOutlined />,       '#94a3b8'),  // 灰蓝 — 系统设置
  // ── 新增功能图标 ──
  BarChartOutlined:     ic(<BarChartOutlined />,      '#34d399'),  // 翠绿 — 财务概览/图表
  MinusCircleOutlined:  ic(<MinusCircleOutlined />,   '#f87171'),  // 红色 — 支出管理
  GlobalOutlined:       ic(<GlobalOutlined />,        '#60a5fa'),  // 蓝色 — 全球货币
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
  const { user, merchant, menus, isMerchant, setLogout, setMenus } = useAuthStore()
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

  // ── 静默刷新菜单（解决 localStorage 缓存与数据库不同步的问题）────────────────
  // 每次 MainLayout 挂载时重新拉一次菜单树，并更新 zustand store 缓存，
  // 确保菜单 icon / 名称 / 排序等变更后无需退出登录即可生效。
  useEffect(() => {
    const refresh = isMerchant
      ? () => merchantPortalApi.menus().then(res => {
          const list: PermissionVO[] = (res.data as any)?.data ?? res.data ?? []
          if (Array.isArray(list) && list.length) setMenus(list)
        })
      : () => authApi.menus().then(res => {
          const list: PermissionVO[] = (res.data as any)?.data ?? res.data ?? []
          if (Array.isArray(list) && list.length) setMenus(list)
        })
    refresh().catch(() => {/* 网络异常静默忽略，继续用缓存 */})
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

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

      <Layout style={{
        marginLeft: collapsed ? 80 : 220,
        transition: 'margin-left 0.2s',
        minHeight: '100vh',
        display: 'flex',
        flexDirection: 'column',
      }}>
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
          {/* 动画 + 侧边栏菜单字重 + 粉色细滚动条 */}
          <style>{`
            @keyframes icon-breathe {
              0%,100% { box-shadow: 0 0 8px rgba(99,102,241,0.5); }
              50%      { box-shadow: 0 0 18px rgba(139,92,246,0.85), 0 0 36px rgba(99,102,241,0.3); }
            }
            .merchant-icon-pulse { animation: icon-breathe 3s ease-in-out infinite; }

            /* ── 侧边栏菜单字重 ── */
            .ant-menu-dark .ant-menu-item,
            .ant-menu-dark .ant-menu-submenu-title,
            .ant-menu-dark .ant-menu-item > span,
            .ant-menu-dark .ant-menu-submenu-title > span {
              font-weight: 600;
              letter-spacing: 0.2px;
            }
            .ant-menu-dark .ant-menu-item-selected,
            .ant-menu-dark .ant-menu-item-selected > span {
              font-weight: 700;
            }

            /* ── 彩色图标：hover 时轻微提亮 ── */
            .ant-menu-dark .ant-menu-item:not(.ant-menu-item-selected):hover .anticon > span,
            .ant-menu-dark .ant-menu-submenu-title:hover .anticon > span {
              filter: brightness(1.25);
              transition: filter 0.2s;
            }
            /* ── 选中项图标改为白色，保证橙色背景上清晰可读 ── */
            .ant-menu-dark .ant-menu-item-selected .anticon > span {
              color: rgba(255,255,255,0.95) !important;
              filter: drop-shadow(0 0 4px rgba(255,255,255,0.4));
            }
            /* ── 子菜单展开箭头也用柔和颜色 ── */
            .ant-menu-dark .ant-menu-submenu-arrow {
              opacity: 0.5;
            }
            .ant-menu-dark .ant-menu-submenu-open > .ant-menu-submenu-title .ant-menu-submenu-arrow {
              opacity: 0.85;
            }

            /* ── 侧边栏细滚动条（粉色主题） ── */
            .ant-layout-sider .ant-menu::-webkit-scrollbar {
              width: 3px;
            }
            .ant-layout-sider .ant-menu::-webkit-scrollbar-track {
              background: transparent;
            }
            .ant-layout-sider .ant-menu::-webkit-scrollbar-thumb {
              background: linear-gradient(180deg, #f472b6 0%, #ec4899 50%, #db2777 100%);
              border-radius: 3px;
            }
            .ant-layout-sider .ant-menu::-webkit-scrollbar-thumb:hover {
              background: linear-gradient(180deg, #fb7bb8 0%, #f472b6 100%);
            }
            /* Firefox */
            .ant-layout-sider .ant-menu {
              scrollbar-width: thin;
              scrollbar-color: #ec4899 transparent;
            }
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
        <Content style={{
          flex: 1,
          padding: '24px',
          background: '#f8fafc',
        }}>
          <Outlet />
        </Content>
      </Layout>
    </Layout>
  )
}
