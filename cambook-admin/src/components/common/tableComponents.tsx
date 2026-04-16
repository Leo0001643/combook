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
    cell: (props: React.ThHTMLAttributes<HTMLTableCellElement>) => (
      <th
        {...props}
        style={{
          ...props.style,
          background: 'linear-gradient(180deg,#f5f7ff 0%,#eef1ff 100%)',
          borderBottom: '2px solid #e0e4ff',
          padding: '9px 8px',
          height: 'auto',        // 显式覆盖 fixed 列可能注入的 height 值
          boxSizing: 'border-box',
          fontSize: 12,
          fontWeight: 600,
          color: '#374151',
          whiteSpace: 'nowrap',
          textAlign: 'center',
          verticalAlign: 'middle',
        }}
      />
    ),
  },
  body: {
    /**
     * 垂直居中方案（双保险）：
     * 1. td 设 height:'1px'：table layout 自动将 td 拉伸到行高，子元素可用 height:100%
     * 2. 内层 div height:'100%' + display:flex + alignItems:center → 真正垂直居中
     * 3. justifyContent:'center' 让简单文字/标签水平居中；
     *    avatar+文字列的 render 应返回 width:100% 容器以实现左对齐
     */
    cell: (props: React.TdHTMLAttributes<HTMLTableCellElement>) => {
      const { children, ...rest } = props as React.TdHTMLAttributes<HTMLTableCellElement> & { children?: React.ReactNode }
      return (
        <td
          {...rest}
          style={{
            ...rest.style,
            padding: 0,
            height: '1px', // table layout 拉伸到行高；子元素 height:100% 得以生效
          }}
        >
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              padding: '8px 12px',
              height: '100%',
              minHeight: 52,
              boxSizing: 'border-box',
            }}
          >
            {children}
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
export function col(icon: React.ReactNode, label: string) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      gap: 5, fontWeight: 600, fontSize: 12, color: '#374151',
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
}
