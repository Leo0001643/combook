import { Card, Typography, Space, Button, Empty } from 'antd'
import { TagsOutlined, PlusOutlined, MessageOutlined } from '@ant-design/icons'

const { Text } = Typography

export default function MerchantCouponsPage() {
  return (
    <div style={{ marginTop: -24 }}>
      <div style={{ position: 'sticky', top: 64, zIndex: 88, marginLeft: -24, marginRight: -24, background: 'rgba(255,255,255,0.97)', backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)', borderBottom: '1px solid rgba(0,0,0,0.07)', boxShadow: '0 4px 20px rgba(0,0,0,0.06)' }}>
        <div style={{ display: 'flex', alignItems: 'center', padding: '10px 24px 12px', gap: 12 }}>
          <div style={{ width: 34, height: 34, borderRadius: 10, background: 'linear-gradient(135deg,#fa709a,#fee140)', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 4px 12px rgba(250,112,154,0.35)', flexShrink: 0 }}>
            <TagsOutlined style={{ color: '#fff', fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1e293b', lineHeight: 1.2 }}>优惠管理</div>
            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>管理您的优惠券、折扣活动及促销规则</div>
          </div>
        </div>
      </div>
      <div style={{ paddingTop: 20 }}>
      <Card variant="borderless" style={{ borderRadius: 16, boxShadow: '0 2px 12px rgba(0,0,0,0.06)', textAlign: 'center', padding: '40px 0' }}>
        <Empty
          image={<TagsOutlined style={{ fontSize: 64, color: '#fa709a' }} />}
          imageStyle={{ height: 80 }}
          description={
            <div>
              <div style={{ fontWeight: 700, fontSize: 16, color: '#333', marginBottom: 8 }}>优惠券管理</div>
              <Text type="secondary" style={{ fontSize: 13 }}>
                优惠券功能需由平台超级管理员统一配置和审批
              </Text>
            </div>
          }
        >
          <Space>
            <Button
              type="primary"
              icon={<PlusOutlined />}
              style={{ background: 'linear-gradient(135deg,#fa709a,#fee140)', border: 'none', borderRadius: 8 }}
            >
              申请添加优惠券
            </Button>
            <Button icon={<MessageOutlined />} style={{ borderRadius: 8 }}>联系平台运营</Button>
          </Space>
        </Empty>
      </Card>
      </div>
    </div>
  )
}
