import { BrowserRouter, Routes, Route, Navigate, useLocation } from 'react-router-dom'
import { Suspense, lazy, useEffect } from 'react'
import { Spin } from 'antd'
import MainLayout from './components/layout/MainLayout'
import LoginPage from './pages/auth/LoginPage'
import MerchantLoginPage from './pages/auth/MerchantLoginPage'
import { useAuthStore } from './store/authStore'
import { authApi, merchantPortalApi } from './api/api'
import ErrorBoundary from './components/common/ErrorBoundary'

// ── 管理端页面懒加载 ─────────────────────────────────────────────────────────
const DashboardPage       = lazy(() => import('./pages/dashboard/DashboardPage'))
const UserListPage        = lazy(() => import('./pages/user/UserListPage'))
const TechnicianListPage  = lazy(() => import('./pages/technician/TechnicianListPage'))
const TechnicianAuditPage = lazy(() => import('./pages/technician/TechnicianAuditPage'))
const MerchantListPage    = lazy(() => import('./pages/merchant/MerchantListPage'))
const OrderListPage       = lazy(() => import('./pages/order/OrderListPage'))
const OrderDetailPage     = lazy(() => import('./pages/order/OrderDetailPage'))
const VehicleListPage     = lazy(() => import('./pages/vehicle/VehicleListPage'))
const FinancePage         = lazy(() => import('./pages/finance/FinancePage'))
const WithdrawAuditPage   = lazy(() => import('./pages/finance/WithdrawAuditPage'))
const CouponListPage      = lazy(() => import('./pages/coupon/CouponListPage'))
const BannerPage          = lazy(() => import('./pages/system/BannerPage'))
const CategoryPage        = lazy(() => import('./pages/operation/CategoryPage'))
const ReviewPage          = lazy(() => import('./pages/operation/ReviewPage'))
const StaffListPage       = lazy(() => import('./pages/admin/StaffListPage'))
const PositionListPage    = lazy(() => import('./pages/admin/PositionListPage'))
const RoleListPage        = lazy(() => import('./pages/system/RoleListPage'))
const MenuManagePage      = lazy(() => import('./pages/admin/MenuManagePage'))
const PermissionTreePage  = lazy(() => import('./pages/system/PermissionTreePage'))
const SysConfigPage       = lazy(() => import('./pages/system/SysConfigPage'))
const DeptManagePage      = lazy(() => import('./pages/system/DeptManagePage'))
const DictManagePage      = lazy(() => import('./pages/system/DictManagePage'))
const SysParamPage        = lazy(() => import('./pages/system/SysParamPage'))
const NoticePage          = lazy(() => import('./pages/system/NoticePage'))
const LogManagePage       = lazy(() => import('./pages/system/LogManagePage'))
const OnlineUserPage      = lazy(() => import('./pages/monitor/OnlineUserPage'))
const JobManagePage       = lazy(() => import('./pages/monitor/JobManagePage'))
const ServerMonitorPage   = lazy(() => import('./pages/monitor/ServerMonitorPage'))
const CacheMonitorPage    = lazy(() => import('./pages/monitor/CacheMonitorPage'))

// ── 商户专属页面（merchant-portal 已废弃，统一使用 pages/merchant/）─────────
const MerchantProfilePage  = lazy(() => import('./pages/merchant/ProfilePage'))
const MerchantStaffPage    = lazy(() => import('./pages/merchant/StaffPage'))
const MerchantRolePage     = lazy(() => import('./pages/merchant/RolePage'))
const MerchantDeptPage     = lazy(() => import('./pages/merchant/DeptPage'))
const MerchantPositionPage = lazy(() => import('./pages/merchant/PositionPage'))
const AnnouncePage         = lazy(() => import('./pages/merchant/AnnouncePage'))
// ── 新增功能模块 ──────────────────────────────────────────────────────────────
const WalkinSessionPage    = lazy(() => import('./pages/walkin/WalkinSessionPage'))
const VehicleDispatchPage  = lazy(() => import('./pages/vehicle/VehicleDispatchPage'))
const FinanceOverviewPage  = lazy(() => import('./pages/finance/FinanceOverviewPage'))
const ExpenseManagePage    = lazy(() => import('./pages/finance/ExpenseManagePage'))
const SalaryManagePage     = lazy(() => import('./pages/finance/SalaryManagePage'))
const IncomeRecordPage     = lazy(() => import('./pages/finance/IncomeRecordPage'))
const CurrencyManagePage          = lazy(() => import('./pages/system/CurrencyManagePage'))
const MerchantCurrencyPage        = lazy(() => import('./pages/settings/MerchantCurrencyPage'))
const TechnicianSettlementPage    = lazy(() => import('./pages/finance/TechnicianSettlementPage'))
const OrderHistoryPage            = lazy(() => import('./pages/order/OrderHistoryPage'))
// ── Loading ──────────────────────────────────────────────────────────────────
const LoadingFallback = () => (
  <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', height: '100vh', gap: 16 }}>
    <Spin size="large" />
    <span style={{ color: '#999', fontSize: 14 }}>页面加载中...</span>
  </div>
)

// ── 路由守卫 ─────────────────────────────────────────────────────────────────
const ProtectedRoute = ({ children }: { children: React.ReactNode }) => {
  const { isLoggedIn } = useAuthStore()
  if (!isLoggedIn) return <Navigate to="/login" replace />
  return <>{children}</>
}

/**
 * 商户路由守卫
 * - 未登录 → 跳转登录页
 * - 非商户 → 跳转管理员首页
 * - 菜单已加载时做路径级鉴权：访问不在权限内的路径 → 重定向到 dashboard
 *   （菜单未加载时放行，等待 useMenuRefresh 异步补全后自动重渲染）
 */
const MerchantRoute = ({ children }: { children: React.ReactNode }) => {
  const { isLoggedIn, isMerchant, menus } = useAuthStore()
  const location = useLocation()
  if (!isLoggedIn) return <Navigate to="/merchant/login" replace />
  if (!isMerchant)  return <Navigate to="/dashboard"      replace />
  if (menus.length > 0) {
    const allowed = flattenMenuPaths(menus)
    const cur     = location.pathname
    if (cur !== '/merchant/dashboard' && cur !== '/merchant' && !allowed.has(cur)) {
      return <Navigate to="/merchant/dashboard" replace />
    }
  }
  return <>{children}</>
}

/** 递归收集 PermissionVO 树中所有菜单路径 */
function flattenMenuPaths(nodes: import('./api/api').PermissionVO[]): Set<string> {
  const set  = new Set<string>()
  const walk = (list: import('./api/api').PermissionVO[]) => {
    for (const n of list) {
      if (n.path) set.add(n.path)
      if (n.children?.length) walk(n.children)
    }
  }
  walk(nodes)
  return set
}

/**
 * 应用启动 / 会话恢复时刷新菜单。
 * - 管理员：调用 /admin/auth/menus
 * - 商户：调用 /merchant/auth/menus（含 RBAC 链解析）
 * 解决持久化 session 因 menus=[] 导致侧边栏空白的问题。
 */
function useMenuRefresh() {
  const { isLoggedIn, isMerchant, setMenus, setPermissions } = useAuthStore()
  useEffect(() => {
    if (!isLoggedIn) return
    if (isMerchant) {
      merchantPortalApi.menus()
        .then(res => { if (res.data?.data?.length) setMenus(res.data.data) })
        .catch(() => {})
      merchantPortalApi.permCodes()
        .then(res => { if (res.data?.data) setPermissions(res.data.data) })
        .catch(() => {})
    } else {
      authApi.menus()
        .then(res => { if (res.data?.data?.length) setMenus(res.data.data) })
        .catch(() => {})
    }
  }, [isLoggedIn, isMerchant])
}

export default function App() {
  useMenuRefresh()
  return (
    <BrowserRouter>
      <ErrorBoundary>
        <Suspense fallback={<LoadingFallback />}>
          <Routes>
          {/* ── 公共路由 ── */}
          <Route path="/login"          element={<LoginPage />} />
          <Route path="/merchant/login" element={<MerchantLoginPage />} />

          {/* ── 管理员路由 ── */}
          <Route path="/" element={<ProtectedRoute><MainLayout /></ProtectedRoute>}>
            <Route index element={<Navigate to="/dashboard" replace />} />
            <Route path="dashboard"              element={<DashboardPage />} />

            <Route path="users"                  element={<UserListPage />} />
            <Route path="technicians"            element={<TechnicianListPage />} />
            <Route path="technicians/audit"      element={<TechnicianAuditPage />} />
            <Route path="merchants"              element={<MerchantListPage />} />
            <Route path="orders"                 element={<OrderListPage />} />
            <Route path="orders/history"         element={<OrderHistoryPage />} />
            <Route path="orders/:orderId"        element={<OrderDetailPage />} />
            <Route path="vehicles"               element={<VehicleListPage />} />
            <Route path="vehicles/dispatch"      element={<VehicleDispatchPage />} />

            {/* 门店订单 */}
            <Route path="walkin"                 element={<WalkinSessionPage />} />

            <Route path="operation/category"     element={<CategoryPage />} />
            <Route path="operation/banner"       element={<BannerPage />} />
            <Route path="operation/reviews"      element={<ReviewPage />} />
            <Route path="coupons"                element={<CouponListPage />} />

            <Route path="finance"                element={<FinancePage />} />
            <Route path="finance/withdraw"       element={<WithdrawAuditPage />} />
            <Route path="finance/overview"       element={<FinanceOverviewPage />} />
            <Route path="finance/income"         element={<IncomeRecordPage />} />
            <Route path="finance/expense"        element={<ExpenseManagePage />} />
            <Route path="finance/salary"         element={<SalaryManagePage />} />
            <Route path="finance/settlement"     element={<TechnicianSettlementPage />} />

            <Route path="admin/staff"            element={<StaffListPage />} />
            <Route path="admin/positions"        element={<PositionListPage />} />
            <Route path="system/roles"           element={<RoleListPage />} />
            <Route path="admin/menus"            element={<MenuManagePage />} />
            <Route path="system/permissions"     element={<PermissionTreePage />} />

            <Route path="system/config"          element={<SysConfigPage />} />
            <Route path="system/dept"            element={<DeptManagePage />} />
            <Route path="system/dict"            element={<DictManagePage />} />
            <Route path="system/param"           element={<SysParamPage />} />
            <Route path="system/notice"          element={<NoticePage />} />
            <Route path="system/log"             element={<LogManagePage />} />

            <Route path="monitor/online"         element={<OnlineUserPage />} />
            <Route path="monitor/job"            element={<JobManagePage />} />
            <Route path="monitor/server"         element={<ServerMonitorPage />} />
            <Route path="monitor/cache"          element={<CacheMonitorPage />} />

            {/* 币种管理 */}
            <Route path="system/currency"        element={<CurrencyManagePage />} />

            <Route path="system/banner"          element={<Navigate to="/operation/banner"   replace />} />
            <Route path="system/category"        element={<Navigate to="/operation/category" replace />} />

            {/* 旧式路径兼容重定向（admin/ 前缀风格 → 新式路由）*/}
            <Route path="admin/category"         element={<Navigate to="/operation/category" replace />} />
            <Route path="admin/banner"           element={<Navigate to="/operation/banner"   replace />} />
            <Route path="admin/review"           element={<Navigate to="/operation/reviews"  replace />} />
            <Route path="admin/reviews"          element={<Navigate to="/operation/reviews"  replace />} />
            <Route path="admin/order"            element={<Navigate to="/orders"             replace />} />
            <Route path="admin/orders"           element={<Navigate to="/orders"             replace />} />
            <Route path="admin/member"           element={<Navigate to="/users"              replace />} />
            <Route path="admin/members"          element={<Navigate to="/users"              replace />} />
            <Route path="admin/technician"       element={<Navigate to="/technicians"        replace />} />
            <Route path="admin/technicians"      element={<Navigate to="/technicians"        replace />} />
            <Route path="admin/merchant"         element={<Navigate to="/merchants"          replace />} />
            <Route path="admin/merchants"        element={<Navigate to="/merchants"          replace />} />
            <Route path="admin/vehicle"          element={<Navigate to="/vehicles"           replace />} />
            <Route path="admin/vehicles"         element={<Navigate to="/vehicles"           replace />} />
            <Route path="admin/coupon"           element={<Navigate to="/coupons"            replace />} />
            <Route path="admin/coupons"          element={<Navigate to="/coupons"            replace />} />
            <Route path="admin/role"             element={<Navigate to="/system/roles"       replace />} />
            <Route path="admin/roles"            element={<Navigate to="/system/roles"       replace />} />
            <Route path="admin/dept"             element={<Navigate to="/system/dept"        replace />} />
            <Route path="admin/permission"       element={<Navigate to="/system/permissions" replace />} />
            <Route path="admin/permissions"      element={<Navigate to="/system/permissions" replace />} />
            <Route path="admin/menu"             element={<Navigate to="/admin/menus"        replace />} />
            <Route path="admin/notice"           element={<Navigate to="/system/notice"      replace />} />
            <Route path="admin/log"              element={<Navigate to="/system/log"         replace />} />
            <Route path="admin/dict"             element={<Navigate to="/system/dict"        replace />} />
            <Route path="admin/sysconfig"        element={<Navigate to="/system/config"      replace />} />
            <Route path="admin/announce"         element={<Navigate to="/system/notice"      replace />} />
            <Route path="admin/monitor/online"   element={<Navigate to="/monitor/online"     replace />} />
            <Route path="admin/monitor/job"      element={<Navigate to="/monitor/job"        replace />} />
            <Route path="admin/monitor/server"   element={<Navigate to="/monitor/server"     replace />} />
            <Route path="admin/monitor/cache"    element={<Navigate to="/monitor/cache"      replace />} />
            <Route path="admin/dashboard"        element={<Navigate to="/dashboard"          replace />} />

            {/* 任何未匹配路径 → 重定向到仪表板，防止内容区空白 */}
            <Route path="*"                      element={<Navigate to="/dashboard"          replace />} />
          </Route>

          {/* ── 商户端路由（与管理员共用同一套页面组件，通过 usePortalScope 区分上下文）── */}
          <Route path="/merchant" element={<MerchantRoute><MainLayout /></MerchantRoute>} >
            <Route index element={<Navigate to="/merchant/dashboard" replace />} />
            {/* 共用管理员页面 — usePortalScope Hook 自动切换数据来源 */}
            <Route path="dashboard"                element={<DashboardPage />} />
            <Route path="orders"                   element={<OrderListPage />} />
            <Route path="orders/history"           element={<OrderHistoryPage />} />
            <Route path="technicians"              element={<TechnicianListPage />} />
            <Route path="members"                  element={<UserListPage />} />
            <Route path="vehicles"                 element={<VehicleListPage />} />
            <Route path="vehicles/dispatch"        element={<VehicleDispatchPage />} />
            <Route path="coupons"                  element={<CouponListPage />} />
            {/* 门店订单 */}
            <Route path="walkin"                   element={<WalkinSessionPage />} />
            {/* 运营管理 */}
            <Route path="operation/category"       element={<CategoryPage />} />
            <Route path="operation/banner"         element={<BannerPage />} />
            <Route path="operation/reviews"        element={<ReviewPage />} />
            <Route path="operation/notices"        element={<NoticePage />} />
            {/* 财务管理 */}
            <Route path="finance"                  element={<FinancePage />} />
            <Route path="finance/withdraw"         element={<WithdrawAuditPage />} />
            <Route path="finance/overview"         element={<FinanceOverviewPage />} />
            <Route path="finance/income"           element={<IncomeRecordPage />} />
            <Route path="finance/expense"          element={<ExpenseManagePage />} />
            <Route path="finance/salary"           element={<SalaryManagePage />} />
            <Route path="finance/settlement"       element={<TechnicianSettlementPage />} />
            {/* 商户专属功能页 */}
            <Route path="profile"                  element={<MerchantProfilePage />} />
            <Route path="perm/staff"               element={<MerchantStaffPage />} />
            <Route path="perm/roles"               element={<MerchantRolePage />} />
            <Route path="perm/dept"                element={<MerchantDeptPage />} />
            <Route path="perm/positions"           element={<MerchantPositionPage />} />
            {/* 公告管理 */}
            <Route path="announce/internal"        element={<AnnouncePage type={1} />} />
            <Route path="announce/customer"        element={<AnnouncePage type={2} />} />
            {/* 结算币种配置 */}
            <Route path="settings/currency"        element={<MerchantCurrencyPage />} />

            {/* 任何未匹配路径 → 重定向到商户仪表板，防止内容区空白 */}
            <Route path="*"                        element={<Navigate to="/merchant/dashboard" replace />} />
          </Route>

          <Route path="*" element={<Navigate to="/dashboard" replace />} />
        </Routes>
      </Suspense>
    </ErrorBoundary>
    </BrowserRouter>
  )
}
