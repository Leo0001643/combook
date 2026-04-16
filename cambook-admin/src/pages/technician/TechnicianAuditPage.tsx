import { useState, useEffect, useCallback } from 'react'
import {
  Table, Tag, Button, Space, Card, Row, Col,
  Modal, Input, Typography, Avatar, Drawer, message,
  Descriptions, Progress, Empty, Tooltip, Divider,
} from 'antd'
import {
  UserOutlined, CheckCircleOutlined, CloseCircleOutlined,
  AuditOutlined, ClockCircleOutlined, EyeOutlined,
  EnvironmentOutlined, StarFilled, PhoneOutlined,
  ManOutlined, WomanOutlined, ReloadOutlined, FireOutlined,
  SearchOutlined, GlobalOutlined, TagsOutlined, SettingOutlined,
  TagOutlined, FieldNumberOutlined,
} from '@ant-design/icons'
import type { ColumnsType } from 'antd/es/table'
import { technicianApi, type TechnicianVO } from '../../api/api'
import PermGuard from '../../components/common/PermGuard'
import PagePagination from '../../components/common/PagePagination'
import { col, styledTableComponents } from '../../components/common/tableComponents'
import { useTableBodyHeight } from '../../hooks/useTableBodyHeight'

const { Text, Paragraph } = Typography

export default function TechnicianAuditPage() {
  const { ref, height: tableBodyH } = useTableBodyHeight()
  const [loading, setLoading]         = useState(false)
  const [data, setData]               = useState<TechnicianVO[]>([])
  const [total, setTotal]             = useState(0)
  const [page, setPage]               = useState(1)
  const [pageSize, setPageSize]       = useState(10)
  const [selected, setSelected]       = useState<TechnicianVO | null>(null)
  const [drawerOpen, setDrawerOpen]   = useState(false)
  const [rejectOpen, setRejectOpen]   = useState(false)
  const [rejectTarget, setRejectTarget] = useState<TechnicianVO | null>(null)
  const [rejectReason, setRejectReason] = useState('')
  const [actionLoading, setActionLoading] = useState(false)

  const fetchPending = useCallback(async (pg = page) => {
    setLoading(true)
    try {
      const res = await technicianApi.list({ page: pg, size: pageSize, auditStatus: 0 })
      const d = res.data?.data
      setData(d?.list ?? [])
      setTotal(d?.total ?? 0)
    } finally {
      setLoading(false)
    }
  }, [page, pageSize])

  useEffect(() => { fetchPending() }, [fetchPending])

  const handlePass = (record: TechnicianVO) => {
    Modal.confirm({
      title: '确认通过技师认证？',
      icon: <CheckCircleOutlined style={{ color: '#52c41a' }} />,
      content: (
        <div>
          <p>技师 <strong>{record.realName}</strong>（{record.mobile}）的认证申请将被批准。</p>
          <p style={{ color: '#888', fontSize: 13 }}>通过后技师将立即收到短信通知，可正式接单。</p>
        </div>
      ),
      okText: '通过认证',
      cancelText: '暂不处理',
      okButtonProps: { style: { background: '#52c41a', borderColor: '#52c41a' } },
      async onOk() {
        setActionLoading(true)
        try {
          await technicianApi.audit({ id: record.id, auditStatus: 1 })
          message.success(`✅ ${record.realName} 认证已通过，短信通知已发送`)
          setDrawerOpen(false)
          fetchPending()
        } finally {
          setActionLoading(false)
        }
      },
    })
  }

  const handleRejectSubmit = async () => {
    if (!rejectReason.trim()) { message.warning('请填写拒绝原因'); return }
    setActionLoading(true)
    try {
      await technicianApi.audit({ id: rejectTarget!.id, auditStatus: 2, rejectReason })
      message.success('已拒绝认证，技师将收到通知')
      setRejectOpen(false)
      setDrawerOpen(false)
      fetchPending()
    } finally {
      setActionLoading(false)
    }
  }

  const openReject = (r: TechnicianVO) => {
    setRejectTarget(r)
    setRejectReason('')
    setRejectOpen(true)
  }

  const urgentCount = data.filter(r => {
    if (!r.createTime) return false
    const hours = Math.floor((Date.now() - new Date(r.createTime).getTime()) / 3600000)
    return hours > 48
  }).length

  const statBadges = [
    { label: '待审核', value: total, color: '#fa8c16', bg: 'rgba(250,140,22,0.1)', border: 'rgba(250,140,22,0.25)', icon: '⏳' },
    { label: '超48小时', value: urgentCount, color: '#ef4444', bg: 'rgba(239,68,68,0.1)', border: 'rgba(239,68,68,0.25)', icon: '⚠️' },
    { label: '本页', value: data.length, color: '#6366f1', bg: 'rgba(99,102,241,0.1)', border: 'rgba(99,102,241,0.25)', icon: '📋' },
  ]

  const handleReset = () => {
    setPage(1)
    fetchPending(1)
  }

  const handleSearch = () => {
    setPage(1)
    fetchPending(1)
  }

  const columns: ColumnsType<TechnicianVO> = [
    {
      title: col(<UserOutlined style={{ color: '#6366f1' }} />, '申请人', 'left'),
      key: 'applicant',
      width: 220,
      render: (_, r) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, width: '100%' }}>
          <div style={{ position: 'relative', flexShrink: 0 }}>
            <Avatar size={46} icon={<UserOutlined />}
              style={{ background: 'linear-gradient(135deg,#f43f5e,#fb7185)', border: '2px solid #fff3f5' }} />
            <div style={{
              position: 'absolute', bottom: -2, right: -2, height: 16,
              borderRadius: '50%', background: '#fa8c16',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <ClockCircleOutlined style={{ color: '#fff', fontSize: 9 }} />
            </div>
          </div>
          <div>
            <div style={{ fontWeight: 700, fontSize: 14 }}>
              {r.realName}
              {r.gender === 2
                ? <WomanOutlined style={{ color: '#ff85c2', marginLeft: 4, fontSize: 12 }} />
                : <ManOutlined style={{ color: '#1677ff', marginLeft: 4, fontSize: 12 }} />}
            </div>
            <div style={{ fontSize: 11, color: '#999' }}>
              <PhoneOutlined style={{ marginRight: 3 }} />{r.mobile}
            </div>
          </div>
        </div>
      ),
    },
    {
      title: col(<TagOutlined style={{ color: '#2563eb' }} />, '昵称'),
      dataIndex: 'nickname',
      width: 100,
      render: v => <Tag color="blue">{v || '—'}</Tag>,
    },
    {
      title: col(<GlobalOutlined style={{ color: '#14b8a6' }} />, '国籍'),
      dataIndex: 'nationality',
      width: 90,
      render: v => {
        if (!v) return <Text type="secondary">—</Text>
        const flagMap: Record<string, string> = {
          '中国': '🇨🇳', '柬埔寨': '🇰🇭', '越南': '🇻🇳', '泰国': '🇹🇭',
          '马来西亚': '🇲🇾', '新加坡': '🇸🇬', '缅甸': '🇲🇲', '老挝': '🇱🇦',
          '菲律宾': '🇵🇭', '韩国': '🇰🇷', '日本': '🇯🇵',
        }
        return <Tag color="geekblue">{flagMap[v] ? `${flagMap[v]} ` : ''}{v}</Tag>
      },
    },
    {
      title: col(<EnvironmentOutlined style={{ color: '#2563eb' }} />, '所在城市'),
      dataIndex: 'serviceCity',
      width: 110,
      render: v => v ? (
        <Tag icon={<EnvironmentOutlined />} color="cyan">{v}</Tag>
      ) : <Text type="secondary">未填写</Text>,
    },
    {
      title: col(<TagsOutlined style={{ color: '#2563eb' }} />, '技能标签'),
      dataIndex: 'skillTags',
      width: 220,
      render: v => v ? (
        <Space wrap size={[4, 4]}>
          {String(v).replace(/[\[\]"]/g, '').split(',').slice(0, 4).map((t: string) => (
            <Tag key={t} color="purple" style={{ fontSize: 11 }}>{t.trim()}</Tag>
          ))}
        </Space>
      ) : <Text type="secondary">暂无</Text>,
    },
    {
      title: col(<FieldNumberOutlined style={{ color: '#7c3aed' }} />, '技师编号'),
      dataIndex: 'techNo',
      width: 100,
      render: v => <Text code style={{ fontSize: 11 }}>{v}</Text>,
    },
    {
      title: col(<ClockCircleOutlined style={{ color: '#fa8c16' }} />, '待审时长'),
      dataIndex: 'createTime',
      width: 120,
      render: v => {
        if (!v) return '—'
        const hours = Math.floor((Date.now() - new Date(v).getTime()) / 3600000)
        const days = Math.floor(hours / 24)
        const color = hours > 48 ? '#ff4d4f' : hours > 24 ? '#fa8c16' : '#52c41a'
        return (
          <Tag color={color} style={{ fontWeight: 600 }}>
            {days > 0 ? `${days}天${hours % 24}时` : `${hours}小时`}
          </Tag>
        )
      },
    },
    {
      title: col(<SettingOutlined style={{ color: '#64748b' }} />, '操作'),
      key: 'action',
      fixed: 'right',
      width: 225,
      render: (_, r) => (
        <Space size={[4, 4]} wrap>
          <Button size="small" type="primary" ghost icon={<EyeOutlined />}
            style={{ borderRadius: 6, fontSize: 12 }}
            onClick={() => { setSelected(r); setDrawerOpen(true) }}>查看</Button>
          <PermGuard code="technician:audit">
            <Button size="small" icon={<CheckCircleOutlined />}
              style={{ borderRadius: 6, fontSize: 12, color: '#52c41a', borderColor: '#b7eb8f' }}
              onClick={() => handlePass(r)}>通过</Button>
          </PermGuard>
          <PermGuard code="technician:audit">
            <Button size="small" danger icon={<CloseCircleOutlined />}
              style={{ borderRadius: 6, fontSize: 12 }}
              onClick={() => openReject(r)}>拒绝</Button>
          </PermGuard>
        </Space>
      ),
    },
  ]

  return (
    <div style={{ marginTop: -24 }}>
      <div style={{
        position: 'sticky', top: 64, zIndex: 88,
        marginLeft: -24, marginRight: -24,
        background: 'rgba(255,255,255,0.97)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderBottom: '1px solid rgba(0,0,0,0.07)',
        boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', padding: '10px 24px 0', gap: 12 }}>
          <div style={{
            width: 34, height: 34, borderRadius: 10,
            background: 'linear-gradient(135deg,#fa8c16,#ffc53d)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 4px 12px rgba(250,140,22,0.35)', flexShrink: 0,
          }}>
            <AuditOutlined style={{ color: '#fff', fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1e293b', lineHeight: 1.2 }}>技师审核</div>
            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>
              审核技师入驻申请 · 核实资质证件 · 维护平台服务质量
            </div>
          </div>
          <div style={{ width: 1, height: 20, margin: '0 4px', background: '#ffe7ba', flexShrink: 0 }} />
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            {statBadges.map((s, i) => (
              <div key={i} style={{
                display: 'flex', alignItems: 'center', gap: 5,
                padding: '3px 10px', borderRadius: 20, background: s.bg, border: `1px solid ${s.border}`,
              }}>
                <span style={{ fontSize: 13 }}>{s.icon}</span>
                <span style={{ fontSize: 12, color: '#6b7280' }}>{s.label}</span>
                <span style={{ fontSize: 13, fontWeight: 700, color: s.color }}>{s.value}</span>
              </div>
            ))}
          </div>
          <div style={{ flex: 1 }} />
        </div>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', padding: '10px 24px 12px' }}>
          <Button icon={<ReloadOutlined />} size="middle" style={{ borderRadius: 8 }} onClick={handleReset}>重置</Button>
          <Tooltip title="刷新列表">
            <Button
              icon={<ReloadOutlined />}
              size="middle"
              loading={loading}
              style={{ borderRadius: 8, color: '#fa8c16', borderColor: '#ffd591' }}
              onClick={() => fetchPending()}
            />
          </Tooltip>
          <Button
            type="primary"
            icon={<SearchOutlined />}
            style={{
              borderRadius: 8, border: 'none',
              background: 'linear-gradient(135deg,#fa8c16,#ffc53d)',
              boxShadow: '0 2px 8px rgba(250,140,22,0.35)',
            }}
            onClick={handleSearch}
          >搜索</Button>
        </div>
      </div>

      <div ref={ref} style={{ marginLeft: -24, marginRight: -24, marginBottom: -24, background: '#fff', borderTop: '1px solid #eef0f8' }}>
        {data.length === 0 && !loading ? (
          <Empty
            image={Empty.PRESENTED_IMAGE_SIMPLE}
            description={<Text type="secondary">暂无待审核的技师申请 🎉</Text>}
            style={{ padding: '40px 0' }}
          />
        ) : (
          <Table
            rowKey="id"
            dataSource={data}
            columns={columns}
            loading={loading}
            size="middle"
            components={styledTableComponents}
            scroll={{ x: 'max-content', y: tableBodyH }}
            pagination={false}
            rowClassName={(r) => {
              if (!r.createTime) return ''
              const hours = Math.floor((Date.now() - new Date(r.createTime).getTime()) / 3600000)
              return hours > 48 ? 'row-urgent' : ''
            }}
          />
        )}
        {!(data.length === 0 && !loading) && (
          <PagePagination
            total={total}
            current={page}
            pageSize={pageSize}
            onChange={p => setPage(p)}
            onSizeChange={s => { setPageSize(s); setPage(1) }}
            countLabel="条待审核"
            pageSizeOptions={[10, 20, 50, 100, 200]}
          />
        )}
      </div>

      {/* 技师详情抽屉 */}
      <Drawer
        title={
          <Space>
            <Avatar size={36} icon={<UserOutlined />}
              style={{ background: 'linear-gradient(135deg,#f43f5e,#fb923c)' }} />
            <div>
              <div style={{ fontWeight: 700 }}>{selected?.realName}</div>
              <div style={{ fontSize: 11, color: '#999', fontWeight: 400 }}>技师认证审核</div>
            </div>
          </Space>
        }
        styles={{ wrapper: { width: 880 } }}
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        extra={
          <Space>
            <Button danger icon={<CloseCircleOutlined />}
              onClick={() => { openReject(selected!) }}>
              拒绝
            </Button>
            <Button type="primary" icon={<CheckCircleOutlined />}
              style={{ background: '#52c41a', borderColor: '#52c41a' }}
              onClick={() => { handlePass(selected!) }}>
              通过认证
            </Button>
          </Space>
        }
      >
        {selected && (
          <div>
            {/* 个人信息卡 */}
            <div style={{
              background: 'linear-gradient(135deg,rgba(244,63,94,0.06),rgba(251,146,60,0.06))',
              borderRadius: 14, padding: '20px 24px', marginBottom: 20, textAlign: 'center',
            }}>
              <Avatar size={80} icon={<UserOutlined />}
                style={{ background: 'linear-gradient(135deg,#f43f5e,#fb923c)', border: '3px solid #fff', boxShadow: '0 4px 16px rgba(244,63,94,0.3)' }} />
              <div style={{ marginTop: 12, fontSize: 20, fontWeight: 800 }}>
                {selected.realName}
                {selected.gender === 2
                  ? <WomanOutlined style={{ color: '#ff85c2', marginLeft: 6 }} />
                  : <ManOutlined style={{ color: '#1677ff', marginLeft: 6 }} />}
              </div>
              <div style={{ color: '#888', fontSize: 13 }}>昵称：{selected.nickname || '未设置'}</div>
              <div style={{ marginTop: 8 }}>
                <Tag color="orange" icon={<ClockCircleOutlined />}>待审核</Tag>
                {selected.nationality && (
                  <Tag color="geekblue">{selected.nationality}</Tag>
                )}
                {selected.serviceCity && (
                  <Tag color="blue" icon={<EnvironmentOutlined />}>{selected.serviceCity}</Tag>
                )}
              </div>
            </div>

            {/* 联系信息 */}
            <Card size="small" variant="borderless" style={{ background: '#f9f9f9', borderRadius: 12, marginBottom: 16 }}
              title={<Text strong><PhoneOutlined style={{ marginRight: 6, color: '#1677ff' }} />联系方式</Text>}>
              <Descriptions column={2} size="small">
                <Descriptions.Item label="手机号" span={2}>{selected.mobile}</Descriptions.Item>
                <Descriptions.Item label="国籍">
                  {selected.nationality ? <Tag color="geekblue">{selected.nationality}</Tag> : '—'}
                </Descriptions.Item>
                <Descriptions.Item label="技师编号">{selected.techNo}</Descriptions.Item>
                <Descriptions.Item label="所在城市">{selected.serviceCity || '—'}</Descriptions.Item>
              </Descriptions>
            </Card>

            {/* 技能信息 */}
            {selected.skillTags && (
              <Card size="small" variant="borderless" style={{ background: '#f9f9f9', borderRadius: 12, marginBottom: 16 }}
                title={<Text strong>⚡ 技能标签</Text>}>
                <Space wrap size={[6, 6]}>
                  {String(selected.skillTags).replace(/[\[\]"]/g, '').split(',').map((t: string) => (
                    <Tag key={t} color="purple" style={{ fontSize: 13, padding: '2px 10px' }}>{t.trim()}</Tag>
                  ))}
                </Space>
              </Card>
            )}

            {/* 数据摘要（即便新技师也展示） */}
            <Row gutter={12} style={{ marginBottom: 16 }}>
              {[
                { label: '接单数', value: selected.orderCount ?? 0, color: '#722ed1', icon: '📦' },
                { label: '评价数', value: selected.reviewCount ?? 0, color: '#1677ff', icon: '💬' },
                { label: '评分',   value: Number(selected.rating).toFixed(1), color: '#faad14', icon: '⭐' },
              ].map(item => (
                <Col span={8} key={item.label}>
                  <div style={{ textAlign: 'center', padding: '12px 8px', background: '#fafafa', borderRadius: 10 }}>
                    <div style={{ fontSize: 20 }}>{item.icon}</div>
                    <div style={{ fontWeight: 800, color: item.color, fontSize: 18 }}>{item.value}</div>
                    <div style={{ color: '#999', fontSize: 12 }}>{item.label}</div>
                  </div>
                </Col>
              ))}
            </Row>

            {/* 好评率 */}
            <Card size="small" variant="borderless" style={{ background: '#f9f9f9', borderRadius: 12, marginBottom: 16 }}
              title={<Text strong><StarFilled style={{ color: '#faad14', marginRight: 6 }} />好评率</Text>}>
              <Progress
                percent={Number(selected.goodReviewRate)}
                strokeColor={{
                  '0%': '#faad14',
                  '100%': '#52c41a',
                }}
                format={p => <Text strong style={{ color: '#52c41a' }}>{p}%</Text>}
              />
            </Card>

            <div style={{ padding: '12px 16px', background: '#fff7e6', borderRadius: 10, border: '1px dashed #ffa940' }}>
              <Text type="secondary" style={{ fontSize: 12 }}>
                📋 审核提示：请核实技师的手机号真实性、技能描述的准确性，通过后技师将可正式接受平台订单。
              </Text>
            </div>
          </div>
        )}
      </Drawer>

      {/* 拒绝弹窗 */}
      <Modal
        title={
          <Space>
            <div style={{
              width: 32, height: 32, borderRadius: 8,
              background: 'linear-gradient(135deg,#ff4d4f,#ff7875)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <CloseCircleOutlined style={{ color: '#fff' }} />
            </div>
            <span>拒绝认证申请</span>
          </Space>
        }
        open={rejectOpen}
        onCancel={() => { setRejectOpen(false) }}
        onOk={handleRejectSubmit}
        okText="确认拒绝"
        okButtonProps={{ danger: true, loading: actionLoading }}
        cancelText="取消"
        width={880}
        styles={{ body: { maxHeight: 'calc(85vh - 150px)', overflowY: 'auto', overflowX: 'hidden' } }}
      >
        <div style={{
          marginBottom: 16, padding: '12px 16px',
          background: '#fff7e6', borderRadius: 10,
          display: 'flex', alignItems: 'center', gap: 10,
        }}>
          <Avatar size={36} icon={<UserOutlined />}
            style={{ background: 'linear-gradient(135deg,#f43f5e,#fb923c)', flexShrink: 0 }} />
          <div>
            <div style={{ fontWeight: 700 }}>{rejectTarget?.realName}</div>
            <div style={{ color: '#888', fontSize: 12 }}>{rejectTarget?.mobile}</div>
          </div>
        </div>
        <Input.TextArea
          placeholder="请详细填写拒绝原因，将通过短信告知技师（必填）&#10;例：身份证照片不清晰，请重新上传清晰照片后再次申请。"
          rows={5}
          value={rejectReason}
          onChange={e => setRejectReason(e.target.value)}
          style={{ borderRadius: 8 }}
          showCount
          maxLength={200}
        />
        <Paragraph type="secondary" style={{ marginTop: 8, fontSize: 12 }}>
          拒绝后技师可修改资料重新申请。请给出明确的拒绝原因以帮助技师改进。
        </Paragraph>
      </Modal>
    </div>
  )
}
