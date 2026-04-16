import { useEffect, useState, useCallback } from 'react'
import {
  Table, Button, Space, Tag, Modal, Form, Input, Select, message,
  Popconfirm, Tooltip, Row, Col, Typography, Divider,
} from 'antd'
import {
  SettingOutlined, PlusOutlined, EditOutlined, DeleteOutlined,
  ReloadOutlined, SearchOutlined, LockOutlined, UnlockOutlined,
  KeyOutlined, AppstoreOutlined,
} from '@ant-design/icons'
import { sysConfigApi } from '../../api/api'
import PermGuard from '../../components/common/PermGuard'
import { col, styledTableComponents, INPUT_STYLE } from '../../components/common/tableComponents'
import PagePagination from '../../components/common/PagePagination'
import { useTableBodyHeight } from '../../hooks/useTableBodyHeight'

const { Text } = Typography

interface SysConfig {
  id: number
  configName: string
  configGroup: string
  configKey: string
  configValue: string
  isSystem: number
  remark?: string
  createTime?: string
}

const GROUP_COLORS: Record<string, string> = {
  sys: 'blue', platform: 'purple', business: 'orange', app: 'green', custom: 'default',
}
const GROUP_NAMES: Record<string, string> = {
  sys: '系统内置', platform: '平台设置', business: '业务配置', app: 'APP配置', custom: '自定义',
}

const PAGE_GRADIENT = 'linear-gradient(135deg,#f5576c,#f093fb)'

export default function SysParamPage() {
  const { ref, height: tableBodyH } = useTableBodyHeight()
  const [configs, setConfigs]     = useState<SysConfig[]>([])
  const [loading, setLoading]     = useState(false)
  const [current, setCurrent]     = useState(1)
  const [pageSize, setPageSize]   = useState(15)
  const [total, setTotal]         = useState(0)
  const [modalOpen, setModalOpen] = useState(false)
  const [editing, setEditing]     = useState<SysConfig | null>(null)
  const [form]                    = Form.useForm()
  const [searchName, setSearchName]   = useState('')
  const [searchKey, setSearchKey]     = useState('')
  const [searchGroup, setSearchGroup] = useState('')

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const res = await sysConfigApi.list({
        current, size: pageSize,
        configName:  searchName  || undefined,
        configKey:   searchKey   || undefined,
        configGroup: searchGroup || undefined,
      })
      const d = res.data?.data
      setConfigs(d?.records ?? [])
      setTotal(d?.total ?? 0)
    } finally {
      setLoading(false)
    }
  }, [current, pageSize, searchName, searchKey, searchGroup])

  useEffect(() => { load() }, [load])

  const openModal = (record?: SysConfig) => {
    setEditing(record ?? null)
    if (record) {
      form.setFieldsValue({ ...record })
    } else {
      form.resetFields()
      form.setFieldsValue({ configGroup: 'custom' })
    }
    setModalOpen(true)
  }

  const handleOk = async () => {
    const values = await form.validateFields()
    if (editing) {
      await sysConfigApi.edit({ id: editing.id, ...values })
      message.success('修改成功')
    } else {
      await sysConfigApi.add(values)
      message.success('新增成功')
    }
    setModalOpen(false)
    load()
  }

  const handleDelete = async (id: number) => {
    await sysConfigApi.delete(id)
    message.success('删除成功')
    load()
  }

  const handleSearch = () => { setCurrent(1); load() }
  const handleReset  = () => { setSearchName(''); setSearchKey(''); setSearchGroup(''); setCurrent(1) }

  const statBadges = [
    { label: '参数总数',  value: total,                                         color: '#f5576c', bg: 'rgba(245,87,108,0.1)',  border: 'rgba(245,87,108,0.25)',  icon: '⚙️' },
    { label: '内置参数',  value: configs.filter(c => c.isSystem === 1).length,  color: '#ff6b6b', bg: 'rgba(255,107,107,0.1)', border: 'rgba(255,107,107,0.25)', icon: '🔒' },
    { label: '自定义',    value: configs.filter(c => c.isSystem !== 1).length,  color: '#10b981', bg: 'rgba(16,185,129,0.1)',  border: 'rgba(16,185,129,0.25)',  icon: '🔓' },
    { label: '分组数',    value: [...new Set(configs.map(c => c.configGroup))].length, color: '#7c3aed', bg: 'rgba(124,58,237,0.1)', border: 'rgba(124,58,237,0.25)', icon: '📂' },
  ]

  const columns = [
    {
      title: col(<SettingOutlined style={{ color: '#f5576c' }} />, '参数名称'),
      dataIndex: 'configName', key: 'configName',
      render: (v: string, r: SysConfig) => (
        <Space>
          {r.isSystem === 1
            ? <div style={{ width: 26, height: 26, borderRadius: 6, background: 'linear-gradient(135deg,#ff6b6b,#ffd93d)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', fontSize: 11 }}><LockOutlined /></div>
            : <div style={{ width: 26, height: 26, borderRadius: 6, background: 'linear-gradient(135deg,#a8edea,#fed6e3)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#555', fontSize: 11 }}><UnlockOutlined /></div>
          }
          <Text strong>{v}</Text>
          {r.isSystem === 1 && <Tag color="red" style={{ borderRadius: 4, fontSize: 10 }}>内置</Tag>}
        </Space>
      ),
    },
    {
      title: col(<KeyOutlined style={{ color: '#6366f1' }} />, '参数键名'),
      dataIndex: 'configKey', key: 'configKey',
      render: (v: string) => <code style={{ background: '#f0f5ff', padding: '2px 8px', borderRadius: 4, color: '#1890ff', fontSize: 12 }}>{v}</code>,
    },
    {
      title: col(<AppstoreOutlined style={{ color: '#10b981' }} />, '参数值'),
      dataIndex: 'configValue', key: 'configValue',
      render: (v: string) => <Text ellipsis={{ tooltip: v }} style={{ maxWidth: 200 }}>{v}</Text>,
    },
    {
      title: col(<AppstoreOutlined style={{ color: '#7c3aed' }} />, '所属分组'),
      dataIndex: 'configGroup', key: 'configGroup',
      render: (v: string) => (
        <Tag color={GROUP_COLORS[v] || 'default'} icon={<AppstoreOutlined />} style={{ borderRadius: 6 }}>
          {GROUP_NAMES[v] || v}
        </Tag>
      ),
    },
    {
      title: col(<SettingOutlined style={{ color: '#9ca3af' }} />, '操作'),
      key: 'action', width: 145,
      render: (_: any, r: SysConfig) => (
        <Space size={4}>
          <PermGuard code="sysconfig:edit">
            <Button size="small" icon={<EditOutlined />}
              style={{ borderRadius: 6, fontSize: 12, color: '#fa8c16', borderColor: '#ffd591' }}
              onClick={() => openModal(r)}>编辑</Button>
          </PermGuard>
          {r.isSystem !== 1 && (
            <PermGuard code="sysconfig:delete">
              <Popconfirm title="确认删除该参数？" onConfirm={() => handleDelete(r.id)} okText="删除" cancelText="取消" okButtonProps={{ danger: true }}>
                <Button size="small" danger icon={<DeleteOutlined />} style={{ borderRadius: 6, fontSize: 12 }}>删除</Button>
              </Popconfirm>
            </PermGuard>
          )}
        </Space>
      ),
    },
  ]

  return (
    <div style={{ marginTop: -24 }}>

      {/* ── 吸顶复合头部 ── */}
      <div style={{
        position: 'sticky', top: 64, zIndex: 88,
        marginLeft: -24, marginRight: -24,
        background: 'rgba(255,255,255,0.97)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderBottom: '1px solid rgba(0,0,0,0.07)',
        boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
      }}>
        {/* 标题行 */}
        <div style={{ display: 'flex', alignItems: 'center', padding: '10px 24px 0', gap: 12 }}>
          <div style={{
            width: 34, height: 34, borderRadius: 10, background: PAGE_GRADIENT,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 4px 12px rgba(245,87,108,0.35)', flexShrink: 0,
          }}>
            <SettingOutlined style={{ color: '#fff', fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1e293b', lineHeight: 1.2 }}>参数设置</div>
            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>管理系统全局参数和业务配置项</div>
          </div>
          <Divider type="vertical" style={{ height: 20, margin: '0 4px', borderColor: '#e0e4ff' }} />
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            {statBadges.map((s, i) => (
              <div key={i} style={{
                display: 'flex', alignItems: 'center', gap: 5,
                padding: '3px 10px', borderRadius: 20,
                background: s.bg, border: `1px solid ${s.border}`,
              }}>
                <span style={{ fontSize: 13 }}>{s.icon}</span>
                <span style={{ fontSize: 12, color: '#6b7280' }}>{s.label}</span>
                <span style={{ fontSize: 13, fontWeight: 700, color: s.color }}>{s.value}</span>
              </div>
            ))}
          </div>
          <div style={{ flex: 1 }} />
          <PermGuard code="sysconfig:add">
            <Button type="primary" icon={<PlusOutlined />} onClick={() => openModal()}
              style={{ borderRadius: 8, border: 'none', background: PAGE_GRADIENT }}>
              新增参数
            </Button>
          </PermGuard>
        </div>

        {/* 筛选行 */}
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', padding: '10px 24px 12px' }}>
          <Input
            placeholder="参数名称"
            prefix={<SettingOutlined style={{ color: '#f5576c', fontSize: 12 }} />}
            value={searchName} onChange={e => setSearchName(e.target.value)}
            allowClear size="middle" style={{ width: 180, ...INPUT_STYLE }}
            onPressEnter={handleSearch}
          />
          <Input
            placeholder="参数键名"
            prefix={<KeyOutlined style={{ color: '#6366f1', fontSize: 12 }} />}
            value={searchKey} onChange={e => setSearchKey(e.target.value)}
            allowClear size="middle" style={{ width: 190, ...INPUT_STYLE }}
            onPressEnter={handleSearch}
          />
          <Select placeholder={<Space size={4}><AppstoreOutlined style={{ color: '#7c3aed', fontSize: 12 }} />所属分组</Space>} allowClear size="middle" style={{ width: 115 }}
            value={searchGroup || undefined} onChange={v => setSearchGroup(v ?? '')}>
            {Object.entries(GROUP_NAMES).map(([k, v]) => (
              <Select.Option key={k} value={k}>{v}</Select.Option>
            ))}
          </Select>
          <div style={{ flex: 1 }} />
          <Button icon={<ReloadOutlined />} size="middle" style={{ borderRadius: 8 }} onClick={handleReset}>重置</Button>
          <Tooltip title="刷新列表">
            <Button icon={<ReloadOutlined />} size="middle" loading={loading}
              style={{ borderRadius: 8, color: '#f5576c', borderColor: '#fecdd3' }}
              onClick={load}
            />
          </Tooltip>
          <Button type="primary" icon={<SearchOutlined />} size="middle"
            style={{ borderRadius: 8, border: 'none', background: PAGE_GRADIENT, boxShadow: '0 2px 8px rgba(245,87,108,0.35)' }}
            onClick={handleSearch}>
            搜索
          </Button>
        </div>
      </div>

      {/* ── 表格区域 ── */}
      <div ref={ref} style={{ marginLeft: -24, marginRight: -24, marginBottom: -24, background: '#fff', borderTop: '1px solid #eef0f8' }}>
        <Table
          columns={columns} dataSource={configs} rowKey="id" loading={loading}
          size="middle" pagination={false}
          components={styledTableComponents}
          scroll={{ x: 'max-content', y: tableBodyH }}
        />
        <PagePagination
          total={total} current={current} pageSize={pageSize}
          onChange={p => setCurrent(p)}
          onSizeChange={s => { setPageSize(s); setCurrent(1) }}
          countLabel="条参数"
        />
      </div>

      {/* ── 新增/编辑弹窗 ── */}
      <Modal open={modalOpen} onCancel={() => setModalOpen(false)} onOk={handleOk}
        title={
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{ width: 32, height: 32, borderRadius: 8, background: PAGE_GRADIENT, display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff' }}>
              <SettingOutlined />
            </div>
            {editing ? '编辑参数' : '新增参数'}
          </div>
        }
        okText="保存" width={880}
        styles={{ body: { maxHeight: 'calc(85vh - 150px)', overflowY: 'auto', overflowX: 'hidden' } }}
        okButtonProps={{ style: { borderRadius: 8, background: PAGE_GRADIENT, border: 'none' } }}
        cancelButtonProps={{ style: { borderRadius: 8 } }}
      >
        <Divider style={{ margin: '12px 0' }} />
        <Form form={form} layout="vertical" size="large">
          <Form.Item name="configName" label="参数名称" rules={[{ required: true, message: '请输入参数名称' }]}>
            <Input placeholder="如：平台名称" style={{ borderRadius: 8 }} />
          </Form.Item>
          <Form.Item name="configKey" label="参数键名" rules={[{ required: true, message: '请输入参数键名' }]}>
            <Input prefix={<KeyOutlined style={{ color: '#6366f1' }} />} placeholder="如：cb.platform.name" disabled={!!editing} style={{ borderRadius: 8 }} />
          </Form.Item>
          <Form.Item name="configValue" label="参数值" rules={[{ required: true, message: '请输入参数值' }]}>
            <Input.TextArea rows={3} placeholder="请输入参数值" style={{ borderRadius: 8 }} />
          </Form.Item>
          <Row gutter={12}>
            <Col span={12}>
              <Form.Item name="configGroup" label="所属分组">
                <Select style={{ borderRadius: 8 }}>
                  {Object.entries(GROUP_NAMES).map(([k, v]) => (
                    <Select.Option key={k} value={k}>{v}</Select.Option>
                  ))}
                </Select>
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="remark" label="备注说明">
                <Input placeholder="备注说明" style={{ borderRadius: 8 }} />
              </Form.Item>
            </Col>
          </Row>
        </Form>
      </Modal>
    </div>
  )
}
