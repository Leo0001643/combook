/**
 * useDict — 字典数据访问 Hook（带内存缓存）
 *
 * 特性：
 *  - 首次请求后结果缓存在模块级 Map，相同 dictType 不重复请求
 *  - 支持多字典批量加载
 *  - 提供工具方法：label()、color()、opts()
 *
 * 用法示例：
 *   const { label, opts } = useDict('gender')
 *   <Select options={opts()} />
 *   <Tag>{label('1')}</Tag>
 */
import { useEffect, useState, useCallback } from 'react'
import { dictApi } from '../api/api'

export interface DictItem {
  dictValue: string
  labelZh:   string
  labelEn?:  string
  labelVi?:  string
  sort:      number
  status:    number
  /** 可在 sys_dict 的 remark 字段存储 Ant Design Tag color，如 'green' / 'red' */
  remark?:   string
}

/** 模块级缓存：dictType → DictItem[] */
const CACHE = new Map<string, DictItem[]>()
/** 正在进行的请求（防止同时发多个相同请求） */
const PENDING = new Map<string, Promise<DictItem[]>>()

/** 获取字典原始数据（带缓存） */
async function fetchDict(dictType: string): Promise<DictItem[]> {
  if (CACHE.has(dictType)) return CACHE.get(dictType)!
  if (PENDING.has(dictType)) return PENDING.get(dictType)!

  const promise = dictApi.dataList(dictType, 1)
    .then(res => {
      const raw: any[] = res.data?.data ?? []
      const items: DictItem[] = raw.map(d => ({
        dictValue: String(d.dictValue ?? d.dict_value ?? ''),
        labelZh:   d.labelZh ?? d.label_zh ?? d.dictLabel ?? d.dict_label ?? d.label ?? '',
        labelEn:   d.labelEn ?? d.label_en,
        labelVi:   d.labelVi ?? d.label_vi,
        sort:      d.sort ?? 0,
        status:    d.status ?? 1,
        remark:    d.remark,
      })).sort((a, b) => a.sort - b.sort)
      CACHE.set(dictType, items)
      return items
    })
    .catch(() => {
      // 失败时不缓存，下次仍可重试
      return [] as DictItem[]
    })
    .finally(() => { PENDING.delete(dictType) })

  PENDING.set(dictType, promise)
  return promise
}

/** 主动预加载（在路由守卫或布局组件中调用，避免首屏闪烁） */
export function preloadDicts(...types: string[]) {
  types.forEach(t => fetchDict(t))
}

/** 清除缓存（单测或强制刷新场景使用） */
export function clearDictCache(dictType?: string) {
  if (dictType) {
    CACHE.delete(dictType)
  } else {
    CACHE.clear()
  }
}

/**
 * 解析 remark 字段中存储的复合元数据。
 * 支持两种格式：
 *  - 简单字符串：直接作为 color 返回（如 'green', '#3b82f6'）
 *  - JSON 对象：`{"c":"#hex","i":"emoji","b":"badge","nc":1}` — c=颜色, i=图标emoji, b=Ant Design Badge status, nc=needCurrency
 */
export function parseRemark(remark?: string | null): { color?: string; icon?: string; badge?: string; needCurrency?: boolean } {
  if (!remark) return {}
  if (remark.startsWith('{')) {
    try {
      const o = JSON.parse(remark) as Record<string, string | number>
      return {
        color:       (o.c  ?? o.color) as string | undefined,
        icon:        (o.i  ?? o.icon)  as string | undefined,
        badge:       (o.b  ?? o.badge) as string | undefined,
        needCurrency: !!(o.nc),
      }
    } catch { /* fall through */ }
  }
  return { color: remark }
}

// ── Hook ──────────────────────────────────────────────────────────────────────

interface UseDictResult {
  /** 字典数据项列表 */
  items:   DictItem[]
  loading: boolean
  /** 转换为 Ant Design Select options */
  opts:    () => { value: string; label: string }[]
  /** 根据 dictValue 获取中文 label（找不到返回 value 本身） */
  label:   (value: string | number | null | undefined) => string
  /** 根据 dictValue 获取 remark（常用于存 Tag color） */
  color:   (value: string | number | null | undefined) => string | undefined
}

export function useDict(dictType: string): UseDictResult {
  const [items, setItems]     = useState<DictItem[]>(() => CACHE.get(dictType) ?? [])
  const [loading, setLoading] = useState(!CACHE.has(dictType))

  useEffect(() => {
    if (CACHE.has(dictType)) {
      setItems(CACHE.get(dictType)!)
      setLoading(false)
      return
    }
    setLoading(true)
    fetchDict(dictType).then(list => {
      setItems(list)
      setLoading(false)
    })
  }, [dictType])

  const opts = useCallback(
    () => items.filter(i => i.status === 1).map(i => ({ value: i.dictValue, label: i.labelZh })),
    [items],
  )

  const label = useCallback(
    (value: string | number | null | undefined): string => {
      if (value == null || value === '') return '—'
      const v = String(value)
      return items.find(i => i.dictValue === v)?.labelZh ?? v
    },
    [items],
  )

  const color = useCallback(
    (value: string | number | null | undefined): string | undefined => {
      if (value == null || value === '') return undefined
      const v = String(value)
      return items.find(i => i.dictValue === v)?.remark
    },
    [items],
  )

  return { items, loading, opts, label, color }
}

/**
 * 批量加载多个字典，返回 Record<dictType, UseDictResult>
 *
 * 示例：
 *   const d = useDicts('gender', 'pay_type', 'order_status')
 *   d.gender.label('1')  // → '男'
 */
export function useDicts<T extends string>(
  ...types: T[]
): Record<T, UseDictResult> {
  const results = {} as Record<T, UseDictResult>
  // 逐个调用 useDict（hooks 数量在运行时须稳定）
  // eslint-disable-next-line react-hooks/rules-of-hooks
  types.forEach(t => { results[t] = useDict(t) })
  return results
}
