import { useState, useEffect, useRef } from 'react'

/**
 * 动态计算表格 tbody 的最佳滚动高度。
 *
 * 使用方法：将返回的 `ref` 挂到 Table 所在的容器 div 上，
 * 将 `height` 传给 Table 的 `scroll.y`，即可确保表格内容
 * 始终完整可见，不因布局偏差导致最后一行被裁切。
 *
 * @param paginationH  底部分页器的像素高度，默认 46px；无分页器时传 0
 */
export function useTableBodyHeight(paginationH = 46) {
  const ref = useRef<HTMLDivElement>(null)
  const [height, setHeight] = useState(500)

  useEffect(() => {
    const THEAD_H = 40   // Ant Design Table thead 高度（含边框）
    // 28 = 24（table 容器 marginBottom:-24 导致分页器上移 24px）+ 4（精度安全余量）
    const SAFETY  = 28

    const update = () => {
      if (!ref.current) return
      const top = ref.current.getBoundingClientRect().top
      const available = window.innerHeight - top - THEAD_H - paginationH - SAFETY
      setHeight(Math.max(200, available))
    }

    // 多次触发：立即、100ms、400ms，覆盖异步渲染 / 数据加载后的布局变化
    update()
    const t1 = setTimeout(update, 100)
    const t2 = setTimeout(update, 400)
    window.addEventListener('resize', update)

    return () => {
      clearTimeout(t1)
      clearTimeout(t2)
      window.removeEventListener('resize', update)
    }
  }, [paginationH])

  return { ref, height }
}
