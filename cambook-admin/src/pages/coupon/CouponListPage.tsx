import { useState, useEffect, useCallback } from 'react';
import {
  Table, Tag, Button, Space, Row, Col,
  Modal, Form, Input, Select, InputNumber,
  Typography, Progress, message, Popconfirm, Switch,
  Divider, Tooltip,
} from 'antd';
import {
  PlusOutlined, EditOutlined, DeleteOutlined, GiftOutlined,
  SearchOutlined, ReloadOutlined, TagsOutlined, TagOutlined, DollarOutlined,
  ShoppingCartOutlined, TeamOutlined, CalendarOutlined,
  SafetyCertificateOutlined, SettingOutlined, ShopOutlined,
  PercentageOutlined, CheckCircleOutlined, StopOutlined,
} from '@ant-design/icons';
import type { ColumnsType } from 'antd/es/table';
import { usePortalScope } from '../../hooks/usePortalScope';
import { merchantApi } from '../../api/api';
import PermGuard from '../../components/common/PermGuard';
import PagePagination from '../../components/common/PagePagination';
import { col, INPUT_STYLE, styledTableComponents } from '../../components/common/tableComponents';

const { Text } = Typography;

interface Coupon {
  id: number;
  nameZh: string;
  nameEn?: string;
  type: number;
  value: number;
  minAmount: number;
  totalCount: number;
  issuedCount: number;
  validDays?: number;
  startTime?: string;
  endTime?: string;
  status: number;
}

const typeMap: Record<number, { text: string; color: string }> = {
  1: { text: '满减券', color: 'red' },
  2: { text: '折扣券', color: 'purple' },
};

const PAGE_GRADIENT = 'linear-gradient(135deg,#f59e0b,#d97706)';

const CouponListPage: React.FC = () => {
  const { isMerchant, couponList, couponAdd, couponEdit, couponUpdateStatus, couponDelete } = usePortalScope();
  const [data, setData]               = useState<Coupon[]>([]);
  const [loading, setLoading]         = useState(false);
  const [total, setTotal]             = useState(0);
  const [current, setCurrent]         = useState(1);
  const [pageSize, setPageSize]       = useState(20);
  const [keyword, setKeyword]         = useState('');
  const [typeFilter, setTypeFilter]   = useState<number | undefined>();
  const [statusFilter, setStatusFilter] = useState<number | undefined>();
  const [merchantId, setMerchantId]   = useState<number | undefined>();
  const [merchantOpts, setMerchantOpts] = useState<{ value: number; label: string }[]>([]);
  const [modalVisible, setModalVisible] = useState(false);
  const [editing, setEditing]         = useState<Coupon | null>(null);
  const [form]                        = Form.useForm();

  useEffect(() => {
    if (!isMerchant) {
      merchantApi.list({ page: 1, size: 200 }).then(res => {
        const list = res.data?.data?.list ?? res.data?.data?.records ?? [];
        setMerchantOpts(list.map((m: any) => ({ value: m.id, label: m.name })));
      }).catch(() => {});
    }
  }, [isMerchant]);

  type FetchOverrides = Partial<{ keyword: string; type: number | undefined; status: number | undefined; merchantId: number | undefined }>;

  const fetchData = useCallback(async (page = current, overrides?: FetchOverrides) => {
    setLoading(true);
    try {
      const kw  = overrides?.keyword     !== undefined ? overrides.keyword     : keyword;
      const tf  = overrides?.type        !== undefined ? overrides.type        : typeFilter;
      const sf  = overrides?.status      !== undefined ? overrides.status      : statusFilter;
      const mid = overrides?.merchantId  !== undefined ? overrides.merchantId  : merchantId;
      const res = await couponList({
        current: page,
        size: pageSize,
        keyword: kw || undefined,
        type: tf,
        status: sf,
        ...(mid != null ? { merchantId: mid } : {}),
      });
      if (res.data?.code === 200) {
        setData(res.data.data.list ?? []);
        setTotal(res.data.data.total ?? 0);
      }
    } catch {
      message.error('加载失败');
    } finally {
      setLoading(false);
    }
  }, [current, pageSize, keyword, typeFilter, statusFilter, couponList]);

  useEffect(() => {
    fetchData(current);
    // Intentionally omit fetchData: include keyword/type/status would refetch every keystroke.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [current, pageSize]);

  const handleSearch = () => { setCurrent(1); fetchData(1); };
  const handleReset = () => {
    setKeyword('');
    setTypeFilter(undefined);
    setStatusFilter(undefined);
    setMerchantId(undefined);
    setCurrent(1);
    fetchData(1, { keyword: '', type: undefined, status: undefined, merchantId: undefined });
  };

  const openCreate = () => {
    setEditing(null);
    form.resetFields();
    form.setFieldsValue({ type: 1, status: 1, totalCount: 100, minAmount: 0 });
    setModalVisible(true);
  };

  const openEdit = (r: Coupon) => {
    setEditing(r);
    form.setFieldsValue({
      nameZh: r.nameZh,
      nameEn: r.nameEn,
      type: r.type,
      value: r.value,
      minAmount: r.minAmount,
      totalCount: r.totalCount,
      validDays: r.validDays,
      status: r.status,
    });
    setModalVisible(true);
  };

  const handleSubmit = async () => {
    const values = await form.validateFields();
    try {
      if (editing) {
        await couponEdit({ id: editing.id, ...values });
        message.success('修改成功');
      } else {
        await couponAdd(values);
        message.success('创建成功');
      }
      setModalVisible(false);
      fetchData(current);
    } catch {
      message.error('操作失败');
    }
  };

  const handleDelete = async (id: number) => {
    try {
      await couponDelete(id);
      message.success('已删除');
      fetchData(current);
    } catch {
      message.error('删除失败');
    }
  };

  const handleStatusToggle = async (record: Coupon) => {
    try {
      await couponUpdateStatus(record.id, record.status === 1 ? 0 : 1);
      message.success('状态已更新');
      fetchData(current);
    } catch {
      message.error('操作失败');
    }
  };

  const activeCount = data.filter(c => c.status === 1).length;
  const disabledCount = data.filter(c => c.status === 0).length;

  const headerStats = [
    { icon: '🎁', label: '优惠券总数', value: total, bg: '#fffbeb', border: '#fde68a', color: '#d97706' },
    { icon: '✅', label: '启用', value: activeCount, bg: '#ecfdf5', border: '#a7f3d0', color: '#059669' },
    { icon: '⏸️', label: '停用', value: disabledCount, bg: '#f3f4f6', border: '#e5e7eb', color: '#6b7280' },
  ];

  const columns: ColumnsType<Coupon> = [
    {
      title: col(<GiftOutlined style={{ color: '#f59e0b' }} />, '优惠券名称', 'left'),
      key: 'name',
      render: (_, r) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, width: '100%' }}>
          <div style={{
            width: 36, height: 36, borderRadius: 8, flexShrink: 0,
            background: typeMap[r.type]?.color === 'red'
              ? 'linear-gradient(135deg,#ff4d4f,#ff7875)'
              : 'linear-gradient(135deg,#9254de,#b37feb)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <GiftOutlined style={{ color: '#fff', fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontWeight: 600, fontSize: 13 }}>{r.nameZh}</div>
            {r.nameEn && <Text type="secondary" style={{ fontSize: 11 }}>{r.nameEn}</Text>}
          </div>
        </div>
      ),
    },
    {
      title: col(<TagsOutlined style={{ color: '#2563eb' }} />, '类型'),
      dataIndex: 'type',
      render: v => <Tag color={typeMap[v]?.color}>{typeMap[v]?.text ?? '—'}</Tag>,
    },
    {
      title: col(<DollarOutlined style={{ color: '#10b981' }} />, '优惠金额'),
      key: 'value',
      render: (_, r) => (
        <Text strong style={{ color: '#f5222d', fontSize: 15 }}>
          {r.type === 1 ? `减 $${r.value}` : `${(r.value * 100).toFixed(0)}折`}
        </Text>
      ),
    },
    {
      title: col(<ShoppingCartOutlined style={{ color: '#8b5cf6' }} />, '使用门槛'),
      dataIndex: 'minAmount',
      render: v => v > 0 ? <Text>满 ${v}</Text> : <Text type="secondary">无门槛</Text>,
    },
    {
      title: col(<TeamOutlined style={{ color: '#2563eb' }} />, '发放/总量'),
      key: 'count',
      render: (_, r) => {
        const pct = r.totalCount > 0 ? Math.round((r.issuedCount / r.totalCount) * 100) : 0;
        return (
          <div>
            <div style={{ fontSize: 12, marginBottom: 4 }}>
              <Text strong>{r.issuedCount}</Text>
              <Text type="secondary"> / {r.totalCount}</Text>
            </div>
            <Progress percent={pct} size="small" showInfo={false}
              strokeColor={pct > 80 ? '#ff4d4f' : '#52c41a'} />
          </div>
        );
      },
    },
    {
      title: col(<CalendarOutlined style={{ color: '#ef4444' }} />, '有效期'),
      key: 'validity',
      render: (_, r) => r.validDays
        ? <Tag color="cyan">{r.validDays} 天</Tag>
        : r.endTime ? <Text style={{ fontSize: 12 }}>{r.endTime?.slice(0, 10)}</Text>
          : <Text type="secondary">—</Text>,
    },
    {
      title: col(<SafetyCertificateOutlined style={{ color: '#10b981' }} />, '状态'),
      dataIndex: 'status',
      render: (s, r) => (
        <Switch checked={s === 1} checkedChildren="启用" unCheckedChildren="停用"
          onChange={() => handleStatusToggle(r)} />
      ),
    },
    {
      title: col(<SettingOutlined style={{ color: '#9ca3af' }} />, '操作'),
      key: 'action', fixed: 'right', width: 145,
      render: (_, r) => (
        <Space size={4}>
          <Button size="small" icon={<EditOutlined />}
            style={{ borderRadius: 6, color: '#fa8c16', borderColor: '#ffd591' }}
            onClick={() => openEdit(r)}>编辑</Button>
          <Popconfirm title="确认删除该优惠券？" onConfirm={() => handleDelete(r.id)} okText="删除" cancelText="取消" okButtonProps={{ danger: true }}>
            <Button size="small" danger icon={<DeleteOutlined />} style={{ borderRadius: 6 }}>删除</Button>
          </Popconfirm>
        </Space>
      ),
    },
  ];

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
            width: 34, height: 34, borderRadius: 10, background: PAGE_GRADIENT,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 4px 12px rgba(245,158,11,0.35)', flexShrink: 0,
          }}>
            <GiftOutlined style={{ color: '#fff', fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1e293b', lineHeight: 1.2 }}>优惠券管理</div>
            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>
              {isMerchant ? '管理本店优惠券 · 配置满减折扣 · 吸引更多客户' : '创建和管理平台优惠券 · 配置满减折扣 · 追踪发放数量'}
            </div>
          </div>
          <Divider type="vertical" style={{ height: 20, margin: '0 4px', borderColor: '#e0e4ff' }} />
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            {headerStats.map((s, i) => (
              <div key={i} style={{
                display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20,
                background: s.bg, border: `1px solid ${s.border}`,
              }}>
                <span style={{ fontSize: 13 }}>{s.icon}</span>
                <span style={{ fontSize: 12, color: '#6b7280' }}>{s.label}</span>
                <span style={{ fontSize: 13, fontWeight: 700, color: s.color }}>{s.value}</span>
              </div>
            ))}
          </div>
          <div style={{ flex: 1 }} />
          <PermGuard code="coupon:add">
            <Button type="primary" icon={<PlusOutlined />} onClick={openCreate}
              style={{
                borderRadius: 8, border: 'none',
                background: 'linear-gradient(135deg,#6366f1,#8b5cf6)',
                boxShadow: '0 2px 8px rgba(99,102,241,0.35)',
              }}>
              新增优惠券
            </Button>
          </PermGuard>
        </div>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', padding: '10px 24px 12px' }}>
          <Input
            placeholder="搜索优惠券名称"
            prefix={<SearchOutlined style={{ color: '#f59e0b' }} />}
            value={keyword} onChange={e => setKeyword(e.target.value)}
            onPressEnter={handleSearch} allowClear
            style={{ ...INPUT_STYLE, width: 180 }}
          />
          {!isMerchant && (
            <Select
              placeholder={<span><ShopOutlined style={{ color: '#6366f1', marginRight: 4 }} />所属商户</span>}
              allowClear
              size="middle"
              style={{ width: 160 }}
              value={merchantId}
              onChange={v => { setMerchantId(v); setCurrent(1); fetchData(1, { merchantId: v }) }}
              showSearch
              filterOption={(input, opt) =>
                String(opt?.label ?? '').toLowerCase().includes(input.toLowerCase())
              }
              options={merchantOpts}
            />
          )}
          <Select
            placeholder={<Space size={4}><TagsOutlined style={{ color: '#f59e0b', fontSize: 12 }} />券类型</Space>}
            value={typeFilter}
            onChange={setTypeFilter}
            allowClear
            style={{ ...INPUT_STYLE, width: 105 }}
            options={[
              { value: 1, label: <Space size={4}><TagOutlined style={{ color: '#f59e0b' }} />满减券</Space> },
              { value: 2, label: <Space size={4}><PercentageOutlined style={{ color: '#6366f1' }} />折扣券</Space> },
            ]}
          />
          <Select
            placeholder={<Space size={4}><SafetyCertificateOutlined style={{ color: '#10b981', fontSize: 12 }} />状态</Space>}
            value={statusFilter}
            onChange={setStatusFilter}
            allowClear
            style={{ ...INPUT_STYLE, width: 90 }}
            options={[
              { value: 1, label: <Space size={4}><CheckCircleOutlined style={{ color: '#10b981' }} />启用中</Space> },
              { value: 0, label: <Space size={4}><StopOutlined style={{ color: '#ef4444' }} />已停用</Space> },
            ]}
          />
          <div style={{ flex: 1 }} />
          <Button icon={<ReloadOutlined />} size="middle" style={{ borderRadius: 8 }} onClick={handleReset}>重置</Button>
          <Tooltip title="刷新列表">
            <Button
              icon={<ReloadOutlined />}
              size="middle"
              loading={loading}
              style={{ borderRadius: 8, color: '#6366f1', borderColor: '#c7d2fe' }}
              onClick={() => fetchData(current)}
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
          >
            搜索
          </Button>
        </div>
      </div>

      <div style={{
        marginLeft: -24, marginRight: -24, marginBottom: -24,
        background: '#fff', borderTop: '1px solid #eef0f8',
      }}>
        <Table
          columns={columns}
          dataSource={data}
          rowKey="id"
          loading={loading}
          components={styledTableComponents}
          scroll={{ x: 'max-content', y: 'calc(100vh - 272px)' }}
          pagination={false}
        />
        <PagePagination
          total={total}
          current={current}
          pageSize={pageSize}
          onChange={p => setCurrent(p)}
          onSizeChange={setPageSize}
          countLabel="张优惠券"
        />
      </div>

      <Modal
        title={
          <div style={{
            background: editing
              ? 'linear-gradient(135deg,#7c3aed,#a855f7)'
              : 'linear-gradient(135deg,#ec4899,#a855f7)',
            margin: '-20px -24px 20px',
            padding: '18px 24px',
            borderRadius: '8px 8px 0 0',
            display: 'flex', alignItems: 'center', gap: 12,
          }}>
            <div style={{
              width: 40, height: 40, borderRadius: 10,
              background: 'rgba(255,255,255,0.2)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <GiftOutlined style={{ color: '#fff', fontSize: 20 }} />
            </div>
            <div>
              <div style={{ color: '#fff', fontWeight: 800, fontSize: 16 }}>
                {editing ? '编辑优惠券' : '新增优惠券'}
              </div>
              <div style={{ color: 'rgba(255,255,255,0.8)', fontSize: 12, marginTop: 2 }}>
                {editing ? '修改优惠配置，让促销更精准' : '🎁 创建专属优惠，让每位顾客感受你的诚意！'}
              </div>
            </div>
          </div>
        }
        open={modalVisible}
        onCancel={() => setModalVisible(false)}
        onOk={handleSubmit}
        okText="保存" cancelText="取消"
        okButtonProps={{ style: { background: 'linear-gradient(135deg,#ec4899,#a855f7)', border: 'none', borderRadius: 8 } }}
        cancelButtonProps={{ style: { borderRadius: 8 } }}
        width={880}
        styles={{ body: { maxHeight: 'calc(85vh - 150px)', overflowY: 'auto', overflowX: 'hidden' } }}
      >
        <Form form={form} layout="vertical">
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="nameZh" label="优惠券名称（中文）" rules={[{ required: true }]}>
                <Input prefix={<GiftOutlined style={{ color: '#ec4899' }} />} placeholder="如：新用户首单立减30" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="nameEn" label="优惠券名称（英文）">
                <Input prefix={<GiftOutlined style={{ color: '#a855f7' }} />} placeholder="New User $30 Off" />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="type" label="券类型" rules={[{ required: true }]}>
                <Select options={[{ value: 1, label: '满减券' }, { value: 2, label: '折扣券' }]} />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="value" label="优惠金额/折扣" rules={[{ required: true }]}>
                <InputNumber min={0} style={{ width: '100%' }} placeholder="满减填金额，折扣填0.8" />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="minAmount" label="使用门槛（$0=无门槛）">
                <InputNumber min={0} style={{ width: '100%' }} />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="totalCount" label="发放总量" rules={[{ required: true }]}>
                <InputNumber min={1} style={{ width: '100%' }} />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="validDays" label="有效天数（领取后）">
                <InputNumber min={1} style={{ width: '100%' }} placeholder="如 30" />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="status" label="状态">
                <Select options={[{ value: 1, label: '启用' }, { value: 0, label: '停用' }]} />
              </Form.Item>
            </Col>
          </Row>
        </Form>
      </Modal>
    </div>
  );
};

export default CouponListPage;
