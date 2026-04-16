import { useEffect, useState } from 'react'
import {
  Card, Row, Col, Progress, Typography, Space,
  Button, Divider, Badge, Table, Tooltip,
} from 'antd'
import {
  DesktopOutlined, ReloadOutlined, CloudServerOutlined,
  HddOutlined, CodeOutlined, ClockCircleOutlined, ThunderboltOutlined,
} from '@ant-design/icons'
import request from '../../api/request'

const { Text } = Typography

function toFixed(n: number | undefined, d = 1): string {
  return (n ?? 0).toFixed(d)
}

function formatMs(ms: number): string {
  const s = Math.floor(ms / 1000)
  const h = Math.floor(s / 3600)
  const m = Math.floor((s % 3600) / 60)
  return `${h}小时 ${m}分钟`
}

function getProgressColor(pct: number): string {
  if (pct < 60) return '#52c41a'
  if (pct < 80) return '#faad14'
  return '#ff4d4f'
}

export default function ServerMonitorPage() {
  const [data, setData] = useState<any>(null)
  const [loading, setLoading] = useState(false)

  const load = async () => {
    setLoading(true)
    try {
      const res = await request.get('/admin/monitor/server/info')
      setData(res.data?.data)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { load() }, [])

  const jvm    = data?.jvm    || {}
  const os     = data?.os     || {}
  const disks  = data?.disks  || []
  const gc     = data?.gc     || []
  const thread = data?.thread || {}

  return (
    <div style={{ marginTop: -24, height: 'calc(100vh - 64px)', display: 'flex', flexDirection: 'column' }}>
      {/* Sticky header */}
      <div style={{ position: 'sticky', top: 64, zIndex: 88, marginLeft: -24, marginRight: -24, background: 'rgba(255,255,255,0.97)', backdropFilter: 'blur(20px)', borderBottom: '1px solid rgba(0,0,0,0.07)', boxShadow: '0 4px 20px rgba(0,0,0,0.06)' }}>
        <div style={{ display: 'flex', alignItems: 'center', padding: '10px 24px 12px', gap: 12 }}>
          <div style={{ width: 34, height: 34, borderRadius: 10, background: 'linear-gradient(135deg,#1a1a2e,#0f3460)', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 4px 12px rgba(15,52,96,0.4)', flexShrink: 0 }}>
            <DesktopOutlined style={{ color: '#4facfe', fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1e293b', lineHeight: 1.2 }}>服务监控</div>
            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>实时监控服务器 CPU、内存、JVM、磁盘状态</div>
          </div>
          <div style={{ width: 1, height: 20, margin: '0 4px', background: '#e0e4ff', flexShrink: 0 }} />
          <div style={{ display: 'flex', gap: 8 }}>
            {[
              { label: 'CPU', value: `${toFixed(os.cpuUsedPercent)}%`, color: '#4facfe', bg: 'rgba(79,172,254,0.1)', border: 'rgba(79,172,254,0.25)', icon: '⚡' },
              { label: '内存', value: `${toFixed(os.memUsedPercent)}%`, color: '#f093fb', bg: 'rgba(240,147,251,0.1)', border: 'rgba(240,147,251,0.25)', icon: '💾' },
              { label: 'JVM', value: `${toFixed(jvm.usedPercent)}%`, color: '#43e97b', bg: 'rgba(67,233,123,0.1)', border: 'rgba(67,233,123,0.25)', icon: '☕' },
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
      {/* Content area */}
      <div style={{ padding: '16px 0 0', flex: 1, overflowY: 'auto' }}>
      {/* OS + JVM 核心指标 */}
      <Row gutter={12} style={{ marginBottom: 12 }}>
        {[
          { title: 'CPU使用率', value: os.cpuUsedPercent ?? 0, color: '#4facfe', suffix: '%', icon: <ThunderboltOutlined /> },
          { title: '内存使用率', value: os.memUsedPercent ?? 0, color: '#f093fb', suffix: '%', icon: <CloudServerOutlined /> },
          { title: 'JVM内存使用', value: jvm.usedPercent ?? 0, color: '#43e97b', suffix: '%', icon: <CodeOutlined /> },
          { title: '运行时长', value: formatMs(jvm.upTimeMs ?? 0), isStr: true, color: '#faad14', icon: <ClockCircleOutlined /> },
        ].map(s => (
          <Col span={6} key={s.title}>
            <Card variant="borderless" style={{ borderRadius: 12, textAlign: 'center' }}>
              <div style={{ width: 36, height: 36, borderRadius: 10, background: s.color, display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', fontSize: 22, margin: '0 auto 12px' }}>{s.icon}</div>
              {s.isStr
                ? <div><div style={{ fontSize: 20, fontWeight: 700, color: s.color }}>{s.value}</div><div style={{ color: '#999', fontSize: 13 }}>{s.title}</div></div>
                : <>
                    <div style={{ fontSize: 28, fontWeight: 900, color: s.color }}>{toFixed(s.value as number)}%</div>
                    <div style={{ color: '#999', fontSize: 13, marginBottom: 8 }}>{s.title}</div>
                    <Progress percent={Number(toFixed(s.value as number))} showInfo={false} strokeColor={getProgressColor(s.value as number)} size="small" />
                  </>
              }
            </Card>
          </Col>
        ))}
      </Row>

      <Row gutter={12} style={{ marginBottom: 12 }}>
        {/* CPU & OS */}
        <Col span={12}>
          <Card title={<Space><ThunderboltOutlined style={{ color: '#4facfe' }} /><span>操作系统</span></Space>}
            variant="borderless" style={{ borderRadius: 12, height: '100%' }}>
            <Row gutter={[12, 12]}>
              {[
                { label: '系统名称', value: os.name },
                { label: '系统版本', value: os.version },
                { label: '系统架构', value: os.arch },
                { label: 'CPU核心数', value: os.processors },
                { label: '系统负载', value: `${toFixed(os.cpuLoad)} (1min avg)` },
                { label: 'CPU使用率', value: <span style={{ color: getProgressColor(os.cpuUsedPercent ?? 0), fontWeight: 700 }}>{toFixed(os.cpuUsedPercent)}%</span> },
                { label: '物理内存', value: `${toFixed(os.totalMemoryGB)}GB` },
                { label: '已用内存', value: `${toFixed(os.usedMemoryGB)}GB` },
                { label: '空闲内存', value: `${toFixed(os.freeMemoryGB)}GB` },
                { label: '内存使用率', value: <span style={{ color: getProgressColor(os.memUsedPercent ?? 0), fontWeight: 700 }}>{toFixed(os.memUsedPercent)}%</span> },
              ].map(item => (
                <Col span={12} key={item.label}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', padding: '6px 12px', background: '#f5f7fa', borderRadius: 8 }}>
                    <Text type="secondary" style={{ fontSize: 13 }}>{item.label}</Text>
                    <Text strong style={{ fontSize: 13 }}>{item.value ?? '-'}</Text>
                  </div>
                </Col>
              ))}
            </Row>
          </Card>
        </Col>

        {/* JVM */}
        <Col span={12}>
          <Card title={<Space><CodeOutlined style={{ color: '#43e97b' }} /><span>JVM 信息</span></Space>}
            variant="borderless" style={{ borderRadius: 12, height: '100%' }}>
            <Row gutter={[12, 12]}>
              {[
                { label: 'JVM名称', value: jvm.name },
                { label: 'Java版本', value: jvm.version },
                { label: 'CPU核心数', value: jvm.processors },
                { label: '运行时长', value: formatMs(jvm.upTimeMs ?? 0) },
                { label: '已用内存', value: `${toFixed(jvm.usedMemoryMB)}MB` },
                { label: '空闲内存', value: `${toFixed(jvm.freeMemoryMB)}MB` },
                { label: '总内存', value: `${toFixed(jvm.totalMemoryMB)}MB` },
                { label: '最大内存', value: `${toFixed(jvm.maxMemoryMB)}MB` },
                { label: '内存使用率', value: <span style={{ color: getProgressColor(jvm.usedPercent ?? 0), fontWeight: 700 }}>{toFixed(jvm.usedPercent)}%</span> },
              ].map(item => (
                <Col span={12} key={item.label}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', padding: '6px 12px', background: '#f0fff4', borderRadius: 8 }}>
                    <Text type="secondary" style={{ fontSize: 13 }}>{item.label}</Text>
                    <Text strong style={{ fontSize: 13 }}>{item.value ?? '-'}</Text>
                  </div>
                </Col>
              ))}
            </Row>
            <Divider style={{ margin: '12px 0' }} />
            <div style={{ fontSize: 13, color: '#666', marginBottom: 6 }}>JVM 内存占用</div>
            <Progress
              percent={Number(toFixed(jvm.usedPercent))}
              strokeColor={getProgressColor(jvm.usedPercent ?? 0)}
              format={() => `${toFixed(jvm.usedMemoryMB)}MB / ${toFixed(jvm.maxMemoryMB)}MB`}
            />
          </Card>
        </Col>
      </Row>

      <Row gutter={12} style={{ marginBottom: 12 }}>
        {/* 磁盘 */}
        <Col span={14}>
          <Card title={<Space><HddOutlined style={{ color: '#fa709a' }} /><span>磁盘状态</span></Space>}
            variant="borderless" style={{ borderRadius: 12 }}>
            {disks.map((d: any, i: number) => (
              <div key={i} style={{ marginBottom: 16 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
                  <Space>
                    <HddOutlined style={{ color: '#fa709a' }} />
                    <Text strong>{d.path}</Text>
                  </Space>
                  <Space size={16}>
                    <Text type="secondary">总计 {toFixed(d.totalGB)}GB</Text>
                    <Text style={{ color: '#ff4d4f' }}>已用 {toFixed(d.usedGB)}GB</Text>
                    <Text style={{ color: '#52c41a' }}>空闲 {toFixed(d.freeGB)}GB</Text>
                    <Badge color={getProgressColor(d.usedPercent)} text={<Text strong style={{ color: getProgressColor(d.usedPercent) }}>{toFixed(d.usedPercent)}%</Text>} />
                  </Space>
                </div>
                <Progress percent={Number(toFixed(d.usedPercent))} strokeColor={getProgressColor(d.usedPercent)} showInfo={false} />
              </div>
            ))}
          </Card>
        </Col>

        {/* 线程 + GC */}
        <Col span={10}>
          <Card title={<Space><ClockCircleOutlined style={{ color: '#667eea' }} /><span>线程 & GC</span></Space>}
            variant="borderless" style={{ borderRadius: 12 }}>
            <Row gutter={12} style={{ marginBottom: 16 }}>
              {[
                { title: '活跃线程', value: thread.total, color: '#667eea' },
                { title: '守护线程', value: thread.daemon, color: '#43e97b' },
                { title: '峰值线程', value: thread.peak, color: '#fa709a' },
              ].map(s => (
                <Col span={8} key={s.title}>
                  <div style={{ textAlign: 'center', padding: '12px 0', background: '#f5f7fa', borderRadius: 8 }}>
                    <div style={{ fontSize: 24, fontWeight: 900, color: s.color }}>{s.value ?? 0}</div>
                    <div style={{ fontSize: 12, color: '#999' }}>{s.title}</div>
                  </div>
                </Col>
              ))}
            </Row>
            <Divider style={{ margin: '8px 0' }}>GC 回收</Divider>
            <Table
              size="small"
              dataSource={gc}
              rowKey="name"
              pagination={false}
              columns={[
                { title: '收集器', dataIndex: 'name', key: 'name', render: (v: string) => <Text style={{ fontSize: 12 }}>{v}</Text> },
                { title: '次数', dataIndex: 'count', key: 'count',  align: 'center' as const },
                { title: '耗时(ms)', dataIndex: 'timeMs', key: 'timeMs',  align: 'center' as const },
              ]}
            />
          </Card>
        </Col>
      </Row>
      </div>
    </div>
  )
}
