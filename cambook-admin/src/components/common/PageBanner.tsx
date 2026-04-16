import { type ReactNode } from 'react'

export interface BannerStat {
  label: string
  value: number | string
  emoji: string
}

interface PageBannerProps {
  title: string
  subtitle?: string
  breadcrumb?: string
  icon: ReactNode
  gradient: string
  shadowColor: string
  stats?: BannerStat[]
}

/**
 * 统一页面顶部渐变横幅组件
 * 用于所有列表页顶部，提供美观一致的视觉体验
 */
export default function PageBanner({
  title, subtitle, breadcrumb, icon, gradient, shadowColor, stats = [],
}: PageBannerProps) {
  return (
    <div style={{
      background: gradient,
      borderRadius: 18,
      padding: '22px 28px',
      marginBottom: 22,
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center',
      boxShadow: `0 8px 32px ${shadowColor}`,
      position: 'relative',
      overflow: 'hidden',
    }}>
      {/* 装饰圆形 */}
      <div style={{
        position: 'absolute', right: -30, top: -30,
        width: 160, height: 160, borderRadius: '50%',
        background: 'rgba(255,255,255,0.08)',
        pointerEvents: 'none',
      }} />
      <div style={{
        position: 'absolute', right: 80, bottom: -60,
        width: 200, height: 200, borderRadius: '50%',
        background: 'rgba(255,255,255,0.05)',
        pointerEvents: 'none',
      }} />

      <div style={{ zIndex: 1 }}>
        {breadcrumb && (
          <div style={{ color: 'rgba(255,255,255,0.7)', fontSize: 12, marginBottom: 4 }}>
            {breadcrumb}
          </div>
        )}
        <div style={{ color: '#fff', fontSize: 22, fontWeight: 800, display: 'flex', alignItems: 'center', gap: 10 }}>
          <span style={{ fontSize: 20 }}>{icon}</span>
          {title}
        </div>
        {subtitle && (
          <div style={{ color: 'rgba(255,255,255,0.72)', fontSize: 13, marginTop: 5 }}>
            {subtitle}
          </div>
        )}
      </div>

      {stats.length > 0 && (
        <div style={{ display: 'flex', gap: 10, zIndex: 1 }}>
          {stats.map(s => (
            <div key={s.label} style={{
              background: 'rgba(255,255,255,0.18)',
              backdropFilter: 'blur(10px)',
              borderRadius: 12,
              padding: '10px 18px',
              textAlign: 'center',
              minWidth: 72,
            }}>
              <div style={{ fontSize: 18 }}>{s.emoji}</div>
              <div style={{ color: '#fff', fontSize: 20, fontWeight: 800, lineHeight: 1.2 }}>{s.value}</div>
              <div style={{ color: 'rgba(255,255,255,0.75)', fontSize: 11 }}>{s.label}</div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
