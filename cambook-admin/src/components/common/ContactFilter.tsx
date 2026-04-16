import { Input, Dropdown } from 'antd'
import type { MenuProps } from 'antd'
import { SendOutlined, DownOutlined, WechatOutlined } from '@ant-design/icons'
import type { CSSProperties } from 'react'

export type ContactFilterType = 'telegram' | 'wechat' | 'facebook'

/** 平台配置：icon 渲染在彩色小圆角背景上 */
const CFG: Record<ContactFilterType, {
  label:       string
  icon:        React.ReactNode
  bg:          string
  placeholder: string
}> = {
  telegram: {
    label:       'Telegram',
    icon:        <SendOutlined style={{ fontSize: 11 }} />,
    bg:          '#229ED9',
    placeholder: 'Telegram 账号',
  },
  wechat: {
    label:       '微信',
    icon:        <WechatOutlined style={{ fontSize: 12 }} />,
    bg:          '#07C160',
    placeholder: '微信账号',
  },
  facebook: {
    label:       'Facebook',
    icon:        <span style={{ fontWeight: 900, fontSize: 11, lineHeight: 1, letterSpacing: '-0.5px' }}>f</span>,
    bg:          '#1877F2',
    placeholder: 'Facebook 账号',
  },
}

/** 彩色平台圆角图标 */
function PlatIcon({ type, size = 20 }: { type: ContactFilterType; size?: number }) {
  const c = CFG[type]
  return (
    <span style={{
      display:        'inline-flex',
      alignItems:     'center',
      justifyContent: 'center',
      width:          size,
      height:         size,
      borderRadius:   5,
      background:     c.bg,
      color:          '#fff',
      flexShrink:     0,
      lineHeight:     1,
    }}>
      {c.icon}
    </span>
  )
}

interface Props {
  contactType:  ContactFilterType
  value?:       string
  onTypeChange: (t: ContactFilterType) => void
  onChange:     (v: string) => void
  onSearch:     () => void
  /** 显示哪些选项，默认全部三个 */
  options?:     ContactFilterType[]
  style?:       CSSProperties
}

/**
 * 联系方式单输入框筛选器
 *
 * 前缀：彩色平台图标（点击弹出下拉切换联系方式类型）
 * 文本框：输入账号关键词
 */
export default function ContactFilter({
  contactType, value, onTypeChange, onChange, onSearch,
  options = ['telegram', 'wechat', 'facebook'],
  style,
}: Props) {
  const cfg = CFG[contactType]

  const menuItems: MenuProps['items'] = options.map(k => ({
    key: k,
    label: (
      <div style={{ display: 'flex', alignItems: 'center', gap: 9, padding: '2px 0' }}>
        <PlatIcon type={k} size={22} />
        <span style={{
          fontSize:   13,
          fontWeight: contactType === k ? 600 : 400,
          color:      contactType === k ? CFG[k].bg : '#374151',
        }}>
          {CFG[k].label}
        </span>
        {contactType === k && (
          <span style={{
            marginLeft: 'auto', width: 6, height: 6, borderRadius: '50%',
            background: CFG[k].bg, flexShrink: 0,
          }} />
        )}
      </div>
    ),
  }))

  const prefix = (
    <Dropdown
      menu={{
        items:        menuItems,
        selectedKeys: [contactType],
        onClick:      ({ key }) => { onTypeChange(key as ContactFilterType); onChange('') },
      }}
      trigger={['click']}
      placement="bottomLeft"
    >
      <div style={{
        display:      'flex',
        alignItems:   'center',
        gap:          3,
        cursor:       'pointer',
        userSelect:   'none',
        paddingRight: 8,
        marginRight:  4,
        borderRight:  '1px solid #eaecf5',
      }}>
        <PlatIcon type={contactType} size={20} />
        <DownOutlined style={{ fontSize: 7, color: '#b8bfcc', marginTop: 1 }} />
      </div>
    </Dropdown>
  )

  return (
    <Input
      prefix={prefix}
      placeholder={cfg.placeholder}
      allowClear
      value={value ?? ''}
      onChange={e => onChange(e.target.value)}
      onPressEnter={onSearch}
      style={{ width: 192, ...style }}
    />
  )
}
