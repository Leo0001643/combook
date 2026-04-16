import { Modal, Button, Space, Typography } from 'antd'
import {
  StopOutlined, CheckCircleOutlined, DeleteOutlined,
  ExclamationCircleFilled,
} from '@ant-design/icons'
import { useState } from 'react'
import type { ReactNode } from 'react'

const { Text, Title } = Typography

export type DangerModalVariant = 'ban' | 'unban' | 'delete' | 'warning' | 'confirm'

const VARIANT_CFG: Record<DangerModalVariant, {
  iconEl:     ReactNode
  bgGradient: string
  btnGradient: string
  shadow:     string
  iconColor:  string
}> = {
  ban: {
    iconEl:      <StopOutlined style={{ fontSize: 32, color: '#ef4444' }} />,
    bgGradient:  'linear-gradient(135deg,#fee2e2,#fecaca)',
    btnGradient: 'linear-gradient(135deg,#ef4444,#dc2626)',
    shadow:      '0 4px 14px rgba(239,68,68,0.35)',
    iconColor:   '#ef4444',
  },
  unban: {
    iconEl:      <CheckCircleOutlined style={{ fontSize: 32, color: '#10b981' }} />,
    bgGradient:  'linear-gradient(135deg,#d1fae5,#a7f3d0)',
    btnGradient: 'linear-gradient(135deg,#10b981,#059669)',
    shadow:      '0 4px 14px rgba(16,185,129,0.35)',
    iconColor:   '#10b981',
  },
  delete: {
    iconEl:      <DeleteOutlined style={{ fontSize: 32, color: '#ef4444' }} />,
    bgGradient:  'linear-gradient(135deg,#fee2e2,#fecaca)',
    btnGradient: 'linear-gradient(135deg,#ef4444,#dc2626)',
    shadow:      '0 4px 14px rgba(239,68,68,0.35)',
    iconColor:   '#ef4444',
  },
  warning: {
    iconEl:      <ExclamationCircleFilled style={{ fontSize: 32, color: '#f59e0b' }} />,
    bgGradient:  'linear-gradient(135deg,#fef3c7,#fde68a)',
    btnGradient: 'linear-gradient(135deg,#f59e0b,#d97706)',
    shadow:      '0 4px 14px rgba(245,158,11,0.35)',
    iconColor:   '#f59e0b',
  },
  confirm: {
    iconEl:      <CheckCircleOutlined style={{ fontSize: 32, color: '#3b82f6' }} />,
    bgGradient:  'linear-gradient(135deg,#eff6ff,#dbeafe)',
    btnGradient: 'linear-gradient(135deg,#3b82f6,#2563eb)',
    shadow:      '0 4px 14px rgba(59,130,246,0.35)',
    iconColor:   '#3b82f6',
  },
}

export interface DangerModalProps {
  open:         boolean
  variant?:     DangerModalVariant
  title:        string
  description?: ReactNode
  warning?:     string
  confirmText:  string
  cancelText?:  string
  loading?:     boolean
  onConfirm:    () => void | Promise<void>
  onCancel:     () => void
}

/**
 * 通用危险操作确认弹窗 —— 全局可复用
 * 支持 ban / unban / delete / warning / confirm 五种风格
 * 内容区（description）可传入任意 JSX
 */
export default function DangerModal({
  open, variant = 'warning', title, description, warning,
  confirmText, cancelText = '取消',
  loading: extLoading, onConfirm, onCancel,
}: DangerModalProps) {
  const [loading, setLoading] = useState(false)
  const cfg = VARIANT_CFG[variant]

  const handleConfirm = async () => {
    setLoading(true)
    try {
      await onConfirm()
    } finally {
      setLoading(false)
    }
  }

  return (
    <Modal
      open={open}
      footer={null}
      centered
      width={400}
      onCancel={onCancel}
      closable={false}
      styles={{
        mask: { backdropFilter: 'blur(5px)', WebkitBackdropFilter: 'blur(5px)' },
        body: { padding: 0 },
      }}
      style={{ borderRadius: 20, padding: 0, overflow: 'hidden' }}
    >
      <div style={{ padding: '36px 28px 28px', textAlign: 'center' }}>

        {/* 大图标区 */}
        <div style={{
          width: 72, height: 72, borderRadius: 24,
          background: cfg.bgGradient,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          margin: '0 auto 20px',
          boxShadow: `0 8px 28px ${cfg.iconColor}25`,
        }}>
          {cfg.iconEl}
        </div>

        {/* 标题 */}
        <Title level={5} style={{ margin: '0 0 8px', color: '#111827', fontSize: 17, fontWeight: 700 }}>
          {title}
        </Title>

        {/* 描述卡片 */}
        {description && (
          <div style={{
            background: '#f8fafc', borderRadius: 14,
            padding: '12px 16px', margin: '14px 0',
            textAlign: 'left', border: '1px solid #e5e7eb',
          }}>
            {description}
          </div>
        )}

        {/* 警告提示条 */}
        {warning && (
          <div style={{
            background: `${cfg.iconColor}10`,
            borderRadius: 10, padding: '9px 14px',
            marginTop: 12,
            border: `1px solid ${cfg.iconColor}30`,
          }}>
            <Text style={{ fontSize: 12, color: cfg.iconColor }}>
              ⚠️ {warning}
            </Text>
          </div>
        )}

        {/* 操作按钮 */}
        <Space size={10} style={{ marginTop: 24, width: '100%', justifyContent: 'center' }}>
          <Button
            size="large"
            onClick={onCancel}
            style={{
              width: 110, borderRadius: 12, fontWeight: 500,
              border: '1px solid #e5e7eb', color: '#6b7280',
              background: '#fff',
            }}
          >
            {cancelText}
          </Button>
          <Button
            size="large"
            loading={loading || extLoading}
            onClick={handleConfirm}
            style={{
              width: 150, borderRadius: 12, fontWeight: 700,
              border: 'none', color: '#fff',
              background: cfg.btnGradient,
              boxShadow: cfg.shadow,
            }}
          >
            {confirmText}
          </Button>
        </Space>
      </div>
    </Modal>
  )
}
