// ── dayjs 中文化：必须在 React / antd 任何模块渲染前完成 ──────────────────
import dayjs from 'dayjs'
import 'dayjs/locale/zh-cn'
import customParseFormat from 'dayjs/plugin/customParseFormat'
import advancedFormat from 'dayjs/plugin/advancedFormat'
import weekday from 'dayjs/plugin/weekday'
import localeData from 'dayjs/plugin/localeData'
import weekOfYear from 'dayjs/plugin/weekOfYear'
import isSameOrBefore from 'dayjs/plugin/isSameOrBefore'
import isSameOrAfter from 'dayjs/plugin/isSameOrAfter'

dayjs.extend(customParseFormat)
dayjs.extend(advancedFormat)
dayjs.extend(weekday)
dayjs.extend(localeData)
dayjs.extend(weekOfYear)
dayjs.extend(isSameOrBefore)
dayjs.extend(isSameOrAfter)
dayjs.locale('zh-cn')
// ─────────────────────────────────────────────────────────────────────────────

import ReactDOM from 'react-dom/client'
import App from './App'
import { ConfigProvider } from 'antd'
import { StyleProvider } from '@ant-design/cssinjs'
import zhCN from 'antd/locale/zh_CN'
import { zhCNPickerLocale } from './utils/datePicker'
import './index.css'

/**
 * 直接在 locale 对象中注入中文星期 / 月份短名称。
 *
 * antd DatePicker 内部通过 generateConfig.getShortWeekDays(locale) 和
 * getShortMonths(locale) 获取这些值，底层调用
 * dayjs().locale('zh-cn').localeData().weekdaysShort()。
 * 若 antd 预编译包内的 dayjs 实例未能成功加载 zh-cn locale，
 * 会静默降级为英文。
 *
 * 通过在 ConfigProvider locale 的 DatePicker.lang 中直接提供
 * shortWeekDays / shortMonths，可完全绕过 dayjs locale 依赖，
 * 彻底保证日历组件显示中文。
 */
const zhCNWithDates = {
  ...zhCN,
  DatePicker: zhCNPickerLocale,
}

ReactDOM.createRoot(document.getElementById('root')!).render(
  // StyleProvider hashPriority="low"：antd CSS-in-JS 使用 :where() 选择器
  // 使其特异性降为 0，index.css 中的普通选择器即可无需 !important 直接覆盖。
  <StyleProvider hashPriority="low">
    <ConfigProvider
        locale={zhCNWithDates}
        theme={{
          token: {
            // CamBook 品牌色：温暖的橙金色
            colorPrimary:          '#F5A623',
            colorLink:             '#F5A623',
            borderRadius:          8,
            fontFamily:            "'PingFang SC', 'Helvetica Neue', Arial, sans-serif",
            // 全局 placeholder 颜色
            colorTextPlaceholder:  '#9ca3af',
          },
          components: {
            Menu: {
              darkItemBg:        '#1a1f2e',
              darkSubMenuItemBg: '#141824',
              darkItemSelectedBg:'#F5A623',
            },
            Layout: {
              siderBg:    '#1a1f2e',
              triggerBg:  '#141824',
            },
          },
        }}
      >
        <App />
      </ConfigProvider>
    </StyleProvider>
)
