/**
 * 服务项目目录 + 技师专属定价模块
 *
 * 设计原则：
 *  - SERVICES_CATALOG  — 全局服务项目，含分类、时长、门店基础指导价
 *  - techPricingStore  — 技师专属定价覆盖表（模块级可变对象，跨页共享）
 *    每位技师对每个服务项目可设置独立价格；
 *    未设置则回退到 SERVICES_CATALOG.basePrice
 *
 * 真实项目接入后端时，只需把 techPricingStore 替换为 API 调用即可。
 */

// ── 服务项目分类 ─────────────────────────────────────────────────────────────

export const SERVICE_CATEGORIES = ['全部', '推拿', '足疗', 'SPA', '套餐', '面部', '理疗']

// ── 服务项目目录 ─────────────────────────────────────────────────────────────

export interface ServiceItem {
  id: number
  name: string
  category: string
  duration: number   // 分钟
  basePrice: number  // 门店指导价（技师无专属定价时使用）
  icon: string
}

export const SERVICES_CATALOG: ServiceItem[] = [
  { id: 1,  name: '全身精油推拿 90min', category: '推拿', duration: 90,  basePrice: 298, icon: '💆' },
  { id: 2,  name: '肩颈舒缓 30min',     category: '推拿', duration: 30,  basePrice: 98,  icon: '🤲' },
  { id: 3,  name: '足疗 60min',         category: '足疗', duration: 60,  basePrice: 128, icon: '🦶' },
  { id: 4,  name: 'SPA 护理套餐',       category: 'SPA',  duration: 90,  basePrice: 180, icon: '🛁' },
  { id: 5,  name: '全套豪华套餐',       category: '套餐', duration: 120, basePrice: 480, icon: '👑' },
  { id: 6,  name: '面部护理 60min',     category: '面部', duration: 60,  basePrice: 168, icon: '✨' },
  { id: 7,  name: '针灸理疗 45min',     category: '理疗', duration: 45,  basePrice: 138, icon: '🔮' },
  { id: 8,  name: '热石推拿 75min',     category: '推拿', duration: 75,  basePrice: 258, icon: '🪨' },
  { id: 9,  name: '精油浴 45min',       category: 'SPA',  duration: 45,  basePrice: 148, icon: '🌺' },
  { id: 10, name: '颈椎调理 30min',     category: '理疗', duration: 30,  basePrice: 118, icon: '🦴' },
]

// ── 技师专属定价存储（模块级单例，跨组件共享同一引用）─────────────────────

/**
 * 结构：techId → serviceId → 价格
 * 例：techPricingStore[101][1] = 368  表示技师101对服务1收费368
 */
export const techPricingStore: Record<number, Record<number, number>> = {
  101: { 1: 368, 2: 88,  3: 168, 4: 200, 8: 288 },
  102: { 1: 480, 3: 128, 4: 180, 5: 560, 9: 168 },
  103: { 1: 520, 5: 680, 6: 260, 8: 320          },
  104: { 2: 78,  6: 188, 7: 158, 10: 128         },
  105: { 1: 398, 2: 98,  7: 168, 10: 138         },
}

// ── 工具函数 ─────────────────────────────────────────────────────────────────

/** 获取技师对指定服务的实际价格（专属价 > 门店基础价） */
export function getTechServicePrice(techId: number, serviceId: number): number {
  return techPricingStore[techId]?.[serviceId]
    ?? SERVICES_CATALOG.find(s => s.id === serviceId)?.basePrice
    ?? 0
}

/** 设置技师专属价格（会影响所有引用该存储的页面） */
export function setTechServicePrice(techId: number, serviceId: number, price: number): void {
  if (!techPricingStore[techId]) techPricingStore[techId] = {}
  techPricingStore[techId][serviceId] = price
}

/** 删除技师专属价格（回退到门店基础价） */
export function removeTechServicePrice(techId: number, serviceId: number): void {
  if (techPricingStore[techId]) {
    delete techPricingStore[techId][serviceId]
  }
}

/** 获取技师可提供的所有服务（含专属价） */
export function getTechServices(techId: number): Array<ServiceItem & { techPrice: number; hasOverride: boolean }> {
  return SERVICES_CATALOG.map(s => ({
    ...s,
    techPrice:   getTechServicePrice(techId, s.id),
    hasOverride: techPricingStore[techId]?.[s.id] !== undefined,
  }))
}
