/**
 * 商户端 — 结算币种配置页
 *
 * 商户可以：
 *  - 查看平台支持的全部币种
 *  - 勾选自己接受的结算货币
 *  - 设置默认收款币种（仅 1 个）
 *  - 为每种货币设置自定义汇率（覆盖全局汇率）
 *  - 自定义各币种的显示名称
 */
import React, { useEffect, useState } from 'react'
import {
  Alert, Badge, Button, Col, InputNumber, message, Row,
  Space, Switch, Table, Tag, Tooltip,
} from 'antd'
import {
  CheckCircleFilled, GlobalOutlined, InfoCircleOutlined, StarFilled,
} from '@ant-design/icons'
import type { ColumnsType } from 'antd/es/table'
import { merchantPortalApi } from '../../api/api'

// ── Types ────────────────────────────────────────────────────────────────────

interface CurrencyConfigItem {
  currencyCode: string
  currencyName: string
  currencyNameEn: string
  symbol: string
  flag: string
  isCrypto: number
  globalRate: number
  decimalPlaces: number
  enabled: boolean
  isDefault: boolean
  customRate: number | null
  displayName: string | null
  sortOrder: number
}

// ── Component ─────────────────────────────────────────────────────────────────

const MerchantCurrencyPage: React.FC = () => {
  const [items, setItems]     = useState<CurrencyConfigItem[]>([])
  const [loading, setLoading] = useState(false)
  const [saving, setSaving]   = useState(false)

  useEffect(() => {
    setLoading(true)
    merchantPortalApi.currencyConfig()
      .then(res => setItems(res.data?.data ?? []))
      .finally(() => setLoading(false))
  }, [])

  // ── Helpers ─────────────────────────────────────────────────────────────────

  const update = (code: string, patch: Partial<CurrencyConfigItem>) => {
    setItems(prev => prev.map(c => {
      if (patch.isDefault === true && c.currencyCode !== code) {
        return { ...c, isDefault: false }
      }
      if (c.currencyCode === code) return { ...c, ...patch }
      return c
    }))
  }

  const handleSave = async () => {
    const defaultList = items.filter(c => c.enabled && c.isDefault)
    if (defaultList.length > 1) {
      message.warning('只能设置一个默认收款币种')
      return
    }
    const enabledList = items.filter(c => c.enabled)
    if (enabledList.length === 0) {
      message.warning('至少启用一种收款币种')
      return
    }

    setSaving(true)
    try {
      const configs = items.map(c => ({
        currencyCode: c.currencyCode,
        enabled:      c.enabled,
        isDefault:    c.isDefault,
        customRate:   c.customRate,
        displayName:  c.displayName,
        sortOrder:    c.sortOrder,
      }))
      await merchantPortalApi.currencySave(configs)
      message.success('币种配置已保存')
    } finally {
      setSaving(false)
    }
  }

  // ── Columns ─────────────────────────────────────────────────────────────────

  const columns: ColumnsType<CurrencyConfigItem> = [
    {
      title: '币种',
      key: 'currency',
      width: 220,
      align: 'left',
      render: (_, row) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ fontSize: 22, flexShrink: 0 }}>{row.flag}</span>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 4, flexWrap: 'wrap' }}>
              <span style={{ fontWeight: 700, fontSize: 15 }}>{row.currencyCode}</span>
              <span style={{ fontWeight: 600 }}>{row.symbol}</span>
              {row.isCrypto === 1 && <Tag color="purple" style={{ fontSize: 10, padding: '0 4px' }}>加密</Tag>}
              {row.isDefault && row.enabled && (
                <Tooltip title="当前默认收款币种">
                  <StarFilled style={{ color: '#faad14', fontSize: 12 }} />
                </Tooltip>
              )}
            </div>
            <div style={{ fontSize: 12, color: '#888' }}>{row.currencyName} · {row.currencyNameEn}</div>
          </div>
        </div>
      ),
    },
    {
      title: (
        <Space>
          接受此币种
          <Tooltip title="开启后客户可用此货币结算">
            <InfoCircleOutlined style={{ color: '#aaa' }} />
          </Tooltip>
        </Space>
      ),
      key: 'enabled',
      width: 100,
      align: 'center',
      render: (_, row) => (
        <Switch
          checked={row.enabled}
          onChange={v => {
            update(row.currencyCode, { enabled: v, isDefault: v ? row.isDefault : false })
          }}
        />
      ),
    },
    {
      title: (
        <Space>
          设为默认
          <Tooltip title="默认币种在支付界面优先显示，且用于统计汇总">
            <InfoCircleOutlined style={{ color: '#aaa' }} />
          </Tooltip>
        </Space>
      ),
      key: 'isDefault',
      width: 100,
      align: 'center',
      render: (_, row) => (
        <Switch
          checked={row.isDefault}
          disabled={!row.enabled}
          onChange={v => update(row.currencyCode, { isDefault: v })}
        />
      ),
    },
    {
      title: '全局汇率 (→ USD)',
      key: 'globalRate',
      width: 160,
      render: (_, row) => (
        <Tooltip title="平台每日更新的参考汇率">
          <span style={{ color: '#888', fontSize: 13 }}>
            1 {row.currencyCode} = {row.globalRate} USD
          </span>
        </Tooltip>
      ),
    },
    {
      title: (
        <Space>
          自定义汇率
          <Tooltip title="留空则使用全局汇率。若您与客户有协定汇率，可在此覆盖">
            <InfoCircleOutlined style={{ color: '#aaa' }} />
          </Tooltip>
        </Space>
      ),
      key: 'customRate',
      width: 180,
      render: (_, row) => (
        <InputNumber
          size="small"
          disabled={!row.enabled}
          value={row.customRate ?? undefined}
          placeholder="留空用全局汇率"
          min={0.000001}
          step={0.001}
          precision={6}
          style={{ width: 160 }}
          addonAfter="USD"
          onChange={v => update(row.currencyCode, { customRate: v })}
        />
      ),
    },
    {
      title: '小数位',
      dataIndex: 'decimalPlaces',
      width: 70,
      align: 'center',
      render: v => <Tag>{v} 位</Tag>,
    },
  ]

  // ── Stats ────────────────────────────────────────────────────────────────────

  const enabledCount  = items.filter(c => c.enabled).length
  const cryptoEnabled = items.filter(c => c.enabled && c.isCrypto === 1).length
  const fiatEnabled   = items.filter(c => c.enabled && c.isCrypto === 0).length
  const defaultCur    = items.find(c => c.isDefault && c.enabled)

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      {/* Header */}
      <Row justify="space-between" align="middle">
        <Col>
          <Space>
            <GlobalOutlined style={{ fontSize: 20, color: '#1677ff' }} />
            <span style={{ fontSize: 16, fontWeight: 600 }}>结算币种配置</span>
          </Space>
        </Col>
        <Col>
          <Button type="primary" loading={saving} onClick={handleSave}>
            保存配置
          </Button>
        </Col>
      </Row>

      {/* Tips */}
      <Alert
        type="info"
        showIcon
        message="选择您的门店接受的结算货币，客户结算时将可选择这些币种付款。建议至少配置 1 种法定货币和 1 种加密货币（USDT）。"
      />

      {/* Summary */}
      <Row gutter={16}>
        {[
          {
            label: '已启用币种',
            value: enabledCount,
            sub: `${fiatEnabled} 法定 + ${cryptoEnabled} 加密`,
            color: '#1677ff',
            icon: <CheckCircleFilled style={{ color: '#1677ff', fontSize: 20 }} />,
          },
          {
            label: '默认收款币种',
            value: defaultCur ? `${defaultCur.flag} ${defaultCur.currencyCode}` : '未设置',
            sub: defaultCur ? `${defaultCur.currencyName} · ${defaultCur.symbol}` : '请选择一个默认币种',
            color: defaultCur ? '#52c41a' : '#ff4d4f',
            icon: <StarFilled style={{ color: '#faad14', fontSize: 20 }} />,
          },
          {
            label: '法定货币',
            value: fiatEnabled,
            sub: items.filter(c => c.enabled && c.isCrypto === 0).map(c => c.currencyCode).join(' · ') || '无',
            color: '#52c41a',
            icon: <span style={{ fontSize: 20 }}>🏛️</span>,
          },
          {
            label: '加密货币',
            value: cryptoEnabled,
            sub: items.filter(c => c.enabled && c.isCrypto === 1).map(c => c.currencyCode).join(' · ') || '无',
            color: '#722ed1',
            icon: <span style={{ fontSize: 20 }}>💎</span>,
          },
        ].map(card => (
          <Col span={6} key={card.label}>
            <div style={{
              background: 'white',
              borderRadius: 12,
              padding: '16px 20px',
              border: `1px solid ${card.color}22`,
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8 }}>
                {card.icon}
                <span style={{ fontSize: 12, color: '#666' }}>{card.label}</span>
              </div>
              <div style={{ fontSize: 22, fontWeight: 700, color: card.color }}>{card.value}</div>
              <div style={{ fontSize: 11, color: '#999', marginTop: 2 }}>{card.sub}</div>
            </div>
          </Col>
        ))}
      </Row>

      {/* Currency Table */}
      <div style={{ background: 'white', borderRadius: 12, padding: 16 }}>
        <div style={{ marginBottom: 12, display: 'flex', alignItems: 'center', gap: 8 }}>
          <Badge status="processing" />
          <span style={{ fontWeight: 600 }}>平台支持的全部币种</span>
          <span style={{ color: '#888', fontSize: 12 }}>（汇率由平台每日更新，您可为每种货币设置自定义汇率）</span>
        </div>
        <Table<CurrencyConfigItem>
          rowKey="currencyCode"
          size="small"
          loading={loading}
          columns={columns}
          dataSource={items}
          pagination={false}
          rowClassName={row => row.enabled ? 'currency-row-enabled' : ''}
        />
      </div>
    </div>
  )
}

export default MerchantCurrencyPage
