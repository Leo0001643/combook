import { useState, useEffect, useCallback, useRef } from 'react';
import {
  Table, Space, Button, Tag, Typography,
  Select, InputNumber, message, Badge, Popconfirm, Drawer, Descriptions, Rate, Input, Form,
  Tooltip,
} from 'antd';
import {
  StarOutlined, EyeOutlined, EyeInvisibleOutlined, DeleteOutlined, StopOutlined,
  CheckCircleOutlined, ReloadOutlined, SearchOutlined, CommentOutlined, MessageOutlined,
  NumberOutlined, StarFilled, FileTextOutlined, IdcardOutlined, UserOutlined,
  SafetyCertificateOutlined, CalendarOutlined, SettingOutlined,
} from '@ant-design/icons';
import type { ColumnsType } from 'antd/es/table';
import { usePortalScope } from '../../hooks/usePortalScope';
import PermGuard from '../../components/common/PermGuard';
import { col, styledTableComponents } from '../../components/common/tableComponents';
import PagePagination from '../../components/common/PagePagination';
import { useTableBodyHeight } from '../../hooks/useTableBodyHeight'

const { Text } = Typography;

const PAGE_GRADIENT = 'linear-gradient(135deg,#f59e0b,#d97706)';

interface Review {
  id: number;
  orderId: number;
  memberId: number;
  technicianId: number;
  overallScore: number;
  techniqueScore: number;
  attitudeScore: number;
  punctualScore: number;
  content?: string;
  isAnonymous: number;
  reply?: string;
  status: number;
  createTime: string;
}

const ReviewPage: React.FC = () => {
  const { ref, height: tableBodyH } = useTableBodyHeight()
  const { isAdmin, isMerchant, reviewList, reviewUpdateStatus, reviewDelete, reviewReply } = usePortalScope();
  const [data, setData] = useState<Review[]>([]);
  const [loading, setLoading] = useState(false);
  const [total, setTotal] = useState(0);
  const [current, setCurrent] = useState(1);
  const [pageSize, setPageSize] = useState(10);
  const pageSizeRef = useRef(pageSize);
  pageSizeRef.current = pageSize;
  const [scoreFilter, setScoreFilter] = useState<number | undefined>();
  const [statusFilter, setStatusFilter] = useState<number | undefined>();
  const [techId, setTechId] = useState<number | undefined>();
  const [detailOpen, setDetailOpen] = useState(false);
  const [selected, setSelected] = useState<Review | null>(null);
  const [replyForm] = Form.useForm();
  const [replyVisible, setReplyVisible] = useState(false);

  const fetchData = useCallback(async (page: number, size = pageSizeRef.current) => {
    setLoading(true);
    try {
      const res = await reviewList({
        current: page, size,
        overallScore: scoreFilter,
        status: statusFilter,
        technicianId: techId,
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
  }, [scoreFilter, statusFilter, techId]);

  useEffect(() => { fetchData(1); }, []);

  const handleSearch = () => { setCurrent(1); fetchData(1); };

  const handleStatusToggle = async (record: Review) => {
    try {
      await reviewUpdateStatus(record.id, record.status === 1 ? 0 : 1);
      message.success('状态已更新');
      fetchData(current);
    } catch {
      message.error('操作失败');
    }
  };

  const handleDelete = async (id: number) => {
    try {
      await reviewDelete(id);
      message.success('已删除');
      fetchData(current);
    } catch {
      message.error('删除失败');
    }
  };

  const handleReply = async () => {
    const { reply } = await replyForm.validateFields();
    if (!selected) return;
    try {
      await reviewReply(selected.id, reply);
      message.success('回复成功');
      setReplyVisible(false);
      fetchData(current);
    } catch {
      message.error('回复失败');
    }
  };

  const avgScore = data.length > 0
    ? (data.reduce((s, r) => s + r.overallScore, 0) / data.length).toFixed(1)
    : '0.0';

  const fiveStarCount = data.filter(r => r.overallScore === 5).length;

  const columns: ColumnsType<Review> = [
    {
      title: col(<NumberOutlined style={{ color: '#6366f1' }} />, 'ID'), dataIndex: 'id',
      render: v => <Text type="secondary">#{v}</Text>,
    },
    {
      title: col(<StarFilled style={{ color: '#f59e0b' }} />, '评分'), dataIndex: 'overallScore',
      render: v => <Rate disabled defaultValue={v} style={{ fontSize: 14 }} />,
      sorter: (a, b) => a.overallScore - b.overallScore,
    },
    {
      title: col(<CommentOutlined style={{ color: '#6366f1' }} />, '内容'), dataIndex: 'content',
      render: v => v
        ? <Text ellipsis={{ tooltip: v }} style={{ maxWidth: 260 }}>{v}</Text>
        : <Text type="secondary">无文字评价</Text>,
    },
    {
      title: col(<FileTextOutlined style={{ color: '#6366f1' }} />, '订单ID'), dataIndex: 'orderId',
      render: v => <Tag color="blue">#{v}</Tag>,
    },
    {
      title: col(<IdcardOutlined style={{ color: '#6366f1' }} />, '技师'), dataIndex: 'technicianId',
      render: v => <Tag color="green">#{v}</Tag>,
    },
    {
      title: col(<UserOutlined style={{ color: '#6366f1' }} />, '会员'), dataIndex: 'memberId',
      render: (v, r) => (
        <Space orientation="vertical" size={0}>
          <Text>#{v}</Text>
          {r.isAnonymous === 1 && <Tag color="default" style={{ fontSize: 11 }}>匿名</Tag>}
        </Space>
      ),
    },
    {
      title: col(<SafetyCertificateOutlined style={{ color: '#6366f1' }} />, '状态'), dataIndex: 'status',
      render: s => <Badge status={s === 1 ? 'success' : 'error'} text={s === 1 ? '显示' : '屏蔽'} />,
    },
    {
      title: col(<CalendarOutlined style={{ color: '#6366f1' }} />, '时间'), dataIndex: 'createTime',
      render: v => v?.slice(0, 10),
    },
    {
      title: col(<SettingOutlined style={{ color: '#6366f1' }} />, '操作'), key: 'action', fixed: 'right', width: 225,
      render: (_, r) => (
        <Space size={4}>
          <Button size="small" type="primary" ghost icon={<EyeOutlined />}
            style={{ borderRadius: 6 }}
            onClick={() => { setSelected(r); setDetailOpen(true); }}>查看</Button>
          {isMerchant && (
            <PermGuard code="review:reply">
              <Button size="small" icon={<MessageOutlined />}
                style={{ borderRadius: 6, color: '#1677ff', borderColor: '#91caff' }}
                onClick={() => { setSelected(r); replyForm.setFieldsValue({ reply: r.reply ?? '' }); setReplyVisible(true); }}>回复</Button>
            </PermGuard>
          )}
          {isAdmin && (
            <>
              {r.status === 1 ? (
                <PermGuard code="review:toggle">
                  <Button size="small" icon={<StopOutlined />}
                    style={{ borderRadius: 6, color: '#fa8c16', borderColor: '#ffd591' }}
                    onClick={() => handleStatusToggle(r)}>隐藏</Button>
                </PermGuard>
              ) : (
                <PermGuard code="review:toggle">
                  <Button size="small" icon={<CheckCircleOutlined />}
                    style={{ borderRadius: 6, color: '#52c41a', borderColor: '#b7eb8f' }}
                    onClick={() => handleStatusToggle(r)}>显示</Button>
                </PermGuard>
              )}
              <PermGuard code="review:delete">
                <Popconfirm title="确认删除此评价？" onConfirm={() => handleDelete(r.id)} okText="删除" cancelText="取消" okButtonProps={{ danger: true }}>
                  <Button size="small" danger icon={<DeleteOutlined />} style={{ borderRadius: 6 }}>删除</Button>
                </Popconfirm>
              </PermGuard>
            </>
          )}
        </Space>
      ),
    },
  ];

  const handleReset = async () => {
    setScoreFilter(undefined);
    setStatusFilter(undefined);
    setTechId(undefined);
    setCurrent(1);
    setLoading(true);
    try {
      const res = await reviewList({
        current: 1, size: pageSizeRef.current,
        overallScore: undefined, status: undefined, technicianId: undefined,
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
  };

  return (
    <div style={{ marginTop: -24 }}>
      <div style={{ position: 'sticky', top: 64, zIndex: 88, marginLeft: -24, marginRight: -24, background: 'rgba(255,255,255,0.97)', backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)', borderBottom: '1px solid rgba(0,0,0,0.07)', boxShadow: '0 4px 20px rgba(0,0,0,0.06)' }}>
        <div style={{ display: 'flex', alignItems: 'center', padding: '10px 24px 0', gap: 12 }}>
          <div style={{ width: 34, height: 34, borderRadius: 10, background: PAGE_GRADIENT, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 4px 12px rgba(245,158,11,0.35)', flexShrink: 0 }}>
            <StarOutlined style={{ color: '#fff', fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1e293b', lineHeight: 1.2 }}>评价管理</div>
            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>审核用户评价 · 管理评分</div>
          </div>
          <div style={{ width: 1, height: 20, margin: '0 4px', background: '#e0e4ff', flexShrink: 0 }} />
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: 'rgba(99,102,241,0.1)', border: '1px solid rgba(99,102,241,0.25)' }}>
              <span>💬</span><span style={{ fontSize: 12, color: '#6b7280' }}>总数</span><span style={{ fontSize: 13, fontWeight: 700, color: '#6366f1' }}>{total}</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: 'rgba(245,158,11,0.12)', border: '1px solid rgba(245,158,11,0.28)' }}>
              <span>⭐</span><span style={{ fontSize: 12, color: '#6b7280' }}>均分</span><span style={{ fontSize: 13, fontWeight: 700, color: '#d97706' }}>{avgScore}</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: 'rgba(34,197,94,0.1)', border: '1px solid rgba(34,197,94,0.25)' }}>
              <span>🏆</span><span style={{ fontSize: 12, color: '#6b7280' }}>五星</span><span style={{ fontSize: 13, fontWeight: 700, color: '#16a34a' }}>{fiveStarCount}</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: 'rgba(239,68,68,0.08)', border: '1px solid rgba(239,68,68,0.22)' }}>
              <span>🚫</span><span style={{ fontSize: 12, color: '#6b7280' }}>已屏蔽</span><span style={{ fontSize: 13, fontWeight: 700, color: '#ef4444' }}>{data.filter(r => r.status === 0).length}</span>
            </div>
          </div>
          <div style={{ flex: 1 }} />
        </div>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', padding: '10px 24px 12px' }}>
          <Select placeholder={<Space size={4}><StarOutlined style={{ color: '#f59e0b', fontSize: 12 }} />评分</Space>} allowClear style={{ width: 90 }} value={scoreFilter} onChange={setScoreFilter}
            options={[5, 4, 3, 2, 1].map(s => ({ value: s, label: `${'★'.repeat(s)} ${s}星` }))}
          />
          <Select placeholder={<Space size={4}><SafetyCertificateOutlined style={{ color: '#6366f1', fontSize: 12 }} />状态</Space>} allowClear style={{ width: 90 }} value={statusFilter} onChange={setStatusFilter}
            options={[
              { value: 1, label: <Space size={4}><EyeOutlined style={{ color: '#10b981' }} />显示</Space> },
              { value: 0, label: <Space size={4}><EyeInvisibleOutlined style={{ color: '#ef4444' }} />屏蔽</Space> },
            ]}
          />
          <Space.Compact style={{ width: 140 }}>
            <Button style={{ pointerEvents: 'none', paddingInline: 8, color: '#6366f1', borderRight: 0 }} icon={<IdcardOutlined style={{ fontSize: 12 }} />} />
            <InputNumber
              placeholder="技师ID"
              value={techId}
              onChange={v => setTechId(v ?? undefined)}
              style={{ flex: 1 }}
              min={1}
            />
          </Space.Compact>
          <div style={{ flex: 1 }} />
          <Button icon={<ReloadOutlined />} size="middle" style={{ borderRadius: 8 }} onClick={handleReset}>重置</Button>
          <Tooltip title="刷新"><Button icon={<ReloadOutlined />} size="middle" loading={loading} style={{ borderRadius: 8, color: '#6366f1', borderColor: '#c7d2fe' }} onClick={() => fetchData(current)} /></Tooltip>
          <Button type="primary" icon={<SearchOutlined />} style={{ borderRadius: 8, border: 'none', background: 'linear-gradient(135deg,#6366f1,#8b5cf6)' }} onClick={handleSearch}>搜索</Button>
        </div>
      </div>
      <div ref={ref} style={{ marginLeft: -24, marginRight: -24, marginBottom: -24, background: '#fff', borderTop: '1px solid #eef0f8' }}>
        <Table
          columns={columns}
          dataSource={data}
          rowKey="id"
          loading={loading}
          pagination={false}
          components={styledTableComponents}
          scroll={{ x: 'max-content', y: tableBodyH }}
        />
        <PagePagination
          total={total}
          current={current}
          pageSize={pageSize}
          onChange={p => { setCurrent(p); fetchData(p); }}
          onSizeChange={s => { setPageSize(s); pageSizeRef.current = s; }}
          countLabel="条评价"
          pageSizeOptions={[10, 20, 50, 100]}
        />
      </div>

      <Drawer
        title={<Space><MessageOutlined style={{ color: '#1677ff' }} />回复客户评价</Space>}
        styles={{ wrapper: { width: 880 } }}
        open={replyVisible}
        onClose={() => setReplyVisible(false)}
        extra={
          <Button type="primary" onClick={handleReply}
            style={{ background: 'linear-gradient(135deg,#1677ff,#69b1ff)', border: 'none' }}>
            提交回复
          </Button>
        }
      >
        {selected && (
          <div style={{ padding: '0 4px' }}>
            <div style={{ background: '#fafafa', borderRadius: 8, padding: 12, marginBottom: 16 }}>
              <Rate disabled value={selected.overallScore} style={{ fontSize: 14 }} />
              <div style={{ marginTop: 8, color: '#595959' }}>{selected.content || '（无文字评价）'}</div>
            </div>
            <Form form={replyForm} layout="vertical">
              <Form.Item name="reply" label="回复内容" rules={[{ required: true, message: '请输入回复内容' }]}>
                <Input.TextArea rows={4} placeholder="感谢您的评价，我们会继续努力..." maxLength={300} showCount />
              </Form.Item>
            </Form>
          </div>
        )}
      </Drawer>

      <Drawer
        title="评价详情"
        styles={{ wrapper: { width: 880 } }}
        open={detailOpen}
        onClose={() => setDetailOpen(false)}
      >
        {selected && (
          <Descriptions bordered column={2} size="small">
            <Descriptions.Item label="评价ID">#{selected.id}</Descriptions.Item>
            <Descriptions.Item label="订单ID">#{selected.orderId}</Descriptions.Item>
            <Descriptions.Item label="会员ID">#{selected.memberId}</Descriptions.Item>
            <Descriptions.Item label="技师ID">#{selected.technicianId}</Descriptions.Item>
            <Descriptions.Item label="是否匿名">
              {selected.isAnonymous === 1 ? <Tag color="default">匿名</Tag> : <Tag color="blue">实名</Tag>}
            </Descriptions.Item>
            <Descriptions.Item label="状态">
              <Badge status={selected.status === 1 ? 'success' : 'error'}
                text={selected.status === 1 ? '显示' : '屏蔽'} />
            </Descriptions.Item>
            <Descriptions.Item label="综合评分" span={2}>
              <Rate disabled value={selected.overallScore} />
              <Text style={{ marginLeft: 8 }}>{selected.overallScore} 分</Text>
            </Descriptions.Item>
            <Descriptions.Item label="技术评分">
              <Rate disabled value={selected.techniqueScore} style={{ fontSize: 12 }} />
            </Descriptions.Item>
            <Descriptions.Item label="服务态度">
              <Rate disabled value={selected.attitudeScore} style={{ fontSize: 12 }} />
            </Descriptions.Item>
            <Descriptions.Item label="准时评分">
              <Rate disabled value={selected.punctualScore} style={{ fontSize: 12 }} />
            </Descriptions.Item>
            <Descriptions.Item label="评价时间">{selected.createTime?.slice(0, 16)}</Descriptions.Item>
            <Descriptions.Item label="评价内容" span={2}>
              {selected.content || <Text type="secondary">无文字评价</Text>}
            </Descriptions.Item>
            {selected.reply && (
              <Descriptions.Item label="技师回复" span={2}>{selected.reply}</Descriptions.Item>
            )}
          </Descriptions>
        )}
      </Drawer>
    </div>
  );
};

export default ReviewPage;
