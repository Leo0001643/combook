/**
 * 技师工资结算管理页
 *
 * 支持四种结算模式：每笔结算 / 日结 / 周结 / 月结
 *
 * 功能亮点：
 *  - 精品统计看板：待结算金额、本月已结算、总结算笔数、今日数据
 *  - 筛选：技师、结算方式、状态、日期范围
 *  - 生成结算单（选周期→自动计算提成→预览→确认）
 *  - 调整奖励/扣款
 *  - 批量打款
 *  - 结算单详情抽屉（含订单明细列表）
 *  - 撤销结算
 */
import { useCallback, useEffect, useState } from 'react'
import {
  Avatar, Badge, Button, Col, DatePicker, Descriptions, Divider, Drawer,
  Form, Input, InputNumber, message, Modal, Popconfirm, Progress,
  Row, Select, Space, Steps, Table, Tag,
} from 'antd'
import {
  BankOutlined, BarChartOutlined, CalendarOutlined, CheckCircleOutlined,
  ClockCircleOutlined, DollarOutlined, EditOutlined, IdcardOutlined,
  FileTextOutlined, MinusCircleOutlined, PlusCircleOutlined, PlusOutlined,
  RedoOutlined, ReloadOutlined, SearchOutlined, SendOutlined, SettingOutlined,
  UserOutlined, WalletOutlined,
} from '@ant-design/icons'
import type { ColumnsType } from 'antd/es/table'
import dayjs from 'dayjs'
import type { Dayjs } from 'dayjs'
import { useTableBodyHeight } from '../../hooks/useTableBodyHeight'
import { fmtTime, fmtDate, toEpochSec, fromEpochSec } from '../../utils/time'
import { useDict, parseRemark } from '../../hooks/useDict'
import PagePagination from '../../components/common/PagePagination'
import { col } from '../../components/common/tableComponents'
import { merchantPortalApi } from '../../api/api'
import { useAuthStore } from '../../store/authStore'

const { RangePicker } = DatePicker

// ── Constants (fallback - 字典加载前的静态兜底) ─────────────────────────────

const SETTLEMENT_MODES_FB: Record<number, { label: string; color: string; icon: string; desc: string }> = {
  0: { label: '每笔结算', color: '#6366f1', icon: '💳', desc: '每完成一单立即生成结算' },
  1: { label: '日结',     color: '#0891b2', icon: '📅', desc: '次日汇总前一天所有订单' },
  2: { label: '周结',     color: '#7c3aed', icon: '📆', desc: '每周一汇总上一自然周' },
  3: { label: '月结',     color: '#b45309', icon: '🗓️',  desc: '每月 1 日汇总上一自然月' },
}

const SETTLEMENT_STATUS_FB: Record<number, { label: string; color: string; badge: 'default' | 'processing' | 'success' | 'error' | 'warning' }> = {
  0: { label: '待结算',  color: '#f59e0b', badge: 'warning' },
  1: { label: '已结算',  color: '#10b981', badge: 'success' },
  2: { label: '争议暂扣', color: '#ef4444', badge: 'error' },
}

const PAY_METHODS_FB = [
  { value: 'cash',    label: '💵 现金' },
  { value: 'bank',    label: '🏦 银行转账' },
  { value: 'usdt',    label: '₮ USDT' },
  { value: 'wechat',  label: '💚 微信' },
  { value: 'alipay',  label: '💙 支付宝' },
  { value: 'other',   label: '🔗 其他' },
]

// ── Settlement Mode Badge ─────────────────────────────────────────────────────

function ModeTag({ mode, modesMap }: { mode: number; modesMap?: Record<number, { label: string; color: string; icon: string; desc: string }> }) {
  const m = (modesMap ?? SETTLEMENT_MODES_FB)[mode]
  if (!m) return null
  return (
    <Tag style={{
      background: m.color + '18', border: `1px solid ${m.color}44`,
      color: m.color, borderRadius: 6, fontWeight: 600,
    }}>
      {m.icon} {m.label}
    </Tag>
  )
}

// ════════════════════════════════════════════════════════════════════════════════

export default function TechnicianSettlementPage() {
  const { ref, height: tableBodyH } = useTableBodyHeight(46)
  const { isMerchant } = useAuthStore()

  const { items: settleModeItems }   = useDict('settlement_mode')
  const { items: settleStatusItems } = useDict('settlement_status')
  const { items: payItems }          = useDict('walkin_pay_type')

  const SETTLEMENT_MODES: Record<number, { label: string; color: string; icon: string; desc: string }> =
    settleModeItems.length > 0
      ? Object.fromEntries(settleModeItems.map(i => {
          const { color, icon } = parseRemark(i.remark)
          return [Number(i.dictValue), { label: i.labelZh, color: color ?? '#6366f1', icon: icon ?? '💳', desc: i.remark ?? '' }]
        }))
      : SETTLEMENT_MODES_FB

  const SETTLEMENT_STATUS: Record<number, { label: string; color: string; badge: 'default' | 'processing' | 'success' | 'error' | 'warning' }> =
    settleStatusItems.length > 0
      ? Object.fromEntries(settleStatusItems.map(i => {
          const badgeMap: Record<string, any> = { orange: 'warning', green: 'success', red: 'error' }
          const hexMap: Record<string, string> = { orange: '#f59e0b', green: '#10b981', red: '#ef4444' }
          return [Number(i.dictValue), { label: i.labelZh, color: hexMap[i.remark ?? ''] ?? '#94a3b8', badge: badgeMap[i.remark ?? ''] ?? 'default' }]
        }))
      : SETTLEMENT_STATUS_FB

  const PAY_METHODS = payItems.length > 0
    ? payItems.filter(i => i.status === 1).map(i => ({ value: i.dictValue, label: `${i.remark ?? ''} ${i.labelZh}`.trim() }))
    : PAY_METHODS_FB

  const [records, setRecords]             = useState<any[]>([])
  const [total, setTotal]                 = useState(0)
  const [page, setPage]                   = useState(1)
  const [pageSize, setPageSize]           = useState(20)
  const [loading, setLoading]             = useState(false)
  const [selectedRowKeys, setSelectedRowKeys] = useState<number[]>([])

  // Filter state
  const [technicianId, setTechnicianId]   = useState<number | undefined>()
  const [modeFilter, setModeFilter]       = useState<number | undefined>()
  const [statusFilter, setStatusFilter]   = useState<number | undefined>()
  const [dateRange, setDateRange]         = useState<[number, number] | null>(null)

  // Technician list (for selector)
  const [technicians, setTechnicians] = useState<any[]>([])

  // KPI summary
  const [summary, setSummary] = useState({
    pendingCount: 0, pendingAmount: 0, settledAmount: 0, monthAmount: 0,
  })

  // Generate settlement modal (3-step wizard)
  const [genOpen, setGenOpen]             = useState(false)
  const [genStep, setGenStep]             = useState(0)
  const [genForm]                         = Form.useForm()
  const [_genTech, setGenTech]            = useState<any>(null)
  const [genLoading, setGenLoading]       = useState(false)
  const [genPreview, setGenPreview]       = useState<any>(null)

  // Pay modal
  const [payOpen, setPayOpen]             = useState(false)
  const [payTarget, setPayTarget]         = useState<any>(null)
  const [payForm]                         = Form.useForm()
  const [payLoading, setPayLoading]       = useState(false)

  // Adjust modal
  const [adjustOpen, setAdjustOpen]       = useState(false)
  const [adjustTarget, setAdjustTarget]   = useState<any>(null)
  const [adjustForm]                      = Form.useForm()

  // Batch pay modal
  const [batchPayOpen, setBatchPayOpen]   = useState(false)
  const [batchForm]                       = Form.useForm()
  const [batchLoading, setBatchLoading]   = useState(false)

  // Detail drawer
  const [detailOpen, setDetailOpen]       = useState(false)
  const [detail, setDetail]               = useState<any>(null)

  // ── Load technicians for selector ──────────────────────────────────────────
  useEffect(() => {
    if (!isMerchant) return
    merchantPortalApi.technicians({ page: 1, size: 200 }).then(res => {
      const d = res.data?.data
      const list: any[] = d?.list ?? d?.records ?? []
      setTechnicians(list.map(t => ({
        id:             t.id,
        name:           t.nickname ?? t.name,
        settlementMode: t.settlementMode ?? 3,
        commissionType: t.commissionType ?? 0,
        commissionRate: t.commissionRatePct ?? t.commissionRate ?? 0,
      })))
    }).catch(() => {})
  }, [isMerchant])

  const load = useCallback(async () => {
    if (!isMerchant) return
    setLoading(true)
    try {
      const res = await merchantPortalApi.settlementList({
        page, size: pageSize,
        technicianId: technicianId || undefined,
        settlementMode: modeFilter,
        status: statusFilter,
        startDate: dateRange?.[0],
        endDate:   dateRange?.[1],
      })
      const d = res.data?.data
      const list: any[] = d?.list ?? d?.records ?? []
      setRecords(list)
      setTotal(d?.total ?? list.length)
      // KPI from summary if backend returns it, else compute from current page
      if (d?.summary) {
        setSummary(d.summary)
      } else {
        setSummary({
          pendingCount:  list.filter((r: any) => r.status === 0).length,
          pendingAmount: list.filter((r: any) => r.status === 0).reduce((a: number, r: any) => a + (r.finalAmount ?? 0), 0),
          settledAmount: list.filter((r: any) => r.status === 1).reduce((a: number, r: any) => a + (r.finalAmount ?? 0), 0),
          monthAmount:   list.filter((r: any) => r.status === 1 && fmtTime(r.paidTime, 'YYYY-MM') === dayjs().format('YYYY-MM')).reduce((a: number, r: any) => a + (r.finalAmount ?? 0), 0),
        })
      }
    } catch {
      setRecords([])
      setTotal(0)
    } finally {
      setLoading(false)
    }
  }, [technicianId, modeFilter, statusFilter, dateRange, page, pageSize, isMerchant])

  useEffect(() => { load() }, [load])

  // ── Generate settlement wizard ─────────────────────────────────────────────

  const openGenerate = () => {
    setGenStep(0)
    setGenPreview(null)
    genForm.resetFields()
    setGenTech(null)
    setGenOpen(true)
  }

  const onGenTechChange = (id: number) => {
    const t = technicians.find(t => t.id === id)
    setGenTech(t)
    if (t) {
      genForm.setFieldsValue({
        settlementMode: t.settlementMode,
        commissionType: t.commissionType,
        commissionRate: t.commissionRate,
        currencyCode:   'USD',
      })
    }
  }

  const handleGenPreview = async () => {
    await genForm.validateFields(['technicianId', 'settlementMode', 'periodStart', 'periodEnd', 'totalRevenue', 'commissionRate'])
    const vals = genForm.getFieldsValue()
    const totalRevenue    = parseFloat(vals.totalRevenue ?? 0)
    const commissionType  = vals.commissionType ?? 0
    const commissionRate  = parseFloat(vals.commissionRate ?? 0)
    const commissionAmount = commissionType === 0
      ? parseFloat((totalRevenue * commissionRate / 100).toFixed(2))
      : parseFloat((vals.orderCount * commissionRate).toFixed(2))
    const bonusAmount     = parseFloat(vals.bonusAmount ?? 0)
    const deductionAmount = parseFloat(vals.deductionAmount ?? 0)
    const finalAmount     = Math.max(0, commissionAmount + bonusAmount - deductionAmount)
    const tech = technicians.find(t => t.id === vals.technicianId)

    setGenPreview({
      technicianName: tech?.name ?? '—',
      ...vals,
      commissionAmount,
      finalAmount,
    })
    setGenStep(1)
  }

  const handleGenConfirm = async () => {
    if (!genPreview) return
    setGenLoading(true)
    try {
      await merchantPortalApi.settlementGenerate({
        technicianId:    genPreview.technicianId,
        settlementMode:  genPreview.settlementMode,
        periodStart:     genPreview.periodStart,
        periodEnd:       genPreview.periodEnd,
        totalRevenue:    genPreview.totalRevenue,
        commissionType:  genPreview.commissionType,
        commissionRate:  genPreview.commissionRate,
        bonusAmount:     genPreview.bonusAmount ?? 0,
        deductionAmount: genPreview.deductionAmount ?? 0,
        currencyCode:    genPreview.currencyCode ?? 'USD',
        remark:          genPreview.remark ?? '',
      })
      message.success(`已为 ${genPreview.technicianName} 生成结算单`)
      setGenOpen(false)
      load()
    } catch { message.error('生成失败，请重试') }
    finally { setGenLoading(false) }
  }

  // ── Pay ────────────────────────────────────────────────────────────────────

  const openPay = (record: any) => {
    setPayTarget(record)
    payForm.resetFields()
    setPayOpen(true)
  }

  const handlePay = async () => {
    try {
      const values = await payForm.validateFields()
      setPayLoading(true)
      await merchantPortalApi.settlementPay(payTarget.id, {
        paymentMethod: values.method,
        paidTime:      dayjs().format('YYYY-MM-DD HH:mm:ss'),
        remark:        values.remark ?? '',
      })
      message.success(`结算单 ${payTarget.settlementNo} 已打款成功！`)
      setPayOpen(false)
      setPayTarget(null)
      load()
    } catch { message.error('打款失败，请重试') }
    finally { setPayLoading(false) }
  }

  // ── Adjust ────────────────────────────────────────────────────────────────

  const openAdjust = (record: any) => {
    setAdjustTarget(record)
    adjustForm.setFieldsValue({
      bonusAmount:     record.bonusAmount,
      deductionAmount: record.deductionAmount,
      remark:          record.remark,
    })
    setAdjustOpen(true)
  }

  const handleAdjust = async () => {
    try {
      const values = await adjustForm.validateFields()
      await merchantPortalApi.settlementAdjust(adjustTarget.id, {
        bonusAmount:     values.bonusAmount     ?? 0,
        deductionAmount: values.deductionAmount ?? 0,
        remark:          values.remark ?? '',
      })
      message.success('金额调整成功')
      setAdjustOpen(false)
      load()
    } catch { message.error('调整失败') }
  }

  // ── Batch Pay ────────────────────────────────────────────────────────────

  const handleBatchPay = async () => {
    try {
      const values = await batchForm.validateFields()
      setBatchLoading(true)
      await merchantPortalApi.settlementBatchPay({
        ids:           selectedRowKeys,
        paymentMethod: values.method,
        paidTime:      dayjs().format('YYYY-MM-DD HH:mm:ss'),
      })
      message.success(`已批量打款 ${selectedRowKeys.length} 笔结算单`)
      setBatchPayOpen(false)
      setSelectedRowKeys([])
      load()
    } catch { message.error('批量打款失败') }
    finally { setBatchLoading(false) }
  }

  // ── Columns ───────────────────────────────────────────────────────────────

  const columns: ColumnsType<any> = [
    {
      title: col(<FileTextOutlined style={{ color: '#64748b' }} />, '结算单号', 'left'),
      dataIndex: 'settlementNo',
      width: 180,
      align: 'left',
      render: (v, row) => (
        <div>
          <div style={{ fontWeight: 700, fontSize: 12, color: '#6366f1', fontFamily: 'monospace' }}>{v}</div>
          <div style={{ fontSize: 11, color: '#999' }}>{fmtTime(row.createTime, 'MM-DD HH:mm')}</div>
        </div>
      ),
    },
    {
      title: col(<UserOutlined style={{ color: '#64748b' }} />, '技师', 'center'),
      key: 'tech',
      width: 120,
      align: 'center',
      render: (_, row) => (
        <Space style={{ justifyContent: 'center' }}>
          <Avatar size={32} style={{ background: '#6366f1', fontWeight: 700 }}>
            {row.technicianName?.charAt(0)}
          </Avatar>
          <div>
            <div style={{ fontWeight: 600, fontSize: 13 }}>{row.technicianName}</div>
            <ModeTag modesMap={SETTLEMENT_MODES} mode={row.settlementMode} />
          </div>
        </Space>
      ),
    },
    {
      title: col(<ClockCircleOutlined style={{ color: '#64748b' }} />, '结算周期', 'center'),
      key: 'period',
      width: 180,
      align: 'center',
      render: (_, row) => (
        <div style={{ textAlign: 'center' }}>
          {row.periodStart === row.periodEnd
            ? <span style={{ fontWeight: 600 }}>{row.periodStart}</span>
            : <span style={{ fontWeight: 600 }}>{row.periodStart} ～ {row.periodEnd}</span>
          }
          <div style={{ fontSize: 11, color: '#888', marginTop: 2 }}>
            {row.orderCount} 单 · 营收 {row.currencySymbol}{row.totalRevenue?.toLocaleString()}
          </div>
        </div>
      ),
    },
    {
      title: col(<DollarOutlined style={{ color: '#64748b' }} />, '提成结构', 'center'),
      key: 'commission',
      width: 160,
      align: 'center',
      render: (_, row) => (
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: 12 }}>
            基础：
            <span style={{ fontWeight: 700, color: '#6366f1' }}>
              {row.commissionType === 0
                ? `${row.commissionRate}% → ${row.currencySymbol}${row.commissionAmount?.toLocaleString()}`
                : `${row.currencySymbol}${row.commissionRate}/单 → ${row.currencySymbol}${row.commissionAmount?.toLocaleString()}`
              }
            </span>
          </div>
          {row.bonusAmount > 0 && (
            <div style={{ fontSize: 11, color: '#10b981' }}>
              <PlusCircleOutlined /> 奖励 {row.currencySymbol}{row.bonusAmount}
            </div>
          )}
          {row.deductionAmount > 0 && (
            <div style={{ fontSize: 11, color: '#ef4444' }}>
              <MinusCircleOutlined /> 扣款 {row.currencySymbol}{row.deductionAmount}
            </div>
          )}
        </div>
      ),
    },
    {
      title: col(<DollarOutlined style={{ color: '#64748b' }} />, '实发金额', 'center'),
      key: 'final',
      width: 130,
      align: 'center',
      render: (_, row) => (
        <div style={{ textAlign: 'center' }}>
          <div style={{
            fontSize: 18, fontWeight: 800,
            color: row.status === 1 ? '#10b981' : '#f59e0b',
          }}>
            {row.currencySymbol}{row.finalAmount?.toLocaleString()}
          </div>
          <div style={{ fontSize: 11, color: '#999' }}>{row.currencyCode}</div>
        </div>
      ),
    },
    {
      title: col(<CheckCircleOutlined style={{ color: '#64748b' }} />, '状态', 'center'),
      key: 'status',
      width: 110,
      align: 'center',
      render: (_, row) => {
        const s = SETTLEMENT_STATUS[row.status]
        return (
          <div style={{ textAlign: 'center' }}>
            <Badge status={s?.badge} text={
              <span style={{ fontWeight: 600, color: s?.color }}>{s?.label}</span>
            } />
            {row.status === 1 && row.paidTime && (
              <div style={{ fontSize: 10, color: '#999', marginTop: 2 }}>
                {fmtTime(row.paidTime, 'MM-DD HH:mm')}
              </div>
            )}
          </div>
        )
      },
    },
    {
      title: col(<SettingOutlined style={{ color: '#64748b' }} />, '操作'),
      key: 'action',
      width: 200,
      render: (_, row) => (
        <Space size={4} style={{ flexWrap: 'nowrap' }}>
          <Button size="small" icon={<FileTextOutlined />}
            onClick={() => { setDetail(row); setDetailOpen(true) }}>
            详情
          </Button>
          {row.status === 0 && (
            <>
              <Button size="small" type="primary" icon={<SendOutlined />}
                style={{ background: '#10b981', border: 'none' }}
                onClick={() => openPay(row)}>
                打款
              </Button>
              <Button size="small" icon={<EditOutlined />} onClick={() => openAdjust(row)}>调整</Button>
            </>
          )}
          {row.status === 1 && (
            <Popconfirm title="确认撤销此结算单？" okText="确认撤销" cancelText="取消" onConfirm={async () => {
              try {
                await merchantPortalApi.settlementRevoke(row.id)
                message.success('已撤销结算')
                load()
              } catch { message.error('撤销失败，请重试') }
            }}>
              <Button size="small" danger icon={<RedoOutlined />}>撤销</Button>
            </Popconfirm>
          )}
        </Space>
      ),
    },
  ]

  // ── Render ────────────────────────────────────────────────────────────────

  const pendingSelected = selectedRowKeys.length > 0
    ? records.filter(r => selectedRowKeys.includes(r.id) && r.status === 0)
    : []

  return (
    <div style={{ marginTop: -24 }}>

      {!isMerchant && (
        <div style={{ padding: '40px 24px', textAlign: 'center', color: '#9ca3af' }}>
          <BankOutlined style={{ fontSize: 48, marginBottom: 16 }} />
          <div style={{ fontSize: 16, fontWeight: 600, marginBottom: 8 }}>技师结算管理</div>
          <div style={{ fontSize: 13 }}>此功能仅限商户后台使用，请进入对应商户账号查看结算数据。</div>
        </div>
      )}

      {isMerchant && (<>
      <div style={{
        position: 'sticky', top: 64, zIndex: 88,
        marginLeft: -24, marginRight: -24,
        background: 'rgba(255,255,255,0.97)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderBottom: '1px solid rgba(0,0,0,0.07)',
        boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
      }}>
        {/* 标题行 + KPI 徽章 */}
        <div style={{ display: 'flex', alignItems: 'center', padding: '10px 24px 0', gap: 16, flexWrap: 'wrap' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, flex: '0 0 auto' }}>
            <div style={{
              width: 34, height: 34, borderRadius: 10,
              background: 'linear-gradient(135deg,#4f46e5,#6366f1)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: '0 4px 12px rgba(99,102,241,0.35)', flexShrink: 0,
            }}>
              <WalletOutlined style={{ color: '#fff', fontSize: 16 }} />
            </div>
            <div>
              <div style={{ fontWeight: 700, fontSize: 15, color: '#111827', lineHeight: 1.2 }}>技师结算管理</div>
              <div style={{ fontSize: 11, color: '#9ca3af', lineHeight: 1.3, marginTop: 1 }}>提成核算 · 薪酬发放 · 历史结算</div>
            </div>
          </div>
          <div style={{ width: 1, height: 28, margin: '0 4px', background: '#e5e7eb', flexShrink: 0 }} />
          {/* KPI 徽章 */}
          {[
            { label: '待结算', value: summary.pendingCount + ' 笔',                color: '#f59e0b', bg: '#fffbeb', border: '#fde68a' },
            { label: '待打款', value: `$${summary.pendingAmount.toLocaleString()}`, color: '#6366f1', bg: '#eff6ff', border: '#bfdbfe' },
            { label: '本月打款', value: `$${summary.monthAmount.toLocaleString()}`, color: '#10b981', bg: '#ecfdf5', border: '#a7f3d0' },
            { label: '历史合计', value: `$${summary.settledAmount.toLocaleString()}`, color: '#8b5cf6', bg: '#f5f3ff', border: '#ddd6fe' },
          ].map(s => (
            <div key={s.label} style={{
              display: 'flex', alignItems: 'center', gap: 6, padding: '5px 12px',
              borderRadius: 20, background: s.bg, border: `1px solid ${s.border}`,
            }}>
              <span style={{ color: s.color, fontWeight: 700, fontSize: 13 }}>{s.value}</span>
              <span style={{ color: s.color, fontSize: 11, opacity: 0.8 }}>{s.label}</span>
            </div>
          ))}
          <div style={{ marginLeft: 'auto', display: 'flex', gap: 8, flexShrink: 0 }}>
            {pendingSelected.length > 0 && (
              <Button icon={<BankOutlined />}
                style={{ background: '#10b981', color: '#fff', border: 'none', borderRadius: 8 }}
                onClick={() => { batchForm.resetFields(); setBatchPayOpen(true) }}>
                批量打款 ({pendingSelected.length})
              </Button>
            )}
            <Button type="primary" icon={<PlusOutlined />}
              style={{ background: 'linear-gradient(135deg,#6366f1,#4f46e5)', border: 'none', borderRadius: 8 }}
              onClick={openGenerate}>
              生成结算单
            </Button>
          </div>
        </div>

        {/* 筛选行 */}
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', padding: '10px 24px 12px' }}>
          <Select
            allowClear
            placeholder={<Space size={4}><IdcardOutlined style={{ color: '#6366f1', fontSize: 12 }} />选择技师</Space>}
            style={{ width: 155 }}
            value={technicianId}
            onChange={setTechnicianId}
            options={technicians.map(t => ({ value: t.id, label: t.name }))}
          />
          <Select
            allowClear
            placeholder={<Space size={4}><BarChartOutlined style={{ color: '#f59e0b', fontSize: 12 }} />结算方式</Space>}
            style={{ width: 130 }}
            value={modeFilter}
            onChange={setModeFilter}
            options={Object.entries(SETTLEMENT_MODES).map(([k, v]) => ({
              value: +k, label: `${v.icon} ${v.label}`,
            }))}
          />
          <Select
            allowClear
            placeholder={<Space size={4}><CheckCircleOutlined style={{ color: '#10b981', fontSize: 12 }} />状态</Space>}
            style={{ width: 110 }}
            value={statusFilter}
            onChange={setStatusFilter}
            options={Object.entries(SETTLEMENT_STATUS).map(([k, v]) => ({
              value: +k, label: v.label,
            }))}
          />
          <RangePicker
            value={(() => {
              if (dateRange?.[0] == null || dateRange?.[1] == null) return null
              const a = fromEpochSec(dateRange[0])
              const b = fromEpochSec(dateRange[1])
              return a && b ? ([a, b] as [Dayjs, Dayjs]) : null
            })()}
            onChange={dates => {
              const s0 = dates?.[0] ? toEpochSec(dates[0]) : null
              const s1 = dates?.[1] ? toEpochSec(dates[1]) : null
              setDateRange(s0 != null && s1 != null ? [s0, s1] : null)
            }}
            style={{ width: 260 }}
          />
          <Button icon={<ReloadOutlined />} style={{ borderRadius: 8 }} onClick={() => {
            setTechnicianId(undefined); setModeFilter(undefined)
            setStatusFilter(undefined); setDateRange(null)
          }}>重置</Button>
        </div>
      </div>

      {/* ── 结算方式说明卡片 ─────────────────────────────────────────────── */}
      <div style={{ padding: '16px 0 0' }}>
        <Row gutter={8}>
          {Object.entries(SETTLEMENT_MODES).map(([mode, cfg]) => (
            <Col span={6} key={mode}>
              <div style={{
                background: cfg.color + '0d', border: `1px solid ${cfg.color}33`,
                borderRadius: 10, padding: '10px 14px',
                display: 'flex', alignItems: 'center', gap: 10,
              }}>
                <span style={{ fontSize: 22 }}>{cfg.icon}</span>
                <div>
                  <div style={{ fontWeight: 700, color: cfg.color, fontSize: 13 }}>{cfg.label}</div>
                  <div style={{ fontSize: 11, color: '#888' }}>{cfg.desc}</div>
                </div>
              </div>
            </Col>
          ))}
        </Row>
      </div>

      {/* ── 数据表格 ────────────────────────────────────────────────────── */}
      <div ref={ref} style={{
        marginLeft: -24, marginRight: -24, marginBottom: -24,
        background: '#fff', borderTop: '1px solid #eef0f8', marginTop: 16,
      }}>
        <Table
          rowKey="id"
          size="small"
          loading={loading}
          columns={columns}
          dataSource={records}
          scroll={{ x: 1100, y: tableBodyH }}
          pagination={false}
          rowSelection={{
            selectedRowKeys,
            onChange: keys => setSelectedRowKeys(keys as number[]),
            getCheckboxProps: row => ({ disabled: row.status === 1 }),
          }}
          rowClassName={row => row.status === 0 ? 'settlement-pending-row' : ''}
        />
        <PagePagination
          total={total} current={page} pageSize={pageSize}
          onChange={setPage} onSizeChange={setPageSize}
        />
      </div>

      {/* ════════════════════════════════════════════════════════════════════
          生成结算单 — 三步向导 Modal
      ════════════════════════════════════════════════════════════════════ */}
      <Modal
        title={
          <div style={{
            background: 'linear-gradient(135deg,#1e1b4b,#4338ca)',
            margin: '-20px -24px 0', padding: '20px 24px 20px',
            borderRadius: '8px 8px 0 0',
          }}>
            <div style={{ color: '#fff', fontWeight: 800, fontSize: 16 }}>
              <CalendarOutlined style={{ marginRight: 10 }} />生成结算单
            </div>
            <div style={{ color: 'rgba(255,255,255,0.7)', fontSize: 12, marginTop: 4 }}>
              三步完成：选技师 → 填写信息 → 确认生成
            </div>
          </div>
        }
        open={genOpen} onCancel={() => setGenOpen(false)} footer={null}
        width={680} destroyOnHidden
      >
        <div style={{ marginTop: 24 }}>
          <Steps
            current={genStep} size="small"
            items={[
              { title: '选择技师 & 周期' },
              { title: '预览结算金额' },
              { title: '确认生成' },
            ]}
            style={{ marginBottom: 24 }}
          />

          {genStep === 0 && (
            <Form form={genForm} layout="vertical">
              <Row gutter={16}>
                <Col span={12}>
                  <Form.Item name="technicianId" label="技师" rules={[{ required: true }]}>
                    <Select
                      placeholder="选择技师"
                      onChange={onGenTechChange}
                      options={technicians.map(t => ({ value: t.id, label: t.name }))}
                    />
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item name="settlementMode" label="结算方式" rules={[{ required: true }]}>
                    <Select
                      options={Object.entries(SETTLEMENT_MODES).map(([k, v]) => ({
                        value: +k, label: `${v.icon} ${v.label}`,
                      }))}
                    />
                  </Form.Item>
                </Col>
              </Row>
              <Row gutter={16}>
                <Col span={12}>
                  <Form.Item name="periodStart" label="周期开始" rules={[{ required: true }]}>
                    <DatePicker style={{ width: '100%' }} />
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item name="periodEnd" label="周期结束" rules={[{ required: true }]}>
                    <DatePicker style={{ width: '100%' }} />
                  </Form.Item>
                </Col>
              </Row>
              <Row gutter={16}>
                <Col span={8}>
                  <Form.Item name="orderCount" label="订单数量">
                    <InputNumber min={0} style={{ width: '100%' }} placeholder="0" />
                  </Form.Item>
                </Col>
                <Col span={8}>
                  <Form.Item name="totalRevenue" label="总营业额" rules={[{ required: true }]}>
                    <InputNumber min={0} step={0.01} style={{ width: '100%' }} placeholder="0.00" addonBefore="$" />
                  </Form.Item>
                </Col>
                <Col span={8}>
                  <Form.Item name="currencyCode" label="结算币种" rules={[{ required: true }]}>
                    <Select options={[
                      { value: 'USD',  label: '🇺🇸 USD' },
                      { value: 'CNY',  label: '🇨🇳 CNY' },
                      { value: 'USDT', label: '💵 USDT' },
                      { value: 'PHP',  label: '🇵🇭 PHP' },
                      { value: 'THB',  label: '🇹🇭 THB' },
                      { value: 'VND',  label: '🇻🇳 VND' },
                      { value: 'KRW',  label: '🇰🇷 KRW' },
                      { value: 'AED',  label: '🇦🇪 AED' },
                      { value: 'MYR',  label: '🇲🇾 MYR' },
                    ]} />
                  </Form.Item>
                </Col>
              </Row>
              <Row gutter={16}>
                <Col span={8}>
                  <Form.Item name="commissionType" label="提成类型">
                    <Select options={[
                      { value: 0, label: '📊 按比例 (%)' },
                      { value: 1, label: '💵 固定金额/单' },
                    ]} />
                  </Form.Item>
                </Col>
                <Col span={8}>
                  <Form.Item name="commissionRate" label="提成比例/金额" rules={[{ required: true }]}>
                    <InputNumber min={0} step={0.5} style={{ width: '100%' }} placeholder="60" />
                  </Form.Item>
                </Col>
                <Col span={4}>
                  <Form.Item name="bonusAmount" label="奖励金额">
                    <InputNumber min={0} step={0.01} style={{ width: '100%' }} placeholder="0" />
                  </Form.Item>
                </Col>
                <Col span={4}>
                  <Form.Item name="deductionAmount" label="扣款金额">
                    <InputNumber min={0} step={0.01} style={{ width: '100%' }} placeholder="0" />
                  </Form.Item>
                </Col>
              </Row>
              <Form.Item name="remark" label="备注">
                <Input.TextArea rows={2} placeholder="可选：本次结算说明" />
              </Form.Item>
              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10, marginTop: 8 }}>
                <Button onClick={() => setGenOpen(false)}>取消</Button>
                <Button type="primary" icon={<SearchOutlined />} onClick={handleGenPreview}
                  style={{ background: 'linear-gradient(135deg,#4338ca,#6366f1)', border: 'none' }}>
                  下一步：预览
                </Button>
              </div>
            </Form>
          )}

          {genStep === 1 && genPreview && (
            <div>
              {/* Preview card */}
              <div style={{
                background: 'linear-gradient(135deg,#f0f4ff,#e8f0fe)',
                borderRadius: 16, padding: 24, marginBottom: 20,
                border: '1px solid #c7d7fd',
              }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 20 }}>
                  <Avatar size={48} style={{ background: '#6366f1', fontSize: 20, fontWeight: 800 }}>
                    {genPreview.technicianName?.charAt(0)}
                  </Avatar>
                  <div>
                    <div style={{ fontWeight: 800, fontSize: 16 }}>{genPreview.technicianName}</div>
                    <ModeTag modesMap={SETTLEMENT_MODES} mode={genPreview.settlementMode} />
                  </div>
                </div>

                <Row gutter={[16, 12]}>
                  {[
                    { label: '周期', value: `${fmtDate(genPreview.periodStart).replace(/-/g, '/')} ~ ${fmtDate(genPreview.periodEnd).replace(/-/g, '/')}` },
                    { label: '订单数', value: `${genPreview.orderCount ?? 0} 单` },
                    { label: '总营业额', value: `${genPreview.currencyCode} ${parseFloat(genPreview.totalRevenue ?? 0).toLocaleString()}` },
                    { label: '提成方式', value: genPreview.commissionType === 0 ? `按比例 ${genPreview.commissionRate}%` : `固定 ${genPreview.commissionRate}/单` },
                    { label: '基础提成', value: `${genPreview.currencyCode} ${genPreview.commissionAmount?.toLocaleString()}` },
                    { label: '奖励金额', value: `+ ${genPreview.currencyCode} ${parseFloat(genPreview.bonusAmount ?? 0).toLocaleString()}`, color: '#10b981' },
                    { label: '扣款金额', value: `- ${genPreview.currencyCode} ${parseFloat(genPreview.deductionAmount ?? 0).toLocaleString()}`, color: '#ef4444' },
                  ].map(item => (
                    <Col span={12} key={item.label}>
                      <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                        <span style={{ color: '#666', fontSize: 13 }}>{item.label}</span>
                        <span style={{ fontWeight: 600, color: (item as any).color || '#374151' }}>{item.value}</span>
                      </div>
                    </Col>
                  ))}
                </Row>

                <Divider style={{ margin: '16px 0' }} />

                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span style={{ fontSize: 14, fontWeight: 700, color: '#374151' }}>实发金额</span>
                  <span style={{ fontSize: 32, fontWeight: 900, color: '#6366f1' }}>
                    {genPreview.currencyCode} {genPreview.finalAmount?.toLocaleString()}
                  </span>
                </div>

                <Progress
                  percent={Math.min(100, Math.round(genPreview.commissionAmount / genPreview.totalRevenue * 100))}
                  strokeColor={{ '0%': '#6366f1', '100%': '#818cf8' }}
                  trailColor="#e8f0fe"
                  format={p => `提成占比 ${p}%`}
                  style={{ marginTop: 12 }}
                />
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', gap: 10 }}>
                <Button onClick={() => setGenStep(0)}>← 返回修改</Button>
                <Button type="primary" loading={genLoading} onClick={handleGenConfirm}
                  icon={<CheckCircleOutlined />}
                  style={{ background: 'linear-gradient(135deg,#10b981,#059669)', border: 'none', padding: '0 32px' }}>
                  确认生成结算单
                </Button>
              </div>
            </div>
          )}
        </div>
      </Modal>

      {/* ── 打款 Modal ────────────────────────────────────────────────────── */}
      <Modal
        title={
          <Space>
            <SendOutlined style={{ color: '#10b981' }} />
            <span>确认打款 — {payTarget?.technicianName}</span>
          </Space>
        }
        open={payOpen} onCancel={() => setPayOpen(false)} footer={null} width={440} destroyOnHidden
      >
        {payTarget && (
          <div>
            <div style={{
              background: 'linear-gradient(135deg,#f0fdf4,#dcfce7)',
              borderRadius: 12, padding: '16px 20px', marginBottom: 20,
              border: '1px solid #bbf7d0',
            }}>
              <div style={{ fontSize: 12, color: '#065f46', marginBottom: 4 }}>
                {payTarget.settlementNo} · {payTarget.periodStart} ～ {payTarget.periodEnd}
              </div>
              <div style={{ fontSize: 28, fontWeight: 900, color: '#10b981' }}>
                {payTarget.currencySymbol}{payTarget.finalAmount?.toLocaleString()}
              </div>
              <div style={{ fontSize: 12, color: '#6b7280', marginTop: 2 }}>
                {payTarget.orderCount} 单 · 提成 {payTarget.currencySymbol}{payTarget.commissionAmount}
                {payTarget.bonusAmount > 0 && ` + 奖励 ${payTarget.currencySymbol}${payTarget.bonusAmount}`}
                {payTarget.deductionAmount > 0 && ` - 扣款 ${payTarget.currencySymbol}${payTarget.deductionAmount}`}
              </div>
            </div>

            <Form form={payForm} layout="vertical">
              <Form.Item name="paymentMethod" label="支付方式" rules={[{ required: true }]}>
                <Select placeholder="选择支付方式" options={PAY_METHODS} />
              </Form.Item>
              <Form.Item name="paymentRef" label="转账流水号 / 凭证号">
                <Input placeholder="如有请填写，方便核对" prefix={<BankOutlined />} />
              </Form.Item>
              <Form.Item name="remark" label="备注">
                <Input.TextArea rows={2} placeholder="如有特殊说明" />
              </Form.Item>
            </Form>

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10 }}>
              <Button onClick={() => setPayOpen(false)}>取消</Button>
              <Button type="primary" loading={payLoading} onClick={handlePay}
                style={{ background: 'linear-gradient(135deg,#10b981,#059669)', border: 'none' }}
                icon={<CheckCircleOutlined />}>
                确认已打款
              </Button>
            </div>
          </div>
        )}
      </Modal>

      {/* ── 调整金额 Modal ────────────────────────────────────────────────── */}
      <Modal
        title={<Space><EditOutlined /><span>调整结算金额 — {adjustTarget?.technicianName}</span></Space>}
        open={adjustOpen} onCancel={() => setAdjustOpen(false)}
        onOk={handleAdjust} okText="保存调整" destroyOnHidden
      >
        <Form form={adjustForm} layout="vertical" style={{ marginTop: 16 }}>
          <Form.Item name="bonusAmount" label={<span style={{ color: '#10b981' }}>奖励金额（+）</span>}
            tooltip="好评奖励、业绩达标奖、节日红包等">
            <InputNumber min={0} step={0.01} style={{ width: '100%' }}
              addonBefore={<PlusCircleOutlined style={{ color: '#10b981' }} />}
              placeholder="0.00" />
          </Form.Item>
          <Form.Item name="deductionAmount" label={<span style={{ color: '#ef4444' }}>扣款金额（-）</span>}
            tooltip="设备损耗、违规扣分、迟到等">
            <InputNumber min={0} step={0.01} style={{ width: '100%' }}
              addonBefore={<MinusCircleOutlined style={{ color: '#ef4444' }} />}
              placeholder="0.00" />
          </Form.Item>
          <Form.Item name="remark" label="调整说明">
            <Input.TextArea rows={2} placeholder="请说明调整原因，方便技师理解" />
          </Form.Item>
        </Form>
      </Modal>

      {/* ── 批量打款 Modal ────────────────────────────────────────────────── */}
      <Modal
        title={
          <Space>
            <BankOutlined style={{ color: '#10b981' }} />
            <span>批量打款 — 共 {pendingSelected.length} 笔</span>
          </Space>
        }
        open={batchPayOpen} onCancel={() => setBatchPayOpen(false)} footer={null} destroyOnHidden
      >
        <div style={{
          background: '#f0fdf4', borderRadius: 10, padding: '12px 16px',
          marginBottom: 16, border: '1px solid #bbf7d0',
        }}>
          <div style={{ fontWeight: 700, color: '#065f46', marginBottom: 6 }}>本次打款明细</div>
          {pendingSelected.map(r => (
            <div key={r.id} style={{ display: 'flex', justifyContent: 'space-between', fontSize: 13, padding: '4px 0' }}>
              <span>{r.technicianName} · <ModeTag modesMap={SETTLEMENT_MODES} mode={r.settlementMode} /></span>
              <span style={{ fontWeight: 700, color: '#10b981' }}>
                {r.currencySymbol}{r.finalAmount?.toLocaleString()}
              </span>
            </div>
          ))}
          <Divider style={{ margin: '8px 0' }} />
          <div style={{ display: 'flex', justifyContent: 'space-between', fontWeight: 800, fontSize: 15 }}>
            <span>合计</span>
            <span style={{ color: '#10b981' }}>
              ${pendingSelected.reduce((a, r) => a + r.finalAmount, 0).toLocaleString()}
            </span>
          </div>
        </div>

        <Form form={batchForm} layout="vertical">
          <Form.Item name="paymentMethod" label="统一支付方式" rules={[{ required: true }]}>
            <Select placeholder="选择支付方式" options={PAY_METHODS} />
          </Form.Item>
          <Form.Item name="paymentRef" label="批量转账凭证">
            <Input placeholder="流水号或备注" prefix={<BankOutlined />} />
          </Form.Item>
        </Form>
        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10 }}>
          <Button onClick={() => setBatchPayOpen(false)}>取消</Button>
          <Button type="primary" loading={batchLoading} onClick={handleBatchPay}
            style={{ background: 'linear-gradient(135deg,#10b981,#059669)', border: 'none' }}>
            确认批量打款
          </Button>
        </div>
      </Modal>

      {/* ── 详情抽屉 ──────────────────────────────────────────────────────── */}
      <Drawer
        title={
          <Space>
            <Avatar size={36} style={{ background: '#6366f1', fontWeight: 800 }}>
              {detail?.technicianName?.charAt(0)}
            </Avatar>
            <div>
              <div style={{ fontWeight: 700, fontSize: 14 }}>{detail?.technicianName} — 结算详情</div>
              <div style={{ fontSize: 11, color: '#999', fontFamily: 'monospace' }}>{detail?.settlementNo}</div>
            </div>
          </Space>
        }
        open={detailOpen} onClose={() => setDetailOpen(false)}
        styles={{ wrapper: { width: 780 } }} placement="right"
      >
        {detail && (
          <>
            {/* Status banner */}
            <div style={{
              borderRadius: 12, padding: '16px 20px', marginBottom: 20,
              background: detail.status === 1
                ? 'linear-gradient(135deg,#f0fdf4,#dcfce7)'
                : 'linear-gradient(135deg,#fffbeb,#fef3c7)',
              border: `1px solid ${detail.status === 1 ? '#bbf7d0' : '#fde68a'}`,
            }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                  <Badge status={SETTLEMENT_STATUS[detail.status]?.badge}
                    text={<span style={{ fontWeight: 700, fontSize: 14, color: SETTLEMENT_STATUS[detail.status]?.color }}>
                      {SETTLEMENT_STATUS[detail.status]?.label}
                    </span>} />
                  <ModeTag modesMap={SETTLEMENT_MODES} mode={detail.settlementMode} />
                </div>
                <div style={{ textAlign: 'right' }}>
                  <div style={{ fontSize: 28, fontWeight: 900, color: detail.status === 1 ? '#10b981' : '#f59e0b' }}>
                    {detail.currencySymbol}{detail.finalAmount?.toLocaleString()}
                  </div>
                  <div style={{ fontSize: 11, color: '#888' }}>{detail.currencyCode}</div>
                </div>
              </div>
            </div>

            {/* Details */}
            <Descriptions size="small" column={2} bordered>
              <Descriptions.Item label="技师" span={2}>{detail.technicianName}</Descriptions.Item>
              <Descriptions.Item label="结算周期" span={2}>
                {detail.periodStart} ～ {detail.periodEnd}
              </Descriptions.Item>
              <Descriptions.Item label="订单数">{detail.orderCount} 单</Descriptions.Item>
              <Descriptions.Item label="总营业额">{detail.currencySymbol}{detail.totalRevenue?.toLocaleString()}</Descriptions.Item>
              <Descriptions.Item label="提成方式" span={2}>
                {detail.commissionType === 0
                  ? `按比例 ${detail.commissionRate}%`
                  : `固定 ${detail.currencySymbol}${detail.commissionRate}/单`}
              </Descriptions.Item>
              <Descriptions.Item label="基础提成">{detail.currencySymbol}{detail.commissionAmount?.toLocaleString()}</Descriptions.Item>
              <Descriptions.Item label="奖励">
                <span style={{ color: '#10b981', fontWeight: 600 }}>+{detail.currencySymbol}{detail.bonusAmount}</span>
              </Descriptions.Item>
              <Descriptions.Item label="扣款">
                <span style={{ color: '#ef4444', fontWeight: 600 }}>-{detail.currencySymbol}{detail.deductionAmount}</span>
              </Descriptions.Item>
              <Descriptions.Item label="实发金额">
                <span style={{ fontWeight: 800, color: '#6366f1', fontSize: 16 }}>
                  {detail.currencySymbol}{detail.finalAmount?.toLocaleString()}
                </span>
              </Descriptions.Item>
            </Descriptions>

            {/* Payment info */}
            {detail.status === 1 && (
              <>
                <Divider>打款信息</Divider>
                <Descriptions size="small" column={1} bordered>
                  <Descriptions.Item label="支付方式">
                    {PAY_METHODS.find(m => m.value === detail.paymentMethod)?.label ?? detail.paymentMethod ?? '—'}
                  </Descriptions.Item>
                  <Descriptions.Item label="打款时间">
                    {detail.paidTime ? fmtTime(detail.paidTime, 'YYYY-MM-DD HH:mm') : '—'}
                  </Descriptions.Item>
                  {detail.paymentRef && (
                    <Descriptions.Item label="流水号">{detail.paymentRef}</Descriptions.Item>
                  )}
                </Descriptions>
              </>
            )}

            {detail.remark && (
              <>
                <Divider>备注</Divider>
                <div style={{
                  background: '#f8fafc', borderRadius: 8, padding: '10px 14px',
                  fontSize: 13, color: '#555', border: '1px solid #e2e8f0',
                }}>
                  {detail.remark}
                </div>
              </>
            )}

            {/* Quick actions */}
            {detail.status === 0 && (
              <>
                <Divider />
                <Space>
                  <Button type="primary" icon={<SendOutlined />}
                    style={{ background: '#10b981', border: 'none' }}
                    onClick={() => { setDetailOpen(false); openPay(detail) }}>
                    打款
                  </Button>
                  <Button icon={<EditOutlined />} onClick={() => { setDetailOpen(false); openAdjust(detail) }}>
                    调整金额
                  </Button>
                </Space>
              </>
            )}
          </>
        )}
      </Drawer>
      </>)}
    </div>
  )
}
