import React, { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  Card, Row, Col, Descriptions, Tag, Button, Space, Timeline,
  Steps, Divider, Typography, Avatar, Statistic, Modal, Input, message
} from 'antd';
import {
  ArrowLeftOutlined, UserOutlined, PhoneOutlined, EnvironmentOutlined,
  ClockCircleOutlined, CreditCardOutlined, StarOutlined,
  MessageOutlined, StopOutlined, FileTextOutlined
} from '@ant-design/icons';

const { Text } = Typography;
const { TextArea } = Input;

/** 订单状态配置 */
const statusConfig: Record<number, { text: string; color: string }> = {
  0: { text: '待支付', color: 'warning' },
  1: { text: '待服务', color: 'processing' },
  2: { text: '已接单', color: 'blue' },
  3: { text: '服务中', color: 'geekblue' },
  4: { text: '已完成', color: 'success' },
  5: { text: '已取消', color: 'default' },
  6: { text: '退款中', color: 'orange' },
  7: { text: '已退款', color: 'default' },
};

/** 支付方式配置 */
const payMethodConfig: Record<number, { text: string; color: string }> = {
  1: { text: 'USDT', color: 'gold' },
  2: { text: 'ABA转账', color: 'blue' },
  3: { text: '余额支付', color: 'green' },
  4: { text: '微信', color: 'green' },
  5: { text: '支付宝', color: 'blue' },
};

// ==================== 模拟数据 ====================
const mockOrder = {
  id: 1,
  orderNo: 'CB20260412001',
  status: 3,
  paymentMethod: 1,
  amount: 45.00,
  discountAmount: 5.00,
  payAmount: 40.00,
  technicianIncome: 32.00,
  platformCommission: 8.00,
  createTime: '2026-04-12 10:30:00',
  payTime: '2026-04-12 10:32:00',
  appointmentTime: '2026-04-12 14:00:00',
  startTime: '2026-04-12 14:05:00',
  serviceAddress: 'BKK1, Chamkarmon, Building 5, Room 201, Phnom Penh',
  remarks: '请带精油，需要深层按摩',
  member: { id: 10001, name: 'Sokha Chan', phone: '+855 12 345 678', avatar: '', level: '黄金会员', orderCount: 8 },
  technician: { id: 20001, name: '陈秀玲', phone: '+86 139 xxxx 5678', rating: 4.9, completedOrders: 226, avatar: '' },
  service: { id: 1, name: '全身精油 SPA', category: '精油按摩', duration: 90, originalPrice: 50.00, memberPrice: 45.00 },
  coupon: { id: 'u1', name: '新用户5元券', discount: 5.00 },
  timeline: [
    { time: '2026-04-12 10:30:00', event: '用户下单', desc: '用户提交订单' },
    { time: '2026-04-12 10:32:00', event: '支付成功', desc: 'USDT 支付 $40.00' },
    { time: '2026-04-12 10:35:00', event: '技师接单', desc: '陈秀玲接受服务' },
    { time: '2026-04-12 13:55:00', event: '技师出发', desc: '技师前往服务地址' },
    { time: '2026-04-12 14:05:00', event: '服务开始', desc: '技师已到达，服务开始' },
  ],
  review: null,
};

const OrderDetailPage: React.FC = () => {
  const { orderNo } = useParams<{ orderNo: string }>();
  const navigate = useNavigate();
  const [cancelModalOpen, setCancelModalOpen] = useState(false);
  const [cancelReason, setCancelReason] = useState('');
  const [cancelling, setCancelling] = useState(false);

  const order = { ...mockOrder, orderNo: orderNo || mockOrder.orderNo };
  const statusInfo = statusConfig[order.status];
  const payInfo = payMethodConfig[order.paymentMethod];

  const handleForceCancel = async () => {
    if (!cancelReason.trim()) {
      message.warning('请填写取消原因');
      return;
    }
    setCancelling(true);
    await new Promise(r => setTimeout(r, 800));
    setCancelling(false);
    setCancelModalOpen(false);
    message.success('订单已强制取消');
  };

  const steps = [
    { title: '待支付', description: '等待用户付款' },
    { title: '待服务', description: '已支付，等待技师' },
    { title: '服务中', description: '技师正在服务' },
    { title: '已完成', description: '服务完成' },
  ];
  const currentStep = order.status >= 4 ? 3 : order.status;

  return (
    <div style={{ padding: '0 0 40px' }}>
      {/* 顶部导航 */}
      <Card
        variant="borderless"
        style={{ borderRadius: 0, marginBottom: 16, boxShadow: '0 1px 4px rgba(0,0,0,0.06)' }}
        styles={{ body: { padding: '16px 24px' } }}
      >
        <Space align="center" size={16}>
          <Button
            icon={<ArrowLeftOutlined />}
            onClick={() => navigate('/order')}
            type="text"
            style={{ fontWeight: 600 }}
          >
            返回订单列表
          </Button>
          <Divider type="vertical" />
          <Text strong style={{ fontSize: 16 }}>订单详情</Text>
          <Tag color={statusInfo.color} style={{ fontSize: 13, padding: '2px 10px' }}>
            {statusInfo.text}
          </Tag>
          <Text type="secondary" style={{ fontSize: 12 }}>#{order.orderNo}</Text>
        </Space>
      </Card>

      <div style={{ padding: '0 24px' }}>
        {/* 订单进度条 */}
        {order.status !== 5 && order.status !== 6 && order.status !== 7 && (
          <Card
            variant="borderless"
            style={{ borderRadius: 12, marginBottom: 16 }}
            title={<Text strong>📋 订单进度</Text>}
          >
            <Steps
              current={currentStep}
              items={steps}
              style={{ padding: '8px 0' }}
            />
          </Card>
        )}

        <Row gutter={16}>
          {/* 左侧 — 主要信息 */}
          <Col xs={24} lg={16}>
            {/* 服务信息 */}
            <Card
              variant="borderless"
              style={{ borderRadius: 12, marginBottom: 16 }}
              title={<Space><FileTextOutlined style={{ color: '#6366F1' }} /><Text strong>服务信息</Text></Space>}
            >
              <Descriptions column={{ xs: 1, sm: 2 }} size="small">
                <Descriptions.Item label="服务项目">
                  <Text strong>{order.service.name}</Text>
                </Descriptions.Item>
                <Descriptions.Item label="服务分类">{order.service.category}</Descriptions.Item>
                <Descriptions.Item label="服务时长">{order.service.duration} 分钟</Descriptions.Item>
                <Descriptions.Item label="预约时间">
                  <Space><ClockCircleOutlined style={{ color: '#6366F1' }} />{order.appointmentTime}</Space>
                </Descriptions.Item>
                <Descriptions.Item label="服务地址" span={2}>
                  <Space><EnvironmentOutlined style={{ color: '#FF6B6B' }} />{order.serviceAddress}</Space>
                </Descriptions.Item>
                {order.remarks && (
                  <Descriptions.Item label="备注" span={2}>
                    <Text type="secondary">{order.remarks}</Text>
                  </Descriptions.Item>
                )}
              </Descriptions>
            </Card>

            {/* 会员信息 */}
            <Card
              variant="borderless"
              style={{ borderRadius: 12, marginBottom: 16 }}
              title={<Space><UserOutlined style={{ color: '#10B981' }} /><Text strong>会员信息</Text></Space>}
            >
              <Row gutter={16} align="middle">
                <Col flex="none">
                  <Avatar size={52} style={{ background: 'linear-gradient(135deg, #6366F1, #8B5CF6)', color: '#fff', fontSize: 20 }}>
                    {order.member.name.charAt(0)}
                  </Avatar>
                </Col>
                <Col flex="auto">
                  <Space orientation="vertical" size={2}>
                    <Space>
                      <Text strong style={{ fontSize: 15 }}>{order.member.name}</Text>
                      <Tag color="gold">{order.member.level}</Tag>
                    </Space>
                    <Space>
                      <PhoneOutlined style={{ color: '#6B7280' }} />
                      <Text type="secondary">{order.member.phone}</Text>
                    </Space>
                    <Text type="secondary">历史订单: {order.member.orderCount} 单</Text>
                  </Space>
                </Col>
                <Col flex="none">
                  <Button icon={<MessageOutlined />} size="small">发消息</Button>
                </Col>
              </Row>
            </Card>

            {/* 技师信息 */}
            <Card
              variant="borderless"
              style={{ borderRadius: 12, marginBottom: 16 }}
              title={<Space><StarOutlined style={{ color: '#F59E0B' }} /><Text strong>技师信息</Text></Space>}
            >
              <Row gutter={16} align="middle">
                <Col flex="none">
                  <Avatar size={52} style={{ background: 'linear-gradient(135deg, #F59E0B, #EF4444)', color: '#fff', fontSize: 20 }}>
                    {order.technician.name.charAt(0)}
                  </Avatar>
                </Col>
                <Col flex="auto">
                  <Space orientation="vertical" size={2}>
                    <Text strong style={{ fontSize: 15 }}>{order.technician.name}</Text>
                    <Space>
                      <StarOutlined style={{ color: '#F59E0B' }} />
                      <Text>{order.technician.rating}</Text>
                      <Text type="secondary">·</Text>
                      <Text type="secondary">完成 {order.technician.completedOrders} 单</Text>
                    </Space>
                    <Space>
                      <PhoneOutlined style={{ color: '#6B7280' }} />
                      <Text type="secondary">{order.technician.phone}</Text>
                    </Space>
                  </Space>
                </Col>
                <Col flex="none">
                  <Button icon={<MessageOutlined />} size="small">发消息</Button>
                </Col>
              </Row>
            </Card>

            {/* 订单时间轴 */}
            <Card
              variant="borderless"
              style={{ borderRadius: 12, marginBottom: 16 }}
              title={<Space><ClockCircleOutlined style={{ color: '#6366F1' }} /><Text strong>操作记录</Text></Space>}
            >
              <Timeline
                items={order.timeline.map(item => ({
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
          </Col>

          {/* 右侧 — 金额与操作 */}
          <Col xs={24} lg={8}>
            {/* 金额信息 */}
            <Card
              variant="borderless"
              style={{ borderRadius: 12, marginBottom: 16 }}
              title={<Space><CreditCardOutlined style={{ color: '#10B981' }} /><Text strong>金额明细</Text></Space>}
            >
              <Row gutter={[12, 16]}>
                <Col span={12}><Statistic title="服务原价" value={`$${order.service.originalPrice.toFixed(2)}`} styles={{ content: { fontSize: 16, color: '#374151' } }} /></Col>
                <Col span={12}><Statistic title="会员价" value={`$${order.service.memberPrice.toFixed(2)}`} styles={{ content: { fontSize: 16, color: '#374151' } }} /></Col>
                <Col span={12}><Statistic title="优惠减免" value={`-$${order.discountAmount.toFixed(2)}`} styles={{ content: { fontSize: 16, color: '#10B981' } }} /></Col>
                <Col span={12}><Statistic title="实付金额" value={`$${order.payAmount.toFixed(2)}`} styles={{ content: { fontSize: 16, color: '#EF4444', fontWeight: 700 } }} /></Col>
              </Row>
              <Divider style={{ margin: '12px 0' }} />
              <Row gutter={[12, 8]}>
                <Col span={12}><Statistic title="技师收入" value={`$${order.technicianIncome.toFixed(2)}`} styles={{ content: { fontSize: 14, color: '#6366F1' } }} /></Col>
                <Col span={12}><Statistic title="平台佣金" value={`$${order.platformCommission.toFixed(2)}`} styles={{ content: { fontSize: 14, color: '#F59E0B' } }} /></Col>
              </Row>
              <Divider style={{ margin: '12px 0' }} />
              <Descriptions column={1} size="small">
                <Descriptions.Item label="支付方式">
                  <Tag color={payInfo.color}>{payInfo.text}</Tag>
                </Descriptions.Item>
                {order.coupon && (
                  <Descriptions.Item label="优惠券">{order.coupon.name}</Descriptions.Item>
                )}
                <Descriptions.Item label="下单时间">{order.createTime}</Descriptions.Item>
                {order.payTime && <Descriptions.Item label="支付时间">{order.payTime}</Descriptions.Item>}
              </Descriptions>
            </Card>

            {/* 操作区 */}
            <Card
              variant="borderless"
              style={{ borderRadius: 12 }}
              title={<Text strong>操作</Text>}
            >
              <Space orientation="vertical" style={{ width: '100%' }}>
                {[0, 1, 2, 3].includes(order.status) && (
                  <Button
                    block
                    danger
                    icon={<StopOutlined />}
                    onClick={() => setCancelModalOpen(true)}
                    style={{ borderRadius: 8 }}
                  >
                    强制取消订单
                  </Button>
                )}
                <Button
                  block
                  icon={<MessageOutlined />}
                  style={{ borderRadius: 8 }}
                >
                  联系双方
                </Button>
                <Button
                  block
                  icon={<FileTextOutlined />}
                  style={{ borderRadius: 8 }}
                  onClick={() => navigate('/order')}
                >
                  返回订单列表
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
        <p>订单号: <Text strong>#{order.orderNo}</Text></p>
        <p style={{ color: '#6B7280', fontSize: 13, marginBottom: 12 }}>
          强制取消后，已支付金额将自动退款到用户账户，此操作不可撤销。
        </p>
        <TextArea
          rows={3}
          placeholder="请填写取消原因（必填）"
          value={cancelReason}
          onChange={e => setCancelReason(e.target.value)}
          style={{ borderRadius: 8 }}
        />
      </Modal>
    </div>
  );
};

export default OrderDetailPage;
