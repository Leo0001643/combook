/**
 * 时间戳工具
 *
 * 后端时间字段以 UTC 秒级时间戳（number）为主；
 * 格式化时按浏览器本地时区输出。兼容历史 ISO / 数字字符串。
 */
import type { Dayjs } from 'dayjs'
import dayjs from 'dayjs'

function toUnixSeconds(n: number): number {
  const x = Math.floor(Number(n))
  return x > 1e12 ? Math.floor(x / 1000) : x
}

/** 归一为 Unix 秒：秒/毫秒时间戳、纯数字字符串、ISO 日期字符串 */
export function toUnixSec(ts: number | string | null | undefined): number | null {
  if (ts == null || ts === '') return null
  if (typeof ts === 'string') {
    const t = ts.trim()
    if (/^\d+$/.test(t)) return toUnixSeconds(Number(t))
    const ms = Date.parse(t)
    return Number.isFinite(ms) ? Math.floor(ms / 1000) : null
  }
  if (!Number.isFinite(ts)) return null
  return toUnixSeconds(ts)
}

/** 毫秒时间戳（用于时长、距现在多久等计算） */
export function toEpochMs(ts: number | string | null | undefined): number | null {
  const s = toUnixSec(ts)
  return s == null ? null : s * 1000
}

/** 格式化本地日期时间；无效时返回 '-' */
export function fmtTime(ts: number | string | null | undefined, fmt = 'YYYY-MM-DD HH:mm:ss'): string {
  const sec = toUnixSec(ts)
  if (sec == null) return '-'
  return dayjs(sec * 1000).format(fmt)
}

export function fmtDate(ts: number | string | null | undefined): string {
  return fmtTime(ts, 'YYYY-MM-DD')
}

export function fmtClock(ts: number | string | null | undefined): string {
  return fmtTime(ts, 'HH:mm')
}

/** dayjs → Unix 秒（查询参数） */
export function toEpochSec(d: Dayjs | null | undefined): number | null {
  if (!d || !d.isValid()) return null
  return Math.floor(d.valueOf() / 1000)
}

/** Unix 秒 → dayjs（DatePicker / RangePicker） */
export function fromEpochSec(ts: number | null | undefined): Dayjs | null {
  if (ts == null || !Number.isFinite(ts)) return null
  return dayjs(toUnixSeconds(ts) * 1000)
}

/** 接口时间字段 → dayjs（diff、比较用） */
export function dayjsFromApi(ts: number | string | null | undefined): Dayjs | null {
  const sec = toUnixSec(ts)
  return sec == null ? null : dayjs(sec * 1000)
}
