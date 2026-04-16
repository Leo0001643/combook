/**
 * 全局通用日期时间区间选择器
 *
 * 封装了：
 *  - 中文日历 locale（直接内联 shortWeekDays / shortMonths，确保不回退英文）
 *  - 精确到秒的 showTime，开始默认 00:00:00，结束默认 23:59:59
 *  - 统一的格式、样式和图标
 *
 * 用法：
 *   <DateTimeRangePicker
 *     placeholder={['注册开始', '注册结束']}
 *     value={dateRange}
 *     onChange={(dates, strings) => { setDateRange(dates); setPage(1) }}
 *   />
 */
import { DatePicker } from 'antd'
import type { Dayjs } from 'dayjs'
import dayjs from 'dayjs'
import { CalendarOutlined } from '@ant-design/icons'
import { zhCNPickerLocale } from '../../utils/datePicker'
import { INPUT_STYLE } from './tableComponents'

const { RangePicker } = DatePicker

export const DT_FORMAT = 'YYYY-MM-DD HH:mm:ss'

interface Props {
  value?: [Dayjs, Dayjs] | null
  onChange?: (
    dates:       [Dayjs, Dayjs] | null,
    dateStrings: [string, string] | null,
  ) => void
  placeholder?: [string, string]
  style?: React.CSSProperties
  size?: 'small' | 'middle' | 'large'
  allowClear?: boolean
}

export default function DateTimeRangePicker({
  value,
  onChange,
  placeholder = ['开始时间', '结束时间'],
  style,
  size = 'middle',
  allowClear = true,
}: Props) {
  return (
    <RangePicker
      locale={zhCNPickerLocale}
      value={value}
      placeholder={placeholder}
      size={size}
      allowClear={allowClear}
      showTime={{
        defaultValue: [
          dayjs('00:00:00', 'HH:mm:ss'),
          dayjs('23:59:59', 'HH:mm:ss'),
        ],
      }}
      format={DT_FORMAT}
      suffixIcon={<CalendarOutlined style={{ color: '#6366f1', fontSize: 12 }} />}
      style={{ ...INPUT_STYLE, width: 360, borderRadius: 8, ...style }}
      onChange={(dates, dateStrings) => {
        const ds = dates as [Dayjs, Dayjs] | null
        const ss = dateStrings as [string, string]
        onChange?.(ds, ss[0] && ss[1] ? ss : null)
      }}
    />
  )
}
