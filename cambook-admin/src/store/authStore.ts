import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import type { PermissionVO } from '../api/api'

export interface AdminUser {
  userId: number
  username: string
  avatar?: string
  userType?: number
}

export interface MerchantUser {
  merchantId: number
  merchantName: string
  merchantNameZh?: string
  merchantLogo?: string
  merchantMobile?: string
}

interface AuthState {
  isLoggedIn: boolean
  user: AdminUser | null
  merchant: MerchantUser | null
  accessToken: string | null
  permissions: string[]
  menus: PermissionVO[]
  /** true = 当前登录身份是商户，false = 管理员 */
  isMerchant: boolean

  setLogin: (user: AdminUser, accessToken: string, permissions: string[], menus: PermissionVO[]) => void
  setMerchantLogin: (merchant: MerchantUser, accessToken: string, menus?: PermissionVO[]) => void
  setLogout: () => void
  updateToken: (accessToken: string) => void
  setMenus: (menus: PermissionVO[]) => void
  setPermissions: (permissions: string[]) => void
  hasPermission: (code: string) => boolean
}

const EMPTY_STATE = {
  isLoggedIn: false,
  user: null,
  merchant: null,
  accessToken: null,
  permissions: [],
  menus: [],
  isMerchant: false,
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      ...EMPTY_STATE,

      setLogin: (user, accessToken, permissions, menus) => set({
        isLoggedIn: true,
        user,
        merchant: null,
        accessToken,
        permissions,
        menus,
        isMerchant: false,
      }),

      setMerchantLogin: (merchant, accessToken, menus = []) => set({
        isLoggedIn: true,
        user: null,
        merchant,
        accessToken,
        permissions: ['*'],
        menus,
        isMerchant: true,
      }),

      setLogout: () => set({ ...EMPTY_STATE }),

      updateToken: (accessToken) => set({ accessToken }),

      setMenus: (menus) => set({ menus }),

      setPermissions: (permissions) => set({ permissions }),

      hasPermission: (code: string) => {
        const perms = get().permissions
        return perms.includes('*') || perms.includes(code)
      },
    }),
    { name: 'cambook-admin-auth' }
  )
)
