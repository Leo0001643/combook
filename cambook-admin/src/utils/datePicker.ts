/**
 * 中文 DatePicker / RangePicker locale 配置。
 *
 * 直接内联 shortWeekDays / shortMonths，避免 rc-picker 走
 * dayjs().locale('zh-cn').localeData() 路径失败时回退到英文。
 */
import zhCN from 'antd/locale/zh_CN'
import type { PickerLocale } from 'antd/es/date-picker/generatePicker/interface'

export const zhCNPickerLocale = {
  ...zhCN.DatePicker,
  lang: {
    ...zhCN.DatePicker?.lang,
    locale: zhCN.DatePicker?.lang?.locale ?? 'zh-cn',
    // 直接提供，无需 dayjs localeData()
    shortWeekDays: ['日', '一', '二', '三', '四', '五', '六'],
    shortMonths:   ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'],
  },
} as PickerLocale
