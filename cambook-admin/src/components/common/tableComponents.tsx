/**
 * 全局统一表格单元格渲染组件
 *
 * 使用方式：
 *   import { styledTableComponents } from '@/components/common/tableComponents'
 *   <Table components={styledTableComponents} ... />
 *
 * 效果：
 *   - 表头：渐变蓝紫背景 + 加粗文字 + 居中
 *   - 表身：垂直居中 + 紧凑内边距
 */
export const styledTableComponents = {
  header: {
    cell: (props: React.ThHTMLAttributes<HTMLTableCellElement>) => {
      // antd/rc-table may deliver alignment via HTML `align` attr OR via style.textAlign
      const rawAlign = (props as any).align ?? props.style?.textAlign ?? 'center'
      const textAlign = rawAlign as React.CSSProperties['textAlign']
      return (
        <th
          {...props}
          style={{
            ...props.style,
            background: 'linear-gradient(180deg,#f5f7ff 0%,#eef1ff 100%)',
            borderBottom: '2px solid #e0e4ff',
            padding: '9px 8px',
            height: 'auto',
            boxSizing: 'border-box',
            fontSize: 12,
            fontWeight: 600,
            color: '#374151',
            whiteSpace: 'nowrap',
            verticalAlign: 'middle',
            textAlign,
          }}
        />
      )
    },
  },
  body: {
    cell: (props: React.TdHTMLAttributes<HTMLTableCellElement>) => {
      const { children, ...rest } = props as React.TdHTMLAttributes<HTMLTableCellElement> & { children?: React.ReactNode }
      // Check both HTML `align` attribute and CSS style.textAlign — antd may use either
      const rawAlign = (rest as any).align ?? rest.style?.textAlign ?? 'left'
      const justifyContent =
        rawAlign === 'center' ? 'center' :
        rawAlign === 'right'  ? 'flex-end' :
        'flex-start'
      const textAlign = rawAlign as React.CSSProperties['textAlign']
      return (
        <td
          {...rest}
          style={{
            ...rest.style,
            padding: 0,
            height: '1px',
          }}
        >
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent,
              textAlign,
              padding: '8px',
              height: '100%',
              minHeight: 52,
              boxSizing: 'border-box',
            }}
          >
            {/* 让 render 函数返回的 100%-宽容器能正确撑满 */}
            <div style={{ width: '100%', display: 'flex', alignItems: 'inherit', justifyContent: 'inherit' }}>
              {children}
            </div>
          </div>
        </td>
      )
    },
  },
}

/**
 * 表头 title 辅助函数：图标 + 文字居中排列
 *
 * @example col(<UserOutlined style={{ color: '#6366f1' }} />, '会员信息')
 */
export function col(icon: React.ReactNode, label: string, align: 'center' | 'left' = 'center') {
  return (
    <div style={{
      display: 'flex', alignItems: 'center',
      justifyContent: align === 'left' ? 'flex-start' : 'center',
      textAlign: align,
      gap: 5, fontWeight: 600, fontSize: 12, color: '#374151',
      width: '100%',
    }}>
      {icon}<span>{label}</span>
    </div>
  )
}

/** 统一的条件筛选输入框样式 */
export const INPUT_STYLE: React.CSSProperties = {
  borderRadius: 8,
  background: '#f5f7fa',
  border: '1px solid #eaecf0',
  fontSize: 13,
  fontWeight: 500,
}
