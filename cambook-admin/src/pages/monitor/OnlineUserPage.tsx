import { useEffect, useState, useCallback, useMemo } from 'react'
import {
  Table, Button, Space, Tag, Input, Badge, Popconfirm, message, Tooltip,
} from 'antd'
import {
  TeamOutlined, ReloadOutlined, SearchOutlined, UserOutlined, GlobalOutlined, StopOutlined,
  ClockCircleOutlined, ChromeOutlined, NumberOutlined, ApartmentOutlined, AppstoreOutlined,
  LaptopOutlined, SafetyCertificateOutlined, CalendarOutlined, SettingOutlined,
} from '@ant-design/icons'
import request from '../../api/request'
import PermGuard from '../../components/common/PermGuard'
import { col, styledTableComponents, INPUT_STYLE } from '../../components/common/tableComponents'
import PagePagination from '../../components/common/PagePagination'
import { useTableBodyHeight } from '../../hooks/useTableBodyHeight'

const PAGE_GRADIENT = 'linear-gradient(135deg,#10b981,#059669)'

interface OnlineUser {
  sessionId: string
  userId: number
  username: string
  realName?: string
  deptName?: string
  ipAddr?: string
  loginLocation?: string
  browser?: string
  os?: string
  status: string
  loginTime: number
  lastAccessTime: number
}

function formatDuration(ms: number): string {
  const sec = Math.floor((Date.now() - ms) / 1000)
  if (sec < 60) return `${sec}秒前`
  if (sec < 3600) return `${Math.floor(sec / 60)}分钟前`
  if (sec < 86400) return `${Math.floor(sec / 3600)}小时前`
  return `${Math.floor(sec / 86400)}天前`
}

function formatTime(ms: number): string {
  return new Date(ms).toLocaleString('zh-CN', { hour12: false })
}

const BROWSER_COLORS: Record<string, string> = {
  Chrome: '#4285F4', Firefox: '#FF7139', Safari: '#000', Edge: '#0078D4', IE: '#1EBBEE',
}

export default function OnlineUserPage() {
  const { ref, height: tableBodyH } = useTableBodyHeight()
  const [users, setUsers] = useState<OnlineUser[]>([])
  const [loading, setLoading] = useState(false)
  const [searchName, setSearchName] = useState('')
  const [page, setPage] = useState(1)
  const [pageSize, setPageSize] = useState(20)

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const res = await request.get('/admin/monitor/online/list', { params: { username: searchName || undefined } })
      setUsers(res.data?.data ?? [])
    } finally {
      setLoading(false)
    }
  }, [searchName])

  useEffect(() => { load() }, [load])

  // Auto-refresh every 30s
  useEffect(() => {
    const timer = setInterval(load, 30000)
    return () => clearInterval(timer)
  }, [load])

  const forceLogout = async (sessionId: string, username: string) => {
    await request.delete(`/admin/monitor/online/${sessionId}`)
    message.success(`已强制退出用户 ${username}`)
    load()
  }

  const onlineCount = users.filter(u => u.status === 'online').length

  const pagedUsers = useMemo(() => {
    const start = (page - 1) * pageSize
    return users.slice(start, start + pageSize)
  }, [users, page, pageSize])

  useEffect(() => {
    const max = Math.max(1, Math.ceil(users.length / pageSize) || 1)
    if (page > max) setPage(max)
  }, [users.length, pageSize, page])

  const handleSearch = () => {
    setPage(1)
    load()
  }

  const handleReset = () => {
    setSearchName('')
    setPage(1)
  }

  const columns = [
    {
      title: col(<NumberOutlined style={{ color: '#10b981' }} />, '序号'), key: 'index', align: 'center' as const,
      render: (_: any, __: any, i: number) => (
        <span style={{
          display: 'inline-block', height: 24, lineHeight: '24px', textAlign: 'center',
          borderRadius: '50%', background: 'linear-gradient(135deg,#4facfe,#00f2fe)', color: '#fff', fontSize: 12,
        }}>{(page - 1) * pageSize + i + 1}</span>
      ),
    },
    {
      title: col(<UserOutlined style={{ color: '#10b981' }} />, '账号'), key: 'username',
      render: (_: any, r: OnlineUser) => (
        <Space>
          <div style={{
            width: 36, height: 36, borderRadius: '50%',
            background: `linear-gradient(135deg,hsl(${(r.userId || 0) * 47 % 360},70%,60%),hsl(${(r.userId || 0) * 73 % 360},60%,50%))`,
            display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', fontSize: 14, fontWeight: 700,
          }}>{(r.realName || r.username || '?')[0]}</div>
          <div>
            <div style={{ fontWeight: 600 }}>{r.realName || r.username}</div>
            <div style={{ fontSize: 12, color: '#999' }}><UserOutlined /> {r.username}</div>
          </div>
        </Space>
      ),
    },
    {
      title: col(<ApartmentOutlined style={{ color: '#10b981' }} />, '部门'), dataIndex: 'deptName', key: 'deptName',
      render: (v: string) => v
        ? <Tag color="blue" style={{ borderRadius: 6 }}>{v}</Tag>
        : <span style={{ color: '#94a3b8' }}>-</span>,
    },
    {
      title: col(<GlobalOutlined style={{ color: '#10b981' }} />, '主机'), dataIndex: 'ipAddr', key: 'ipAddr',
      render: (v: string) => (
        <Space>
          <GlobalOutlined style={{ color: '#52c41a' }} />
          <code style={{ fontSize: 12 }}>{v || '127.0.0.1'}</code>
        </Space>
      ),
    },
    {
      title: col(<AppstoreOutlined style={{ color: '#10b981' }} />, '浏览器'), dataIndex: 'browser', key: 'browser',
      render: (v: string) => (
        <Space>
          <ChromeOutlined style={{ color: BROWSER_COLORS[v] || '#666' }} />
          <span>{v || 'Unknown'}</span>
        </Space>
      ),
    },
    {
      title: col(<LaptopOutlined style={{ color: '#10b981' }} />, '操作系统'), dataIndex: 'os', key: 'os',
      render: (v: string) => <Space><LaptopOutlined style={{ color: '#722ed1' }} /><span>{v || '-'}</span></Space>,
    },
    {
      title: col(<SafetyCertificateOutlined style={{ color: '#10b981' }} />, '状态'), dataIndex: 'status', key: 'status',
      render: (v: string) => v === 'online'
        ? <Badge status="processing" text={<span style={{ color: '#52c41a', fontWeight: 600 }}>在线</span>} />
        : <Badge status="default" text={<span style={{ color: '#999' }}>超时</span>} />,
    },
    {
      title: col(<ClockCircleOutlined style={{ color: '#10b981' }} />, '登录时间'), dataIndex: 'loginTime', key: 'loginTime',
      render: (v: number) => (
        <div>
          <div style={{ fontSize: 13 }}>{formatTime(v)}</div>
          <div style={{ fontSize: 11, color: '#999' }}><ClockCircleOutlined /> {formatDuration(v)}</div>
        </div>
      ),
    },
    {
      title: col(<CalendarOutlined style={{ color: '#10b981' }} />, '最后访问'), dataIndex: 'lastAccessTime', key: 'lastAccessTime',
      render: (v: number) => (
        <div>
          <div style={{ fontSize: 13 }}>{formatTime(v)}</div>
          <div style={{ fontSize: 11, color: '#52c41a' }}>{formatDuration(v)}</div>
        </div>
      ),
    },
    {
      title: col(<SettingOutlined style={{ color: '#10b981' }} />, '操作'), key: 'action', width: 100,
      render: (_: any, r: OnlineUser) => (
        <PermGuard code="monitor:online:kick">
          <Popconfirm
            title={`确认强制退出 ${r.username}？`}
            okText="强制退出" cancelText="取消"
            okButtonProps={{ danger: true }}
            onConfirm={() => forceLogout(r.sessionId, r.username)}
          >
            <Button size="small" danger icon={<StopOutlined />} style={{ borderRadius: 6, fontWeight: 600 }}>强退</Button>
          </Popconfirm>
        </PermGuard>
      ),
    },
  ]

  return (
    <div style={{ marginTop: -24 }}>
      <div style={{ position: 'sticky', top: 64, zIndex: 88, marginLeft: -24, marginRight: -24, background: 'rgba(255,255,255,0.97)', backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)', borderBottom: '1px solid rgba(0,0,0,0.07)', boxShadow: '0 4px 20px rgba(0,0,0,0.06)' }}>
        <div style={{ display: 'flex', alignItems: 'center', padding: '10px 24px 0', gap: 12 }}>
          <div style={{ width: 34, height: 34, borderRadius: 10, background: PAGE_GRADIENT, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 4px 12px rgba(16,185,129,0.3)', flexShrink: 0 }}>
            <TeamOutlined style={{ color: '#fff', fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1e293b', lineHeight: 1.2 }}>在线用户</div>
            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>实时监控在线会话 · 强制下线</div>
          </div>
          <div style={{ width: 1, height: 20, margin: '0 4px', background: '#e0e4ff', flexShrink: 0 }} />
          <div style={{ display: 'flex', gap: 8 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: 'rgba(16,185,129,0.1)', border: '1px solid rgba(16,185,129,0.25)' }}>
              <span>📊</span>
              <span style={{ fontSize: 12, color: '#6b7280' }}>在线总数</span>
              <span style={{ fontSize: 13, fontWeight: 700, color: '#059669' }}>{onlineCount}</span>
            </div>
          </div>
          <div style={{ flex: 1 }} />
          <Tooltip title="刷新列表（每30秒自动刷新）"><Button icon={<ReloadOutlined />} loading={loading} style={{ borderRadius: 8, color: '#10b981', borderColor: '#a7f3d0' }} onClick={load} /></Tooltip>
        </div>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', padding: '10px 24px 12px' }}>
          <Input
            placeholder="登录账号"
            prefix={<UserOutlined style={{ color: '#10b981', fontSize: 12 }} />}
            value={searchName}
            onChange={e => setSearchName(e.target.value)}
            allowClear
            size="middle"
            style={{ width: 180, ...INPUT_STYLE }}
            onPressEnter={handleSearch}
          />
          <div style={{ flex: 1 }} />
          <Button icon={<ReloadOutlined />} size="middle" style={{ borderRadius: 8 }} onClick={handleReset}>重置</Button>
          <Button type="primary" icon={<SearchOutlined />} style={{ borderRadius: 8, border: 'none', background: PAGE_GRADIENT }} onClick={handleSearch}>搜索</Button>
        </div>
      </div>
      <div ref={ref} style={{ marginLeft: -24, marginRight: -24, marginBottom: -24, background: '#fff', borderTop: '1px solid #eef0f8' }}>
        <Table
          columns={columns}
          dataSource={pagedUsers}
          rowKey="sessionId"
          loading={loading}
          pagination={false}
          components={styledTableComponents}
          scroll={{ x: 'max-content', y: tableBodyH }}
          size="middle"
        />
        <PagePagination
          total={users.length}
          current={page}
          pageSize={pageSize}
          onChange={setPage}
          onSizeChange={setPageSize}
          countLabel="条记录"
        />
      </div>
    </div>
  )
}
