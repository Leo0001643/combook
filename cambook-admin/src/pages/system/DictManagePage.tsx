import { useEffect, useState, useCallback } from 'react'
import {
  Table, Button, Space, Tag, Modal, Form, Input, Select, message,
  Popconfirm, Badge, Divider, Drawer, InputNumber, Row, Col, Tooltip, Typography,
} from 'antd'
import {
  BookOutlined, PlusOutlined, EditOutlined, DeleteOutlined,
  ReloadOutlined, SearchOutlined, TagOutlined,
  UnorderedListOutlined, BarsOutlined,
  SafetyCertificateOutlined, FileTextOutlined, SettingOutlined,
  CheckCircleOutlined, StopOutlined,
} from '@ant-design/icons'
import { dictApi } from '../../api/api'
import { useTableBodyHeight } from '../../hooks/useTableBodyHeight'
import PermGuard from '../../components/common/PermGuard'
import { col, styledTableComponents, INPUT_STYLE } from '../../components/common/tableComponents'
import PagePagination from '../../components/common/PagePagination'

const { Text } = Typography

const PAGE_GRADIENT = 'linear-gradient(135deg,#7c3aed,#a78bfa)'

interface DictType {
  id: number
  dictName: string
  dictType: string
  status: number
  remark?: string
  createTime?: string
}

interface DictData {
  id: number
  dictType: string
  dictLabel: string
  dictValue: string
  sort: number
  isDefault: number
  cssClass?: string
  status: number
  remark?: string
}

const CSS_COLORS = ['default', 'blue', 'green', 'red', 'orange', 'purple', 'cyan', 'pink', 'gold', 'lime', 'magenta', 'volcano', 'geekblue']

export default function DictManagePage() {
  const { ref, height: tableBodyH } = useTableBodyHeight()
  const [types, setTypes] = useState<DictType[]>([])
  const [loading, setLoading] = useState(false)
  const [current, setCurrent] = useState(1)
  const [pageSize, setPageSize] = useState(10)
  const [total, setTotal] = useState(0)
  const [typeModal, setTypeModal] = useState(false)
  const [editingType, setEditingType] = useState<DictType | null>(null)
  const [typeForm] = Form.useForm()

  const [dataDrawer, setDataDrawer] = useState(false)
  const [selectedType, setSelectedType] = useState<DictType | null>(null)
  const [dataList, setDataList] = useState<DictData[]>([])
  const [dataLoading, setDataLoading] = useState(false)
  const [dataModal, setDataModal] = useState(false)
  const [editingData, setEditingData] = useState<DictData | null>(null)
  const [dataForm] = Form.useForm()

  const [searchName, setSearchName] = useState('')
  const [searchType, setSearchType] = useState('')
  const [searchStatus, setSearchStatus] = useState<number | undefined>()

  const loadTypes = useCallback(async () => {
    setLoading(true)
    try {
      const res = await dictApi.typeList({ current, size: pageSize, dictName: searchName || undefined, dictType: searchType || undefined, status: searchStatus })
      const d = res.data?.data
      setTypes(d?.records ?? [])
      setTotal(d?.total ?? 0)
    } finally {
      setLoading(false)
    }
  }, [current, pageSize, searchName, searchType, searchStatus])

  useEffect(() => { loadTypes() }, [loadTypes])

  const loadData = async (type: DictType) => {
    setSelectedType(type)
    setDataDrawer(true)
    setDataLoading(true)
    try {
      const res = await dictApi.dataList(type.dictType)
      setDataList(res.data?.data ?? [])
    } finally {
      setDataLoading(false)
    }
  }

  const openTypeModal = (record?: DictType) => {
    setEditingType(record ?? null)
    if (record) typeForm.setFieldsValue({ ...record })
    else { typeForm.resetFields(); typeForm.setFieldsValue({ status: 1 }) }
    setTypeModal(true)
  }

  const handleTypeSave = async () => {
    const values = await typeForm.validateFields()
    if (editingType) {
      await dictApi.editType({ id: editingType.id, ...values })
      message.success('修改成功')
    } else {
      await dictApi.addType(values)
      message.success('新增成功')
    }
    setTypeModal(false)
    loadTypes()
  }

  const deleteType = async (id: number) => {
    await dictApi.deleteType(id)
    message.success('删除成功')
    loadTypes()
  }

  const openDataModal = (record?: DictData) => {
    setEditingData(record ?? null)
    if (record) {
      dataForm.setFieldsValue({ ...record })
    } else {
      dataForm.resetFields()
      dataForm.setFieldsValue({ dictType: selectedType?.dictType, sort: 0, isDefault: 0, status: 1 })
    }
    setDataModal(true)
  }

  const handleDataSave = async () => {
    const values = await dataForm.validateFields()
    if (editingData) {
      await dictApi.editData({ id: editingData.id, ...values })
    } else {
      await dictApi.addData(values)
    }
    message.success('保存成功')
    setDataModal(false)
    if (selectedType) {
      const res = await dictApi.dataList(selectedType.dictType)
      setDataList(res.data?.data ?? [])
    }
  }

  const deleteData = async (id: number) => {
    await dictApi.deleteData(id)
    message.success('删除成功')
    if (selectedType) {
      const res = await dictApi.dataList(selectedType.dictType)
      setDataList(res.data?.data ?? [])
    }
  }

  const handleSearch = () => {
    if (current === 1) loadTypes()
    else setCurrent(1)
  }

  const handleReset = () => {
    setSearchName('')
    setSearchType('')
    setSearchStatus(undefined)
    setCurrent(1)
  }

  const typeColumns = [
    {
      title: col(<BookOutlined style={{ color: '#6366f1' }} />, '字典名称'), dataIndex: 'dictName', key: 'dictName',
      render: (v: string) => (
        <Space>
          <div style={{ width: 30, height: 30, borderRadius: 8, background: 'linear-gradient(135deg,#4facfe,#00f2fe)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', fontSize: 14 }}>
            <BookOutlined />
          </div>
          <Text strong>{v}</Text>
        </Space>
      ),
    },
    {
      title: col(<TagOutlined style={{ color: '#6366f1' }} />, '类型'), dataIndex: 'dictType', key: 'dictType',
      render: (v: string) => <Tag color="blue" icon={<TagOutlined />} style={{ borderRadius: 6 }}>{v}</Tag>,
    },
    {
      title: col(<SafetyCertificateOutlined style={{ color: '#6366f1' }} />, '状态'), dataIndex: 'status', key: 'status',
      render: (v: number) => v === 1
        ? <Badge status="success" text={<span style={{ color: '#52c41a', fontWeight: 600 }}>正常</span>} />
        : <Badge status="error" text={<span style={{ color: '#ff4d4f', fontWeight: 600 }}>停用</span>} />,
    },
    {
      title: col(<FileTextOutlined style={{ color: '#6366f1' }} />, '备注'), dataIndex: 'remark', key: 'remark',
      render: (v: string) => <Text type="secondary" ellipsis={{ tooltip: v }} style={{ maxWidth: 180 }}>{v || '-'}</Text>,
    },
    {
      title: col(<SettingOutlined style={{ color: '#6366f1' }} />, '操作'), key: 'action', width: 235,
      render: (_: any, r: DictType) => (
        <Space size={4}>
          <Button size="small" type="primary" ghost icon={<UnorderedListOutlined />} onClick={() => loadData(r)} style={{ borderRadius: 6 }}>字典数据</Button>
          <PermGuard code="dict:edit">
            <Button size="small" icon={<EditOutlined />} onClick={() => openTypeModal(r)} style={{ borderRadius: 6, color: '#fa8c16', borderColor: '#ffd591' }}>编辑</Button>
          </PermGuard>
          <PermGuard code="dict:delete">
            <Popconfirm title="确认删除？将同时删除该字典下所有数据" onConfirm={() => deleteType(r.id)} okText="删除" cancelText="取消" okButtonProps={{ danger: true }}>
              <Button size="small" danger icon={<DeleteOutlined />} style={{ borderRadius: 6 }}>删除</Button>
            </Popconfirm>
          </PermGuard>
        </Space>
      ),
    },
  ]

  const dataColumns = [
    {
      title: '显示标签', dataIndex: 'dictLabel', key: 'dictLabel',
      render: (v: string, r: DictData) => (
        <Tag color={r.cssClass || 'default'} style={{ borderRadius: 6, fontWeight: 600, fontSize: 13 }}>{v}</Tag>
      ),
    },
    {
      title: '数据键值', dataIndex: 'dictValue', key: 'dictValue',
      render: (v: string) => <code style={{ background: '#f0f5ff', padding: '2px 8px', borderRadius: 4, color: '#1890ff' }}>{v}</code>,
    },
    { title: '排序', dataIndex: 'sort', key: 'sort'},
    {
      title: '默认', dataIndex: 'isDefault', key: 'isDefault',
      render: (v: number) => v === 1 ? <Tag color="success">是</Tag> : <Tag>否</Tag>,
    },
    {
      title: '状态', dataIndex: 'status', key: 'status',
      render: (v: number) => v === 1 ? <Badge status="success" text="正常" /> : <Badge status="error" text="停用" />,
    },
    {
      title: '操作', key: 'action', width: 145,
      render: (_: any, r: DictData) => (
        <Space size={4}>
          <PermGuard code="dict:edit">
            <Button size="small" icon={<EditOutlined />} onClick={() => openDataModal(r)}
              style={{ borderRadius: 6, color: '#fa8c16', borderColor: '#ffd591' }}>编辑</Button>
          </PermGuard>
          <PermGuard code="dict:delete">
            <Popconfirm title="确认删除该字典数据？" onConfirm={() => deleteData(r.id)} okText="删除" cancelText="取消" okButtonProps={{ danger: true }}>
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
          <div style={{ width: 34, height: 34, borderRadius: 10, background: PAGE_GRADIENT, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 4px 12px rgba(124,58,237,0.35)', flexShrink: 0 }}>
            <BookOutlined style={{ color: '#fff', fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1e293b', lineHeight: 1.2 }}>字典管理</div>
            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>管理系统字典类型 · 配置字典数据</div>
          </div>
          <div style={{ width: 1, height: 20, margin: '0 4px', background: '#e0e4ff', flexShrink: 0 }} />
          <div style={{ display: 'flex', gap: 8 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: 'rgba(99,102,241,0.1)', border: '1px solid rgba(99,102,241,0.25)' }}>
              <span>📋</span><span style={{ fontSize: 12, color: '#6b7280' }}>总数</span><span style={{ fontSize: 13, fontWeight: 700, color: '#6366f1' }}>{total}</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: 'rgba(34,197,94,0.1)', border: '1px solid rgba(34,197,94,0.25)' }}>
              <span>✓</span><span style={{ fontSize: 12, color: '#6b7280' }}>正常</span><span style={{ fontSize: 13, fontWeight: 700, color: '#16a34a' }}>{types.filter(t => t.status === 1).length}</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: 'rgba(239,68,68,0.08)', border: '1px solid rgba(239,68,68,0.22)' }}>
              <span>⏸</span><span style={{ fontSize: 12, color: '#6b7280' }}>停用</span><span style={{ fontSize: 13, fontWeight: 700, color: '#ef4444' }}>{types.filter(t => t.status === 0).length}</span>
            </div>
          </div>
          <div style={{ flex: 1 }} />
          <PermGuard code="dict:add">
            <Button type="primary" icon={<PlusOutlined />} onClick={() => openTypeModal()} style={{ borderRadius: 8, background: 'linear-gradient(135deg,#6366f1,#8b5cf6)', border: 'none' }}>新增</Button>
          </PermGuard>
        </div>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', padding: '10px 24px 12px' }}>
          <Input placeholder="字典名称" prefix={<BookOutlined style={{ color: '#7c3aed', fontSize: 12 }} />} value={searchName} onChange={e => setSearchName(e.target.value)} allowClear size="middle" style={{ width: 180, ...INPUT_STYLE }} />
          <Input placeholder="字典类型" prefix={<TagOutlined style={{ color: '#6366f1', fontSize: 12 }} />} value={searchType} onChange={e => setSearchType(e.target.value)} allowClear size="middle" style={{ width: 160, ...INPUT_STYLE }} />
          <Select placeholder={<Space size={4}><SafetyCertificateOutlined style={{ color: '#10b981', fontSize: 12 }} />字典状态</Space>} allowClear style={{ width: 115 }} value={searchStatus} onChange={v => setSearchStatus(v)}>
            <Select.Option value={1}><Space size={4}><CheckCircleOutlined style={{ color: '#10b981' }} />正常</Space></Select.Option>
            <Select.Option value={0}><Space size={4}><StopOutlined style={{ color: '#ef4444' }} />停用</Space></Select.Option>
          </Select>
          <div style={{ flex: 1 }} />
          <Button icon={<ReloadOutlined />} size="middle" style={{ borderRadius: 8 }} onClick={handleReset}>重置</Button>
          <Tooltip title="刷新"><Button icon={<ReloadOutlined />} size="middle" loading={loading} style={{ borderRadius: 8, color: '#6366f1', borderColor: '#c7d2fe' }} onClick={loadTypes} /></Tooltip>
          <Button type="primary" icon={<SearchOutlined />} style={{ borderRadius: 8, border: 'none', background: 'linear-gradient(135deg,#6366f1,#8b5cf6)' }} onClick={handleSearch}>搜索</Button>
        </div>
      </div>
      <div ref={ref} style={{ marginLeft: -24, marginRight: -24, marginBottom: -24, background: '#fff', borderTop: '1px solid #eef0f8' }}>
        <Table
          columns={typeColumns}
          dataSource={types}
          rowKey="id"
          loading={loading}
          pagination={false}
          components={styledTableComponents}
          scroll={{ x: 'max-content', y: tableBodyH }}
          size="middle"
        />
        <PagePagination total={total} current={current} pageSize={pageSize} onChange={p => setCurrent(p)} onSizeChange={setPageSize} countLabel="条字典" pageSizeOptions={[10, 20, 50, 100]} />
      </div>

      <Modal
        open={typeModal}
        onCancel={() => setTypeModal(false)}
        onOk={handleTypeSave}
        title={
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{ width: 32, height: 32, borderRadius: 8, background: 'linear-gradient(135deg,#4facfe,#00f2fe)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff' }}>
              <BookOutlined />
            </div>
            {editingType ? '编辑字典类型' : '新增字典类型'}
          </div>
        }
        okText="保存" width={880}
        styles={{ body: { maxHeight: 'calc(85vh - 150px)', overflowY: 'auto', overflowX: 'hidden' } }}
      >
        <Divider style={{ margin: '12px 0' }} />
        <Form form={typeForm} layout="vertical" size="large">
          <Form.Item name="dictName" label="字典名称" rules={[{ required: true, message: '请输入字典名称' }]}>
            <Input prefix={<BookOutlined />} placeholder="如：用户性别" style={{ borderRadius: 8 }} />
          </Form.Item>
          <Form.Item name="dictType" label="字典类型" rules={[{ required: true, message: '请输入字典类型' }]}>
            <Input prefix={<TagOutlined />} placeholder="如：sys_user_sex" disabled={!!editingType} style={{ borderRadius: 8 }} />
          </Form.Item>
          <Form.Item name="status" label="状态">
            <Select style={{ borderRadius: 8 }}>
              <Select.Option value={1}><Badge status="success" text="正常" /></Select.Option>
              <Select.Option value={0}><Badge status="error" text="停用" /></Select.Option>
            </Select>
          </Form.Item>
          <Form.Item name="remark" label="备注">
            <Input.TextArea rows={3} placeholder="请输入备注说明" style={{ borderRadius: 8 }} />
          </Form.Item>
        </Form>
      </Modal>

      <Drawer
        open={dataDrawer}
        onClose={() => setDataDrawer(false)}
        styles={{ wrapper: { width: 880 } }}
        title={
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{ width: 32, height: 32, borderRadius: 8, background: 'linear-gradient(135deg,#4facfe,#00f2fe)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff' }}>
              <BarsOutlined />
            </div>
            <div>
              <div style={{ fontWeight: 600 }}>{selectedType?.dictName} - 字典数据</div>
              <div style={{ fontSize: 12, color: '#999' }}>{selectedType?.dictType}</div>
            </div>
          </div>
        }
        extra={
          <PermGuard code="dict:add">
            <Button type="primary" icon={<PlusOutlined />} onClick={() => openDataModal()} style={{ borderRadius: 8 }}>新增数据</Button>
          </PermGuard>
        }
      >
        <Table
          columns={dataColumns}
          dataSource={dataList}
          rowKey="id"
          loading={dataLoading}
          pagination={false}
          size="small"
          components={styledTableComponents}
          scroll={{ x: 'max-content', y: 'calc(100vh - 220px)' }}
        />
      </Drawer>

      <Modal
        open={dataModal}
        onCancel={() => setDataModal(false)}
        onOk={handleDataSave}
        title={editingData ? '编辑字典数据' : '新增字典数据'}
        okText="保存" width={880}
        styles={{ body: { maxHeight: 'calc(85vh - 150px)', overflowY: 'auto', overflowX: 'hidden' } }}
      >
        <Form form={dataForm} layout="vertical" size="middle">
          <Form.Item name="dictType" label="字典类型" rules={[{ required: true }]}>
            <Input disabled style={{ borderRadius: 8 }} />
          </Form.Item>
          <Row gutter={12}>
            <Col span={12}>
              <Form.Item name="dictLabel" label="显示标签" rules={[{ required: true, message: '请输入显示标签' }]}>
                <Input placeholder="如：男" style={{ borderRadius: 8 }} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="dictValue" label="数据键值" rules={[{ required: true, message: '请输入数据键值' }]}>
                <Input placeholder="如：1" style={{ borderRadius: 8 }} />
              </Form.Item>
            </Col>
          </Row>
          <Row gutter={12}>
            <Col span={8}>
              <Form.Item name="sort" label="排序"><InputNumber style={{ width: '100%', borderRadius: 8 }} /></Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="cssClass" label="标签颜色">
                <Select placeholder="选择颜色" style={{ borderRadius: 8 }}>
                  {CSS_COLORS.map(c => <Select.Option key={c} value={c}><Tag color={c}>{c}</Tag></Select.Option>)}
                </Select>
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="isDefault" label="是否默认">
                <Select style={{ borderRadius: 8 }}>
                  <Select.Option value={1}>是</Select.Option>
                  <Select.Option value={0}>否</Select.Option>
                </Select>
              </Form.Item>
            </Col>
          </Row>
          <Form.Item name="remark" label="备注">
            <Input.TextArea rows={2} style={{ borderRadius: 8 }} />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  )
}
