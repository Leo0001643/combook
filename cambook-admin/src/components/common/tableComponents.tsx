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
    /**
     * AntD 6 的 Cell 把 column.align 转成 style.textAlign 传给自定义组件。
     * 水平对齐由 index.css 的 !important 规则全局居中，
     * 仅对 align:'left'/'start' 列添加 cb-td-start 类恢复左对齐。
     */
    cell: (props: React.TdHTMLAttributes<HTMLTableCellElement>) => {
      const { children, ...rest } = props as any
      const textAlign = (rest.style?.textAlign ?? '') as string
      const isStart = textAlign === 'left' || textAlign === 'start'
      const cls = [rest.className, isStart ? 'cb-td-start' : ''].filter(Boolean).join(' ')
      return (
        <td
          {...rest}
          className={cls}
          style={{
            ...rest.style,
            padding: '8px 10px',
            verticalAlign: 'middle',
            height: 52,
          }}
        >
          {children}
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
