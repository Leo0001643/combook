import { PhoneOutlined, SendOutlined } from '@ant-design/icons'
import { WechatOutlined } from '@ant-design/icons'
import { Typography } from 'antd'

const { Text } = Typography

export interface ContactCellProps {
  mobile?:   string
  telegram?: string
  wechat?:   string
  /** 单元格水平对齐，默认 center */
  align?: 'left' | 'center'
}

const ROWS = [
  {
    key: 'mobile' as const,
    bg: 'linear-gradient(135deg,#3b82f6,#60a5fa)',
    icon: <PhoneOutlined  style={{ color: '#fff', fontSize: 9 }} />,
    color: '#374151',
    fmt: (v: string) => v,
  },
  {
    key: 'telegram' as const,
    bg: 'linear-gradient(135deg,#229ED9,#0088cc)',
    icon: <SendOutlined   style={{ color: '#fff', fontSize: 9 }} />,
    color: '#229ED9',
    fmt: (v: string) => `@${v}`,
  },
  {
    key: 'wechat' as const,
    bg: 'linear-gradient(135deg,#07C160,#09bb5c)',
    icon: <WechatOutlined style={{ color: '#fff', fontSize: 10 }} />,
    color: '#07C160',
    fmt: (v: string) => v,
  },
]

/**
 * 联系方式单元格
 * 手机 / Telegram / 微信，有值才显示，每种单独一行
 */
export default function ContactCell({ mobile, telegram, wechat, align = 'center' }: ContactCellProps) {
  const values: Record<string, string | undefined> = { mobile, telegram, wechat }
  const jc = align === 'center' ? 'center' : 'flex-start'

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 5 }}>
      {ROWS.map(row => {
        const val = values[row.key]
        if (!val) return null
        return (
          <div key={row.key} style={{ display: 'flex', alignItems: 'center', justifyContent: jc, gap: 6 }}>
            <div style={{
              width: 18, height: 18, borderRadius: 5,
              background: row.bg,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              flexShrink: 0,
              boxShadow: '0 1px 4px rgba(0,0,0,0.12)',
            }}>
              {row.icon}
            </div>
            <Text style={{ fontSize: 12, color: row.color, letterSpacing: 0.2 }}>
              {row.fmt(val)}
            </Text>
          </div>
        )
      })}
    </div>
  )
}
