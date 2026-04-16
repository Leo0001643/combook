import { useEffect } from 'react'
import { LeftOutlined, RightOutlined, CloseOutlined } from '@ant-design/icons'

interface Props {
  images: string[]
  current: number
  open: boolean
  onClose: () => void
  onChange: (idx: number) => void
}

/**
 * 图片灯箱：全屏暗色背景 + 左右切换 + 缩略图条 + 键盘导航
 */
export default function ImageLightbox({ images, current, open, onClose, onChange }: Props) {
  useEffect(() => {
    if (!open) return
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose()
      if (e.key === 'ArrowLeft' && current > 0) onChange(current - 1)
      if (e.key === 'ArrowRight' && current < images.length - 1) onChange(current + 1)
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [open, current, images.length, onClose, onChange])

  if (!open || images.length === 0) return null

  const btnStyle: React.CSSProperties = {
    position: 'absolute',
    background: 'rgba(255,255,255,0.12)',
    border: 'none',
    borderRadius: '50%',
    width: 52, height: 52,
    cursor: 'pointer',
    color: '#fff',
    fontSize: 20,
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    transition: 'background 0.2s',
    backdropFilter: 'blur(4px)',
  }

  return (
    <div
      style={{
        position: 'fixed', inset: 0, zIndex: 9999,
        background: 'rgba(0,0,0,0.88)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}
      onClick={onClose}
    >
      {/* 关闭按钮 */}
      <button
        onClick={onClose}
        style={{ ...btnStyle, top: 20, right: 20 }}
        onMouseEnter={e => (e.currentTarget.style.background = 'rgba(255,255,255,0.25)')}
        onMouseLeave={e => (e.currentTarget.style.background = 'rgba(255,255,255,0.12)')}
      >
        <CloseOutlined />
      </button>

      {/* 上一张 */}
      {current > 0 && (
        <button
          onClick={e => { e.stopPropagation(); onChange(current - 1) }}
          style={{ ...btnStyle, left: 24, top: '50%', transform: 'translateY(-50%)' }}
          onMouseEnter={e => (e.currentTarget.style.background = 'rgba(255,255,255,0.28)')}
          onMouseLeave={e => (e.currentTarget.style.background = 'rgba(255,255,255,0.12)')}
        >
          <LeftOutlined />
        </button>
      )}

      {/* 主图 */}
      <img
        src={images[current]}
        alt={`photo-${current + 1}`}
        style={{
          maxWidth: '78vw', maxHeight: '82vh',
          objectFit: 'contain',
          borderRadius: 12,
          boxShadow: '0 24px 64px rgba(0,0,0,0.6)',
          userSelect: 'none',
        }}
        onClick={e => e.stopPropagation()}
        draggable={false}
      />

      {/* 下一张 */}
      {current < images.length - 1 && (
        <button
          onClick={e => { e.stopPropagation(); onChange(current + 1) }}
          style={{ ...btnStyle, right: 24, top: '50%', transform: 'translateY(-50%)' }}
          onMouseEnter={e => (e.currentTarget.style.background = 'rgba(255,255,255,0.28)')}
          onMouseLeave={e => (e.currentTarget.style.background = 'rgba(255,255,255,0.12)')}
        >
          <RightOutlined />
        </button>
      )}

      {/* 页码 */}
      <div style={{
        position: 'absolute', bottom: images.length > 1 ? 120 : 28,
        background: 'rgba(0,0,0,0.55)', color: '#fff',
        padding: '4px 18px', borderRadius: 20, fontSize: 13,
        backdropFilter: 'blur(4px)',
        userSelect: 'none',
      }}>
        {current + 1} / {images.length}
      </div>

      {/* 缩略图条 */}
      {images.length > 1 && (
        <div
          style={{
            position: 'absolute', bottom: 24,
            display: 'flex', gap: 8, padding: '10px 16px',
            background: 'rgba(0,0,0,0.45)', borderRadius: 14,
            maxWidth: '80vw', overflowX: 'auto',
            backdropFilter: 'blur(6px)',
          }}
          onClick={e => e.stopPropagation()}
        >
          {images.map((url, idx) => (
            <img
              key={idx}
              src={url}
              alt={`thumb-${idx}`}
              onClick={() => onChange(idx)}
              style={{
                width: 56, height: 70,
                objectFit: 'cover', borderRadius: 7,
                cursor: 'pointer',
                border: `2.5px solid ${idx === current ? '#fff' : 'transparent'}`,
                opacity: idx === current ? 1 : 0.55,
                transition: 'all 0.18s',
                flexShrink: 0,
              }}
            />
          ))}
        </div>
      )}
    </div>
  )
}
