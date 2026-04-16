import { useEffect, useState } from 'react'
import {
  Card, Row, Col, Progress, Typography, Space, Button,
  Table, Tag, Popconfirm, message, Divider, Tooltip,
} from 'antd'
import type { ColumnsType } from 'antd/es/table'
import {
  DatabaseOutlined, ReloadOutlined, DeleteOutlined,
  ThunderboltOutlined, ClockCircleOutlined, KeyOutlined,
  NumberOutlined, SettingOutlined,
} from '@ant-design/icons'
import request from '../../api/request'
import PermGuard from '../../components/common/PermGuard'
import { styledTableComponents, col } from '../../components/common/tableComponents'

const { Text } = Typography

export default function CacheMonitorPage() {
  const [data, setData] = useState<any>(null)
  const [loading, setLoading] = useState(false)

  const load = async () => {
    setLoading(true)
    try {
      const res = await request.get('/admin/monitor/cache/info')
      setData(res.data?.data)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { load() }, [])

  const clearCache = async (prefix: string) => {
    await request.delete('/admin/monitor/cache/clear', { params: { prefix } })
    message.success(`已清除前缀 ${prefix} 的缓存`)
    load()
  }

  const server   = data?.server   || {}
  const stats    = data?.stats    || {}
  const memory   = data?.memory   || {}
  const keyStats = data?.keyStats || []
  const hitRate  = data?.hitRate  ?? 0

  const keyStatColumns: ColumnsType<any> = [
    {
      title: col(<KeyOutlined style={{ color: '#6366f1' }} />, '缓存前缀'),
      dataIndex: 'prefix',
      key: 'prefix',
      render: (v: string) => <code style={{ background: '#f0f5ff', padding: '2px 8px', borderRadius: 4, color: '#1890ff', fontSize: 12 }}>{v}</code>,
    },
    {
      title: col(<NumberOutlined style={{ color: '#3b82f6' }} />, '键数量'),
      dataIndex: 'count',
      key: 'count',
      align: 'center',
      render: (v: number) => <Tag color={v > 0 ? 'blue' : 'default'} style={{ borderRadius: 20, fontWeight: 700 }}>{v}</Tag>,
    },
    {
      title: col(<SettingOutlined style={{ color: '#9ca3af' }} />, '操作'),
      key: 'action',
      align: 'center',
      width: 100,
      render: (_: any, r: any) => (
        <PermGuard code="monitor:cache:clear">
          <Popconfirm title={`确认清除 ${r.prefix}* 的所有缓存？`} onConfirm={() => clearCache(r.prefix)} okButtonProps={{ danger: true }}>
            <Button size="small" danger icon={<DeleteOutlined />} style={{ borderRadius: 6 }}>清除</Button>
          </Popconfirm>
        </PermGuard>
      ),
    },
  ]

  return (
    <div style={{ marginTop: -24, height: 'calc(100vh - 64px)', display: 'flex', flexDirection: 'column' }}>
      {/* Sticky header */}
      <div style={{ position: 'sticky', top: 64, zIndex: 88, marginLeft: -24, marginRight: -24, background: 'rgba(255,255,255,0.97)', backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)', borderBottom: '1px solid rgba(0,0,0,0.07)', boxShadow: '0 4px 20px rgba(0,0,0,0.06)' }}>
        <div style={{ display: 'flex', alignItems: 'center', padding: '10px 24px 12px', gap: 12 }}>
          <div style={{ width: 34, height: 34, borderRadius: 10, background: 'linear-gradient(135deg,#6366f1,#8b5cf6)', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 4px 12px rgba(99,102,241,0.35)', flexShrink: 0 }}>
            <DatabaseOutlined style={{ color: '#fff', fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1e293b', lineHeight: 1.2 }}>缓存监控</div>
            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>Redis 缓存统计与键管理</div>
          </div>
          <Divider type="vertical" style={{ height: 20, margin: '0 4px', borderColor: '#e0e4ff' }} />
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            {[
              { label: '命中率', value: `${hitRate}%`, color: '#10b981', bg: 'rgba(16,185,129,0.1)', border: 'rgba(16,185,129,0.25)', icon: '🎯' },
              { label: '在线连接', value: String(stats.connected_clients ?? 0), color: '#6366f1', bg: 'rgba(99,102,241,0.1)', border: 'rgba(99,102,241,0.25)', icon: '🔗' },
              { label: '运行天数', value: `${server.uptime_in_days ?? 0}天`, color: '#f59e0b', bg: 'rgba(245,158,11,0.1)', border: 'rgba(245,158,11,0.25)', icon: '⏱' },
            ].map((s, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: s.bg, border: `1px solid ${s.border}` }}>
                <span style={{ fontSize: 13 }}>{s.icon}</span>
                <span style={{ fontSize: 12, color: '#6b7280' }}>{s.label}</span>
                <span style={{ fontSize: 13, fontWeight: 700, color: s.color }}>{s.value}</span>
              </div>
            ))}
          </div>
          <div style={{ flex: 1 }} />
          <Tooltip title="刷新数据"><Button icon={<ReloadOutlined />} onClick={load} loading={loading} style={{ borderRadius: 8, color: '#6366f1', borderColor: '#c7d2fe' }}>刷新</Button></Tooltip>
        </div>
      </div>
      <div style={{ padding: '16px 0 0', flex: 1, overflowY: 'auto' }}>
      {/* Key Stats */}
      <Row gutter={12} style={{ marginBottom: 12 }}>
        {[
          { title: '缓存命中率', value: `${hitRate}%`, color: '#52c41a', icon: <ThunderboltOutlined /> },
          { title: '在线连接数', value: stats.connected_clients ?? 0, color: '#1890ff', icon: <DatabaseOutlined /> },
          { title: '总执行命令', value: Number(stats.total_commands_processed ?? 0).toLocaleString(), color: '#722ed1', icon: <KeyOutlined /> },
          { title: '运行天数', value: `${server.uptime_in_days ?? 0}天`, isStr: true, color: '#f7971e', icon: <ClockCircleOutlined /> },
        ].map(s => (
          <Col span={6} key={s.title}>
            <Card variant="borderless" style={{ borderRadius: 12 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
                <div style={{ width: 36, height: 36, borderRadius: 10, background: s.color, display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', fontSize: 22 }}>{s.icon}</div>
                <div>
                  <div style={{ fontSize: 26, fontWeight: 900, color: s.color }}>{s.value}</div>
                  <div style={{ fontSize: 13, color: '#999' }}>{s.title}</div>
                </div>
              </div>
            </Card>
          </Col>
        ))}
      </Row>

      <Row gutter={12} style={{ marginBottom: 12 }}>
        {/* Server Info */}
        <Col span={8}>
          <Card title={<Space><DatabaseOutlined style={{ color: '#f7971e' }} /><span>Redis 服务器</span></Space>}
            variant="borderless" style={{ borderRadius: 12 }}>
            {[
              { label: 'Redis版本', value: server.redis_version },
              { label: '运行模式', value: server.redis_mode },
              { label: '操作系统', value: server.os },
              { label: '监听端口', value: server.tcp_port },
              { label: '运行天数', value: `${server.uptime_in_days} 天` },
            ].map(item => (
              <div key={item.label} style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 12px', borderRadius: 8, marginBottom: 4, background: '#fffbf0' }}>
                <Text type="secondary" style={{ fontSize: 13 }}>{item.label}</Text>
                <Text strong style={{ fontSize: 13 }}>{item.value || '-'}</Text>
              </div>
            ))}
          </Card>
        </Col>

        {/* Memory */}
        <Col span={8}>
          <Card title={<Space><ThunderboltOutlined style={{ color: '#52c41a' }} /><span>内存使用</span></Space>}
            variant="borderless" style={{ borderRadius: 12 }}>
            {[
              { label: '已用内存', value: memory.usedMemory, color: '#1890ff' },
              { label: '峰值内存', value: memory.peakMemory, color: '#faad14' },
              { label: '最大内存', value: memory.maxMemory, color: '#52c41a' },
              { label: '内存碎片率', value: memory.mem_fragmentation_ratio },
            ].map(item => (
              <div key={item.label} style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 12px', borderRadius: 8, marginBottom: 4, background: '#f6ffed' }}>
                <Text type="secondary" style={{ fontSize: 13 }}>{item.label}</Text>
                <Text strong style={{ fontSize: 13, color: item.color || '#333' }}>{item.value || '-'}</Text>
              </div>
            ))}
            <Divider style={{ margin: '12px 0 8px' }}>命中统计</Divider>
            <div style={{ display: 'flex', justifyContent: 'space-around', marginBottom: 8 }}>
              <div style={{ textAlign: 'center' }}>
                <div style={{ fontSize: 20, fontWeight: 700, color: '#52c41a' }}>{Number(stats.keyspace_hits ?? 0).toLocaleString()}</div>
                <div style={{ fontSize: 12, color: '#999' }}>命中次数</div>
              </div>
              <div style={{ textAlign: 'center' }}>
                <div style={{ fontSize: 20, fontWeight: 700, color: '#ff4d4f' }}>{Number(stats.keyspace_misses ?? 0).toLocaleString()}</div>
                <div style={{ fontSize: 12, color: '#999' }}>未命中</div>
              </div>
              <div style={{ textAlign: 'center' }}>
                <div style={{ fontSize: 20, fontWeight: 700, color: '#1890ff' }}>{hitRate}%</div>
                <div style={{ fontSize: 12, color: '#999' }}>命中率</div>
              </div>
            </div>
            <Progress percent={Number(hitRate)} strokeColor="#52c41a" showInfo={false} size="small" />
          </Card>
        </Col>

        {/* Stats */}
        <Col span={8}>
          <Card title={<Space><KeyOutlined style={{ color: '#722ed1' }} /><span>运行统计</span></Space>}
            variant="borderless" style={{ borderRadius: 12 }}>
            {[
              { label: '在线连接数', value: stats.connected_clients },
              { label: '阻塞连接数', value: stats.blocked_clients },
              { label: '总连接次数', value: Number(stats.total_connections_received ?? 0).toLocaleString() },
              { label: '总执行命令', value: Number(stats.total_commands_processed ?? 0).toLocaleString() },
              { label: '每秒操作数', value: stats.instantaneous_ops_per_sec },
            ].map(item => (
              <div key={item.label} style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 12px', borderRadius: 8, marginBottom: 4, background: '#f9f0ff' }}>
                <Text type="secondary" style={{ fontSize: 13 }}>{item.label}</Text>
                <Text strong style={{ fontSize: 13 }}>{item.value ?? '-'}</Text>
              </div>
            ))}
          </Card>
        </Col>
      </Row>

      {/* Key Stats Table */}
      <Card title={<Space><KeyOutlined style={{ color: '#1890ff' }} /><span>缓存键分布（按前缀）</span></Space>}
        variant="borderless" style={{ borderRadius: 12 }}>
        <Table columns={keyStatColumns} dataSource={keyStats} rowKey="prefix" pagination={false} size="small" components={styledTableComponents} />
      </Card>
      </div>
    </div>
  )
}
