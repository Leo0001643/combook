import { useState, useEffect, useMemo } from 'react'
import {
  Table, Button, Space, Tag, Typography, message,
  Modal, Form, Input, InputNumber, Select, Badge, Row, Col, TreeSelect, Popconfirm, Divider, Tooltip,
} from 'antd'
import type { ColumnsType } from 'antd/es/table'
import {
  AppstoreOutlined, PlusOutlined, EditOutlined, DeleteOutlined,
  CheckCircleOutlined, StopOutlined, ReloadOutlined, SearchOutlined,
  SortAscendingOutlined, ApartmentOutlined, SafetyCertificateOutlined, CalendarOutlined, SettingOutlined,
} from '@ant-design/icons'
import { usePortalScope } from '../../hooks/usePortalScope'
import PermGuard from '../../components/common/PermGuard'
import { col, styledTableComponents, INPUT_STYLE } from '../../components/common/tableComponents'
import PagePagination from '../../components/common/PagePagination'
import { useTableBodyHeight } from '../../hooks/useTableBodyHeight'

const { Text } = Typography
const { Option } = Select

const PAGE_GRADIENT = 'linear-gradient(135deg,#0891b2,#0ea5e9)'

interface CategoryVO {
  id: number
  parentId: number
  nameZh: string
  nameEn?: string
  nameKm?: string
  icon?: string
  sort: number
  status: number
  createTime?: string
  children?: CategoryVO[]
}

function buildTree(list: CategoryVO[]): CategoryVO[] {
  const map: Record<number, CategoryVO> = {}
  const roots: CategoryVO[] = []
  list.forEach(c => { map[c.id] = { ...c, children: [] } })
  list.forEach(c => {
    if (c.parentId === 0) roots.push(map[c.id])
    else if (map[c.parentId]) {
      map[c.parentId].children = map[c.parentId].children ?? []
      map[c.parentId].children!.push(map[c.id])
    }
  })
  return roots
}

function toTreeSelectData(list: CategoryVO[]): any[] {
  return list
    .filter(c => c.parentId === 0)
    .map(c => ({ value: c.id, label: c.nameZh }))
}

export default function CategoryPage() {
  const { ref, height: tableBodyH } = useTableBodyHeight()
  const { isMerchant, categoryList, categoryAdd, categoryEdit, categoryDelete } = usePortalScope()
  const [data, setData] = useState<CategoryVO[]>([])
  const [flat, setFlat] = useState<CategoryVO[]>([])
  const [loading, setLoading] = useState(false)
  const [modalOpen, setModalOpen] = useState(false)
  const [editing, setEditing] = useState<CategoryVO | null>(null)
  const [keyword, setKeyword] = useState('')
  const [page, setPage] = useState(1)
  const [pageSize, setPageSize] = useState(20)
  const [form] = Form.useForm()

  useEffect(() => { loadData() }, [])

  const loadData = async () => {
    setLoading(true)
    try {
      const res = await categoryList()
      const list: CategoryVO[] = res.data?.data ?? []
      setFlat(list)
      setData(buildTree(list))
    } catch {
      message.error('加载失败')
    } finally {
      setLoading(false)
    }
  }

  const openAdd = (parentId = 0) => {
    setEditing(null)
    form.resetFields()
    form.setFieldsValue({ parentId, status: 1, sort: 0 })
    setModalOpen(true)
  }

  const openEdit = (r: CategoryVO) => {
    setEditing(r)
    form.setFieldsValue({
      parentId: r.parentId,
      nameZh: r.nameZh,
      nameEn: r.nameEn,
      nameKm: r.nameKm,
      icon: r.icon,
      sort: r.sort,
      status: r.status,
    })
    setModalOpen(true)
  }

  const handleSubmit = async () => {
    const values = await form.validateFields()
    try {
      if (editing) {
        await categoryEdit({ id: editing.id, ...values })
        message.success('修改成功')
      } else {
        await categoryAdd(values)
        message.success('添加成功')
      }
      setModalOpen(false)
      loadData()
    } catch {
      message.error('操作失败')
    }
  }

  const handleDelete = (r: CategoryVO) => {
    Modal.confirm({
      title: `确认删除分类 "${r.nameZh}"？`,
      content: '若存在子分类请先删除子分类。',
      okType: 'danger',
      onOk: async () => {
        try {
          await categoryDelete(r.id)
          message.success('已删除')
          loadData()
        } catch (e: any) {
          message.error(e?.response?.data?.message || '删除失败')
        }
      },
    })
  }

  const filteredList = useMemo(() => {
    if (!keyword) return []
    return flat.filter(c => c.nameZh.includes(keyword) || c.nameEn?.toLowerCase().includes(keyword.toLowerCase()))
  }, [keyword, flat])

  const pagedKeywordRows = useMemo(() => {
    if (!keyword) return []
    const start = (page - 1) * pageSize
    return filteredList.slice(start, start + pageSize)
  }, [keyword, filteredList, page, pageSize])

  const tableData = keyword ? pagedKeywordRows : data

  useEffect(() => { setPage(1) }, [keyword])

  useEffect(() => {
    if (!keyword) return
    const max = Math.max(1, Math.ceil(filteredList.length / pageSize) || 1)
    if (page > max) setPage(max)
  }, [keyword, filteredList.length, pageSize, page])

  const columns: ColumnsType<CategoryVO> = [
    {
      title: col(<SortAscendingOutlined style={{ color: '#0891b2' }} />, '排序'), dataIndex: 'sort',
      render: v => (
        <div style={{
          width: 28, height: 28, borderRadius: 8,
          background: 'linear-gradient(135deg,#43e97b,#38f9d7)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: '#fff', fontWeight: 700, fontSize: 12,
        }}>{v}</div>
      ),
    },
    {
      title: col(<AppstoreOutlined style={{ color: '#0891b2' }} />, '分类名称', 'left'), key: 'name',
      render: (_, r) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, width: '100%' }}>
          <div style={{
            width: 38, height: 38, borderRadius: 10, flexShrink: 0,
            background: r.status === 1 ? 'linear-gradient(135deg,#43e97b,#38f9d7)' : '#f5f5f5',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <AppstoreOutlined style={{ color: r.status === 1 ? '#fff' : '#ccc', fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontWeight: 600, fontSize: 14 }}>{r.nameZh}</div>
            {r.nameEn && <Text type="secondary" style={{ fontSize: 12 }}>{r.nameEn}</Text>}
          </div>
        </div>
      ),
    },
    {
      title: col(<ApartmentOutlined style={{ color: '#0891b2' }} />, '层级'), dataIndex: 'parentId',
      render: v => <Tag color={v === 0 ? 'geekblue' : 'cyan'}>{v === 0 ? '一级' : '二级'}</Tag>,
    },
    {
      title: col(<SafetyCertificateOutlined style={{ color: '#0891b2' }} />, '状态'), dataIndex: 'status',
      render: s => <Badge status={s === 1 ? 'success' : 'error'} text={s === 1 ? '启用' : '停用'} />,
    },
    {
      title: col(<CalendarOutlined style={{ color: '#0891b2' }} />, '创建时间'), dataIndex: 'createTime',
      render: v => v?.slice(0, 10) ?? '—',
    },
    {
      title: col(<SettingOutlined style={{ color: '#0891b2' }} />, '操作'), width: 235,
      render: (_, r) => (
        <Space size={4}>
          {r.parentId === 0 && (
            <PermGuard code="category:add">
              <Button size="small" type="primary" ghost icon={<PlusOutlined />}
                style={{ borderRadius: 6 }}
                onClick={() => openAdd(r.id)}>添加子类</Button>
            </PermGuard>
          )}
          <PermGuard code="category:edit">
            <Button size="small" icon={<EditOutlined />}
              style={{ borderRadius: 6, color: '#fa8c16', borderColor: '#ffd591' }}
              onClick={() => openEdit(r)}>编辑</Button>
          </PermGuard>
          <PermGuard code="category:delete">
            <Popconfirm title="确认删除该类目？" onConfirm={() => handleDelete(r)} okText="删除" cancelText="取消" okButtonProps={{ danger: true }}>
              <Button size="small" danger icon={<DeleteOutlined />} style={{ borderRadius: 6 }}>删除</Button>
            </Popconfirm>
          </PermGuard>
        </Space>
      ),
    },
  ]

  const activeCount = flat.filter(c => c.status === 1).length

  const subtitle = isMerchant
    ? '管理服务分类层级 · 配置显示状态 · 平台类目只读，可维护本店私有类目'
    : '管理服务分类层级 · 配置显示状态'

  return (
    <div style={{ marginTop: -24 }}>
      <div style={{ position: 'sticky', top: 64, zIndex: 88, marginLeft: -24, marginRight: -24, background: 'rgba(255,255,255,0.97)', backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)', borderBottom: '1px solid rgba(0,0,0,0.07)', boxShadow: '0 4px 20px rgba(0,0,0,0.06)' }}>
        <div style={{ display: 'flex', alignItems: 'center', padding: '10px 24px 0', gap: 12 }}>
          <div style={{ width: 34, height: 34, borderRadius: 10, background: PAGE_GRADIENT, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 4px 12px rgba(8,145,178,0.3)', flexShrink: 0 }}>
            <AppstoreOutlined style={{ color: '#fff', fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1e293b', lineHeight: 1.2 }}>服务类目</div>
            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>{subtitle}</div>
          </div>
          <div style={{ width: 1, height: 20, margin: '0 4px', background: '#e0e4ff', flexShrink: 0 }} />
          <div style={{ display: 'flex', gap: 8 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: 'rgba(8,145,178,0.1)', border: '1px solid rgba(8,145,178,0.25)' }}>
              <span>📊</span>
              <span style={{ fontSize: 12, color: '#6b7280' }}>类目总数</span>
              <span style={{ fontSize: 13, fontWeight: 700, color: '#0891b2' }}>{flat.length}</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: 'rgba(34,197,94,0.1)', border: '1px solid rgba(34,197,94,0.25)' }}>
              <span>✓</span>
              <span style={{ fontSize: 12, color: '#6b7280' }}>启用</span>
              <span style={{ fontSize: 13, fontWeight: 700, color: '#16a34a' }}>{activeCount}</span>
            </div>
          </div>
          <div style={{ flex: 1 }} />
          <Tooltip title="刷新列表"><Button icon={<ReloadOutlined />} style={{ borderRadius: 8, color: '#0891b2', borderColor: '#a5f3fc' }} onClick={loadData} /></Tooltip>
        </div>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', padding: '10px 24px 12px' }}>
          <Input
            placeholder="搜索分类名称"
            prefix={<SearchOutlined style={{ color: '#94a3b8' }} />}
            value={keyword}
            onChange={e => setKeyword(e.target.value)}
            allowClear
            style={{ width: 180, ...INPUT_STYLE }}
          />
          <div style={{ flex: 1 }} />
          <PermGuard code="category:add">
            <Button type="primary" icon={<PlusOutlined />} onClick={() => openAdd(0)}
              style={{ borderRadius: 8, border: 'none', background: PAGE_GRADIENT, color: '#fff' }}>
              新增一级类目
            </Button>
          </PermGuard>
        </div>
      </div>
      <div ref={ref} style={{ marginLeft: -24, marginRight: -24, marginBottom: -24, background: '#fff', borderTop: '1px solid #eef0f8' }}>
        <Table
          rowKey="id"
          columns={columns}
          dataSource={tableData}
          loading={loading}
          pagination={false}
          components={styledTableComponents}
          scroll={{ x: 'max-content', y: tableBodyH }}
          expandable={keyword ? undefined : {
            defaultExpandAllRows: true,
            expandRowByClick: false,
          }}
        />
        {keyword ? (
          <PagePagination
            total={filteredList.length}
            current={page}
            pageSize={pageSize}
            onChange={setPage}
            onSizeChange={setPageSize}
            countLabel="条记录"
          />
        ) : null}
      </div>

      <Modal
        title={
          <div style={{
            background: editing
              ? 'linear-gradient(135deg,#38f9d7,#667eea)'
              : 'linear-gradient(135deg,#43e97b,#38f9d7)',
            margin: '-20px -24px 20px',
            padding: '18px 24px',
            borderRadius: '8px 8px 0 0',
            display: 'flex', alignItems: 'center', gap: 12,
          }}>
            <div style={{
              width: 40, height: 40, borderRadius: 10,
              background: 'rgba(255,255,255,0.25)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <AppstoreOutlined style={{ color: '#fff', fontSize: 20 }} />
            </div>
            <div>
              <div style={{ color: '#fff', fontWeight: 800, fontSize: 16 }}>
                {editing ? '编辑类目' : '新增类目'}
              </div>
              <div style={{ color: 'rgba(255,255,255,0.85)', fontSize: 12, marginTop: 2 }}>
                {editing ? '完善分类信息，让服务结构更清晰' : '🗂️ 完善服务分类，让顾客轻松找到所需！'}
              </div>
            </div>
          </div>
        }
        open={modalOpen}
        onCancel={() => setModalOpen(false)}
        onOk={handleSubmit}
        okText="保存" cancelText="取消"
        okButtonProps={{ style: { background: 'linear-gradient(135deg,#43e97b,#38f9d7)', border: 'none', borderRadius: 8 } }}
        cancelButtonProps={{ style: { borderRadius: 8 } }}
        width={880}
      >
        <Form form={form} layout="vertical">
          <Row gutter={16}>
            <Col span={8}>
              <Form.Item name="nameZh" label="中文名称" rules={[{ required: true, message: '请输入中文名称' }]}>
                <Input prefix={<AppstoreOutlined style={{ color: '#43e97b' }} />} placeholder="如：全身按摩" />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="nameEn" label="英文名称">
                <Input prefix={<AppstoreOutlined style={{ color: '#38f9d7' }} />} placeholder="Full Body Massage" />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="nameKm" label="高棉文名称">
                <Input placeholder="ម៉ាស្សា" />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="icon" label="图标">
                <Input placeholder="如 💆 或图标URL" />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="sort" label="排序">
                <InputNumber min={0} style={{ width: '100%' }} />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="status" label="状态">
                <Select>
                  <Option value={1}><Space><CheckCircleOutlined style={{ color: '#52c41a' }} />启用</Space></Option>
                  <Option value={0}><Space><StopOutlined style={{ color: '#ff4d4f' }} />停用</Space></Option>
                </Select>
              </Form.Item>
            </Col>
            <Col span={24}>
              <Form.Item name="parentId" label="上级分类">
                <TreeSelect
                  placeholder="不选则为一级类目"
                  allowClear
                  treeData={[{ value: 0, label: '顶级类目（一级）' }, ...toTreeSelectData(flat)]}
                  style={{ width: '100%' }}
                />
              </Form.Item>
            </Col>
          </Row>
        </Form>
      </Modal>
    </div>
  )
}
