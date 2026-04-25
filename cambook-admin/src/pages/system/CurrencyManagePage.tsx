/**
 * 币种管理页（超级管理员）
 *
 * 功能：
 *  - 全平台币种列表，支持启用 / 停用
 *  - 新增自定义币种
 *  - 手动更新任意币种的实时汇率
 *  - 查看 / 配置指定商户的接受币种
 */
import React, { useCallback, useEffect, useState } from 'react'
import { fmtTime } from '../../utils/time'
import {
  Badge, Button, Col, Descriptions, Drawer, Form, Input, InputNumber,
  message, Modal, Row, Select, Space, Switch, Table, Tag, Tooltip,
} from 'antd'
import {
  DollarOutlined, EditOutlined, GlobalOutlined, PlusOutlined, SyncOutlined,
} from '@ant-design/icons'
import type { ColumnsType } from 'antd/es/table'
import { currencyApi } from '../../api/api'
import { useTableBodyHeight } from '../../hooks/useTableBodyHeight'
import PermGuard from '../../components/common/PermGuard'

// ── Types ────────────────────────────────────────────────────────────────────

interface Currency {
  id: number
  currencyCode: string
  currencyName: string
  currencyNameEn: string
  symbol: string
  flag: string
  isCrypto: number
  rateToUsd: number
  rateUpdateTime: string
  decimalPlaces: number
  sortOrder: number
  status: number
  remark: string
}

interface MerchantCurrencyItem {
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

// ── Component ────────────────────────────────────────────────────────────────

const CurrencyManagePage: React.FC = () => {
  const [data, setData]         = useState<Currency[]>([])
  const [loading, setLoading]   = useState(false)

  // Add / Edit modal
  const [editModal, setEditModal]   = useState(false)
  const [editItem, setEditItem]     = useState<Currency | null>(null)
  const [editForm] = Form.useForm()

  // Rate update modal
  const [rateModal, setRateModal]   = useState(false)
  const [rateTarget, setRateTarget] = useState<Currency | null>(null)
  const [rateForm] = Form.useForm()

  // Merchant config drawer
  const [merchantDrawer, setMerchantDrawer]             = useState(false)
  const [merchantId, setMerchantId]                     = useState<number | null>(null)
  const [merchantIdInput, setMerchantIdInput]           = useState<number | undefined>()
  const [merchantCurrencies, setMerchantCurrencies]     = useState<MerchantCurrencyItem[]>([])
  const [merchantSaving, setMerchantSaving]             = useState(false)

  const { height: tableBodyHeight } = useTableBodyHeight(200)

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const res = await currencyApi.list()
      setData(res.data?.data ?? [])
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { load() }, [load])

  // ── Handlers ───────────────────────────────────────────────────────────────

  const openAdd = () => {
    setEditItem(null)
    editForm.resetFields()
    editForm.setFieldsValue({ status: 1, decimalPlaces: 2, sortOrder: 0, isCrypto: 0 })
    setEditModal(true)
  }

  const openEdit = (row: Currency) => {
    setEditItem(row)
    editForm.setFieldsValue({ ...row })
    setEditModal(true)
  }

  const handleEditOk = async () => {
    const values = await editForm.validateFields()
    try {
      if (editItem) {
        await currencyApi.update({ ...values, id: editItem.id })
        message.success('币种信息已更新')
      } else {
        await currencyApi.add(values)
        message.success('币种添加成功')
      }
      setEditModal(false)
      load()
    } catch {
      message.error('操作失败，请重试')
    }
  }

  const openRateEdit = (row: Currency) => {
    setRateTarget(row)
    rateForm.setFieldsValue({ rateToUsd: row.rateToUsd })
    setRateModal(true)
  }

  const handleRateOk = async () => {
    const { rateToUsd } = await rateForm.validateFields()
    try {
      await currencyApi.updateRate(rateTarget!.currencyCode, rateToUsd)
      message.success(`${rateTarget!.currencyCode} 汇率已更新`)
      setRateModal(false)
      load()
    } catch {
      message.error('更新失败，请重试')
    }
  }

  const toggleStatus = async (row: Currency, checked: boolean) => {
    await currencyApi.toggleStatus(row.id, checked ? 1 : 0)
    message.success(checked ? '已启用' : '已停用')
    load()
  }

  const openMerchantConfig = async (mid: number) => {
    setMerchantId(mid)
    const res = await currencyApi.merchantConfig(mid)
    setMerchantCurrencies(res.data?.data ?? [])
    setMerchantDrawer(true)
  }

  const saveMerchantConfig = async () => {
    if (!merchantId) return
    setMerchantSaving(true)
    try {
      const configs = merchantCurrencies.map(c => ({
        currencyCode: c.currencyCode,
        enabled:      c.enabled,
        isDefault:    c.isDefault,
        customRate:   c.customRate,
        displayName:  c.displayName,
        sortOrder:    c.sortOrder,
      }))
      await currencyApi.merchantConfigure(merchantId, configs)
      message.success('商户币种配置已保存')
      setMerchantDrawer(false)
    } finally {
      setMerchantSaving(false)
    }
  }

  const toggleMerchantCurrency = (code: string, field: 'enabled' | 'isDefault', value: boolean) => {
    setMerchantCurrencies(prev => prev.map(c => {
      if (field === 'isDefault' && value) {
        // 只能有一个默认
        return { ...c, isDefault: c.currencyCode === code }
      }
      if (c.currencyCode === code) return { ...c, [field]: value }
      return c
    }))
  }

  // ── Columns ────────────────────────────────────────────────────────────────

  const columns: ColumnsType<Currency> = [
    {
      title: '币种',
      key: 'currency',
      width: 200,
      align: 'left',
      render: (_, row) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ fontSize: 20 }}>{row.flag}</span>
          <div>
            <div style={{ fontWeight: 600 }}>
              {row.currencyCode}
              {row.isCrypto === 1 && <Tag color="purple" style={{ marginLeft: 6, fontSize: 11 }}>加密</Tag>}
            </div>
            <div style={{ fontSize: 12, color: '#666' }}>{row.currencyName} · {row.currencyNameEn}</div>
          </div>
        </div>
      ),
    },
    {
      title: '符号',
      dataIndex: 'symbol',
      width: 70,
      render: v => <span style={{ fontSize: 16, fontWeight: 600 }}>{v}</span>,
    },
    {
      title: '对 USD 汇率',
      key: 'rate',
      width: 180,
      align: 'left',
      render: (_, row) => (
        <div>
          <div style={{ fontWeight: 600 }}>1 {row.currencyCode} = {row.rateToUsd} USD</div>
          {row.rateUpdateTime && (
            <div style={{ fontSize: 11, color: '#999' }}>更新：{fmtTime(row.rateUpdateTime, 'YYYY-MM-DD HH:mm')}</div>
          )}
        </div>
      ),
    },
    {
      title: '小数位',
      dataIndex: 'decimalPlaces',
      width: 70,
      align: 'center',
    },
    {
      title: '排序',
      dataIndex: 'sortOrder',
      width: 70,
      align: 'center',
    },
    {
      title: '状态',
      dataIndex: 'status',
      width: 80,
      align: 'center',
      render: (v, row) => (
        <PermGuard code="currency:edit" fallback={
          <Badge status={v === 1 ? 'success' : 'default'} text={v === 1 ? '启用' : '停用'} />
        }>
          <Switch
            size="small"
            checked={v === 1}
            onChange={checked => toggleStatus(row, checked)}
          />
        </PermGuard>
      ),
    },
    {
      title: '操作',
      key: 'action',
      width: 180,
      render: (_, row) => (
        <Space size={4}>
          <PermGuard code="currency:edit">
            <Tooltip title="编辑信息">
              <Button size="small" icon={<EditOutlined />} onClick={() => openEdit(row)} />
            </Tooltip>
          </PermGuard>
          <PermGuard code="currency:rate">
            <Tooltip title="更新汇率">
              <Button size="small" icon={<SyncOutlined />} onClick={() => openRateEdit(row)} />
            </Tooltip>
          </PermGuard>
        </Space>
      ),
    },
  ]

  // ── Merchant currency columns ──────────────────────────────────────────────

  const merchantColumns: ColumnsType<MerchantCurrencyItem> = [
    {
      title: '币种',
      key: 'currency',
      align: 'left',
      render: (_, row) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ fontSize: 18 }}>{row.flag}</span>
          <div>
            <span style={{ fontWeight: 600 }}>{row.currencyCode}</span>
            <span style={{ marginLeft: 6, color: '#666', fontSize: 12 }}>{row.currencyName}</span>
          </div>
        </div>
      ),
    },
    {
      title: '启用',
      key: 'enabled',
      width: 70,
      render: (_, row) => (
        <Switch
          size="small"
          checked={row.enabled}
          onChange={v => toggleMerchantCurrency(row.currencyCode, 'enabled', v)}
        />
      ),
    },
    {
      title: '设为默认',
      key: 'isDefault',
      width: 90,
      render: (_, row) => (
        <Switch
          size="small"
          checked={row.isDefault}
          disabled={!row.enabled}
          onChange={v => toggleMerchantCurrency(row.currencyCode, 'isDefault', v)}
        />
      ),
    },
    {
      title: '全局汇率 (→USD)',
      key: 'globalRate',
      render: (_, row) => <span style={{ fontSize: 12, color: '#888' }}>{row.globalRate}</span>,
    },
    {
      title: '自定义汇率（选填）',
      key: 'customRate',
      width: 160,
      render: (_, row) => (
        <InputNumber
          size="small"
          value={row.customRate ?? undefined}
          placeholder="留空用全局汇率"
          min={0}
          step={0.001}
          style={{ width: 140 }}
          onChange={v => setMerchantCurrencies(prev =>
            prev.map(c => c.currencyCode === row.currencyCode ? { ...c, customRate: v } : c)
          )}
        />
      ),
    },
    {
      title: '自定义显示名',
      key: 'displayName',
      width: 140,
      render: (_, row) => (
        <Input
          size="small"
          value={row.displayName ?? ''}
          placeholder={row.currencyName}
          style={{ width: 120 }}
          onChange={e => setMerchantCurrencies(prev =>
            prev.map(c => c.currencyCode === row.currencyCode ? { ...c, displayName: e.target.value } : c)
          )}
        />
      ),
    },
  ]

  // ── Render ─────────────────────────────────────────────────────────────────

  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', gap: 16 }}>
      {/* Header */}
      <Row justify="space-between" align="middle">
        <Col>
          <Space>
            <GlobalOutlined style={{ fontSize: 20, color: '#1677ff' }} />
            <span style={{ fontSize: 16, fontWeight: 600 }}>币种管理</span>
            <Tag color="blue">{data.filter(c => c.status === 1).length} 个启用</Tag>
            <Tag color="orange">{data.filter(c => c.isCrypto === 1).length} 个加密货币</Tag>
          </Space>
        </Col>
        <Col>
          <Space>
            <InputNumber
              value={merchantIdInput}
              onChange={v => setMerchantIdInput(v ?? undefined)}
              placeholder="商户 ID"
              min={1}
              style={{ width: 120 }}
            />
            <Button
              icon={<GlobalOutlined />}
              disabled={!merchantIdInput}
              onClick={() => merchantIdInput && openMerchantConfig(merchantIdInput)}
            >
              查看商户币种
            </Button>
            <PermGuard code="currency:add">
              <Button type="primary" icon={<PlusOutlined />} onClick={openAdd}>
                添加币种
              </Button>
            </PermGuard>
          </Space>
        </Col>
      </Row>

      {/* Summary cards */}
      <Row gutter={16}>
        {[
          { label: '法定货币', count: data.filter(c => c.isCrypto === 0 && c.status === 1).length, color: '#1677ff', icon: '🏛️' },
          { label: '加密货币', count: data.filter(c => c.isCrypto === 1 && c.status === 1).length, color: '#722ed1', icon: '💎' },
          { label: '亚洲货币', count: data.filter(c => ['CNY','JPY','KRW','THB','PHP','MYR','SGD','KHR'].includes(c.currencyCode) && c.status === 1).length, color: '#eb2f96', icon: '🌏' },
          { label: '国际储备', count: data.filter(c => ['USD','EUR','GBP'].includes(c.currencyCode) && c.status === 1).length, color: '#52c41a', icon: '🌍' },
        ].map(item => (
          <Col span={6} key={item.label}>
            <div style={{
              background: 'white',
              borderRadius: 12,
              padding: '16px 20px',
              border: `1px solid ${item.color}22`,
              display: 'flex',
              alignItems: 'center',
              gap: 12,
            }}>
              <span style={{ fontSize: 28 }}>{item.icon}</span>
              <div>
                <div style={{ fontSize: 22, fontWeight: 700, color: item.color }}>{item.count}</div>
                <div style={{ fontSize: 12, color: '#666' }}>{item.label}</div>
              </div>
            </div>
          </Col>
        ))}
      </Row>

      {/* Table */}
      <div style={{ flex: 1, background: 'white', borderRadius: 12, overflow: 'hidden' }}>
        <Table<Currency>
          rowKey="id"
          size="small"
          loading={loading}
          columns={columns}
          dataSource={data}
          scroll={{ y: tableBodyHeight - 100 }}
          pagination={false}
        />
      </div>

      {/* Add / Edit Modal */}
      <Modal
        title={editItem ? `编辑币种：${editItem.currencyCode}` : '添加新币种'}
        open={editModal}
        onOk={handleEditOk}
        onCancel={() => setEditModal(false)}
        width={560}
        destroyOnHidden
      >
        <Form form={editForm} layout="vertical" style={{ marginTop: 16 }}>
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="currencyCode" label="货币代码（ISO 4217）"
                rules={[{ required: true, message: '请输入货币代码' }]}>
                <Input placeholder="USD / CNY / USDT" style={{ textTransform: 'uppercase' }} disabled={!!editItem} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="symbol" label="货币符号"
                rules={[{ required: true }]}>
                <Input placeholder="$ / ¥ / ₱" />
              </Form.Item>
            </Col>
          </Row>
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="currencyName" label="中文名称" rules={[{ required: true }]}>
                <Input placeholder="美元 / 人民币" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="currencyNameEn" label="英文名称" rules={[{ required: true }]}>
                <Input placeholder="US Dollar" />
              </Form.Item>
            </Col>
          </Row>
          <Row gutter={16}>
            <Col span={8}>
              <Form.Item name="flag" label="国旗 Emoji">
                <Input placeholder="🇺🇸" />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="rateToUsd" label="对 USD 汇率" rules={[{ required: true }]}>
                <InputNumber min={0.000001} step={0.01} style={{ width: '100%' }} placeholder="1.0" />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="decimalPlaces" label="小数位数" rules={[{ required: true }]}>
                <Select options={[{value:0,label:'0位'},{value:2,label:'2位'},{value:4,label:'4位'},{value:6,label:'6位'},{value:8,label:'8位'}]} />
              </Form.Item>
            </Col>
          </Row>
          <Row gutter={16}>
            <Col span={8}>
              <Form.Item name="isCrypto" label="类型">
                <Select options={[{value:0,label:'法定货币'},{value:1,label:'加密货币'}]} />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="sortOrder" label="排序（越小越前）">
                <InputNumber min={0} style={{ width: '100%' }} />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="status" label="状态">
                <Select options={[{value:1,label:'启用'},{value:0,label:'停用'}]} />
              </Form.Item>
            </Col>
          </Row>
          <Form.Item name="remark" label="备注">
            <Input.TextArea rows={2} placeholder="可选：关于该币种的描述" />
          </Form.Item>
        </Form>
      </Modal>

      {/* Rate Update Modal */}
      <Modal
        title={`更新汇率：${rateTarget?.currencyCode ?? ''}`}
        open={rateModal}
        onOk={handleRateOk}
        onCancel={() => setRateModal(false)}
        width={400}
        destroyOnHidden
      >
        {rateTarget && (
          <div style={{ marginBottom: 16 }}>
            <Descriptions size="small" column={1}>
              <Descriptions.Item label="币种">{rateTarget.flag} {rateTarget.currencyCode} — {rateTarget.currencyName}</Descriptions.Item>
              <Descriptions.Item label="当前汇率">1 {rateTarget.currencyCode} = <strong>{rateTarget.rateToUsd}</strong> USD</Descriptions.Item>
              <Descriptions.Item label="上次更新">{fmtTime(rateTarget.rateUpdateTime, 'YYYY-MM-DD HH:mm') ?? '—'}</Descriptions.Item>
            </Descriptions>
          </div>
        )}
        <Form form={rateForm} layout="vertical">
          <Form.Item
            name="rateToUsd"
            label={`新汇率（1 ${rateTarget?.currencyCode ?? ''} = ? USD）`}
            rules={[{ required: true, message: '请输入新汇率' }, { type: 'number', min: 0.000001, message: '汇率必须大于 0' }]}
          >
            <InputNumber
              style={{ width: '100%' }}
              step={0.0001}
              precision={8}
              placeholder="请输入新汇率"
              addonBefore={<DollarOutlined />}
            />
          </Form.Item>
        </Form>
      </Modal>

      {/* Merchant Currency Config Drawer */}
      <Drawer
        title={`商户币种配置（ID: ${merchantId}）`}
        open={merchantDrawer}
        onClose={() => setMerchantDrawer(false)}
        width={900}
        extra={
          <Button type="primary" loading={merchantSaving} onClick={saveMerchantConfig}>
            保存配置
          </Button>
        }
      >
        <p style={{ color: '#666', marginBottom: 16 }}>
          为该商户选择接受的结算货币，可自定义汇率和显示名称。
          <strong> 默认币种</strong>将在收款界面优先显示。
        </p>
        <Table<MerchantCurrencyItem>
          rowKey="currencyCode"
          size="small"
          columns={merchantColumns}
          dataSource={merchantCurrencies}
          pagination={false}
        />
      </Drawer>
    </div>
  )
}

export default CurrencyManagePage
