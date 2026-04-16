import axios, { type AxiosResponse, type InternalAxiosRequestConfig } from 'axios'
import { message } from 'antd'
import { useAuthStore } from '../store/authStore'

/** 统一响应格式 */
export interface ApiResponse<T = unknown> {
  code: number
  message: string
  data: T
  timestamp: number
}

/** 分页数据格式 */
export interface PageData<T = unknown> {
  records: T[]
  total: number
  size: number
  current: number
  pages: number
}

/**
 * 将 params 中的数组序列化为 Spring 可识别的重复参数格式：
 * { ids: [1,2,3] } → "ids=1&ids=2&ids=3"（而非 axios 默认的 ids[]=1&ids[]=2）
 */
function serializeParams(params: Record<string, any>): string {
  const parts: string[] = []
  for (const key of Object.keys(params)) {
    const val = params[key]
    if (val === undefined || val === null) continue
    if (Array.isArray(val)) {
      for (const v of val) {
        if (v !== undefined && v !== null) {
          parts.push(`${encodeURIComponent(key)}=${encodeURIComponent(String(v))}`)
        }
      }
    } else {
      parts.push(`${encodeURIComponent(key)}=${encodeURIComponent(String(val))}`)
    }
  }
  return parts.join('&')
}

/** 创建 axios 实例 */
const request = axios.create({
  baseURL: '/api',
  timeout: 30000,
  paramsSerializer: { serialize: serializeParams },
})

/** 需要 form-encoded 的 HTTP 方法 */
const FORM_METHODS = ['post', 'put', 'patch']

/** 请求拦截器：注入 Token + 自动转换 form-urlencoded */
request.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    // 注入 Bearer Token
    const { accessToken } = useAuthStore.getState()
    if (accessToken) {
      config.headers.Authorization = `Bearer ${accessToken}`
    }

    // POST / PUT / PATCH 自动转为 application/x-www-form-urlencoded
    if (
      config.method &&
      FORM_METHODS.includes(config.method.toLowerCase()) &&
      config.data &&
      typeof config.data === 'object' &&
      !(config.data instanceof FormData) &&
      !(config.data instanceof URLSearchParams)
    ) {
      config.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      config.data = new URLSearchParams(
        Object.entries(config.data)
          .filter(([, v]) => v !== undefined && v !== null)
          .map(([k, v]) => [k, String(v)])
      ).toString()
    }

    return config
  },
  (error) => Promise.reject(error)
)

/** 响应拦截器：统一处理错误 */
request.interceptors.response.use(
  (response: AxiosResponse<ApiResponse>) => {
    const { code, message: msg } = response.data
    if (code === 200) return response

    if (code === 401 || code === 2005 || code === 2006) {
      useAuthStore.getState().setLogout()
      window.location.href = '/login'
      return Promise.reject(new Error('登录已过期'))
    }
    message.error(msg || '操作失败')
    return Promise.reject(new Error(msg))
  },
  (error) => {
    if (error.response?.status === 401) {
      useAuthStore.getState().setLogout()
      window.location.href = '/login'
    } else if (error.code === 'ERR_NETWORK') {
      message.error('无法连接服务器，请检查后端是否启动')
    } else {
      message.error(error.message || '网络错误，请稍后重试')
    }
    return Promise.reject(error)
  }
)

export default request
