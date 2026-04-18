/**
 * useServiceCategories — 按当前身份（管理员/商户）拉取服务类目列表
 *
 * 返回值：
 *  - categories       子类目 + 无子项的独立顶层类目（叶节点），用于选择器 / 服务定价列表
 *  - parentCategories 仅一级分组（parentId === 0），用于分类筛选 Tab
 *  - allCategories    完整列表
 *  - loading
 *
 * 遵循开闭原则：类目来源变化只需修改此 hook，调用方无感知。
 */
import { useState, useEffect } from 'react'
import { usePortalScope } from './usePortalScope'

export interface ServiceCategory {
  id: number
  parentId: number
  nameZh: string
  icon?: string
  price?: number
  duration?: number
  isSpecial?: number   // 0=常规 1=特殊
}

export function useServiceCategories(merchantId?: number) {
  const { categoryAllEnabled } = usePortalScope()
  const [allCategories,    setAllCategories]    = useState<ServiceCategory[]>([])
  const [categories,       setCategories]       = useState<ServiceCategory[]>([])
  const [parentCategories, setParentCategories] = useState<ServiceCategory[]>([])
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    setLoading(true)
    categoryAllEnabled(merchantId)
      .then(res => {
        const raw: any[] = res.data?.data?.list ?? res.data?.data ?? []
        const all: ServiceCategory[] = raw.map(c => ({
          id:        c.id,
          parentId:  c.parentId ?? 0,
          nameZh:    c.nameZh ?? c.name ?? c.nameEn ?? '未命名',
          icon:      c.icon,
          price:     c.price     != null ? Number(c.price)     : undefined,
          duration:  c.duration  != null ? Number(c.duration)  : undefined,
          isSpecial: c.isSpecial != null ? Number(c.isSpecial) : 0,
        }))
        const parentIds = new Set(all.filter(c => c.parentId !== 0).map(c => c.parentId))
        setAllCategories(all)
        // 子类目 + 没有子项的顶层类目（独立叶节点）都作为可选服务项
        setCategories(all.filter(c => c.parentId !== 0 || !parentIds.has(c.id)))
        setParentCategories(all.filter(c => c.parentId === 0))
      })
      .catch(() => { setAllCategories([]); setCategories([]); setParentCategories([]) })
      .finally(() => setLoading(false))
  }, [merchantId])  // eslint-disable-line react-hooks/exhaustive-deps

  return { categories, parentCategories, allCategories, loading }
}
