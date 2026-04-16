import { Input, Dropdown } from 'antd'
import type { MenuProps } from 'antd'
import { SendOutlined, DownOutlined } from '@ant-design/icons'
import { WechatOutlined } from '@ant-design/icons'
import type { CSSProperties } from 'react'

export type ContactFilterType = 'telegram' | 'wechat'

const CFG: Record<ContactFilterType, {
  label:       string
  icon:        React.ReactNode
  color:       string
  placeholder: string
}> = {
  telegram: { label: 'Telegram', icon: <SendOutlined />,   color: '#229ED9', placeholder: 'Telegram 账号' },
  wechat:   { label: '微信',      icon: <WechatOutlined />, color: '#07C160', placeholder: '微信账号'     },
}

interface Props {
  /** 当前选中的联系方式类型，默认 telegram */
  contactType:  ContactFilterType
  value?:       string
  onTypeChange: (t: ContactFilterType) => void
  onChange:     (v: string) => void
  onSearch:     () => void
  style?:       CSSProperties
}

/**
 * 联系方式单输入框筛选器
 * 前缀 ICON 可点击弹出下拉选择 Telegram / 微信，默认 Telegram
 */
export default function ContactFilter({
  contactType, value, onTypeChange, onChange, onSearch, style,
}: Props) {
  const cfg = CFG[contactType]

  const menuItems: MenuProps['items'] = (
    Object.entries(CFG) as [ContactFilterType, typeof CFG[ContactFilterType]][]
  ).map(([k, v]) => ({
    key: k,
    label: (
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '3px 2px' }}>
        <span style={{ color: v.color, fontSize: 15, lineHeight: 1 }}>{v.icon}</span>
        <span style={{ color: v.color, fontWeight: 600, fontSize: 13 }}>{v.label}</span>
      </div>
    ),
  }))

  /** 可点击的前缀：当前类型 ICON + 小下箭头 */
  const prefix = (
    <Dropdown
      menu={{
        items: menuItems,
        selectedKeys: [contactType],
        onClick: ({ key }) => {
          onTypeChange(key as ContactFilterType)
          onChange('')
        },
      }}
      trigger={['click']}
    >
      <div style={{
        display: 'flex', alignItems: 'center', gap: 3,
        cursor: 'pointer', userSelect: 'none',
        padding: '0 4px 0 0',
      }}>
        <span style={{ color: cfg.color, fontSize: 14, lineHeight: 1 }}>{cfg.icon}</span>
        <DownOutlined style={{ fontSize: 8, color: '#b0b7c3', marginTop: 1 }} />
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
      style={{ width: 210, ...style }}
    />
  )
}
