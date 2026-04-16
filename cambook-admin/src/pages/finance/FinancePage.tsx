import { useState, useEffect, useCallback } from 'react';
import {
  Table, Tabs, Tag, Button, Space,
  Select, Typography, Badge, Spin, Divider,
} from 'antd';
import {
  DollarOutlined, WalletOutlined, UserOutlined,
} from '@ant-design/icons';
import type { ColumnsType } from 'antd/es/table';
import { financeApi } from '../../api/api';
import { usePortalScope } from '../../hooks/usePortalScope';
import MerchantFinanceView from '../merchant/FinanceView';
import PagePagination from '../../components/common/PagePagination';
import { styledTableComponents } from '../../components/common/tableComponents';
import { useTableBodyHeight } from '../../hooks/useTableBodyHeight';

const { Text } = Typography;

interface WalletRecord {
  id: number;
  memberId: number;
  recordType: number;
  amount: number;
  beforeBalance: number;
  afterBalance: number;
  bizNo?: string;
  remark?: string;
  createTime: string;
}

interface WalletVO {
  id: number;
  memberId: number;
  userType: number;
  balance: number;
  totalRecharge: number;
  totalWithdraw: number;
  totalConsume: number;
  status: number;
}

const recordTypeMap: Record<number, { text: string; color: string }> = {
  1: { text: '充值', color: 'green' },
  2: { text: '消费', color: 'red' },
  3: { text: '提现', color: 'orange' },
  4: { text: '退款', color: 'blue' },
  5: { text: '奖励', color: 'purple' },
};

const userTypeMap: Record<number, { text: string; color: string }> = {
  1: { text: '会员', color: 'blue' },
  2: { text: '技师', color: 'green' },
  3: { text: '商户', color: 'purple' },
};

const PAGE_GRADIENT = 'linear-gradient(135deg,#10b981,#059669)';

const AdminFinancePage: React.FC = () => {
  const { ref: refRecords, height: recordsH } = useTableBodyHeight()
  const { ref: refWallets, height: walletsH } = useTableBodyHeight()
  const [overview, setOverview] = useState<any>(null);
  const [records, setRecords] = useState<WalletRecord[]>([]);
  const [wallets, setWallets] = useState<WalletVO[]>([]);
  const [recordsTotal, setRecordsTotal] = useState(0);
  const [walletsTotal, setWalletsTotal] = useState(0);
  const [recordType, setRecordType] = useState<number | undefined>();
  const [userTypeFilter, setUserTypeFilter] = useState<number | undefined>();
  const [loading, setLoading] = useState(false);
  const [recordsPage, setRecordsPage] = useState(1);
  const [walletsPage, setWalletsPage] = useState(1);
  const [recordsPageSize, setRecordsPageSize] = useState(20);
  const [walletsPageSize, setWalletsPageSize] = useState(20);

  const loadOverview = useCallback(async () => {
    try {
      const res = await financeApi.overview();
      if (res.data?.code === 200) setOverview(res.data.data);
    } catch {}
  }, []);

  const loadRecords = useCallback(async () => {
    setLoading(true);
    try {
      const res = await financeApi.records({
        current: recordsPage,
        size: recordsPageSize,
        recordType,
      });
      if (res.data?.code === 200) {
        setRecords(res.data.data.records ?? []);
        setRecordsTotal(res.data.data.total ?? 0);
      }
    } catch {
    } finally {
      setLoading(false);
    }
  }, [recordsPage, recordsPageSize, recordType]);

  const loadWallets = useCallback(async () => {
    try {
      const res = await financeApi.wallets({
        current: walletsPage,
        size: walletsPageSize,
        userType: userTypeFilter,
      });
      if (res.data?.code === 200) {
        setWallets(res.data.data.records ?? []);
        setWalletsTotal(res.data.data.total ?? 0);
      }
    } catch {}
  }, [walletsPage, walletsPageSize, userTypeFilter]);

  useEffect(() => {
    void loadOverview();
  }, [loadOverview]);

  useEffect(() => {
    void loadRecords();
  }, [loadRecords]);

  useEffect(() => {
    void loadWallets();
  }, [loadWallets]);

  const recordColumns: ColumnsType<WalletRecord> = [
    {
      title: '流水ID', dataIndex: 'id',
      render: v => <Text type="secondary">#{v}</Text>,
    },
    {
      title: '用户ID', dataIndex: 'memberId',
      render: v => <Tag>{v}</Tag>,
    },
    {
      title: '类型', dataIndex: 'recordType',
      render: v => <Tag color={recordTypeMap[v]?.color}>{recordTypeMap[v]?.text ?? '—'}</Tag>,
    },
    {
      title: '金额', dataIndex: 'amount',
      render: (v, r) => {
        const isIn = r.recordType === 1 || r.recordType === 4 || r.recordType === 5;
        return <Text strong style={{ color: isIn ? '#52c41a' : '#ff4d4f' }}>
          {isIn ? '+' : '-'}${Number(v).toFixed(2)}
        </Text>;
      },
    },
    {
      title: '变动前余额', dataIndex: 'beforeBalance',
      render: v => <Text>${Number(v).toFixed(2)}</Text>,
    },
    {
      title: '变动后余额', dataIndex: 'afterBalance',
      render: v => <Text strong>${Number(v).toFixed(2)}</Text>,
    },
    {
      title: '业务单号', dataIndex: 'bizNo',
      render: v => v ? <Text copyable style={{ fontSize: 12 }}>{v}</Text> : '—',
    },
    {
      title: '备注', dataIndex: 'remark', ellipsis: true,
      render: v => v || '—',
    },
    {
      title: '时间', dataIndex: 'createTime',
      render: v => v?.slice(0, 16),
    },
  ];

  const walletColumns: ColumnsType<WalletVO> = [
    {
      title: '钱包ID', dataIndex: 'id',
      render: v => <Text type="secondary">#{v}</Text>,
    },
    {
      title: '用户ID', dataIndex: 'memberId',
      render: v => <Space><UserOutlined />{v}</Space>,
    },
    {
      title: '用户类型', dataIndex: 'userType',
      render: v => <Tag color={userTypeMap[v]?.color}>{userTypeMap[v]?.text ?? '—'}</Tag>,
    },
    {
      title: '当前余额', dataIndex: 'balance',
      render: v => <Text strong style={{ color: '#52c41a', fontSize: 15 }}>${Number(v).toFixed(2)}</Text>,
      sorter: (a, b) => a.balance - b.balance,
    },
    {
      title: '累计充值', dataIndex: 'totalRecharge',
      render: v => <Text style={{ color: '#1677ff' }}>${Number(v).toFixed(2)}</Text>,
    },
    {
      title: '累计消费', dataIndex: 'totalConsume',
      render: v => <Text style={{ color: '#722ed1' }}>${Number(v).toFixed(2)}</Text>,
    },
    {
      title: '累计提现', dataIndex: 'totalWithdraw',
      render: v => <Text style={{ color: '#fa8c16' }}>${Number(v).toFixed(2)}</Text>,
    },
    {
      title: '状态', dataIndex: 'status',
      render: s => <Badge status={s === 1 ? 'success' : 'error'} text={s === 1 ? '正常' : '冻结'} />,
    },
  ];

  const headerStats = [
    {
      icon: '💵', label: '钱包总余额',
      value: `$${Number(overview?.totalBalance ?? 0).toFixed(2)}`,
      bg: '#ecfdf5', border: '#a7f3d0', color: '#059669',
    },
    {
      icon: '📈', label: '累计充值',
      value: `$${Number(overview?.totalRecharge ?? 0).toFixed(2)}`,
      bg: '#eff6ff', border: '#bfdbfe', color: '#2563eb',
    },
    {
      icon: '📋', label: '流水总笔数',
      value: overview?.totalRecords ?? 0,
      bg: '#eef2ff', border: '#c7d2fe', color: '#4f46e5',
    },
    {
      icon: '✅', label: '提现笔数',
      value: overview?.withdrawCount ?? 0,
      bg: '#fffbeb', border: '#fde68a', color: '#d97706',
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
        <div style={{ display: 'flex', alignItems: 'center', padding: '10px 24px 12px', gap: 12 }}>
          <div style={{
            width: 34, height: 34, borderRadius: 10, background: PAGE_GRADIENT,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 4px 12px rgba(16,185,129,0.35)', flexShrink: 0,
          }}>
            <DollarOutlined style={{ color: '#fff', fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1e293b', lineHeight: 1.2 }}>财务管理</div>
            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>资金流水与钱包总览 · 平台财务数据</div>
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
        </div>
      </div>

      <Tabs
        defaultActiveKey="records"
        style={{ marginTop: 0 }}
        items={[
          {
            key: 'records',
            label: <Space><WalletOutlined />资金流水</Space>,
            children: (
              <div ref={refRecords} style={{
                marginLeft: -24, marginRight: -24, marginBottom: -24,
                background: '#fff', borderTop: '1px solid #eef0f8',
              }}>
                <div style={{ padding: '12px 24px 0' }}>
                  <Space style={{ marginBottom: 8 }}>
                    <Select
                      placeholder="流水类型"
                      value={recordType}
                      onChange={v => { setRecordType(v); setRecordsPage(1); }}
                      allowClear
                      style={{ width: 120 }}
                      options={Object.entries(recordTypeMap).map(([k, v]) => ({ value: Number(k), label: v.text }))}
                    />
                    <Button onClick={() => void loadRecords()}>刷新</Button>
                  </Space>
                </div>
                <Spin spinning={loading}>
                  <Table
                    columns={recordColumns}
                    dataSource={records}
                    rowKey="id"
                    components={styledTableComponents}
                    scroll={{ x: 'max-content', y: recordsH }}
                    pagination={false}
                  />
                </Spin>
                <PagePagination
                  total={recordsTotal}
                  current={recordsPage}
                  pageSize={recordsPageSize}
                  onChange={setRecordsPage}
                  onSizeChange={setRecordsPageSize}
                  countLabel="条流水"
                />
              </div>
            ),
          },
          {
            key: 'wallets',
            label: <Space><DollarOutlined />钱包列表</Space>,
            children: (
              <div ref={refWallets} style={{
                marginLeft: -24, marginRight: -24, marginBottom: -24,
                background: '#fff', borderTop: '1px solid #eef0f8',
              }}>
                <div style={{ padding: '12px 24px 0' }}>
                  <Space style={{ marginBottom: 8 }}>
                    <Select
                      placeholder="用户类型"
                      value={userTypeFilter}
                      onChange={v => { setUserTypeFilter(v); setWalletsPage(1); }}
                      allowClear
                      style={{ width: 120 }}
                      options={Object.entries(userTypeMap).map(([k, v]) => ({ value: Number(k), label: v.text }))}
                    />
                    <Button onClick={() => void loadWallets()}>刷新</Button>
                  </Space>
                </div>
                <Table
                  columns={walletColumns}
                  dataSource={wallets}
                  rowKey="id"
                  components={styledTableComponents}
                  scroll={{ x: 'max-content', y: walletsH }}
                  pagination={false}
                />
                <PagePagination
                  total={walletsTotal}
                  current={walletsPage}
                  pageSize={walletsPageSize}
                  onChange={setWalletsPage}
                  onSizeChange={setWalletsPageSize}
                  countLabel="个钱包"
                />
              </div>
            ),
          },
        ]}
      />
    </div>
  );
};

const FinancePage: React.FC = () => {
  const { isMerchant } = usePortalScope();
  return isMerchant ? <MerchantFinanceView /> : <AdminFinancePage />;
};

export default FinancePage;
