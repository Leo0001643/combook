import { Pagination, Select, Typography } from 'antd'
import { LeftOutlined, RightOutlined } from '@ant-design/icons'

const { Text } = Typography
const { Option } = Select

interface PagePaginationProps {
  total:         number
  current:       number
  pageSize:      number
  onChange:      (page: number) => void
  onSizeChange?: (size: number) => void
  /** 单位文字，默认"条记录"，可改为"位会员"/"个商户" 等 */
  countLabel?:   string
  /** 是否显示每页条数选择器，默认 true */
  showSizeChanger?: boolean
  /** 可选的每页条数列表，默认 [20, 50, 100, 200] */
  pageSizeOptions?: number[]
}

/**
 * 全局统一分页器
 *
 * 特性：
 *   - 无边框、渐变活跃页
 *   - 左侧显示总数 / 当前页
 *   - 右侧可选每页条数 + 页码按钮
 */
export default function PagePagination({
  total, current, pageSize,
  onChange, onSizeChange,
  countLabel = '条记录',
  showSizeChanger = true,
  pageSizeOptions = [20, 50, 100, 200],
}: PagePaginationProps) {
  const totalPages = Math.ceil(total / pageSize)

  const btnBase: React.CSSProperties = {
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
    height: 26, borderRadius: 6, cursor: 'pointer',
    fontSize: 12, border: 'none', outline: 'none', boxShadow: 'none',
    background: 'transparent', transition: 'all 0.15s', padding: '0 9px',
  }

  return (
    <div style={{
      position: 'sticky', bottom: 0, zIndex: 20,
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      padding: '6px 20px', borderTop: '1px solid #eef0f8',
      background: 'linear-gradient(180deg,#fafbff 0%,#f5f7ff 100%)',
    }}>
      {/* 左侧：统计 */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
        <div style={{ width: 5, height: 5, borderRadius: '50%', background: 'linear-gradient(135deg,#6366f1,#8b5cf6)' }} />
        <Text style={{ color: '#9ca3af', fontSize: 12 }}>
          共 <Text strong style={{ color: '#6366f1', fontSize: 12 }}>{total}</Text> {countLabel}
          &nbsp;·&nbsp;第 <Text strong style={{ color: '#374151', fontSize: 12 }}>{current}</Text> 页
        </Text>
      </div>

      {/* 右侧：每页条数 + 分页 */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
        {showSizeChanger && onSizeChange && (
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <Text style={{ fontSize: 12, color: '#9ca3af', whiteSpace: 'nowrap' }}>每页</Text>
            <Select
              size="small" value={pageSize}
              onChange={v => { onSizeChange(v); onChange(1) }}
              popupMatchSelectWidth={false}
              style={{ width: 72 }}
            >
              {pageSizeOptions.map(n => <Option key={n} value={n}>{n} 条</Option>)}
            </Select>
          </div>
        )}

        <Pagination
          current={current} total={total} pageSize={pageSize}
          showSizeChanger={false}
          onChange={p => onChange(p)}
          itemRender={(pg, type, element) => {
            if (type === 'prev') return (
              <button style={{ ...btnBase, gap: 3, color: current <= 1 ? '#d1d5db' : '#6366f1' }}>
                <LeftOutlined style={{ fontSize: 10 }} />上一页
              </button>
            )
            if (type === 'next') return (
              <button style={{ ...btnBase, gap: 3, color: current >= totalPages ? '#d1d5db' : '#6366f1' }}>
                下一页<RightOutlined style={{ fontSize: 10 }} />
              </button>
            )
            if (type === 'page') {
              const active = pg === current
              return (
                <button style={{
                  ...btnBase, minWidth: 26, padding: '0 2px',
                  background: active ? 'linear-gradient(135deg,#6366f1,#8b5cf6)' : 'transparent',
                  color: active ? '#fff' : '#6b7280',
                  fontWeight: active ? 700 : 400,
                  boxShadow: active ? '0 2px 6px rgba(99,102,241,0.3)' : 'none',
                }}>{pg}</button>
              )
            }
            if (type === 'jump-prev' || type === 'jump-next') return (
              <button style={{ ...btnBase, minWidth: 26, padding: '0 2px', color: '#9ca3af' }}>···</button>
            )
            return element
          }}
        />
      </div>
    </div>
  )
}
