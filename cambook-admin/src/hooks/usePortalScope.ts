/**
 * usePortalScope — 门户作用域 Hook（Strategy Pattern）
 *
 * 统一封装"管理员"与"商户"两种身份对同一业务实体的 API 操作。
 * 业务页面只需调用 scope.xxx() 而无需关心当前是管理员还是商户身份。
 *
 * 设计原则：
 *   - 开闭原则：新增身份类型只需扩展此 hook，不修改业务页面
 *   - DRY：Admin 和 Merchant 共用同一套页面组件，仅数据范围不同
 *   - 单一职责：每个业务页面只关注 UI 与交互，不关注数据来源的身份差异
 */

import { useAuthStore } from '../store/authStore'
import {
  orderApi, technicianApi, memberApi,
  vehicleApi, couponApi, reviewApi, noticeApi,
  categoryApi, bannerApi, merchantPortalApi, currencyApi,
} from '../api/api'
import request from '../api/request'

export function usePortalScope() {
  const { isMerchant } = useAuthStore()
  const isAdmin = !isMerchant

  return {
    isAdmin,
    isMerchant,

    // ── 数据看板 ─────────────────────────────────────────────────────────────
    dashboardStats: (period = 'week') =>
      isMerchant
        ? merchantPortalApi.dashboard(period)
        : request.get<any>('/admin/dashboard/stats', { params: { period } }),

    // ── 订单管理 ─────────────────────────────────────────────────────────────
    orderList: (params: any) =>
      isMerchant ? merchantPortalApi.orders(params) : orderApi.list(params),

    orderDetail: (id: number) =>
      isMerchant ? merchantPortalApi.orderDetail(id) : orderApi.detail(id),

    orderCancel: (id: number, reason?: string) =>
      isMerchant ? merchantPortalApi.orderCancel(id, reason) : orderApi.cancel(id),

    orderDelete: (id: number) =>
      isMerchant ? merchantPortalApi.orderDelete(id) : orderApi.delete(id),

    orderCreate: (data: any) =>
      isMerchant ? merchantPortalApi.orderCreate(data) : orderApi.create(data, data._merchantId),

    // ── 技师管理 ─────────────────────────────────────────────────────────────
    technicianList: (params: any) =>
      isMerchant ? merchantPortalApi.technicians(params) : technicianApi.list(params),

    technicianCreate: (data: any) =>
      isMerchant ? merchantPortalApi.technicianCreate(data) : technicianApi.create(data),

    technicianUpdateStatus: (id: number, status: number) =>
      isMerchant
        ? merchantPortalApi.technicianStatus(id, status)
        : technicianApi.updateStatus(id, status),

    technicianUpdateOnlineStatus: (id: number, onlineStatus: number) =>
      isMerchant
        ? merchantPortalApi.technicianOnlineStatus(id, onlineStatus)
        : technicianApi.updateOnlineStatus(id, onlineStatus),

    technicianSetFeatured: (id: number, featured: number) =>
      isMerchant
        ? merchantPortalApi.technicianFeatured(id, featured)
        : technicianApi.setFeatured(id, featured),

    technicianDelete: (id: number) =>
      isMerchant ? merchantPortalApi.technicianDelete(id) : technicianApi.delete(id),

    technicianUpdate: (data: any) =>
      isMerchant ? merchantPortalApi.technicianUpdate(data) : technicianApi.update(data),

    technicianAudit: (params: any) => technicianApi.audit(params),

    technicianForceLogout: (id: number) => technicianApi.forceLogout(id),

    // ── 会员管理 ─────────────────────────────────────────────────────────────
    memberList: (params: any) =>
      isMerchant ? merchantPortalApi.members(params) : memberApi.list(params),

    memberUpdate: (data: any) =>
      isMerchant ? merchantPortalApi.memberUpdate(data) : memberApi.update(data),

    memberUpdateStatus: (id: number, status: number) =>
      isAdmin ? memberApi.updateStatus(id, status) : Promise.reject('无权操作'),

    // ── 车辆管理 ─────────────────────────────────────────────────────────────
    vehicleList: (params: any) =>
      isMerchant ? merchantPortalApi.vehicles(params) : vehicleApi.list(params),

    vehicleAdd: (data: any) =>
      isMerchant ? merchantPortalApi.vehicleAdd(data) : vehicleApi.add(data),

    vehicleEdit: (data: any) =>
      isMerchant ? merchantPortalApi.vehicleEdit(data) : vehicleApi.edit(data),

    vehicleDelete: (id: number) =>
      isMerchant ? merchantPortalApi.vehicleDelete(id) : vehicleApi.delete(id),

    vehicleStatus: (id: number, status: number) =>
      isMerchant
        ? merchantPortalApi.vehicleStatus(id, status)
        : request.patch<any>(`/admin/vehicle/${id}/status`, null, { params: { status } }),

    // ── 优惠券管理 ───────────────────────────────────────────────────────────
    couponList: (params: any) =>
      isMerchant ? merchantPortalApi.couponList(params) : couponApi.list(params),

    couponAdd: (data: any) =>
      isMerchant ? merchantPortalApi.couponAdd(data) : couponApi.add(data),

    couponEdit: (data: any) =>
      isMerchant ? merchantPortalApi.couponEdit(data) : couponApi.edit(data),

    couponUpdateStatus: (id: number, status: number) =>
      isMerchant ? merchantPortalApi.couponStatus(id, status) : couponApi.updateStatus(id, status),

    couponDelete: (id: number) =>
      isMerchant ? merchantPortalApi.couponDelete(id) : couponApi.delete(id),

    // ── 评价管理 ─────────────────────────────────────────────────────────────
    reviewList: (params: any) =>
      isMerchant ? merchantPortalApi.reviewList(params) : reviewApi.list(params),

    reviewStats: () =>
      isMerchant ? merchantPortalApi.reviewStats() : Promise.resolve({ data: null }),

    reviewReply: (id: number, reply: string) =>
      isMerchant ? merchantPortalApi.reviewReply(id, reply) : Promise.reject('管理员请用状态变更'),

    reviewUpdateStatus: (id: number, status: number) =>
      isAdmin ? reviewApi.updateStatus(id, status) : Promise.reject('无权操作'),

    reviewDelete: (id: number) =>
      isAdmin ? reviewApi.delete(id) : Promise.reject('无权操作'),

    // ── 通知公告 ─────────────────────────────────────────────────────────────
    noticeList: (params: any) =>
      isMerchant ? merchantPortalApi.noticeList(params) : noticeApi.list(params),

    noticeAdd: (data: any) =>
      isMerchant ? merchantPortalApi.noticeAdd(data) : noticeApi.add(data),

    noticeEdit: (data: any) =>
      isMerchant ? merchantPortalApi.noticeEdit(data) : noticeApi.edit(data),

    noticeUpdateStatus: (id: number, status: number) =>
      isMerchant ? merchantPortalApi.noticeStatus(id, status) : Promise.reject('管理员暂不支持状态变更'),

    noticeDelete: (id: number) =>
      isMerchant ? merchantPortalApi.noticeDelete(id) : noticeApi.delete(id),

    // ── 服务类目 ─────────────────────────────────────────────────────────────
    categoryList: (params?: any) =>
      isMerchant ? merchantPortalApi.categoryList(params) : categoryApi.list(params),

    /** 获取当前商户（或指定商户）下已启用的服务类目，供选择器使用 */
    categoryAllEnabled: (merchantId?: number) =>
      isMerchant
        ? merchantPortalApi.categoryList({ status: 1, size: 200 })
        : categoryApi.list({ status: 1, size: 200, ...(merchantId != null ? { merchantId } : {}) }),

    categoryAdd: (data: any) =>
      isMerchant ? merchantPortalApi.categoryAdd(data) : categoryApi.add(data),

    categoryEdit: (data: any) =>
      isMerchant ? merchantPortalApi.categoryEdit(data) : categoryApi.edit(data),

    categoryDelete: (id: number) =>
      isMerchant ? merchantPortalApi.categoryDelete(id) : categoryApi.delete(id),

    // ── 轮播图 ───────────────────────────────────────────────────────────────
    bannerList: (params?: any) =>
      isMerchant ? merchantPortalApi.bannerList(params) : bannerApi.list(params),

    bannerAdd: (data: any) =>
      isMerchant ? merchantPortalApi.bannerAdd(data) : bannerApi.add(data),

    bannerEdit: (data: any) =>
      isMerchant ? merchantPortalApi.bannerEdit(data) : bannerApi.edit(data),

    bannerDelete: (id: number) =>
      isMerchant ? merchantPortalApi.bannerDelete(id) : bannerApi.delete(id),

    bannerStatus: (id: number, status: number) =>
      isMerchant
        ? merchantPortalApi.bannerStatus(id, status)
        : request.patch<any>(`/admin/banner/${id}/status`, null, { params: { status } }),

    // ── 财务 ─────────────────────────────────────────────────────────────────
    financeOverview: () =>
      isMerchant
        ? merchantPortalApi.financeOverview()
        : request.get<any>('/admin/finance/overview'),

    // ── 结算币种 ─────────────────────────────────────────────────────────────
    /** 获取当前上下文（商户或管理员）可用的已启用币种列表 */
    enabledCurrencies: () =>
      isMerchant
        ? merchantPortalApi.currencyEnabled()
        : currencyApi.list(1),        // Admin 上下文：全平台启用币种

    /** 商户保存自己的币种配置 */
    saveCurrencyConfig: (configs: any[]) =>
      merchantPortalApi.currencySave(configs),
  }
}
