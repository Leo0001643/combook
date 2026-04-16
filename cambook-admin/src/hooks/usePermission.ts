import { useCallback } from 'react'
import { useAuthStore } from '../store/authStore'

/**
 * 权限判断 Hook
 *
 * 对 authStore.hasPermission 的轻量封装，支持单码或多码（OR 逻辑）。
 * 在需要在 JSX 条件渲染之外（如 sorter/disabled 逻辑）判断权限时使用。
 *
 * @example
 * const { can } = usePermission()
 * // 单码
 * if (can('technician:delete')) { ... }
 * // 多码 OR
 * if (can(['order:cancel', 'order:delete'])) { ... }
 */
export function usePermission() {
  const hasPermission = useAuthStore(s => s.hasPermission)

  const can = useCallback(
    (code: string | string[]) => {
      const codes = Array.isArray(code) ? code : [code]
      return codes.some(c => hasPermission(c))
    },
    [hasPermission],
  )

  return { can }
}
