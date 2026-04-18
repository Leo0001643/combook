import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  Card, Row, Col, Descriptions, Tag, Button, Space, Timeline,
  Steps, Divider, Typography, Avatar, Statistic, Modal, Input, message, Spin, Empty
} from 'antd';
import {
  ArrowLeftOutlined, UserOutlined, PhoneOutlined, EnvironmentOutlined,
  ClockCircleOutlined, CreditCardOutlined, StarOutlined,
  StopOutlined, FileTextOutlined, ReloadOutlined
} from '@ant-design/icons';
import { usePortalScope } from '../../hooks/usePortalScope';
import { useDict } from '../../hooks/useDict';

const { Text } = Typography;
const { TextArea } = Input;

const STATUS_CONFIG_FB: Record<number, { text: string; color: string }> = {
  0: { text: '待支付',  color: 'warning'    },
  1: { text: '待服务',  color: 'processing' },
  2: { text: '已接单',  color: 'blue'       },
  3: { text: '服务中',  color: 'geekblue'   },
  4: { text: '已完成',  color: 'success'    },
  5: { text: '已取消',  color: 'default'    },
  6: { text: '退款中',  color: 'orange'     },
  7: { text: '已退款',  color: 'default'    },
};

const PAY_METHOD_CONFIG_FB: Record<number, { text: string; color: string }> = {
  1: { text: 'USDT',    color: 'gold'  },
  2: { text: 'ABA转账', color: 'blue'  },
  3: { text: '余额支付', color: 'green' },
  4: { text: '微信',    color: 'green' },
  5: { text: '支付宝',  color: 'blue'  },
};

const STEPS = [
  { title: '待支付', description: '等待用户付款' },
  { title: '待服务', description: '已支付，等待技师' },
  { title: '服务中', description: '技师正在服务' },
  { title: '已完成', description: '服务完成' },
];

const OrderDetailPage: React.FC = () => {
  const { orderId } = useParams<{ orderId: string }>();
  const navigate   = useNavigate();
  const { orderDetail, orderCancel } = usePortalScope();

  const { items: statusItems } = useDict('order_status');
  const { items: payItems }    = useDict('pay_type');

  const STATUS_CONFIG: Record<number, { text: string; color: string }> =
    statusItems.length > 0
      ? Object.fromEntries(statusItems.map(i => [Number(i.dictValue), { text: i.labelZh, color: i.remark ?? 'default' }]))
      : STATUS_CONFIG_FB;

  const PAY_METHOD_CONFIG: Record<number, { text: string; color: string }> =
    payItems.length > 0
      ? Object.fromEntries(payItems.map(i => [Number(i.dictValue), { text: i.labelZh, color: i.remark ?? 'default' }]))
      : PAY_METHOD_CONFIG_FB;

  const [order, setOrder]                   = useState<any>(null);
  const [loading, setLoading]               = useState(true);
  const [cancelModalOpen, setCancelModalOpen] = useState(false);
  const [cancelReason, setCancelReason]     = useState('');
  const [cancelling, setCancelling]         = useState(false);

  const fetchDetail = async () => {
    if (!orderId) return;
    setLoading(true);
    try {
      const res = await orderDetail(Number(orderId));
      setOrder(res.data?.data ?? null);
    } catch {
      setOrder(null);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchDetail(); }, [orderId]); // eslint-disable-line

  const handleForceCancel = async () => {
    if (!cancelReason.trim()) { message.warning('请填写取消原因'); return; }
    if (!order) return;
    setCancelling(true);
    try {
      await orderCancel(order.id);
      message.success('订单已取消');
      setCancelModalOpen(false);
      fetchDetail();
    } catch {
      // 拦截器处理
    } finally {
      setCancelling(false);
    }
  };

  if (loading) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: 400 }}>
        <Spin size="large" />
      </div>
    );
  }

  if (!order) {
    return (
      <div style={{ padding: 40 }}>
        <Button icon={<ArrowLeftOutlined />} onClick={() => navigate(-1)} style={{ marginBottom: 24 }}>返回</Button>
        <Empty description="订单不存在或无权查看" />
      </div>
    );
  }

  const statusInfo   = STATUS_CONFIG[order.status]     ?? { text: '未知', color: 'default' };
  const payInfo      = PAY_METHOD_CONFIG[order.paymentMethod] ?? { text: '未知', color: 'default' };
  const currentStep  = order.status >= 4 ? 3 : Math.max(0, order.status);

  return (
    <div style={{ padding: '0 0 40px' }}>
      {/* 顶部导航 */}
      <Card
        variant="borderless"
        style={{ borderRadius: 0, marginBottom: 16, boxShadow: '0 1px 4px rgba(0,0,0,0.06)' }}
        styles={{ body: { padding: '16px 24px' } }}
      >
        <Space align="center" size={16}>
          <Button icon={<ArrowLeftOutlined />} onClick={() => navigate(-1)} type="text" style={{ fontWeight: 600 }}>
            返回
          </Button>
          <div style={{ width: 1, height: 20, background: '#e5e7eb', flexShrink: 0 }} />
          <Text strong style={{ fontSize: 16 }}>订单详情</Text>
          <Tag color={statusInfo.color} style={{ fontSize: 13, padding: '2px 10px' }}>{statusInfo.text}</Tag>
          <Text type="secondary" style={{ fontSize: 12 }}>#{order.orderNo}</Text>
        </Space>
      </Card>

      <div style={{ padding: '0 24px' }}>
        {/* 订单进度条 */}
        {![5, 6, 7].includes(order.status) && (
          <Card variant="borderless" style={{ borderRadius: 12, marginBottom: 16 }}
            title={<Text strong>📋 订单进度</Text>}>
            <Steps current={currentStep} items={STEPS} style={{ padding: '8px 0' }} />
          </Card>
        )}

        <Row gutter={16}>
          {/* 左侧 — 主要信息 */}
          <Col xs={24} lg={16}>
            {/* 服务信息 */}
            <Card variant="borderless" style={{ borderRadius: 12, marginBottom: 16 }}
              title={<Space><FileTextOutlined style={{ color: '#6366F1' }} /><Text strong>服务信息</Text></Space>}>
              <Descriptions column={{ xs: 1, sm: 2 }} size="small">
                <Descriptions.Item label="服务项目">
                  <Text strong>{order.serviceName ?? order.service?.name ?? '—'}</Text>
                </Descriptions.Item>
                {order.service?.category && (
                  <Descriptions.Item label="服务分类">{order.service.category}</Descriptions.Item>
                )}
                {(order.service?.duration ?? order.duration) && (
                  <Descriptions.Item label="服务时长">{order.service?.duration ?? order.duration} 分钟</Descriptions.Item>
                )}
                {order.appointmentTime && (
                  <Descriptions.Item label="预约时间">
                    <Space><ClockCircleOutlined style={{ color: '#6366F1' }} />{order.appointmentTime}</Space>
                  </Descriptions.Item>
                )}
                {order.serviceAddress && (
                  <Descriptions.Item label="服务地址" span={2}>
                    <Space><EnvironmentOutlined style={{ color: '#FF6B6B' }} />{order.serviceAddress}</Space>
                  </Descriptions.Item>
                )}
                {order.remarks && (
                  <Descriptions.Item label="备注" span={2}>
                    <Text type="secondary">{order.remarks}</Text>
                  </Descriptions.Item>
                )}
              </Descriptions>
            </Card>

            {/* 会员信息 */}
            {(order.member || order.memberNickname) && (
              <Card variant="borderless" style={{ borderRadius: 12, marginBottom: 16 }}
                title={<Space><UserOutlined style={{ color: '#10B981' }} /><Text strong>会员信息</Text></Space>}>
                <Row gutter={16} align="middle">
                  <Col flex="none">
                    <Avatar size={52} src={order.member?.avatar}
                      style={{ background: 'linear-gradient(135deg,#6366F1,#8B5CF6)', color: '#fff', fontSize: 20 }}>
                      {(order.member?.name ?? order.memberNickname ?? '?').charAt(0)}
                    </Avatar>
                  </Col>
                  <Col flex="auto">
                    <Space direction="vertical" size={2}>
                      <Text strong style={{ fontSize: 15 }}>{order.member?.name ?? order.memberNickname}</Text>
                      {order.member?.phone && (
                        <Space>
                          <PhoneOutlined style={{ color: '#6B7280' }} />
                          <Text type="secondary">{order.member.phone}</Text>
                        </Space>
                      )}
                    </Space>
                  </Col>
                </Row>
              </Card>
            )}

            {/* 技师信息 */}
            {(order.technician || order.technicianNickname) && (
              <Card variant="borderless" style={{ borderRadius: 12, marginBottom: 16 }}
                title={<Space><StarOutlined style={{ color: '#F59E0B' }} /><Text strong>技师信息</Text></Space>}>
                <Row gutter={16} align="middle">
                  <Col flex="none">
                    <Avatar size={52} src={order.technician?.avatar}
                      style={{ background: 'linear-gradient(135deg,#F59E0B,#EF4444)', color: '#fff', fontSize: 20 }}>
                      {(order.technician?.name ?? order.technicianNickname ?? '?').charAt(0)}
                    </Avatar>
                  </Col>
                  <Col flex="auto">
                    <Space direction="vertical" size={2}>
                      <Text strong style={{ fontSize: 15 }}>{order.technician?.name ?? order.technicianNickname}</Text>
                      {order.technician?.rating != null && (
                        <Space>
                          <StarOutlined style={{ color: '#F59E0B' }} />
                          <Text>{order.technician.rating}</Text>
                        </Space>
                      )}
                      {order.technician?.phone && (
                        <Space>
                          <PhoneOutlined style={{ color: '#6B7280' }} />
                          <Text type="secondary">{order.technician.phone}</Text>
                        </Space>
                      )}
                    </Space>
                  </Col>
                </Row>
              </Card>
            )}

            {/* 订单时间轴 */}
            {order.timeline?.length > 0 && (
              <Card variant="borderless" style={{ borderRadius: 12, marginBottom: 16 }}
                title={<Space><ClockCircleOutlined style={{ color: '#6366F1' }} /><Text strong>操作记录</Text></Space>}>
                <Timeline
                  items={order.timeline.map((item: any) => ({
                    color: '#6366F1',
                    children: (
                      <div>
                        <Text strong>{item.event}</Text>
                        <br />
                        <Text type="secondary" style={{ fontSize: 12 }}>{item.desc}</Text>
                        <br />
                        <Text type="secondary" style={{ fontSize: 11, color: '#9CA3AF' }}>{item.time}</Text>
                      </div>
                    ),
                  }))}
                />
              </Card>
            )}
          </Col>

          {/* 右侧 — 金额与操作 */}
          <Col xs={24} lg={8}>
            <Card variant="borderless" style={{ borderRadius: 12, marginBottom: 16 }}
              title={<Space><CreditCardOutlined style={{ color: '#10B981' }} /><Text strong>金额明细</Text></Space>}>
              <Row gutter={[12, 16]}>
                {order.amount != null && (
                  <Col span={12}><Statistic title="服务原价" value={`$${(+order.amount).toFixed(2)}`}
                    styles={{ content: { fontSize: 16, color: '#374151' } }} /></Col>
                )}
                {order.discountAmount != null && (
                  <Col span={12}><Statistic title="优惠减免" value={`-$${(+order.discountAmount).toFixed(2)}`}
                    styles={{ content: { fontSize: 16, color: '#10B981' } }} /></Col>
                )}
                {order.payAmount != null && (
                  <Col span={12}><Statistic title="实付金额" value={`$${(+order.payAmount).toFixed(2)}`}
                    styles={{ content: { fontSize: 16, color: '#EF4444', fontWeight: 700 } }} /></Col>
                )}
                {order.technicianIncome != null && (
                  <Col span={12}><Statistic title="技师收入" value={`$${(+order.technicianIncome).toFixed(2)}`}
                    styles={{ content: { fontSize: 14, color: '#6366F1' } }} /></Col>
                )}
              </Row>
              <Divider style={{ margin: '12px 0' }} />
              <Descriptions column={1} size="small">
                <Descriptions.Item label="支付方式">
                  <Tag color={payInfo.color}>{payInfo.text}</Tag>
                </Descriptions.Item>
                {order.coupon?.name && (
                  <Descriptions.Item label="优惠券">{order.coupon.name}</Descriptions.Item>
                )}
                {order.createTime && (
                  <Descriptions.Item label="下单时间">{order.createTime}</Descriptions.Item>
                )}
                {order.payTime && (
                  <Descriptions.Item label="支付时间">{order.payTime}</Descriptions.Item>
                )}
              </Descriptions>
            </Card>

            {/* 操作区 */}
            <Card variant="borderless" style={{ borderRadius: 12 }} title={<Text strong>操作</Text>}>
              <Space direction="vertical" style={{ width: '100%' }}>
                {[0, 1, 2, 3].includes(order.status) && (
                  <Button block danger icon={<StopOutlined />}
                    onClick={() => setCancelModalOpen(true)} style={{ borderRadius: 8 }}>
                    强制取消订单
                  </Button>
                )}
                <Button block icon={<ReloadOutlined />} onClick={fetchDetail} style={{ borderRadius: 8 }}>
                  刷新
                </Button>
                <Button block icon={<FileTextOutlined />} onClick={() => navigate(-1)} style={{ borderRadius: 8 }}>
                  返回
                </Button>
              </Space>
            </Card>
          </Col>
        </Row>
      </div>

      {/* 强制取消弹窗 */}
      <Modal
        title="强制取消订单"
        open={cancelModalOpen}
        onCancel={() => setCancelModalOpen(false)}
        confirmLoading={cancelling}
        onOk={handleForceCancel}
        okText="确认取消"
        okButtonProps={{ danger: true }}
        cancelText="返回"
        centered
      >
        <p>订单号：<Text strong>#{order.orderNo}</Text></p>
        <p style={{ color: '#6B7280', fontSize: 13, marginBottom: 12 }}>
          强制取消后，已支付金额将自动退款到用户账户，此操作不可撤销。
        </p>
        <TextArea rows={3} placeholder="请填写取消原因（必填）"
          value={cancelReason} onChange={e => setCancelReason(e.target.value)} style={{ borderRadius: 8 }} />
      </Modal>
    </div>
  );
};

export default OrderDetailPage;
