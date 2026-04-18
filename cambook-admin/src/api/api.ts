/**
 * CamBook Admin API 统一封装
 * 所有接口路径基于 vite proxy：/api/xxx → http://localhost:8080/xxx
 */
import request from './request'
export type { PageData } from './request'

// ──────────────────────────────────────────────────────────────────────────────
// 文件上传（本地存储）
// ──────────────────────────────────────────────────────────────────────────────

export const uploadApi = {
  /** 上传图片，返回访问 URL */
  image: (file: File) => {
    const form = new FormData()
    form.append('file', file)
    return request.post<any>('/admin/upload/image', form, {
      headers: { 'Content-Type': 'multipart/form-data' },
    })
  },
  /** 上传视频，返回访问 URL */
  video: (file: File) => {
    const form = new FormData()
    form.append('file', file)
    return request.post<any>('/admin/upload/video', form, {
      headers: { 'Content-Type': 'multipart/form-data' },
    })
  },
}

// ──────────────────────────────────────────────────────────────────────────────
// Types
// ──────────────────────────────────────────────────────────────────────────────

export interface LoginVO {
  userId: number
  username: string
  token: string
  permissions: string[]
}

export interface PermissionVO {
  id: number
  parentId: number
  name: string
  code?: string | null
  type: number          // 1=目录  2=菜单  3=按钮/接口
  path?: string | null
  component?: string | null
  icon?: string | null
  sort: number
  visible: number
  status: number
  children?: PermissionVO[]
}

export interface RoleVO {
  id: number
  roleName: string
  roleCode: string
  remark?: string
  sort: number
  status: number
  permissionIds?: number[]
  createTime?: string
}

export interface MemberVO {
  id: number
  mobile: string
  nickname: string
  avatar?: string
  gender: number
  status: number
  createdAt: string
  orderCount: number
  totalAmount: number
}

export interface TechnicianVO {
  id: number
  techNo: string
  realName: string
  mobile: string
  telegram?: string
  nickname: string
  avatar?: string
  photos?: string
  videoUrl?: string
  gender: number
  nationality?: string
  lang?: string
  introZh?: string
  age?: number
  height?: number
  weight?: number
  bust?: string
  province?: string
  serviceCity?: string
  rating: number
  reviewCount: number
  orderCount: number
  todayOrderCount?: number
  goodReviewRate: number
  onlineStatus: number
  auditStatus: number
  rejectReason?: string
  skillTags?: string
  serviceItemIds?: number[]
  isFeatured: number
  status: number
  merchantId?: number
  merchantName?: string
  commissionRate?: number
  settlementMode?: number
  commissionType?: number
  commissionRatePct?: number
  commissionCurrency?: string
  createTime: string
}

export interface OrderVO {
  id: number
  orderNo: string
  memberId: number
  memberNickname?: string
  technicianId?: number
  technicianNickname?: string
  serviceName: string
  serviceDuration?: number
  addressDetail?: string
  appointTime?: string
  originalAmount?: number
  discountAmount?: number
  payAmount?: number
  payType?: number
  status: number
  isReviewed?: number
  remark?: string
  createTime: string
}

export interface BannerVO {
  id: number
  title: string
  imageUrl: string
  linkUrl?: string
  sort: number
  status: number
  createdAt: string
}

export interface VehicleVO {
  id: number
  plateNo: string
  brand: string
  model: string
  color: string
  memberId: number
  memberNickname?: string
  status: number
  createdAt: string
}

export interface StaffVO {
  id: number
  username: string
  realName?: string
  avatar?: string
  email?: string
  mobile?: string
  positionId?: number
  positionName?: string
  status: number
  roleIds?: number[]
  roleNames?: string[]
  createTime?: string
}

export interface PositionVO {
  id: number
  deptId?: number
  name: string
  code: string
  remark?: string
  sort: number
  status: number
  /** 1=全量权限（如总裁），0=按分配 */
  fullAccess?: number
  createTime?: string
}

export interface AnnouncementVO {
  id: number
  merchantId?: number
  deptId?: number
  deptName?: string
  title: string
  content: string
  /** 1=内部公告  2=客户公告 */
  type: number
  /** 1=本部门  2=全商户 */
  targetType: number
  /** 0=草稿  1=已发布 */
  status: number
  createBy?: string
  createTime?: string
}

// ──────────────────────────────────────────────────────────────────────────────
// Auth
// ──────────────────────────────────────────────────────────────────────────────

export const authApi = {
  /** 管理员账号密码登录 */
  login: (data: { username: string; password: string }) =>
    request.post<{ code: number; data: LoginVO }>('/admin/auth/login', data),

  /** 退出登录 */
  logout: () =>
    request.post('/admin/auth/logout'),

  /** 获取当前用户动态菜单树 */
  menus: () =>
    request.get<{ code: number; data: PermissionVO[] }>('/admin/auth/menus'),
}

// ──────────────────────────────────────────────────────────────────────────────
// 会员管理
// ──────────────────────────────────────────────────────────────────────────────

export interface MemberListParams {
  page?:      number
  size?:      number
  keyword?:   string   // 模糊匹配手机号 OR 昵称
  telegram?:  string
  address?:   string
  status?:    number
  gender?:    number
  level?:     number
  lang?:      string
  startDate?: string   // yyyy-MM-dd
  endDate?:   string   // yyyy-MM-dd
}

export const memberApi = {
  list: (params: MemberListParams) =>
    request.get<any>('/admin/member/list', { params }),

  detail: (id: number) =>
    request.get<any>(`/admin/member/${id}`),

  update: (data: { id: number; nickname?: string; avatar?: string; gender?: number; telegram?: string; address?: string }) =>
    request.put<any>('/admin/member', null, { params: data }),

  updateStatus: (id: number, status: number) =>
    request.patch<any>(`/admin/member/${id}/status`, { status }),
}

// ──────────────────────────────────────────────────────────────────────────────
// 技师管理
// ──────────────────────────────────────────────────────────────────────────────

export const technicianApi = {
  list: (params: {
    page?: number; size?: number; keyword?: string;
    auditStatus?: number; onlineStatus?: number;
    serviceCity?: string; gender?: number; nationality?: string;
  }) => request.get<any>('/admin/technician/list', { params }),

  detail: (id: number) =>
    request.get<any>(`/admin/technician/${id}`),

  create: (data: Record<string, any>) =>
    request.post<any>('/admin/technician/create', null, { params: data }),

  update: (data: Record<string, any>) =>
    request.put<any>('/admin/technician', null, { params: data }),

  audit: (data: { id: number; auditStatus: number; rejectReason?: string }) =>
    request.post<any>('/admin/technician/audit', data),

  updateStatus: (id: number, status: number) =>
    request.patch<any>(`/admin/technician/${id}/status`, null, { params: { status } }),

  updateOnlineStatus: (id: number, onlineStatus: number) =>
    request.post<any>(`/admin/technician/${id}/online-status`, null, { params: { onlineStatus } }),

  setFeatured: (id: number, featured: number) =>
    request.patch<any>(`/admin/technician/${id}/featured`, null, { params: { featured } }),

  delete: (id: number) =>
    request.delete<any>(`/admin/technician/${id}`),
}

// ──────────────────────────────────────────────────────────────────────────────
// 订单管理
// ──────────────────────────────────────────────────────────────────────────────

export const orderApi = {
  list: (params: { page?: number; size?: number; status?: number; keyword?: string; startDate?: string; endDate?: string; merchantId?: number; technicianId?: number; memberId?: number }) =>
    request.get<any>('/admin/order/list', { params }),

  detail: (id: number) =>
    request.get<any>(`/admin/order/${id}`),

  cancel: (id: number) =>
    request.patch<any>(`/admin/order/${id}/cancel`),

  delete: (id: number) =>
    request.delete<any>(`/admin/order/${id}`),
}

// ──────────────────────────────────────────────────────────────────────────────
// 车辆管理
// ──────────────────────────────────────────────────────────────────────────────

export const vehicleApi = {
  list: (params: { page?: number; size?: number; keyword?: string; status?: number; merchantId?: number }) =>
    request.get<any>('/admin/vehicle/list', { params }),

  add: (data: { plateNo: string; brand: string; model: string; color: string; memberId: number }) =>
    request.post<any>('/admin/vehicle', data),

  edit: (data: { id: number; plateNo?: string; brand?: string; model?: string; color?: string; status?: number }) =>
    request.put<any>('/admin/vehicle', data),

  delete: (id: number) =>
    request.delete<any>(`/admin/vehicle/${id}`),
}

// ──────────────────────────────────────────────────────────────────────────────
// Banner 管理
// ──────────────────────────────────────────────────────────────────────────────

export const bannerApi = {
  list: (params?: { page?: number; size?: number; status?: number }) =>
    request.get<any>('/admin/banner/list', { params }),

  add: (data: { title: string; imageUrl: string; linkUrl?: string; sort?: number }) =>
    request.post<any>('/admin/banner', data),

  edit: (data: { id: number; title: string; imageUrl: string; linkUrl?: string; sort?: number; status?: number }) =>
    request.put<any>('/admin/banner', data),

  delete: (id: number) =>
    request.delete<any>(`/admin/banner/${id}`),
}

// ──────────────────────────────────────────────────────────────────────────────
// 角色管理
// ──────────────────────────────────────────────────────────────────────────────

export const roleApi = {
  list: () =>
    request.get<{ code: number; data: RoleVO[] }>('/admin/role/list'),

  add: (data: { roleName: string; roleCode: string; remark?: string; sort?: number }) =>
    request.post<any>('/admin/role', data),

  edit: (data: { id: number; roleName?: string; remark?: string; sort?: number }) =>
    request.put<any>('/admin/role', data),

  delete: (id: number) =>
    request.delete<any>(`/admin/role/${id}`),

  /** 查询角色已分配的权限 ID 列表 */
  getPermissions: (roleId: number) =>
    request.get<{ code: number; data: number[] }>(`/admin/role/${roleId}/permissions`),

  /** 全量保存角色-权限关联（permissionIds 逗号分隔） */
  savePermissions: (roleId: number, permissionIds: number[]) =>
    request.post<any>(`/admin/role/${roleId}/permissions`, { permissionIds: permissionIds.join(',') }),

  /** 获取全量权限树（用于分配选择） */
  permissionTree: () =>
    request.get<{ code: number; data: PermissionVO[] }>('/admin/role/permission-tree'),
}

// ──────────────────────────────────────────────────────────────────────────────
// 员工管理
// ──────────────────────────────────────────────────────────────────────────────

export const staffApi = {
  page: (params: { current?: number; size?: number; keyword?: string; status?: number; positionId?: number }) =>
    request.get<any>('/admin/staff/page', { params }),

  add: (data: { username: string; password?: string; realName?: string; email?: string; mobile?: string; positionId?: number; status?: number; roleIds?: number[] }) =>
    request.post<any>('/admin/staff', data),

  edit: (data: { id: number; realName?: string; email?: string; mobile?: string; positionId?: number; status?: number; password?: string; roleIds?: number[] }) =>
    request.put<any>('/admin/staff', data),

  delete: (id: number) =>
    request.delete<any>(`/admin/staff/${id}`),

  updateStatus: (id: number, status: number) =>
    request.patch<any>(`/admin/staff/${id}/status`, { status }),

  assignRoles: (id: number, roleIds: number[]) =>
    request.post<any>(`/admin/staff/${id}/roles`, { roleIds: roleIds.join(',') }),
}

// ──────────────────────────────────────────────────────────────────────────────
// 职位管理
// ──────────────────────────────────────────────────────────────────────────────

export const positionApi = {
  list: () =>
    request.get<any>('/admin/position/list'),

  add: (data: { name: string; code: string; remark?: string; sort?: number; status?: number }) =>
    request.post<any>('/admin/position', data),

  edit: (data: { id: number; name?: string; remark?: string; sort?: number }) =>
    request.put<any>('/admin/position', data),

  delete: (id: number) =>
    request.delete<any>(`/admin/position/${id}`),

  updateStatus: (id: number, status: number) =>
    request.patch<any>(`/admin/position/${id}/status`, { status }),
}

// ──────────────────────────────────────────────────────────────────────────────
// 权限管理
// ──────────────────────────────────────────────────────────────────────────────

export const permissionApi = {
  tree: () =>
    request.get<{ code: number; data: PermissionVO[] }>('/admin/permission/tree'),

  merchantTree: () =>
    request.get<{ code: number; data: PermissionVO[] }>('/admin/permission/merchant-tree'),

  add: (data: { name: string; code?: string; type: number; parentId?: number; icon?: string; path?: string; component?: string; sort?: number; visible?: number; portalType?: number }) =>
    request.post<any>('/admin/permission', data),

  edit: (data: { id: number; name: string; code?: string; type: number; icon?: string; path?: string; component?: string; sort?: number; visible?: number }) =>
    request.put<any>('/admin/permission', data),

  delete: (id: number) =>
    request.delete<any>(`/admin/permission/${id}`),

  /** 移动节点到新父节点（可同步修改排序值） */
  move: (data: { id: number; targetParentId: number; sort?: number }) =>
    request.put<any>('/admin/permission/move', data),
}

// ──────────────────────────────────────────────────────────────────────────────
// 部门管理
// ──────────────────────────────────────────────────────────────────────────────

export const deptApi = {
  list: (params?: { name?: string; status?: number }) =>
    request.get<any>('/admin/dept/list', { params }),
  add: (data: any) => request.post<any>('/admin/dept', data),
  edit: (data: any) => request.put<any>('/admin/dept', data),
  delete: (id: number) => request.delete<any>(`/admin/dept/${id}`),
  updateStatus: (id: number, status: number) =>
    request.patch<any>(`/admin/dept/${id}/status`, { status }),
}

// ──────────────────────────────────────────────────────────────────────────────
// 字典管理
// ──────────────────────────────────────────────────────────────────────────────

export const dictApi = {
  typeList: (params?: any) => request.get<any>('/admin/dict/type/list', { params }),
  addType: (data: any) => request.post<any>('/admin/dict/type', data),
  editType: (data: any) => request.put<any>('/admin/dict/type', data),
  deleteType: (id: number) => request.delete<any>(`/admin/dict/type/${id}`),

  dataList: (dictType: string, status?: number) =>
    request.get<any>('/common/dict/data/list', { params: { dictType, status } }),
  addData: (data: any) => request.post<any>('/admin/dict/data', data),
  editData: (data: any) => request.put<any>('/admin/dict/data', data),
  deleteData: (id: number) => request.delete<any>(`/admin/dict/data/${id}`),
}

// ──────────────────────────────────────────────────────────────────────────────
// 系统参数配置
// ──────────────────────────────────────────────────────────────────────────────

export const sysConfigApi = {
  list: (params?: any) => request.get<any>('/admin/config/list', { params }),
  add: (data: any) => request.post<any>('/admin/config', data),
  edit: (data: any) => request.put<any>('/admin/config', data),
  delete: (id: number) => request.delete<any>(`/admin/config/${id}`),
}

// ──────────────────────────────────────────────────────────────────────────────
// 通知公告
// ──────────────────────────────────────────────────────────────────────────────

export const noticeApi = {
  list: (params?: any) => request.get<any>('/admin/notice/list', { params }),
  add: (data: any) => request.post<any>('/admin/notice', data),
  edit: (data: any) => request.put<any>('/admin/notice', data),
  delete: (id: number) => request.delete<any>(`/admin/notice/${id}`),
}

// ──────────────────────────────────────────────────────────────────────────────
// 操作日志
// ──────────────────────────────────────────────────────────────────────────────

export const operLogApi = {
  list: (params?: any) => request.get<any>('/admin/operlog/list', { params }),
  delete: (id: number) => request.delete<any>(`/admin/operlog/${id}`),
  clean: () => request.delete<any>('/admin/operlog/clean'),
}

// ──────────────────────────────────────────────────────────────────────────────
// 商户管理
// ──────────────────────────────────────────────────────────────────────────────

export const merchantApi = {
  list: (params?: any) => request.get<any>('/admin/merchant/list', { params }),
  detail: (id: number) => request.get<any>(`/admin/merchant/${id}`),
  create: (data: any) => request.post<any>('/admin/merchant/create', null, { params: data }),
  updateStatus: (id: number, status: number) =>
    request.patch<any>(`/admin/merchant/${id}/status`, { status }),
  audit: (id: number, auditStatus: number, rejectReason?: string) =>
    request.patch<any>(`/admin/merchant/${id}/audit`, { auditStatus, rejectReason }),
  updateCommission: (id: number, commissionRate: number) =>
    request.patch<any>(`/admin/merchant/${id}/commission`, { commissionRate }),
  delete: (id: number) => request.delete<any>(`/admin/merchant/${id}`),
}

// ──────────────────────────────────────────────────────────────────────────────
// 服务类目
// ──────────────────────────────────────────────────────────────────────────────

export const categoryApi = {
  list: (params?: any) => request.get<any>('/admin/category/list', { params }),
  add: (data: any) => request.post<any>('/admin/category', data),
  edit: (data: any) => request.put<any>('/admin/category', data),
  delete: (id: number) => request.delete<any>(`/admin/category/${id}`),
  /** 通用——获取所有启用的一级/子级类目（管理员和商户均可使用） */
  allEnabled: () => request.get<any>('/admin/category/list', { params: { status: 1, size: 200 } }),
}

// ──────────────────────────────────────────────────────────────────────────────
// 优惠券
// ──────────────────────────────────────────────────────────────────────────────

export const couponApi = {
  list: (params?: { page?: number; size?: number; keyword?: string; type?: number; status?: number; merchantId?: number }) => request.get<any>('/admin/coupon/list', { params }),
  add: (data: any) => request.post<any>('/admin/coupon', data),
  edit: (data: any) => request.put<any>('/admin/coupon', data),
  updateStatus: (id: number, status: number) =>
    request.patch<any>(`/admin/coupon/${id}/status`, { status }),
  delete: (id: number) => request.delete<any>(`/admin/coupon/${id}`),
}

// ──────────────────────────────────────────────────────────────────────────────
// 财务管理
// ──────────────────────────────────────────────────────────────────────────────

export const financeApi = {
  overview: () => request.get<any>('/admin/finance/overview'),
  records: (params?: any) => request.get<any>('/admin/finance/records', { params }),
  wallets: (params?: any) => request.get<any>('/admin/finance/wallets', { params }),
}

// ──────────────────────────────────────────────────────────────────────────────
// 币种管理（Admin 侧）
// ──────────────────────────────────────────────────────────────────────────────

export const currencyApi = {
  /** 获取全部币种列表（可按状态过滤） */
  list: (status?: number) =>
    request.get<any>('/admin/currency/list', { params: status != null ? { status } : {} }),

  /** 新增币种 */
  add: (data: any) => request.post<any>('/admin/currency', data),

  /** 编辑币种信息 */
  update: (data: any) => request.put<any>('/admin/currency', data),

  /** 更新汇率 */
  updateRate: (code: string, rateToUsd: number) =>
    request.patch<any>(`/admin/currency/${code}/rate`, null, { params: { rateToUsd } }),

  /** 启用 / 停用 */
  toggleStatus: (id: number, status: number) =>
    request.patch<any>(`/admin/currency/${id}/status`, null, { params: { status } }),

  /** 查看指定商户的币种配置 */
  merchantConfig: (merchantId: number) =>
    request.get<any>(`/admin/currency/merchant/${merchantId}`),

  /** Admin 为商户批量配置币种 */
  merchantConfigure: (merchantId: number, configs: any[]) =>
    request.post<any>(`/admin/currency/merchant/${merchantId}/configure`, configs),
}

// ──────────────────────────────────────────────────────────────────────────────
// 评价管理
// ──────────────────────────────────────────────────────────────────────────────

export const reviewApi = {
  list: (params?: any) => request.get<any>('/admin/review/list', { params }),
  updateStatus: (id: number, status: number) =>
    request.patch<any>(`/admin/review/${id}/status`, { status }),
  delete: (id: number) => request.delete<any>(`/admin/review/${id}`),
}

// ──────────────────────────────────────────────────────────────────────────────
// 商户端 Portal API
// ──────────────────────────────────────────────────────────────────────────────

export const merchantPortalApi = {
  /** 商户登录（merchantNo 仅员工账号必填，商户主可留空） */
  login: (data: { merchantNo?: string; account: string; password: string }) =>
    request.post<any>('/merchant/auth/login', data),

  /** 当前登录用户信息（职位、部门、用户名） */
  me: () => request.get<any>('/merchant/auth/me'),

  /** 当前用户有效菜单树（动态侧边栏） */
  menus: () => request.get<{ data: PermissionVO[] }>('/merchant/auth/menus'),

  /** 当前用户操作权限码列表（用于 PermGuard 按钮级控制） */
  permCodes: () => request.get<{ data: string[] }>('/merchant/auth/perm-codes'),

  /** 数据看板（period: day|week|month|year） */
  dashboard: (period = 'week') => request.get<any>('/merchant/dashboard/stats', { params: { period } }),

  /** 商户自身信息 */
  profile: () => request.get<any>('/merchant/dashboard/profile'),

  /** 订单列表 */
  orders: (params?: any) => request.get<any>('/merchant/order/list', { params }),

  /** 订单详情 */
  orderDetail: (id: number) => request.get<any>(`/merchant/order/${id}`),

  /** 取消订单 */
  orderCancel: (id: number, reason?: string) =>
    request.patch<any>(`/merchant/order/${id}/cancel`, null, { params: { reason: reason ?? '前台取消' } }),

  /** 结算订单（组合支付） */
  orderSettle: (id: number, paidAmount: number, payRecords?: string) =>
    request.post<any>(`/merchant/order/${id}/settle`, null, {
      params: { paidAmount, ...(payRecords ? { payRecords } : {}) },
    }),

  /** 删除订单 */
  orderDelete: (id: number) => request.delete<any>(`/merchant/order/${id}`),

  /** 技师列表 */
  technicians: (params?: any) => request.get<any>('/merchant/technician/list', { params }),

  /** 技师详情 */
  technicianDetail: (id: number) => request.get<any>(`/merchant/technician/${id}`),

  /** 新增技师 */
  technicianCreate: (data: any) => request.post<any>('/merchant/technician/create', null, { params: data }),

  /** 编辑技师 */
  technicianUpdate: (data: any) => request.put<any>('/merchant/technician', null, { params: data }),

  /** 启用/停用技师 */
  technicianStatus: (id: number, status: number) =>
    request.post<any>(`/merchant/technician/${id}/status`, null, { params: { status } }),

  /** 设置在线状态 */
  technicianOnlineStatus: (id: number, onlineStatus: number) =>
    request.post<any>(`/merchant/technician/${id}/online-status`, null, { params: { onlineStatus } }),

  /** 设置/取消推荐 */
  technicianFeatured: (id: number, featured: number) =>
    request.post<any>(`/merchant/technician/${id}/featured`, null, { params: { featured } }),

  /** 删除技师 */
  technicianDelete: (id: number) => request.post<any>(`/merchant/technician/${id}/delete`, null),

  /** 查询技师专属定价列表 */
  technicianPricingList: (technicianId: number) =>
    request.get<any>('/merchant/technician/pricing/list', { params: { technicianId } }),

  /** 批量保存技师专属定价（覆盖式，传所有特殊项目价格） */
  technicianPricingSaveAll: (technicianId: number, items: { serviceItemId: number; price: number }[]) =>
    request.post<any>('/merchant/technician/pricing/saveAll', items, { params: { technicianId } }),

  /** 删除技师单个专属定价 */
  technicianPricingDelete: (technicianId: number, serviceItemId: number) =>
    request.post<any>('/merchant/technician/pricing/delete', null, { params: { technicianId, serviceItemId } }),

  /** 会员列表 */
  members: (params?: any) => request.get<any>('/merchant/member/list', { params }),

  /** 编辑会员 */
  memberUpdate: (data: any) => request.put<any>('/merchant/member', null, { params: data }),

  /** 车辆列表 */
  vehicles: (params?: any) => request.get<any>('/merchant/vehicle/list', { params }),

  /** 新增车辆 */
  vehicleAdd: (data: any) => request.post<any>('/merchant/vehicle/add', null, { params: data }),

  /** 编辑车辆 */
  vehicleEdit: (data: any) => request.post<any>('/merchant/vehicle/edit', null, { params: data }),

  /** 删除车辆 */
  vehicleDelete: (id: number) => request.post<any>(`/merchant/vehicle/${id}/delete`, null),

  /** 修改车辆状态 */
  vehicleStatus: (id: number, status: number) =>
    request.post<any>(`/merchant/vehicle/${id}/status`, null, { params: { status } }),

  /** 财务概览 */
  financeOverview: () => request.get<any>('/merchant/finance/overview'),

  /** 员工列表 */
  staffList: (params?: any) => request.get<any>('/merchant/staff/list', { params }),

  /** 新增员工 */
  staffAdd: (data: any) => request.post<any>('/merchant/staff/add', data),

  /** 编辑员工 */
  staffEdit: (data: any) => request.post<any>('/merchant/staff/edit', data),

  /** 修改员工状态 */
  staffStatus: (id: number, status: number) => request.post<any>('/merchant/staff/status', { id, status }),

  /** 删除员工 */
  staffDelete: (id: number) => request.post<any>('/merchant/staff/delete', { id }),

  /** 优惠券列表 */
  couponList: (params?: any) => request.get<any>('/merchant/coupon/list', { params }),

  /** 新增优惠券 */
  couponAdd: (data: any) => request.post<any>('/merchant/coupon/add', null, { params: data }),

  /** 编辑优惠券 */
  couponEdit: (data: any) => request.post<any>('/merchant/coupon/edit', null, { params: data }),

  /** 优惠券状态 */
  couponStatus: (id: number, status: number) => request.post<any>('/merchant/coupon/status', { id, status }),

  /** 删除优惠券 */
  couponDelete: (id: number) => request.post<any>('/merchant/coupon/delete', { id }),

  /** 评价列表 */
  reviewList: (params?: any) => request.get<any>('/merchant/review/list', { params }),

  /** 评价统计 */
  reviewStats: () => request.get<any>('/merchant/review/stats'),

  /** 回复评价 */
  reviewReply: (id: number, reply: string) => request.post<any>('/merchant/review/reply', { id, reply }),

  /** 公告列表 */
  noticeList: (params?: any) => request.get<any>('/merchant/notice/list', { params }),

  /** 新增公告 */
  noticeAdd: (data: any) => request.post<any>('/merchant/notice/add', null, { params: data }),

  /** 编辑公告 */
  noticeEdit: (data: any) => request.post<any>('/merchant/notice/edit', null, { params: data }),

  /** 公告状态 */
  noticeStatus: (id: number, status: number) => request.post<any>('/merchant/notice/status', { id, status }),

  /** 删除公告 */
  noticeDelete: (id: number) => request.post<any>('/merchant/notice/delete', { id }),

  /** 服务类目列表（平台公共 + 本商户私有） */
  categoryList: (params?: any) => request.get<any>('/merchant/category/list', { params }),

  /** 新增私有服务类目 */
  categoryAdd: (data: any) => request.post<any>('/merchant/category/add', null, { params: data }),

  /** 编辑私有服务类目 */
  categoryEdit: (data: any) => request.post<any>('/merchant/category/edit', null, { params: data }),

  /** 删除私有服务类目 */
  categoryDelete: (id: number) => request.post<any>(`/merchant/category/${id}/delete`, null),

  /** 商户轮播图列表 */
  bannerList: (params?: any) => request.get<any>('/merchant/banner/list', { params }),

  /** 新增商户轮播图 */
  bannerAdd: (data: any) => request.post<any>('/merchant/banner/add', null, { params: data }),

  /** 编辑商户轮播图 */
  bannerEdit: (data: any) => request.post<any>('/merchant/banner/edit', null, { params: data }),

  /** 删除商户轮播图 */
  bannerDelete: (id: number) => request.post<any>(`/merchant/banner/${id}/delete`, null),

  /** 修改轮播图状态 */
  bannerStatus: (id: number, status: number) =>
    request.post<any>(`/merchant/banner/${id}/status`, null, { params: { status } }),

  // ── RBAC 权限分配 ────────────────────────────────────────────────────────────
  /** 获取部门已分配菜单 */
  deptMenuGet: (deptId: number) => request.get<any>(`/merchant/perm/dept/${deptId}/menus`),
  /** 设置部门菜单权限 */
  deptMenuSet: (deptId: number, menuKeys: string[]) =>
    request.post<any>(`/merchant/perm/dept/${deptId}/menus`, null, { params: { menuKeys } }),
  /** 获取职位已分配菜单 */
  positionMenuGet: (positionId: number) => request.get<any>(`/merchant/perm/position/${positionId}/menus`),
  /** 设置职位菜单权限 */
  positionMenuSet: (positionId: number, menuKeys: string[]) =>
    request.post<any>(`/merchant/perm/position/${positionId}/menus`, null, { params: { menuKeys } }),
  /** 获取员工已分配菜单 */
  staffMenuGet: (staffId: number) => request.get<any>(`/merchant/perm/staff/${staffId}/menus`),
  /** 设置员工菜单权限 */
  staffMenuSet: (staffId: number, menuKeys: string[]) =>
    request.post<any>(`/merchant/perm/staff/${staffId}/menus`, null, { params: { menuKeys } }),
  /** 获取部门下的职位（级联选择用） */
  deptPositions: (deptId: number) => request.get<any>(`/merchant/perm/dept/${deptId}/positions`),

  // ── 部门管理 ─────────────────────────────────────────────────────────────────
  /** 部门列表 */
  deptList: (params?: any) => request.get<any>('/merchant/dept/list', { params }),

  /** 新增部门 */
  deptAdd: (data: any) => request.post<any>('/merchant/dept', null, { params: data }),

  /** 编辑部门 */
  deptEdit: (data: any) => request.post<any>('/merchant/dept/edit', null, { params: data }),

  /** 删除部门 */
  deptDelete: (id: number) => request.post<any>(`/merchant/dept/${id}/delete`, null),

  /** 修改部门状态 */
  deptStatus: (id: number, status: number) =>
    request.post<any>(`/merchant/dept/${id}/status`, null, { params: { status } }),

  // ── 职位管理 ─────────────────────────────────────────────────────────────────
  /** 职位列表 */
  positionList: () => request.get<any>('/merchant/position/list'),

  /** 新增职位 */
  positionAdd: (data: any) => request.post<any>('/merchant/position', null, { params: data }),

  /** 编辑职位 */
  positionEdit: (data: any) => request.post<any>('/merchant/position/edit', null, { params: data }),

  /** 删除职位 */
  positionDelete: (id: number) => request.post<any>(`/merchant/position/${id}/delete`, null),

  /** 修改职位状态 */
  positionStatus: (id: number, status: number) =>
    request.post<any>(`/merchant/position/${id}/status`, null, { params: { status } }),

  // ── 公告管理 ──────────────────────────────────────────────────────────────

  /** 公告列表 */
  announceList: (params: { type?: number; status?: number; keyword?: string; page?: number; size?: number }) =>
    request.get<any>('/merchant/announce/list', { params }),

  /** 新增公告 */
  announceAdd: (data: {
    title: string; content: string; type: number;
    targetType: number; status: number;
    deptId?: number; deptName?: string;
  }) => request.post<any>('/merchant/announce/add', null, { params: data }),

  /** 编辑公告 */
  announceEdit: (data: {
    id: number; title?: string; content?: string;
    targetType?: number; deptId?: number; deptName?: string;
  }) => request.post<any>('/merchant/announce/edit', null, { params: data }),

  /** 更新公告状态 */
  announceStatus: (id: number, status: number) =>
    request.post<any>('/merchant/announce/status', null, { params: { id, status } }),

  /** 删除公告 */
  announceDelete: (id: number) =>
    request.post<any>('/merchant/announce/delete', null, { params: { id } }),

  /** 内部公告未读数 */
  announceUnreadCount: () =>
    request.get<any>('/merchant/announce/unread-count'),

  /** 未读公告列表（铃铛弹窗） */
  announceUnreadList: () =>
    request.get<any>('/merchant/announce/unread-list'),

  /** 标记已读，返回最新未读数 */
  announceRead: (id: number) =>
    request.post<any>('/merchant/announce/read', null, { params: { id } }),

  // ── 技师结算 ─────────────────────────────────────────────────────────────────
  /** 结算列表（分页） */
  settlementList: (params?: any) => request.get<any>('/merchant/settlement/list', { params }),

  /** 结算单详情（含订单明细） */
  settlementDetail: (id: number) => request.get<any>(`/merchant/settlement/${id}`),

  /** 某技师汇总摘要 */
  settlementSummary: (technicianId: number) => request.get<any>(`/merchant/settlement/summary/${technicianId}`),

  /** 手动生成结算单 */
  settlementGenerate: (data: any) => request.post<any>('/merchant/settlement/generate', data),

  /** 标记已打款 */
  settlementPay: (id: number, data: any) => request.patch<any>(`/merchant/settlement/${id}/pay`, data),

  /** 调整结算金额（奖励/扣款） */
  settlementAdjust: (id: number, data: any) => request.patch<any>(`/merchant/settlement/${id}/adjust`, data),

  /** 撤销结算 */
  settlementRevoke: (id: number) => request.patch<any>(`/merchant/settlement/${id}/revoke`, null),

  /** 批量打款 */
  settlementBatchPay: (data: any) => request.post<any>('/merchant/settlement/batch-pay', data),

  /** 获取结算周期建议 */
  settlementPeriods: (technicianId: number, settlementMode: number) =>
    request.get<any[]>('/merchant/settlement/suggest-periods', { params: { technicianId, settlementMode } }),

  // ── 币种配置 ────────────────────────────────────────────────────────────────
  /** 获取商户币种配置（含全局可选列表） */
  currencyConfig: () => request.get<any>('/merchant/currency/config'),

  /** 获取商户已启用的币种（支付下拉用） */
  currencyEnabled: () => request.get<any>('/merchant/currency/enabled'),

  /** 保存商户币种配置 */
  currencySave: (configs: any[]) => request.post<any>('/merchant/currency/configure', configs),

  // ── 散客接待（Walk-in Session）────────────────────────────────────────────────
  /**
   * 散客接待列表（分页）
   * 字段：id, sessionNo, wristbandNo, memberName, memberMobile,
   *       technicianId, technicianName, technicianNo, technicianMobile,
   *       status(0接待中/1服务中/2待结算/3已结算/4已取消),
   *       totalAmount, paidAmount, checkInTime, checkOutTime,
   *       orderItems[](serviceId, name, duration, unitPrice, svcStatus, startTime, endTime)
   */
  walkinList: (params?: {
    page?: number; size?: number; keyword?: string; status?: number; date?: string
  }) => request.get<any>('/merchant/walkin/list', { params }),

  /** 接待详情（含服务项列表） */
  walkinDetail: (id: number) => request.get<any>(`/merchant/walkin/${id}`),

  /** 新增接待（仅创建 session，不含服务项） */
  walkinCreate: (data: {
    wristbandNo: string; memberName?: string; memberMobile?: string;
    technicianId?: number; technicianName?: string; technicianNo?: string; technicianMobile?: string;
    remark?: string;
  }) => request.post<any>('/merchant/walkin/create', null, { params: data }),

  /**
   * 新增接待（含服务项，原子操作）
   * 服务项以 JSON 字符串传递，格式：[{"serviceItemId":1,"serviceName":"...","serviceDuration":60,"unitPrice":288}]
   * 若任一服务项插入失败，整个事务回滚，session 也不会留在库中。
   */
  walkinCreateWithItems: (data: {
    wristbandNo: string; memberName?: string; memberMobile?: string;
    technicianId?: number; technicianName?: string; technicianNo?: string; technicianMobile?: string;
    remark?: string; itemsJson?: string;
  }) => request.post<any>('/merchant/walkin/createWithItems', null, { params: data }),

  /** 修改接待基本信息 */
  walkinUpdate: (id: number, data: any) =>
    request.post<any>(`/merchant/walkin/${id}/update`, null, { params: data }),

  /** 添加服务项 */
  walkinAddItem: (id: number, data: {
    serviceItemId: number; serviceName: string; serviceDuration: number; unitPrice: number
  }) => request.post<any>(`/merchant/walkin/${id}/addItem`, null, { params: data }),

  /** 删除服务项 */
  walkinRemoveItem: (id: number, orderId: number) =>
    request.delete<any>(`/merchant/walkin/${id}/items/${orderId}`),

  /** 修改服务项单价 */
  walkinUpdateItemPrice: (id: number, orderId: number, unitPrice: number) =>
    request.post<any>(`/merchant/walkin/${id}/items/${orderId}/price`, null, { params: { unitPrice } }),

  /**
   * 开始服务（设置 start_time，order.status → 5服务中）
   * → 前端 svcStatus 变为 1，进度条开始计时
   */
  walkinStartService: (id: number, orderId: number) =>
    request.post<any>(`/merchant/walkin/${id}/items/${orderId}/start`),

  /**
   * 结束服务项（order.status → 6已完成）
   * → 前端 svcStatus 变为 2，进度条停止
   */
  walkinFinishService: (id: number, orderId: number) =>
    request.post<any>(`/merchant/walkin/${id}/items/${orderId}/finish`),

  /** 前台结算（收款，session.status → 3） */
  walkinSettle: (id: number, paidAmount: number, remark?: string) =>
    request.post<any>(`/merchant/walkin/${id}/settle`, null, { params: { paidAmount, remark } }),

  /** 取消接待（仅无进行中服务项时允许，session.status → 4） */
  walkinCancel: (id: number, reason?: string) =>
    request.post<any>(`/merchant/walkin/${id}/cancel`, null, { params: { reason } }),
}

