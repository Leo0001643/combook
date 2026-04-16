import { useState, useEffect, useRef } from 'react'

/**
 * 动态计算内容区的最佳滚动高度，确保内容区精确铺满顶部筛选栏与底部分页栏之间的空间。
 *
 * 页面三层架构：
 *   ┌────────────────────────────┐
 *   │  sticky 顶部筛选/标题栏    │  position: sticky, top: 64
 *   ├────────────────────────────┤  ← ref div 从此处开始测量
 *   │  内容区（表格 / 树形视图） │  height = 本 hook 返回值
 *   ├────────────────────────────┤
 *   │  sticky 底部分页栏         │  position: sticky, bottom: 0
 *   └────────────────────────────┘
 *
 * 使用方法：
 *   const { ref, height } = useTableBodyHeight()
 *   // 表格：<div ref={ref}><Table scroll={{ y: height }} /></div>
 *   // 树形：<div ref={ref} style={{ height, overflowY: 'auto' }}>…</div>
 *
 * @param paginationH  底部分页器高度(px)，默认 46；无分页器时传 0
 * @param theadH       表格 thead 高度(px)，默认 40；非表格内容传 0
 */
export function useTableBodyHeight(paginationH = 46, theadH = 40) {
  const ref = useRef<HTMLDivElement>(null)
  const [height, setHeight] = useState(500)

  useEffect(() => {
    // ref div 用 marginBottom:-24 已抵消 Content margin-bottom，内容精确铺满视口，SAFETY = 0
    const SAFETY = 0

    const update = () => {
      if (!ref.current) return
      const top = ref.current.getBoundingClientRect().top
      // ref div 通过 marginBottom:-24 已抵消 Content 的 margin-bottom，
      // 可精确延伸至视口底部，无需额外安全余量。
      const available = window.innerHeight - top - theadH - paginationH - SAFETY
      setHeight(Math.max(120, available))
    }

    // 多次触发：立即 / 100ms / 400ms，覆盖异步渲染、数据加载后的布局变化
    update()
    const t1 = setTimeout(update, 100)
    const t2 = setTimeout(update, 400)
    window.addEventListener('resize', update)

    return () => {
      clearTimeout(t1)
      clearTimeout(t2)
      window.removeEventListener('resize', update)
    }
  }, [paginationH, theadH])

  return { ref, height }
}
