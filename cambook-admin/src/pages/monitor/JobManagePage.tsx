import { useEffect, useState, useCallback, useMemo } from 'react'
import {
  Table, Button, Space, Tag, Input, Select, Badge, Tooltip, message, Divider,
} from 'antd'
import {
  ClockCircleOutlined, ReloadOutlined, SearchOutlined,
  PlayCircleOutlined, PauseCircleOutlined, CaretRightOutlined,
  FileTextOutlined, TagOutlined, CodeOutlined, SafetyCertificateOutlined,
  CalendarOutlined, SettingOutlined,
} from '@ant-design/icons'
import request from '../../api/request'
import PermGuard from '../../components/common/PermGuard'
import { col, styledTableComponents, INPUT_STYLE } from '../../components/common/tableComponents'
import PagePagination from '../../components/common/PagePagination'

const PAGE_GRADIENT = 'linear-gradient(135deg,#7c3aed,#a78bfa)'

interface Job {
  id: number
  jobName: string
  jobGroup: string
  invokeTarget: string
  cronExpression: string
  status: string
  lastResult: string
  remark?: string
  createTime?: string
  nextFireTime?: string
}

const GROUP_COLORS: Record<string, string> = {
  SYSTEM: 'blue', BUSINESS: 'green', FINANCE: 'gold', REPORT: 'purple',
}

export default function JobManagePage() {
  const [jobs, setJobs] = useState<Job[]>([])
  const [loading, setLoading] = useState(false)
  const [searchName, setSearchName] = useState('')
  const [searchGroup, setSearchGroup] = useState('')
  const [searchStatus, setSearchStatus] = useState('')
  const [page, setPage] = useState(1)
  const [pageSize, setPageSize] = useState(20)

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const res = await request.get('/admin/monitor/job/list', { params: {
        jobName: searchName || undefined,
        jobGroup: searchGroup || undefined,
        status: searchStatus || undefined,
      }})
      setJobs(res.data?.data ?? [])
    } finally {
      setLoading(false)
    }
  }, [searchName, searchGroup, searchStatus])

  useEffect(() => { load() }, [load])

  const toggleStatus = async (job: Job) => {
    const newStatus = job.status === '正常' ? '暂停' : '正常'
    await request.patch(`/admin/monitor/job/${job.id}/status`, null, { params: { status: newStatus } })
    message.success(`任务已${newStatus === '正常' ? '恢复' : '暂停'}`)
    load()
  }

  const runOnce = async (job: Job) => {
    const res = await request.post(`/admin/monitor/job/${job.id}/run`)
    message.success(res.data?.data || '任务已触发')
  }

  const running = jobs.filter(j => j.status === '正常').length

  const pagedJobs = useMemo(() => {
    const start = (page - 1) * pageSize
    return jobs.slice(start, start + pageSize)
  }, [jobs, page, pageSize])

  useEffect(() => {
    const max = Math.max(1, Math.ceil(jobs.length / pageSize) || 1)
    if (page > max) setPage(max)
  }, [jobs.length, pageSize, page])

  const handleSearch = () => {
    setPage(1)
    load()
  }

  const handleReset = () => {
    setSearchName('')
    setSearchGroup('')
    setSearchStatus('')
    setPage(1)
  }

  const columns = [
    {
      title: col(<FileTextOutlined style={{ color: '#7c3aed' }} />, '任务名'), key: 'jobName',
      render: (_: any, r: Job) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, width: '100%' }}>
          <div style={{
            width: 32, height: 32, borderRadius: 8, flexShrink: 0,
            background: r.status === '正常' ? 'linear-gradient(135deg,#43e97b,#38f9d7)' : 'linear-gradient(135deg,#e0e0e0,#bbb)',
            display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', fontSize: 14,
          }}>
            {r.status === '正常' ? <PlayCircleOutlined /> : <PauseCircleOutlined />}
          </div>
          <div>
            <div style={{ fontWeight: 600 }}>{r.jobName}</div>
            <div style={{ fontSize: 12, color: '#999' }}>{r.remark}</div>
          </div>
        </div>
      ),
    },
    {
      title: col(<TagOutlined style={{ color: '#7c3aed' }} />, '组名'), dataIndex: 'jobGroup', key: 'jobGroup',
      render: (v: string) => <Tag color={GROUP_COLORS[v] || 'default'} style={{ borderRadius: 6 }}>{v}</Tag>,
    },
    {
      title: col(<CodeOutlined style={{ color: '#7c3aed' }} />, '调用目标'), dataIndex: 'invokeTarget', key: 'invokeTarget',
      render: (v: string) => <code style={{ background: '#f0f5ff', padding: '1px 8px', borderRadius: 4, color: '#1890ff', fontSize: 12 }}>{v}</code>,
    },
    {
      title: col(<ClockCircleOutlined style={{ color: '#7c3aed' }} />, 'Cron'), dataIndex: 'cronExpression', key: 'cronExpression',
      render: (v: string) => <Tag color="purple" style={{ borderRadius: 6, fontFamily: 'monospace', fontSize: 12 }}>{v}</Tag>,
    },
    {
      title: col(<SafetyCertificateOutlined style={{ color: '#7c3aed' }} />, '状态'), dataIndex: 'status', key: 'status',
      render: (v: string) => v === '正常'
        ? <Badge status="processing" text={<span style={{ color: '#52c41a', fontWeight: 600 }}>正常</span>} />
        : <Badge status="default" text={<span style={{ color: '#999' }}>暂停</span>} />,
    },
    {
      title: col(<CalendarOutlined style={{ color: '#7c3aed' }} />, '下次执行'), dataIndex: 'nextFireTime', key: 'nextFireTime',
      render: (v: string) => <span style={{ fontSize: 12, color: '#666' }}>{v || '-'}</span>,
    },
    {
      title: col(<SettingOutlined style={{ color: '#7c3aed' }} />, '操作'), key: 'action', width: 145,
      render: (_: any, r: Job) => (
        <Space size={4}>
          <PermGuard code="monitor:job:run">
            <Tooltip title="立即执行一次">
              <Button size="small" type="primary" icon={<CaretRightOutlined />} onClick={() => runOnce(r)} style={{ borderRadius: 6, background: '#52c41a', borderColor: '#52c41a' }}>执行</Button>
            </Tooltip>
          </PermGuard>
          <PermGuard code="monitor:job:toggle">
            <Tooltip title={r.status === '正常' ? '暂停任务' : '恢复任务'}>
              <Button size="small" icon={r.status === '正常' ? <PauseCircleOutlined /> : <PlayCircleOutlined />}
                onClick={() => toggleStatus(r)}
                style={{ borderRadius: 6, color: r.status === '正常' ? '#faad14' : '#1890ff', borderColor: r.status === '正常' ? '#faad14' : '#1890ff' }}>
                {r.status === '正常' ? '暂停' : '恢复'}
              </Button>
            </Tooltip>
          </PermGuard>
        </Space>
      ),
    },
  ]

  return (
    <div style={{ marginTop: -24 }}>
      <div style={{ position: 'sticky', top: 64, zIndex: 88, marginLeft: -24, marginRight: -24, background: 'rgba(255,255,255,0.97)', backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)', borderBottom: '1px solid rgba(0,0,0,0.07)', boxShadow: '0 4px 20px rgba(0,0,0,0.06)' }}>
        <div style={{ display: 'flex', alignItems: 'center', padding: '10px 24px 0', gap: 12 }}>
          <div style={{ width: 34, height: 34, borderRadius: 10, background: PAGE_GRADIENT, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 4px 12px rgba(124,58,237,0.3)', flexShrink: 0 }}>
            <ClockCircleOutlined style={{ color: '#fff', fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1e293b', lineHeight: 1.2 }}>定时任务</div>
            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>管理系统定时调度任务 · 执行监控</div>
          </div>
          <Divider type="vertical" style={{ height: 20, margin: '0 4px', borderColor: '#e0e4ff' }} />
          <div style={{ display: 'flex', gap: 8 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: 'rgba(124,58,237,0.1)', border: '1px solid rgba(124,58,237,0.25)' }}>
              <span>📊</span>
              <span style={{ fontSize: 12, color: '#6b7280' }}>任务总数</span>
              <span style={{ fontSize: 13, fontWeight: 700, color: '#7c3aed' }}>{jobs.length}</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: 'rgba(34,197,94,0.1)', border: '1px solid rgba(34,197,94,0.25)' }}>
              <span style={{ fontSize: 11, color: '#16a34a' }}>▶</span>
              <span style={{ fontSize: 12, color: '#6b7280' }}>运行中</span>
              <span style={{ fontSize: 13, fontWeight: 700, color: '#16a34a' }}>{running}</span>
            </div>
          </div>
          <div style={{ flex: 1 }} />
          <Tooltip title="刷新列表"><Button icon={<ReloadOutlined />} loading={loading} style={{ borderRadius: 8, color: '#7c3aed', borderColor: '#ddd6fe' }} onClick={load} /></Tooltip>
        </div>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', padding: '10px 24px 12px' }}>
          <Input placeholder="任务名称" prefix={<FileTextOutlined style={{ color: '#7c3aed', fontSize: 12 }} />} value={searchName} onChange={e => setSearchName(e.target.value)} allowClear size="middle" style={{ width: 160, ...INPUT_STYLE }} onPressEnter={handleSearch} />
          <Input placeholder="任务组" prefix={<TagOutlined style={{ color: '#7c3aed', fontSize: 12 }} />} value={searchGroup} onChange={e => setSearchGroup(e.target.value)} allowClear size="middle" style={{ width: 120, ...INPUT_STYLE }} onPressEnter={handleSearch} />
          <Select placeholder={<Space size={4}><ClockCircleOutlined style={{ color: '#7c3aed', fontSize: 12 }} />任务状态</Space>} allowClear style={{ width: 115 }} value={searchStatus || undefined} onChange={v => setSearchStatus(v ?? '')}>
            <Select.Option value="正常"><Badge status="processing" text="正常" /></Select.Option>
            <Select.Option value="暂停"><Badge status="default" text="暂停" /></Select.Option>
          </Select>
          <div style={{ flex: 1 }} />
          <Button icon={<ReloadOutlined />} size="middle" style={{ borderRadius: 8 }} onClick={handleReset}>重置</Button>
          <Button type="primary" icon={<SearchOutlined />} style={{ borderRadius: 8, border: 'none', background: PAGE_GRADIENT }} onClick={handleSearch}>搜索</Button>
        </div>
      </div>
      <div style={{ marginLeft: -24, marginRight: -24, marginBottom: -24, background: '#fff', borderTop: '1px solid #eef0f8' }}>
        <Table
          columns={columns}
          dataSource={pagedJobs}
          rowKey="id"
          loading={loading}
          pagination={false}
          components={styledTableComponents}
          scroll={{ x: 'max-content', y: 'calc(100vh - 272px)' }}
          size="middle"
        />
        <PagePagination
          total={jobs.length}
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
