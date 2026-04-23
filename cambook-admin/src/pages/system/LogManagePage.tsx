import { useEffect, useState, useCallback, useRef } from 'react'
import {
  Table, Button, Space, Tag, Input, Select, message,
  Popconfirm, Badge, Drawer, Tooltip, Typography,
} from 'antd'
import {
  FileTextOutlined, DeleteOutlined, ReloadOutlined, SearchOutlined,
  CheckCircleOutlined, CloseCircleOutlined, EyeOutlined, UserOutlined,
  LinkOutlined, ClearOutlined,
  AppstoreOutlined, ApiOutlined, GlobalOutlined,
  SafetyCertificateOutlined, CalendarOutlined, SettingOutlined,
} from '@ant-design/icons'
import { operLogApi } from '../../api/api'
import PermGuard from '../../components/common/PermGuard'
import { col, styledTableComponents, INPUT_STYLE } from '../../components/common/tableComponents'
import PagePagination from '../../components/common/PagePagination'
import { useTableBodyHeight } from '../../hooks/useTableBodyHeight'
import { fmtTime, fmtDate } from '../../utils/time'

const { Text } = Typography

const PAGE_GRADIENT = 'linear-gradient(135deg,#6b7280,#9ca3af)'

interface OperLog {
  id: number
  title: string
  method: string
  requestUrl: string
  requestMethod: string
  operName?: string
  operIp?: string
  operParam?: string
  jsonResult?: string
  status: number
  errorMsg?: string
  operTime?: string
}

const METHOD_COLORS: Record<string, string> = {
  GET: 'blue', POST: 'green', PUT: 'orange', DELETE: 'red', PATCH: 'purple',
}

export default function LogManagePage() {
  const { ref, height: tableBodyH } = useTableBodyHeight()
  const [logs, setLogs] = useState<OperLog[]>([])
  const [loading, setLoading] = useState(false)
  const [current, setCurrent] = useState(1)
  const [pageSize, setPageSize] = useState(20)
  const pageSizeRef = useRef(pageSize)
  pageSizeRef.current = pageSize
  const [total, setTotal] = useState(0)
  const [searchTitle, setSearchTitle] = useState('')
  const [searchOperName, setSearchOperName] = useState('')
  const [searchMethod, setSearchMethod] = useState('')
  const [searchStatus, setSearchStatus] = useState<number | undefined>()
  const [viewDrawer, setViewDrawer] = useState(false)
  const [viewing, setViewing] = useState<OperLog | null>(null)

  const load = useCallback(async (page: number) => {
    setLoading(true)
    try {
      const res = await operLogApi.list({
        current: page, size: pageSizeRef.current,
        title: searchTitle || undefined, operName: searchOperName || undefined,
        requestMethod: searchMethod || undefined, status: searchStatus,
      })
      const d = res.data?.data
      setLogs(d?.list ?? [])
      setTotal(d?.total ?? 0)
    } finally {
      setLoading(false)
    }
  }, [searchTitle, searchOperName, searchMethod, searchStatus])

  useEffect(() => { load(current) }, [current, pageSize, load])

  const handleDelete = async (id: number) => {
    await operLogApi.delete(id)
    message.success('删除成功')
    load(current)
  }

  const handleClean = async () => {
    await operLogApi.clean()
    message.success('日志已清空')
    load(current)
  }

  const successCount = logs.filter(l => l.status === 0).length
  const failCount = logs.filter(l => l.status === 1).length

  const handleSearch = () => {
    if (current === 1) load(1)
    else setCurrent(1)
  }

  const handleReset = () => {
    setSearchTitle('')
    setSearchOperName('')
    setSearchMethod('')
    setSearchStatus(undefined)
    setCurrent(1)
  }

  const columns = [
    {
      title: col(<AppstoreOutlined style={{ color: '#6366f1' }} />, '模块'), dataIndex: 'title', key: 'title',
      render: (v: string, r: OperLog) => (
        <Space>
          <div style={{
            width: 30, height: 30, borderRadius: 8,
            background: r.status === 0 ? 'linear-gradient(135deg,#43e97b,#38f9d7)' : 'linear-gradient(135deg,#f093fb,#f5576c)',
            display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', fontSize: 13,
          }}>
            {r.status === 0 ? <CheckCircleOutlined /> : <CloseCircleOutlined />}
          </div>
          <Text strong>{v}</Text>
        </Space>
      ),
    },
    {
      title: col(<ApiOutlined style={{ color: '#6366f1' }} />, '请求方式'), dataIndex: 'requestMethod', key: 'requestMethod',
      render: (v: string) => <Tag color={METHOD_COLORS[v] || 'default'} style={{ borderRadius: 6, fontWeight: 700 }}>{v}</Tag>,
    },
    {
      title: col(<LinkOutlined style={{ color: '#6366f1' }} />, 'URL'), dataIndex: 'requestUrl', key: 'requestUrl',
      render: (v: string) => <code style={{ background: '#f0f5ff', padding: '2px 8px', borderRadius: 4, color: '#1890ff', fontSize: 12 }}>{v}</code>,
    },
    {
      title: col(<UserOutlined style={{ color: '#6366f1' }} />, '操作人'), dataIndex: 'operName', key: 'operName',
      render: (v: string) => v ? <Space><UserOutlined style={{ color: '#1890ff' }} /><span>{v}</span></Space> : '-',
    },
    {
      title: col(<GlobalOutlined style={{ color: '#6366f1' }} />, 'IP'), dataIndex: 'operIp', key: 'operIp',
      render: (v: string) => <span style={{ fontFamily: 'monospace', fontSize: 12, color: '#666' }}>{v || '-'}</span>,
    },
    {
      title: col(<SafetyCertificateOutlined style={{ color: '#6366f1' }} />, '状态'), dataIndex: 'status', key: 'status',
      render: (v: number) => v === 0
        ? <Badge status="success" text={<span style={{ color: '#52c41a', fontWeight: 600 }}>成功</span>} />
        : <Badge status="error" text={<span style={{ color: '#ff4d4f', fontWeight: 600 }}>失败</span>} />,
    },
    {
      title: col(<CalendarOutlined style={{ color: '#6366f1' }} />, '时间'), dataIndex: 'operTime', key: 'operTime',
      render: (v: string | number) => <span style={{ color: '#666', fontSize: 12 }}>{v != null && v !== '' ? fmtTime(v) : '-'}</span>,
    },
    {
      title: col(<SettingOutlined style={{ color: '#6366f1' }} />, '操作'), key: 'action', width: 145,
      render: (_: any, r: OperLog) => (
        <Space size={4}>
          <Button size="small" type="primary" ghost icon={<EyeOutlined />}
            style={{ borderRadius: 6 }}
            onClick={() => { setViewing(r); setViewDrawer(true) }}>查看</Button>
          <PermGuard code="log:delete">
            <Popconfirm title="确认删除该日志？" onConfirm={() => handleDelete(r.id)} okButtonProps={{ danger: true }} okText="删除" cancelText="取消">
              <Button size="small" danger icon={<DeleteOutlined />} style={{ borderRadius: 6 }}>删除</Button>
            </Popconfirm>
          </PermGuard>
        </Space>
      ),
    },
  ]

  return (
    <div style={{ marginTop: -24 }}>
      <div style={{ position: 'sticky', top: 64, zIndex: 88, marginLeft: -24, marginRight: -24, background: 'rgba(255,255,255,0.97)', backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)', borderBottom: '1px solid rgba(0,0,0,0.07)', boxShadow: '0 4px 20px rgba(0,0,0,0.06)' }}>
        <div style={{ display: 'flex', alignItems: 'center', padding: '10px 24px 0', gap: 12 }}>
          <div style={{ width: 34, height: 34, borderRadius: 10, background: PAGE_GRADIENT, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 4px 12px rgba(107,114,128,0.35)', flexShrink: 0 }}>
            <FileTextOutlined style={{ color: '#fff', fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1e293b', lineHeight: 1.2 }}>操作日志</div>
            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>记录系统操作行为 · 审计追踪</div>
          </div>
          <div style={{ width: 1, height: 20, margin: '0 4px', background: '#e0e4ff', flexShrink: 0 }} />
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: 'rgba(99,102,241,0.1)', border: '1px solid rgba(99,102,241,0.25)' }}>
              <span>📋</span><span style={{ fontSize: 12, color: '#6b7280' }}>总数</span><span style={{ fontSize: 13, fontWeight: 700, color: '#6366f1' }}>{total}</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: 'rgba(34,197,94,0.1)', border: '1px solid rgba(34,197,94,0.25)' }}>
              <span>✓</span><span style={{ fontSize: 12, color: '#6b7280' }}>成功</span><span style={{ fontSize: 13, fontWeight: 700, color: '#16a34a' }}>{successCount}</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: 'rgba(239,68,68,0.08)', border: '1px solid rgba(239,68,68,0.22)' }}>
              <span>✕</span><span style={{ fontSize: 12, color: '#6b7280' }}>失败</span><span style={{ fontSize: 13, fontWeight: 700, color: '#ef4444' }}>{failCount}</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: 'rgba(59,130,246,0.1)', border: '1px solid rgba(59,130,246,0.25)' }}>
              <span>📅</span><span style={{ fontSize: 12, color: '#6b7280' }}>今日</span><span style={{ fontSize: 13, fontWeight: 700, color: '#2563eb' }}>{logs.filter(l => l.operTime != null && l.operTime !== '' && fmtDate(l.operTime) === fmtDate(Math.floor(Date.now() / 1000))).length}</span>
            </div>
          </div>
          <div style={{ flex: 1 }} />
          <Popconfirm title="确认清空所有操作日志？此操作不可恢复！" onConfirm={handleClean} okButtonProps={{ danger: true }}>
            <Button danger icon={<ClearOutlined />} size="middle" style={{ borderRadius: 8 }}>清空日志</Button>
          </Popconfirm>
        </div>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', padding: '10px 24px 12px' }}>
          <Input placeholder="操作模块" prefix={<AppstoreOutlined style={{ color: '#6366f1', fontSize: 12 }} />} value={searchTitle} onChange={e => setSearchTitle(e.target.value)} allowClear size="middle" style={{ width: 160, ...INPUT_STYLE }} />
          <Input placeholder="操作人员" prefix={<UserOutlined style={{ color: '#3b82f6', fontSize: 12 }} />} value={searchOperName} onChange={e => setSearchOperName(e.target.value)} allowClear size="middle" style={{ width: 130, ...INPUT_STYLE }} />
          <Select placeholder={<Space size={4}><ApiOutlined style={{ color: '#6b7280', fontSize: 12 }} />请求方式</Space>} allowClear style={{ width: 115 }} value={searchMethod || undefined} onChange={v => setSearchMethod(v ?? '')}>
            {['GET', 'POST', 'PUT', 'DELETE', 'PATCH'].map(m => <Select.Option key={m} value={m}><Tag color={METHOD_COLORS[m]}>{m}</Tag></Select.Option>)}
          </Select>
          <Select placeholder={<Space size={4}><CheckCircleOutlined style={{ color: '#10b981', fontSize: 12 }} />操作状态</Space>} allowClear style={{ width: 115 }} value={searchStatus} onChange={v => setSearchStatus(v)}>
            <Select.Option value={0}><Badge status="success" text="成功" /></Select.Option>
            <Select.Option value={1}><Badge status="error" text="失败" /></Select.Option>
          </Select>
          <div style={{ flex: 1 }} />
          <Button icon={<ReloadOutlined />} size="middle" style={{ borderRadius: 8 }} onClick={handleReset}>重置</Button>
          <Tooltip title="刷新"><Button icon={<ReloadOutlined />} size="middle" loading={loading} style={{ borderRadius: 8, color: '#6366f1', borderColor: '#c7d2fe' }} onClick={() => load(current)} /></Tooltip>
          <Button type="primary" icon={<SearchOutlined />} style={{ borderRadius: 8, border: 'none', background: 'linear-gradient(135deg,#6366f1,#8b5cf6)' }} onClick={handleSearch}>搜索</Button>
        </div>
      </div>
      <div ref={ref} style={{ marginLeft: -24, marginRight: -24, marginBottom: -24, background: '#fff', borderTop: '1px solid #eef0f8' }}>
        <Table columns={columns} dataSource={logs} rowKey="id" loading={loading} pagination={false} components={styledTableComponents} scroll={{ x: 'max-content', y: tableBodyH }} size="small" />
        <PagePagination
          total={total}
          current={current}
          pageSize={pageSize}
          onChange={p => setCurrent(p)}
          onSizeChange={s => { setPageSize(s); pageSizeRef.current = s; }}
          countLabel="条日志"
          pageSizeOptions={[10, 20, 50, 100]}
        />
      </div>

      <Drawer open={viewDrawer} onClose={() => setViewDrawer(false)} styles={{ wrapper: { width: 600 } }}
        title={
          <Space>
            <div style={{ width: 32, height: 32, borderRadius: 8, background: 'linear-gradient(135deg,#2c3e50,#4ca1af)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff' }}>
              <FileTextOutlined />
            </div>
            <span>日志详情</span>
          </Space>
        }>
        {viewing && (
          <div>
            <div style={{ borderRadius: 12, background: '#f5f7fa', marginBottom: 16, border: 'none', padding: 12 }}>
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: 12 }}>
                <div style={{ minWidth: 120 }}><div style={{ color: '#999', fontSize: 12 }}>操作模块</div><div style={{ fontWeight: 600 }}>{viewing.title}</div></div>
                <div style={{ minWidth: 120 }}><div style={{ color: '#999', fontSize: 12 }}>操作人员</div><div style={{ fontWeight: 600 }}>{viewing.operName || '-'}</div></div>
                <div style={{ minWidth: 120 }}><div style={{ color: '#999', fontSize: 12 }}>操作IP</div><div style={{ fontFamily: 'monospace' }}>{viewing.operIp || '-'}</div></div>
              </div>
            </div>
            <div style={{ borderRadius: 12, background: '#f5f7fa', marginBottom: 16, border: 'none', padding: 12 }}>
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: 12 }}>
                <div style={{ minWidth: 120 }}><div style={{ color: '#999', fontSize: 12 }}>请求方式</div><Tag color={METHOD_COLORS[viewing.requestMethod]}>{viewing.requestMethod}</Tag></div>
                <div style={{ minWidth: 120 }}><div style={{ color: '#999', fontSize: 12 }}>操作状态</div>{viewing.status === 0 ? <Badge status="success" text="成功" /> : <Badge status="error" text="失败" />}</div>
                <div style={{ minWidth: 120 }}><div style={{ color: '#999', fontSize: 12 }}>操作时间</div><div style={{ fontSize: 12 }}>{viewing.operTime != null && viewing.operTime !== '' ? fmtTime(viewing.operTime) : '—'}</div></div>
              </div>
            </div>
            <div style={{ marginBottom: 12 }}>
              <div style={{ color: '#999', fontSize: 12, marginBottom: 4 }}><LinkOutlined /> 请求URL</div>
              <code style={{ display: 'block', background: '#1a1a2e', color: '#4facfe', padding: 12, borderRadius: 8, fontSize: 13, wordBreak: 'break-all' }}>{viewing.requestUrl}</code>
            </div>
            <div style={{ marginBottom: 12 }}>
              <div style={{ color: '#999', fontSize: 12, marginBottom: 4 }}>方法名称</div>
              <code style={{ display: 'block', background: '#1a1a2e', color: '#43e97b', padding: 12, borderRadius: 8, fontSize: 12, wordBreak: 'break-all' }}>{viewing.method}</code>
            </div>
            {viewing.operParam && (
              <div style={{ marginBottom: 12 }}>
                <div style={{ color: '#999', fontSize: 12, marginBottom: 4 }}>请求参数</div>
                <pre style={{ background: '#1a1a2e', color: '#ffd93d', padding: 12, borderRadius: 8, fontSize: 12, overflow: 'auto', maxHeight: 160, margin: 0 }}>{viewing.operParam}</pre>
              </div>
            )}
            {viewing.jsonResult && (
              <div style={{ marginBottom: 12 }}>
                <div style={{ color: '#999', fontSize: 12, marginBottom: 4 }}>返回结果</div>
                <pre style={{ background: '#1a1a2e', color: '#f093fb', padding: 12, borderRadius: 8, fontSize: 12, overflow: 'auto', maxHeight: 160, margin: 0 }}>{viewing.jsonResult}</pre>
              </div>
            )}
            {viewing.errorMsg && (
              <div>
                <div style={{ color: '#ff4d4f', fontSize: 12, marginBottom: 4 }}>错误信息</div>
                <div style={{ background: '#fff1f0', border: '1px solid #ffccc7', color: '#ff4d4f', padding: 12, borderRadius: 8, fontSize: 12 }}>{viewing.errorMsg}</div>
              </div>
            )}
          </div>
        )}
      </Drawer>
    </div>
  )
}
