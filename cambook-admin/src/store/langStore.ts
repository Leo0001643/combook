/**
 * 语言切换 Store — 管理后台 UI 语言偏好（持久化到 localStorage）
 *
 * 支持语言：zh（中文）/ en（English）/ vi（Tiếng Việt）/ km（ខ្មែរ）
 */
import { create } from 'zustand'
import { persist } from 'zustand/middleware'

export type AdminLang = 'zh' | 'en' | 'vi' | 'km'

export const LANG_OPTIONS: { value: AdminLang; label: string; flag: string }[] = [
  { value: 'zh', label: '中文',          flag: '🇨🇳' },
  { value: 'en', label: 'English',       flag: '🇬🇧' },
  { value: 'vi', label: 'Tiếng Việt',   flag: '🇻🇳' },
  { value: 'km', label: 'ខ្មែរ',        flag: '🇰🇭' },
]

interface LangState {
  lang: AdminLang
  setLang: (lang: AdminLang) => void
}

export const useLangStore = create<LangState>()(
  persist(
    (set) => ({
      lang: 'zh',
      setLang: (lang) => set({ lang }),
    }),
    { name: 'admin-lang' },
  ),
)

/**
 * 根据当前语言从 DictItem 中选取正确的 label 字符串。
 * 若目标语言缺失则降级为中文。
 */
export function pickLabel(
  item: { labelZh: string; labelEn?: string; labelVi?: string; labelKm?: string },
  lang: AdminLang,
): string {
  switch (lang) {
    case 'en': return item.labelEn  || item.labelZh
    case 'vi': return item.labelVi  || item.labelZh
    case 'km': return item.labelKm  || item.labelZh
    default:   return item.labelZh
  }
}
