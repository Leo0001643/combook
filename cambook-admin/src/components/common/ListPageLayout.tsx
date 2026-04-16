interface StatBadge {
  label: string
  value: number | string
  color: string
  bg: string
  border: string
  icon: string | React.ReactNode
}

interface ListPageLayoutProps {
  /** 页面图标（ReactNode） */
  icon: React.ReactNode
  /** 图标背景渐变，默认紫色 */
  iconBg?: string
  /** 页面主标题 */
  title: string
  /** 副标题/描述 */
  subtitle?: string
  /** 右上角统计徽章（可选） */
  stats?: StatBadge[]
  /** 筛选区内容（可选），直接传入 filter 控件们 */
  filters?: React.ReactNode
  /** 标题行右侧额外内容（如"新增"按钮） */
  extra?: React.ReactNode
  /** 表格 + 分页区域，铺满宽度 */
  children: React.ReactNode
  /** 顶部导航高度，默认 64 */
  navHeight?: number
}

/**
 * 全局统一列表页布局
 *
 * 特性：
 *   - 吸顶复合头部（图标 + 标题 + 统计 + 筛选栏）
 *   - 内容区铺满（负 margin 消除父级 padding）
 *   - 无反弹滚动（index.css 已全局禁止 overscroll）
 */
export default function ListPageLayout({
  icon, iconBg = 'linear-gradient(135deg,#6366f1,#8b5cf6)',
  title, subtitle,
  stats, filters, extra,
  children,
  navHeight = 64,
}: ListPageLayoutProps) {
  return (
    <div style={{ marginTop: -24 }}>
      {/* ── 吸顶头部 ── */}
      <div style={{
        position: 'sticky',
        top: navHeight,
        zIndex: 88,
        marginLeft: -24,
        marginRight: -24,
        background: 'rgba(255,255,255,0.97)',
        backdropFilter: 'blur(20px)',
        WebkitBackdropFilter: 'blur(20px)',
        borderBottom: '1px solid rgba(0,0,0,0.07)',
        boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
      }}>
        {/* 标题行 */}
        <div style={{
          display: 'flex', alignItems: 'center',
          padding: `10px 24px${filters ? ' 0' : ''}`,
          gap: 12, flexWrap: 'wrap',
        }}>
          {/* 图标 */}
          <div style={{
            width: 34, height: 34, borderRadius: 10,
            background: iconBg,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 4px 12px rgba(99,102,241,0.3)',
            flexShrink: 0,
          }}>
            <span style={{ color: '#fff', fontSize: 16, display: 'flex' }}>{icon}</span>
          </div>

          {/* 标题 */}
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1e293b', lineHeight: 1.2 }}>
              {title}
            </div>
            {subtitle && (
              <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>{subtitle}</div>
            )}
          </div>

          {/* 统计徽章 */}
          {stats && stats.length > 0 && (
            <>
              <div style={{ width: 1, height: 20, margin: '0 4px', background: '#e0e4ff', flexShrink: 0 }} />
              <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                {stats.map((s, i) => (
                  <div key={i} style={{
                    display: 'flex', alignItems: 'center', gap: 5,
                    padding: '3px 10px', borderRadius: 20,
                    background: s.bg, border: `1px solid ${s.border}`,
                  }}>
                    <span style={{ fontSize: 13 }}>{s.icon}</span>
                    <span style={{ fontSize: 12, color: '#6b7280' }}>{s.label}</span>
                    <span style={{ fontSize: 13, fontWeight: 700, color: s.color }}>{s.value}</span>
                  </div>
                ))}
              </div>
            </>
          )}

          {/* 弹性占位 */}
          <div style={{ flex: 1 }} />

          {/* 额外操作（如新增按钮） */}
          {extra && (
            <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>{extra}</div>
          )}
        </div>

        {/* 筛选行 */}
        {filters && (
          <div style={{
            display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center',
            padding: '10px 24px 12px',
          }}>
            {filters}
          </div>
        )}
      </div>

      {/* ── 内容区（表格 + 分页） ── */}
      <div style={{
        marginLeft: -24,
        marginRight: -24,
        marginBottom: -24,
        background: '#fff',
        borderTop: '1px solid #eef0f8',
      }}>
        {children}
      </div>
    </div>
  )
}
