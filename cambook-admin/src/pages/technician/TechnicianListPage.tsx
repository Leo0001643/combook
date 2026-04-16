import { useState, useEffect, useCallback } from 'react'
import {
  Row, Col, Table, Input, Select, Tag, Avatar, Space, Button,
  Typography, message, Drawer, Descriptions, Rate, Badge,
  Progress, Modal, Popconfirm, Switch, Dropdown,
  Divider, Tooltip,
} from 'antd'
import {
  SearchOutlined, UserOutlined, ClockCircleOutlined, CheckCircleOutlined, CloseCircleOutlined,
  MinusCircleOutlined, PlayCircleOutlined,
  EyeOutlined, ReloadOutlined, IdcardOutlined,
  StarFilled, ManOutlined, WomanOutlined, EnvironmentOutlined,
  TrophyOutlined, FireOutlined, CrownOutlined, StopOutlined, DeleteOutlined,
  PlusOutlined, SendOutlined, ShopOutlined,
  GlobalOutlined, WifiOutlined, TagsOutlined, AuditOutlined, TeamOutlined,
  SafetyCertificateOutlined, SettingOutlined,
} from '@ant-design/icons'
import type { ColumnsType } from 'antd/es/table'
import { merchantApi, type TechnicianVO } from '../../api/api'
import { usePortalScope } from '../../hooks/usePortalScope'
import TechnicianCreateModal from '../../components/technician/TechnicianCreateModal'
import PermGuard from '../../components/common/PermGuard'
import PagePagination from '../../components/common/PagePagination'
import { col, styledTableComponents, INPUT_STYLE } from '../../components/common/tableComponents'

const { Text } = Typography

const AUDIT_MAP: Record<number, { color: string; text: string; bg: string }> = {
  0: { color: '#fa8c16', text: '待审核', bg: 'rgba(250,140,22,0.1)' },
  1: { color: '#52c41a', text: '已通过', bg: 'rgba(82,196,26,0.1)'  },
  2: { color: '#ff4d4f', text: '已拒绝', bg: 'rgba(255,77,79,0.1)'  },
}

const ONLINE_MAP: Record<number, { color: string; text: string; icon: string; tagColor: string }> = {
  0: { color: 'default',    text: '离线',  icon: '⚫', tagColor: '#8c8c8c' },
  1: { color: 'success',    text: '在线',  icon: '🟢', tagColor: '#52c41a' },
  2: { color: 'processing', text: '忙碌中', icon: '🟠', tagColor: '#fa8c16' },
}

const CITIES = ['金边', '暹粒', '西哈努克', '贡布', '白马']

/** 解析相册 JSON / 逗号字符串为 URL 数组 */
function parsePhotos(photos: string | undefined | null): string[] {
  if (!photos) return []
  try {
    const raw = String(photos).trim()
    if (raw === 'null' || raw === '') return []
    const arr: unknown[] = raw.startsWith('[') ? JSON.parse(raw) : raw.split(',').map(s => s.trim())
    return arr.filter((u): u is string => typeof u === 'string' && u.startsWith('http'))
  } catch {
    return []
  }
}

export default function TechnicianListPage() {
  const { isAdmin, isMerchant, technicianList, technicianCreate, technicianAudit, technicianUpdateStatus, technicianUpdateOnlineStatus, technicianSetFeatured, technicianDelete } = usePortalScope()
  const [loading, setLoading]     = useState(false)
  const [data, setData]           = useState<TechnicianVO[]>([])
  const [total, setTotal]         = useState(0)
  const [page, setPage]           = useState(1)
  const [pageSize, setPageSize]   = useState(10)
  const [keyword, setKeyword]     = useState('')
  const [auditStatus, setAuditStatus] = useState<number | undefined>()
  const [onlineStatus, setOnlineStatus] = useState<number | undefined>()
  const [serviceCity, setServiceCity] = useState<string | undefined>()
  const [gender, setGender]       = useState<number | undefined>()
  const [nationality, setNationality] = useState<string | undefined>()
  const [telegram, setTelegram]   = useState('')
  const [detail, setDetail]       = useState<TechnicianVO | null>(null)
  const [drawerOpen, setDrawerOpen] = useState(false)
  const [rejectTarget, setRejectTarget] = useState<TechnicianVO | null>(null)
  const [rejectReason, setRejectReason] = useState('')
  const [rejectOpen, setRejectOpen] = useState(false)
  const [actionLoading, setActionLoading] = useState(false)
  const [createOpen, setCreateOpen]     = useState(false)
  const [merchantId, setMerchantId]     = useState<number | undefined>()
  const [merchantOptions, setMerchantOptions] = useState<{ value: number; label: string }[]>([])

  // 仅管理员加载商户下拉选项
  useEffect(() => {
    if (!isAdmin) return
    merchantApi.list({ page: 1, size: 200 }).then(res => {
      const list: any[] = res.data?.data?.list ?? []
      setMerchantOptions(list.map(m => ({ value: m.id, label: m.merchantNameZh || m.merchantNameEn || `商户#${m.id}` })))
    }).catch(() => {})
  }, [isAdmin])

  const fetchList = useCallback(async (pg = page) => {
    setLoading(true)
    try {
      const res = await technicianList({
        page: pg, size: pageSize, keyword, auditStatus, onlineStatus, serviceCity, gender, nationality,
        ...(isAdmin && merchantId != null ? { merchantId } : {}),
      })
      const d = res.data?.data
      setData(d?.list ?? [])
      setTotal(d?.total ?? 0)
    } finally {
      setLoading(false)
    }
  }, [page, pageSize, keyword, auditStatus, onlineStatus, serviceCity, gender, nationality, merchantId, isAdmin])

  useEffect(() => { fetchList() }, [fetchList])

  const handleSearch = () => { setPage(1); fetchList(1) }
  const handleReset = () => {
    setKeyword(''); setAuditStatus(undefined); setOnlineStatus(undefined)
    setServiceCity(undefined); setGender(undefined); setNationality(undefined)
    setTelegram(''); setMerchantId(undefined)
    setPage(1); fetchList(1)
  }

  const handlePass = (record: TechnicianVO) => {
    Modal.confirm({
      title: '确认通过审核？',
      icon: <CheckCircleOutlined style={{ color: '#52c41a' }} />,
      content: (
        <div>
          <p>技师：<strong>{record.realName}</strong>（{record.mobile}）</p>
          <p style={{ color: '#888', fontSize: 13 }}>通过后技师将收到短信通知，可正式接单</p>
        </div>
      ),
      okText: '确认通过',
      okButtonProps: { style: { background: '#52c41a', borderColor: '#52c41a' } },
      async onOk() {
        setActionLoading(true)
        try {
          await technicianAudit({ id: record.id, auditStatus: 1 })
          message.success('审核通过，通知已发送')
          fetchList()
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
      await technicianAudit({ id: rejectTarget!.id, auditStatus: 2, rejectReason })
      message.success('已拒绝，技师将收到通知')
      setRejectOpen(false)
      fetchList()
    } finally {
      setActionLoading(false)
    }
  }

  const handleStatusToggle = async (r: TechnicianVO) => {
    const next = r.status === 1 ? 0 : 1
    await technicianUpdateStatus(r.id, next)
    message.success(next === 1 ? '已启用账号' : '已停用账号')
    fetchList()
  }

  const handleOnlineChange = async (r: TechnicianVO, next: number) => {
    if (r.onlineStatus === next) return
    await technicianUpdateOnlineStatus(r.id, next)
    message.success(`已设为「${ONLINE_MAP[next].text}」`)
    fetchList()
  }

  const handleSetFeatured = async (r: TechnicianVO) => {
    const next = r.isFeatured === 1 ? 0 : 1
    await technicianSetFeatured(r.id, next)
    message.success(next === 1 ? '已设为推荐技师 ⭐' : '已取消推荐')
    fetchList()
  }

  const handleDelete = async (r: TechnicianVO) => {
    await technicianDelete(r.id)
    message.success(`技师「${r.realName}」已删除`)
    fetchList()
  }

  const stats = {
    total,
    pending: data.filter(d => d.auditStatus === 0).length,
    passed:  data.filter(d => d.auditStatus === 1).length,
    online:  data.filter(d => d.onlineStatus === 1 || d.onlineStatus === 2).length,
  }

  const statBadges = [
    { label: '总技师', value: total, color: '#6366f1', bg: 'rgba(99,102,241,0.1)', border: 'rgba(99,102,241,0.25)', icon: '👥' },
    { label: '待审核', value: stats.pending, color: '#fa8c16', bg: 'rgba(250,140,22,0.1)', border: 'rgba(250,140,22,0.25)', icon: '⏳' },
    { label: '在线中', value: stats.online, color: '#10b981', bg: 'rgba(16,185,129,0.1)', border: 'rgba(16,185,129,0.25)', icon: '🟢' },
  ]

  const columns: ColumnsType<TechnicianVO> = [
    {
      title: col(<IdcardOutlined style={{ color: '#6366f1' }} />, '技师信息', 'left'),
      key: 'tech',
      fixed: 'left',
      width: 200,
      render: (_, r) => {
        // 优先头像，其次相册第一张，最后默认图标
        const firstPhoto = parsePhotos(r.photos)[0] ?? null
        const displayImg = r.avatar || firstPhoto

        return (
          <div style={{ display: 'flex', alignItems: 'center', width: '100%', gap: 0 }}>
            {/* 头像：固定 80×116，与真实图片尺寸完全一致 */}
            <div style={{ position: 'relative', flexShrink: 0, width: 80, height: 116 }}>
              {displayImg ? (
                <img
                  src={displayImg}
                  alt="avatar"
                  style={{
                    width: 80, height: 116,
                    objectFit: 'cover',
                    borderRadius: 8,
                    display: 'block',
                  }}
                />
              ) : (
                <div style={{
                  width: 80, height: 116,
                  background: 'linear-gradient(160deg,#6366f1 0%,#8b5cf6 60%,#a78bfa 100%)',
                  borderRadius: 8,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  <UserOutlined style={{ color: '#fff', fontSize: 26 }} />
                </div>
              )}
              {r.isFeatured === 1 && (
                <div style={{
                  position: 'absolute', top: 9, right: 4,
                  width: 18, height: 18, borderRadius: '50%',
                  background: 'linear-gradient(135deg,#f59e0b,#d97706)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  boxShadow: '0 1px 4px rgba(0,0,0,0.25)',
                }}>
                  <CrownOutlined style={{ color: '#fff', fontSize: 10 }} />
                </div>
              )}
            </div>
            {/* 文字信息 */}
            <div style={{ padding: '8px 10px', display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
              <div style={{ fontWeight: 700, fontSize: 14 }}>
                {r.nickname || r.realName}
                {r.gender === 2
                  ? <WomanOutlined style={{ color: '#ff85c2', marginLeft: 4, fontSize: 12 }} />
                  : <ManOutlined style={{ color: '#1677ff', marginLeft: 4, fontSize: 12 }} />}
              </div>
              <div style={{ fontSize: 11, color: '#999' }}>{r.mobile} · #{r.techNo}</div>
              {r.telegram && (
                <div style={{ fontSize: 11, color: '#229ED9' }}>
                  <SendOutlined style={{ marginRight: 3 }} />@{r.telegram}
                </div>
              )}
            </div>
          </div>
        )
      },
    },
    ...(isAdmin ? [{
      title: col(<ShopOutlined style={{ color: '#4f46e5' }} />, '所属商户'),
      key: 'merchant',
      width: 140,
      render: (_: any, r: TechnicianVO) => {
        // 优先用接口返回的 merchantName，其次从已加载的商户下拉选项中反查
        const name = r.merchantName
          || merchantOptions.find(m => m.value === r.merchantId)?.label
        return name ? (
          <div style={{
            display: 'inline-flex', alignItems: 'center', gap: 5,
            padding: '2px 8px', borderRadius: 20,
            background: 'rgba(99,102,241,0.08)',
            border: '1px solid rgba(99,102,241,0.18)',
            fontSize: 12, color: '#6366f1', fontWeight: 500,
            maxWidth: 130, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
          }}>
            <ShopOutlined style={{ fontSize: 11, flexShrink: 0 }} />
            <span style={{ overflow: 'hidden', textOverflow: 'ellipsis' }}>{name}</span>
          </div>
        ) : (
          <span style={{ color: '#bfbfbf', fontSize: 12 }}>平台直营</span>
        )
      },
    }] as any : []),
    {
      title: col(<GlobalOutlined style={{ color: '#14b8a6' }} />, '国籍'),
      dataIndex: 'nationality',
      width: 90,
      render: v => {
        if (!v) return <Text type="secondary">—</Text>
        const flagMap: Record<string, string> = {
          '中国': '🇨🇳', '柬埔寨': '🇰🇭', '越南': '🇻🇳', '泰国': '🇹🇭',
          '马来西亚': '🇲🇾', '新加坡': '🇸🇬', '缅甸': '🇲🇲', '老挝': '🇱🇦',
          '菲律宾': '🇵🇭', '印度尼西亚': '🇮🇩', '韩国': '🇰🇷', '日本': '🇯🇵',
        }
        return (
          <Tag color="geekblue" style={{ fontSize: 12 }}>
            {flagMap[v] ? `${flagMap[v]} ` : ''}{v}
          </Tag>
        )
      },
    },
    {
      title: col(<WifiOutlined style={{ color: '#10b981' }} />, '在线 / 推荐'),
      dataIndex: 'onlineStatus',
      width: 145,
      render: (v, r) => {
        const cur = ONLINE_MAP[v ?? 0]
        const featured = r.isFeatured === 1
        return (
          <Space size={4} direction="vertical" style={{ gap: 4 }}>
            {/* 在线状态 Dropdown */}
            <Dropdown
              trigger={['click']}
              menu={{
                selectedKeys: [String(v ?? 0)],
                items: [
                  {
                    key: '1',
                    label: (
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '2px 0' }}>
                        <span style={{
                          display: 'inline-block', width: 10, height: 10, borderRadius: '50%',
                          background: '#52c41a', boxShadow: '0 0 0 3px rgba(82,196,26,0.2)',
                        }} />
                        <span style={{ fontWeight: 600, color: '#52c41a' }}>在线</span>
                        <span style={{ color: '#aaa', fontSize: 12, marginLeft: 'auto' }}>可接单</span>
                      </div>
                    ),
                  },
                  {
                    key: '2',
                    label: (
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '2px 0' }}>
                        <span style={{
                          display: 'inline-block', width: 10, height: 10, borderRadius: '50%',
                          background: '#fa8c16', boxShadow: '0 0 0 3px rgba(250,140,22,0.2)',
                        }} />
                        <span style={{ fontWeight: 600, color: '#fa8c16' }}>忙碌中</span>
                        <span style={{ color: '#aaa', fontSize: 12, marginLeft: 'auto' }}>服务中</span>
                      </div>
                    ),
                  },
                  {
                    key: '0',
                    label: (
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '2px 0' }}>
                        <span style={{
                          display: 'inline-block', width: 10, height: 10, borderRadius: '50%',
                          background: '#bfbfbf', boxShadow: '0 0 0 3px rgba(0,0,0,0.06)',
                        }} />
                        <span style={{ fontWeight: 600, color: '#8c8c8c' }}>离线</span>
                        <span style={{ color: '#aaa', fontSize: 12, marginLeft: 'auto' }}>不接单</span>
                      </div>
                    ),
                  },
                ],
                onClick: ({ key }) => handleOnlineChange(r, Number(key)),
              }}
            >
              <div style={{
                display: 'inline-flex', alignItems: 'center', gap: 5,
                padding: '3px 10px', borderRadius: 20, cursor: 'pointer',
                border: `1.5px solid ${cur.tagColor}22`,
                background: `${cur.tagColor}12`,
                transition: 'all 0.2s',
                userSelect: 'none',
              }}
                onMouseEnter={e => (e.currentTarget.style.background = `${cur.tagColor}22`)}
                onMouseLeave={e => (e.currentTarget.style.background = `${cur.tagColor}12`)}
              >
                {v === 1 ? (
                  <span style={{
                    display: 'inline-block', width: 7, height: 7, borderRadius: '50%',
                    background: cur.tagColor, animation: 'pulse-dot 1.5s infinite',
                  }} />
                ) : (
                  <span style={{
                    display: 'inline-block', width: 7, height: 7, borderRadius: '50%',
                    background: cur.tagColor,
                  }} />
                )}
                <span style={{ fontSize: 12, fontWeight: 600, color: cur.tagColor, lineHeight: 1 }}>
                  {cur.text}
                </span>
                <span style={{ fontSize: 10, color: cur.tagColor, opacity: 0.7, lineHeight: 1 }}>▾</span>
              </div>
            </Dropdown>

            {/* 推荐状态 Dropdown */}
            <Dropdown
              trigger={['click']}
              menu={{
                selectedKeys: [featured ? '1' : '0'],
                items: [
                  {
                    key: '1',
                    disabled: featured,
                    label: (
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '2px 0' }}>
                        <CrownOutlined style={{ color: '#faad14', fontSize: 13 }} />
                        <span style={{ fontWeight: 600, color: '#faad14' }}>推荐技师</span>
                        <span style={{ color: '#aaa', fontSize: 12, marginLeft: 'auto' }}>优先展示</span>
                      </div>
                    ),
                  },
                  {
                    key: '0',
                    disabled: !featured,
                    label: (
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '2px 0' }}>
                        <UserOutlined style={{ color: '#8c8c8c', fontSize: 13 }} />
                        <span style={{ fontWeight: 600, color: '#8c8c8c' }}>普通技师</span>
                        <span style={{ color: '#aaa', fontSize: 12, marginLeft: 'auto' }}>正常排序</span>
                      </div>
                    ),
                  },
                ],
                onClick: () => handleSetFeatured(r),
              }}
            >
              <div style={{
                display: 'inline-flex', alignItems: 'center', gap: 5,
                padding: '3px 10px', borderRadius: 20, cursor: 'pointer',
                border: `1.5px solid ${featured ? '#faad1422' : '#d9d9d9'}`,
                background: featured ? '#faad1412' : '#f5f5f5',
                transition: 'all 0.2s',
                userSelect: 'none',
              }}
                onMouseEnter={e => (e.currentTarget.style.background = featured ? '#faad1422' : '#e8e8e8')}
                onMouseLeave={e => (e.currentTarget.style.background = featured ? '#faad1412' : '#f5f5f5')}
              >
                <CrownOutlined style={{
                  fontSize: 11,
                  color: featured ? '#faad14' : '#bfbfbf',
                }} />
                <span style={{
                  fontSize: 12, fontWeight: 600, lineHeight: 1,
                  color: featured ? '#faad14' : '#8c8c8c',
                }}>
                  {featured ? '推荐' : '普通'}
                </span>
                <span style={{ fontSize: 10, opacity: 0.7, lineHeight: 1, color: featured ? '#faad14' : '#8c8c8c' }}>▾</span>
              </div>
            </Dropdown>
          </Space>
        )
      },
    },
    {
      title: col(<StarFilled style={{ color: '#eab308' }} />, '评分 / 好评率'),
      key: 'score',
      width: 160,
      sorter: (a: TechnicianVO, b: TechnicianVO) => Number(a.rating) - Number(b.rating),
      render: (_: any, r: TechnicianVO) => (
        <div>
          <Space size={4}>
            <StarFilled style={{ color: '#faad14', fontSize: 13 }} />
            <Text strong style={{ color: '#faad14', fontSize: 14 }}>{Number(r.rating).toFixed(1)}</Text>
            <Text type="secondary" style={{ fontSize: 11 }}>({r.reviewCount}评)</Text>
          </Space>
          <div style={{ marginTop: 2 }}>
            <Progress
              percent={Number(r.goodReviewRate)}
              size="small"
              strokeColor={Number(r.goodReviewRate) >= 95 ? '#52c41a' : '#faad14'}
              format={p => <span style={{ fontSize: 11, color: '#888' }}>{p}%好评</span>}
            />
          </div>
        </div>
      ),
    },
    {
      title: col(<FireOutlined style={{ color: '#ef4444' }} />, '今日接单'),
      dataIndex: 'todayOrderCount',
      width: 85,
      sorter: (a: TechnicianVO, b: TechnicianVO) => (a.todayOrderCount ?? 0) - (b.todayOrderCount ?? 0),
      render: (v: number) => (
        <Space>
          <FireOutlined style={{ color: '#ff4d4f', fontSize: 13 }} />
          <Text strong style={{ color: '#ff4d4f' }}>{v ?? 0}</Text>
        </Space>
      ),
    },
    {
      title: col(<TrophyOutlined style={{ color: '#7c3aed' }} />, '总接单数'),
      dataIndex: 'orderCount',
      width: 90,
      sorter: (a: TechnicianVO, b: TechnicianVO) => a.orderCount - b.orderCount,
      render: (v: number) => (
        <Space>
          <TrophyOutlined style={{ color: '#722ed1', fontSize: 13 }} />
          <Text strong style={{ color: '#722ed1' }}>{v ?? 0}</Text>
        </Space>
      ),
    },
    {
      title: col(<TagsOutlined style={{ color: '#2563eb' }} />, '技能标签'),
      dataIndex: 'skillTags',
      width: 200,
      render: (v: string) => v ? (
        <Space wrap size={[4, 4]}>
          {String(v).replace(/[\[\]"]/g, '').split(',').slice(0, 3).map((t: string) => (
            <Tag key={t} color="purple" style={{ fontSize: 11 }}>{t.trim()}</Tag>
          ))}
        </Space>
      ) : <Text type="secondary">—</Text>,
    },
    {
      title: col(<AuditOutlined style={{ color: '#fa8c16' }} />, '审核状态'),
      dataIndex: 'auditStatus',
      width: 100,
      render: v => {
        const s = AUDIT_MAP[v ?? 0]
        return (
          <span style={{
            padding: '2px 10px', borderRadius: 20,
            background: s.bg, color: s.color,
            fontSize: 12, fontWeight: 600,
          }}>{s.text}</span>
        )
      },
    },
    {
      title: col(<EnvironmentOutlined style={{ color: '#2563eb' }} />, '所在城市'),
      dataIndex: 'serviceCity',
      width: 100,
      render: (v: string) => v ? (
        <Tag icon={<EnvironmentOutlined />} color="blue">{v}</Tag>
      ) : <Text type="secondary">—</Text>,
    },
    {
      title: col(<SafetyCertificateOutlined style={{ color: '#10b981' }} />, '账号状态'),
      dataIndex: 'status',
      width: 100,
      render: (v, r) => (
        <Switch checked={v === 1}
          checkedChildren="启用" unCheckedChildren="停用"
          onChange={() => handleStatusToggle(r)} />
      ),
    },
    {
      title: col(<SettingOutlined style={{ color: '#64748b' }} />, '操作'),
      key: 'action',
      fixed: 'right',
      width: 240,
      render: (_, r) => (
        <Space size={[4, 4]} wrap>
          <Button size="small" type="primary" ghost icon={<EyeOutlined />}
            style={{ borderRadius: 6, fontSize: 12 }}
            onClick={() => { setDetail(r); setDrawerOpen(true) }}>查看</Button>
          {r.auditStatus === 0 && (
            <PermGuard code="technician:audit">
              <>
                <Button size="small" icon={<CheckCircleOutlined />}
                  style={{ borderRadius: 6, fontSize: 12, color: '#52c41a', borderColor: '#b7eb8f' }}
                  onClick={() => handlePass(r)}>通过</Button>
                <Button size="small" danger icon={<CloseCircleOutlined />}
                  style={{ borderRadius: 6, fontSize: 12 }}
                  onClick={() => { setRejectTarget(r); setRejectReason(''); setRejectOpen(true) }}>拒绝</Button>
              </>
            </PermGuard>
          )}
          <PermGuard code="technician:toggle">
            {r.status === 1 ? (
              <Button size="small" icon={<StopOutlined />}
                style={{ borderRadius: 6, fontSize: 12, color: '#ff4d4f', borderColor: '#ffa39e' }}
                onClick={() => handleStatusToggle(r)}>停用</Button>
            ) : (
              <Button size="small" icon={<CheckCircleOutlined />}
                style={{ borderRadius: 6, fontSize: 12, color: '#52c41a', borderColor: '#b7eb8f' }}
                onClick={() => handleStatusToggle(r)}>启用</Button>
            )}
          </PermGuard>
          <PermGuard code="technician:delete">
            <Popconfirm
              title="确认删除该技师档案？"
              description="删除后无法恢复。"
              onConfirm={() => handleDelete(r)}
              okText="确认" cancelText="取消"
              okButtonProps={{ danger: true }}
            >
              <Button size="small" danger icon={<DeleteOutlined />} style={{ borderRadius: 6, fontSize: 12 }}>删除</Button>
            </Popconfirm>
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
            background: 'linear-gradient(135deg,#6366f1,#8b5cf6)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 4px 12px rgba(99,102,241,0.3)', flexShrink: 0,
          }}>
            <IdcardOutlined style={{ color: '#fff', fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1e293b', lineHeight: 1.2 }}>技师列表</div>
            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>
              {isMerchant ? '管理本店技师团队 · 新增技师 · 监控状态' : '管理平台全部认证技师 · 审核申请 · 监控状态'}
            </div>
          </div>
          <Divider type="vertical" style={{ height: 20, margin: '0 4px', borderColor: '#e0e4ff' }} />
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
          <PermGuard code="technician:add">
            <Button
              type="primary"
              icon={<PlusOutlined />}
              onClick={() => setCreateOpen(true)}
              style={{
                borderRadius: 8, border: 'none',
                background: 'linear-gradient(135deg,#6366f1,#8b5cf6)',
                boxShadow: '0 2px 8px rgba(99,102,241,0.35)',
              }}
            >新增技师</Button>
          </PermGuard>
        </div>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', padding: '10px 24px 12px' }}>
          <Input
            size="middle"
            placeholder="搜索昵称 / 真实姓名 / 手机号"
            prefix={<SearchOutlined style={{ color: '#6366f1' }} />}
            allowClear
            value={keyword}
            onChange={e => setKeyword(e.target.value)}
            onPressEnter={handleSearch}
            style={{ ...INPUT_STYLE, width: 172 }}
          />
          <Input
            size="middle"
            placeholder="🔵 Telegram账号"
            prefix={<SendOutlined style={{ color: '#229ED9' }} />}
            allowClear
            value={telegram}
            onChange={e => setTelegram(e.target.value)}
            onPressEnter={handleSearch}
            style={{ ...INPUT_STYLE, width: 172 }}
          />
          <Select
            size="middle"
            placeholder={<Space size={4}><AuditOutlined style={{ color: '#6366f1', fontSize: 12 }} />审核状态</Space>}
            allowClear
            style={{ width: 115 }}
            value={auditStatus}
            onChange={setAuditStatus}
            options={[
              { value: 0, label: <Space size={4}><ClockCircleOutlined style={{ color: '#f59e0b' }} />待审核</Space> },
              { value: 1, label: <Space size={4}><CheckCircleOutlined style={{ color: '#10b981' }} />已通过</Space> },
              { value: 2, label: <Space size={4}><CloseCircleOutlined style={{ color: '#ef4444' }} />已拒绝</Space> },
            ]}
          />
          <Select
            size="middle"
            placeholder={<Space size={4}><WifiOutlined style={{ color: '#10b981', fontSize: 12 }} />在线状态</Space>}
            allowClear
            style={{ width: 115 }}
            value={onlineStatus}
            onChange={setOnlineStatus}
            options={[
              { value: 0, label: <Space size={4}><MinusCircleOutlined style={{ color: '#9ca3af' }} />离线</Space> },
              { value: 1, label: <Space size={4}><CheckCircleOutlined style={{ color: '#10b981' }} />在线</Space> },
              { value: 2, label: <Space size={4}><PlayCircleOutlined style={{ color: '#3b82f6' }} />服务中</Space> },
            ]}
          />
          <Select
            size="middle"
            placeholder={<Space size={4}><EnvironmentOutlined style={{ color: '#f59e0b', fontSize: 12 }} />所在城市</Space>}
            allowClear
            style={{ width: 115 }}
            value={serviceCity}
            onChange={setServiceCity}
            options={CITIES.map(c => ({ value: c, label: c }))}
          />
          <Select
            size="middle"
            placeholder={<Space size={4}><TeamOutlined style={{ color: '#ec4899', fontSize: 12 }} />性别</Space>}
            allowClear
            style={{ width: 90 }}
            value={gender}
            onChange={setGender}
            options={[
              { value: 1, label: <Space size={4}><ManOutlined style={{ color: '#3b82f6' }} />男</Space> },
              { value: 2, label: <Space size={4}><WomanOutlined style={{ color: '#ec4899' }} />女</Space> },
            ]}
          />
          <Select
            size="middle"
            placeholder={<Space size={4}><GlobalOutlined style={{ color: '#6366f1', fontSize: 12 }} />国籍</Space>}
            allowClear
            style={{ width: 90 }}
            value={nationality}
            onChange={setNationality}
            options={[
              { value: '中国',     label: <Space size={4}><span>🇨🇳</span>中国</Space> },
              { value: '柬埔寨',   label: <Space size={4}><span>🇰🇭</span>柬埔寨</Space> },
              { value: '越南',     label: <Space size={4}><span>🇻🇳</span>越南</Space> },
              { value: '泰国',     label: <Space size={4}><span>🇹🇭</span>泰国</Space> },
              { value: '马来西亚', label: <Space size={4}><span>🇲🇾</span>马来西亚</Space> },
              { value: '新加坡',   label: <Space size={4}><span>🇸🇬</span>新加坡</Space> },
              { value: '缅甸',     label: <Space size={4}><span>🇲🇲</span>缅甸</Space> },
              { value: '老挝',     label: <Space size={4}><span>🇱🇦</span>老挝</Space> },
              { value: '菲律宾',   label: <Space size={4}><span>🇵🇭</span>菲律宾</Space> },
              { value: '韩国',     label: <Space size={4}><span>🇰🇷</span>韩国</Space> },
              { value: '日本',     label: <Space size={4}><span>🇯🇵</span>日本</Space> },
            ]}
          />
          {isAdmin && (
            <Select
              size="middle"
              placeholder={<><ShopOutlined style={{ marginRight: 4 }} />所属商户</>}
              allowClear
              showSearch
              style={{ width: 172 }}
              value={merchantId}
              onChange={setMerchantId}
              filterOption={(input, opt) =>
                String(opt?.label ?? '').toLowerCase().includes(input.toLowerCase())
              }
              options={merchantOptions}
            />
          )}
          <Button icon={<ReloadOutlined />} size="middle" style={{ borderRadius: 8 }} onClick={handleReset}>重置</Button>
          <Tooltip title="刷新列表">
            <Button
              icon={<ReloadOutlined />}
              size="middle"
              loading={loading}
              style={{ borderRadius: 8, color: '#6366f1', borderColor: '#c7d2fe' }}
              onClick={() => fetchList()}
            />
          </Tooltip>
          <Button
            type="primary"
            icon={<SearchOutlined />}
            style={{
              borderRadius: 8, border: 'none',
              background: 'linear-gradient(135deg,#6366f1,#8b5cf6)',
              boxShadow: '0 2px 8px rgba(99,102,241,0.35)',
            }}
            onClick={handleSearch}
          >搜索</Button>
        </div>
      </div>

      <div style={{ marginLeft: -24, marginRight: -24, marginBottom: -24, background: '#fff', borderTop: '1px solid #eef0f8' }}>
        <Table
          rowKey="id"
          dataSource={data}
          columns={columns}
          loading={loading}
          size="middle"
          components={styledTableComponents}
          scroll={{ x: 'max-content', y: 'calc(100vh - 272px)' }}
          pagination={false}
          rowClassName={(_, idx) => idx % 2 === 0 ? '' : 'table-row-alt'}
        />
        <PagePagination
          total={total}
          current={page}
          pageSize={pageSize}
          onChange={p => setPage(p)}
          onSizeChange={s => { setPageSize(s); setPage(1) }}
          countLabel="名技师"
          pageSizeOptions={[10, 20, 50, 100, 200]}
        />
      </div>

      {/* 详情抽屉 */}
      <Drawer
        title={
          <Space>
            <Avatar src={detail?.avatar || undefined} size={36} icon={<UserOutlined />}
              style={{ background: 'linear-gradient(135deg,#6366f1,#8b5cf6)' }} />
            <div>
              <div style={{ fontWeight: 700 }}>{detail?.nickname || detail?.realName}</div>
              <div style={{ fontSize: 11, color: '#999', fontWeight: 400 }}>#{detail?.techNo}</div>
            </div>
          </Space>
        }
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        styles={{ wrapper: { width: 880 } }}
        extra={
          detail?.auditStatus === 0 ? (
            <Space>
              <Button danger size="small" icon={<CloseCircleOutlined />}
                onClick={() => { setDrawerOpen(false); setRejectTarget(detail); setRejectReason(''); setRejectOpen(true) }}>
                拒绝
              </Button>
              <Button type="primary" size="small" icon={<CheckCircleOutlined />}
                style={{ background: '#52c41a', borderColor: '#52c41a' }}
                onClick={() => { setDrawerOpen(false); handlePass(detail) }}>
                通过审核
              </Button>
            </Space>
          ) : null
        }
      >
        {detail && (
          <div>
            {/* 顶部身份卡片 */}
            {(() => {
              const drawerPhotos = parsePhotos(detail.photos)
              const drawerImg = detail.avatar || drawerPhotos[0]
              return (
                <div style={{
                  display: 'flex', gap: 20, padding: '20px 16px 24px',
                  background: 'linear-gradient(180deg,rgba(99,102,241,0.08),transparent)',
                  borderRadius: 12, marginBottom: 20, alignItems: 'flex-start',
                }}>
                  {/* 头像 */}
                  <div style={{ flexShrink: 0 }}>
                    {drawerImg ? (
                      <img
                        src={drawerImg}
                        alt="avatar"
                        style={{
                          width: 90, height: 110,
                          objectFit: 'cover',
                          borderRadius: 14,
                          border: '3px solid #fff',
                          boxShadow: '0 6px 24px rgba(99,102,241,0.30)',
                          display: 'block',
                        }}
                      />
                    ) : (
                      <div style={{
                        width: 90, height: 110, borderRadius: 14,
                        background: 'linear-gradient(135deg,#6366f1,#8b5cf6)',
                        border: '3px solid #fff',
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                        boxShadow: '0 6px 24px rgba(99,102,241,0.30)',
                      }}>
                        <UserOutlined style={{ color: '#fff', fontSize: 36 }} />
                      </div>
                    )}
                  </div>
                  {/* 基本信息 */}
                  <div style={{ flex: 1, paddingTop: 4 }}>
                    <div style={{ fontSize: 20, fontWeight: 800, marginBottom: 2 }}>
                      {detail.nickname || detail.realName}
                      {detail.gender === 2
                        ? <WomanOutlined style={{ color: '#ff85c2', marginLeft: 6, fontSize: 16 }} />
                        : <ManOutlined style={{ color: '#1677ff', marginLeft: 6, fontSize: 16 }} />}
                    </div>
                    <div style={{ color: '#888', fontSize: 13, marginBottom: 10 }}>
                      {detail.realName} · #{detail.techNo}
                    </div>
                    <Space wrap>
                      <span style={{
                        padding: '2px 12px', borderRadius: 20, fontSize: 12, fontWeight: 600,
                        background: AUDIT_MAP[detail.auditStatus]?.bg,
                        color: AUDIT_MAP[detail.auditStatus]?.color,
                      }}>{AUDIT_MAP[detail.auditStatus]?.text}</span>
                      <Badge
                        status={ONLINE_MAP[detail.onlineStatus ?? 0]?.color as any}
                        text={ONLINE_MAP[detail.onlineStatus ?? 0]?.text}
                      />
                    </Space>
                    {Number(detail.rating) > 0 && (
                      <div style={{ marginTop: 10 }}>
                        <Rate disabled defaultValue={Math.round(Number(detail.rating))} allowHalf style={{ fontSize: 14 }} />
                        <Text style={{ marginLeft: 8, fontWeight: 700, color: '#faad14', fontSize: 15 }}>
                          {Number(detail.rating).toFixed(1)}
                        </Text>
                      </div>
                    )}
                  </div>
                </div>
              )
            })()}

            {/* 相册 */}
            {parsePhotos(detail.photos).length > 0 && (
              <div style={{ marginBottom: 20 }}>
                <div style={{ fontWeight: 700, fontSize: 13, color: '#555', marginBottom: 8 }}>
                  <FireOutlined style={{ color: '#f97316', marginRight: 6 }} />相册
                </div>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
                  {parsePhotos(detail.photos).map((url, idx) => (
                    <a key={idx} href={url} target="_blank" rel="noreferrer">
                      <img
                        src={url}
                        alt={`photo-${idx}`}
                        style={{
                          width: 80, height: 100,
                          objectFit: 'cover',
                          borderRadius: 10,
                          border: '2px solid #f0f0f0',
                          boxShadow: '0 2px 8px rgba(0,0,0,0.10)',
                          transition: 'transform 0.2s',
                          cursor: 'pointer',
                          display: 'block',
                        }}
                        onMouseEnter={e => (e.currentTarget.style.transform = 'scale(1.06)')}
                        onMouseLeave={e => (e.currentTarget.style.transform = 'scale(1)')}
                      />
                    </a>
                  ))}
                </div>
              </div>
            )}

            {/* 数据统计 */}
            <Row gutter={12} style={{ marginBottom: 20 }}>
              {[
                { label: '接单数', value: detail.orderCount ?? 0, color: '#722ed1', icon: '📦' },
                { label: '评价数', value: detail.reviewCount ?? 0, color: '#1677ff', icon: '💬' },
                { label: '好评率', value: `${Number(detail.goodReviewRate ?? 0).toFixed(1)}%`, color: '#52c41a', icon: '👍' },
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

            {/* 详情信息 */}
            <Descriptions column={2} size="small" bordered labelStyle={{ background: '#fafafa', fontWeight: 600 }}>
              {isAdmin && (
                <Descriptions.Item label={<Space size={4}><ShopOutlined style={{ color: '#6366f1' }} /><span>所属商户</span></Space>} span={2}>
                  {detail.merchantName
                    ? <Tag color="purple" icon={<ShopOutlined />}>{detail.merchantName}</Tag>
                    : <Tag color="default">平台直营</Tag>}
                </Descriptions.Item>
              )}
              <Descriptions.Item label="手机号" span={2}>{detail.mobile}</Descriptions.Item>
              <Descriptions.Item label="国籍">
                {detail.nationality ? <Tag color="geekblue">{detail.nationality}</Tag> : '—'}
              </Descriptions.Item>
              <Descriptions.Item label="所在城市">
                {detail.serviceCity
                  ? <Tag icon={<EnvironmentOutlined />} color="blue">{detail.serviceCity}</Tag>
                  : '—'}
              </Descriptions.Item>
              <Descriptions.Item label="推荐技师">
                {detail.isFeatured === 1 ? <Tag color="gold"><CrownOutlined /> 是</Tag> : <Tag>否</Tag>}
              </Descriptions.Item>
              {detail.skillTags && (
                <Descriptions.Item label="技能标签" span={2}>
                  <Space wrap size={[4, 4]}>
                    {String(detail.skillTags).replace(/[\[\]"]/g, '').split(',').map((t: string) => (
                      <Tag key={t} color="purple">{t.trim()}</Tag>
                    ))}
                  </Space>
                </Descriptions.Item>
              )}
              {detail.rejectReason && (
                <Descriptions.Item label="拒绝原因" span={2}>
                  <Text type="danger">{detail.rejectReason}</Text>
                </Descriptions.Item>
              )}
            </Descriptions>
          </div>
        )}
      </Drawer>

      {/* 新增技师弹窗 */}
      <TechnicianCreateModal
        open={createOpen}
        onClose={() => setCreateOpen(false)}
        onSuccess={() => { setPage(1); fetchList(1) }}
        createFn={technicianCreate}
      />

      {/* 拒绝原因弹窗 */}
      <Modal
        title={<Space><CloseCircleOutlined style={{ color: '#ff4d4f' }} /><span>填写拒绝原因</span></Space>}
        open={rejectOpen}
        onOk={handleRejectSubmit}
        onCancel={() => setRejectOpen(false)}
        okText="确认拒绝"
        okButtonProps={{ danger: true, loading: actionLoading }}
        cancelText="取消"
      >
        <div style={{ marginBottom: 12, padding: '10px 14px', background: '#fff7e6', borderRadius: 8 }}>
          <Text>技师：<strong>{rejectTarget?.realName}</strong>（{rejectTarget?.mobile}）</Text>
        </div>
        <Input.TextArea
          placeholder="请填写拒绝原因，将通过短信告知技师（必填）"
          rows={4}
          value={rejectReason}
          onChange={e => setRejectReason(e.target.value)}
          style={{ borderRadius: 8 }}
        />
      </Modal>
    </div>
  )
}
