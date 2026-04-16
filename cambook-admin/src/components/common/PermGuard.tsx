import React from 'react'
import { useAuthStore } from '../../store/authStore'

interface PermGuardProps {
  /**
   * 权限码（单个字符串或数组）
   * 数组时取 OR 逻辑：任一满足即放行
   */
  code: string | string[]
  /**
   * 无权限时渲染的降级内容，默认 null（直接隐藏）
   * 适用于需要保留只读展示的场景，如状态 Tag
   */
  fallback?: React.ReactNode
  children: React.ReactNode
}

/**
 * 按钮级权限守卫组件
 *
 * 遵循开闭原则：无需修改组件本身即可扩展权限码与降级逻辑。
 * 判断逻辑由 authStore.hasPermission 统一处理：
 *   - SUPER_ADMIN / 商户账号持有 "*" 通配符 → 全部放行
 *   - 普通管理员 → 根据角色分配的权限码集合判断
 *
 * @example 保护删除按钮
 * <PermGuard code="technician:delete">
 *   <Button danger>删除</Button>
 * </PermGuard>
 *
 * @example 状态列：有权限则可点击切换，无权限则只读展示
 * <PermGuard code="vehicle:status" fallback={<Tag>{label}</Tag>}>
 *   <Dropdown ...><Tag>...</Tag></Dropdown>
 * </PermGuard>
 */
export default function PermGuard({ code, fallback = null, children }: PermGuardProps) {
  const hasPermission = useAuthStore(s => s.hasPermission)
  const codes = Array.isArray(code) ? code : [code]
  const granted = codes.some(c => hasPermission(c))
  return granted ? <>{children}</> : <>{fallback}</>
}
