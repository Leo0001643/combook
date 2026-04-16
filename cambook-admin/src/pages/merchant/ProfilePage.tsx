import { useState, useEffect } from 'react'
import {
  Card, Descriptions, Avatar, Tag, Spin, Image, Row, Col, Typography, Space, Divider,
} from 'antd'
import {
  ShopOutlined, PhoneOutlined, EnvironmentOutlined, AuditOutlined,
} from '@ant-design/icons'
import { merchantPortalApi } from '../../api/api'

const { Text } = Typography

const AUDIT_MAP: Record<number, { color: string; text: string }> = {
  0: { color: 'orange', text: '待审核' },
  1: { color: 'green',  text: '已通过' },
  2: { color: 'red',    text: '已拒绝' },
}

export default function MerchantProfilePage() {
  const [data, setData]       = useState<any>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    merchantPortalApi.profile().then(r => setData(r.data?.data)).finally(() => setLoading(false))
  }, [])

  if (loading) return <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: 400 }}><Spin size="large" /></div>
  if (!data) return null

  return (
    <div style={{ marginTop: -24, height: 'calc(100vh - 64px)', display: 'flex', flexDirection: 'column' }}>
      {/* Sticky header */}
      <div style={{ position: 'sticky', top: 64, zIndex: 88, marginLeft: -24, marginRight: -24, background: 'rgba(255,255,255,0.97)', backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)', borderBottom: '1px solid rgba(0,0,0,0.07)', boxShadow: '0 4px 20px rgba(0,0,0,0.06)' }}>
        <div style={{ display: 'flex', alignItems: 'center', padding: '10px 24px 12px', gap: 12 }}>
          <div style={{ width: 34, height: 34, borderRadius: 10, background: 'linear-gradient(135deg,#667eea,#764ba2)', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 4px 12px rgba(102,126,234,0.35)', flexShrink: 0 }}>
            <ShopOutlined style={{ color: '#fff', fontSize: 16 }} />
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#1e293b', lineHeight: 1.2 }}>商户设置</div>
            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>{data.merchantNameZh || data.merchantNameEn || '商户'} · 商户号 {data.merchantNo || ''}</div>
          </div>
          <Divider type="vertical" style={{ height: 20, margin: '0 4px', borderColor: '#e0e4ff' }} />
          <div style={{ display: 'flex', gap: 8 }}>
            {[
              { label: '账户余额', value: `¥${Number(data.balance ?? 0).toFixed(0)}`, color: '#10b981', bg: 'rgba(16,185,129,0.1)', border: 'rgba(16,185,129,0.25)', icon: '💰' },
              { label: '佣金率', value: `${data.commissionRate ?? 0}%`, color: '#6366f1', bg: 'rgba(99,102,241,0.1)', border: 'rgba(99,102,241,0.25)', icon: '📊' },
              { label: '审核状态', value: AUDIT_MAP[data.auditStatus]?.text ?? '-', color: data.auditStatus === 1 ? '#10b981' : '#f59e0b', bg: data.auditStatus === 1 ? 'rgba(16,185,129,0.1)' : 'rgba(245,158,11,0.1)', border: data.auditStatus === 1 ? 'rgba(16,185,129,0.25)' : 'rgba(245,158,11,0.25)', icon: '✅' },
            ].map((s, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: s.bg, border: `1px solid ${s.border}` }}>
                <span style={{ fontSize: 13 }}>{s.icon}</span>
                <span style={{ fontSize: 12, color: '#6b7280' }}>{s.label}</span>
                <span style={{ fontSize: 13, fontWeight: 700, color: s.color }}>{s.value}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
      {/* Content - keep all Card/Row/Col content as-is */}
      <div style={{ paddingTop: 20, flex: 1, overflowY: 'auto' }}>
        <Row gutter={[16, 16]}>
          <Col xs={24} lg={8}>
            <Card variant="borderless" style={{ borderRadius: 16, boxShadow: '0 2px 12px rgba(0,0,0,0.06)', textAlign: 'center' }}
                  styles={{ body: { padding: 28 } }}>
              {data.logo
                ? <Image src={data.logo} width={100} height={100} style={{ objectFit: 'cover', borderRadius: 16 }} />
                : <Avatar size={100} icon={<ShopOutlined />} style={{ background: 'linear-gradient(135deg,#667eea,#764ba2)', fontSize: 40 }} />
              }
              <div style={{ marginTop: 14, fontWeight: 800, fontSize: 18 }}>{data.merchantNameZh}</div>
              <Text type="secondary" style={{ fontSize: 13 }}>{data.merchantNameEn}</Text>
              <div style={{ marginTop: 10, display: 'flex', justifyContent: 'center', gap: 8 }}>
                <Tag color={AUDIT_MAP[data.auditStatus]?.color}>{AUDIT_MAP[data.auditStatus]?.text}</Tag>
                <Tag color={data.status === 1 ? 'success' : 'default'}>{data.status === 1 ? '正常营业' : '停用'}</Tag>
              </div>

              <div style={{ marginTop: 20, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                {[
                  { label: '账户余额',   value: `¥${Number(data.balance ?? 0).toFixed(2)}`, color: '#F5A623' },
                  { label: '佣金比例',   value: `${data.commissionRate ?? 0}%`,              color: '#6366f1' },
                ].map((s, i) => (
                  <div key={i} style={{ background: '#f9fafb', borderRadius: 10, padding: '10px 14px' }}>
                    <Text type="secondary" style={{ fontSize: 11 }}>{s.label}</Text>
                    <div style={{ color: s.color, fontWeight: 800, fontSize: 16, marginTop: 2 }}>{s.value}</div>
                  </div>
                ))}
              </div>
            </Card>
          </Col>

          <Col xs={24} lg={16}>
            <Card variant="borderless" style={{ borderRadius: 16, boxShadow: '0 2px 12px rgba(0,0,0,0.06)' }}
                  title={<Space><AuditOutlined style={{ color: '#667eea' }} /><span style={{ fontWeight: 700 }}>商户信息</span></Space>}>
              <Descriptions column={2} bordered size="small">
                <Descriptions.Item label={<Space><ShopOutlined />中文名称</Space>}>{data.merchantNameZh}</Descriptions.Item>
                <Descriptions.Item label="英文名称">{data.merchantNameEn || '-'}</Descriptions.Item>
                <Descriptions.Item label={<Space><PhoneOutlined />联系人</Space>}>{data.contactPerson}</Descriptions.Item>
                <Descriptions.Item label="联系电话">{data.contactMobile}</Descriptions.Item>
                <Descriptions.Item label="商户手机">{data.mobile}</Descriptions.Item>
                <Descriptions.Item label={<Space><EnvironmentOutlined />城市</Space>}>{data.city || '-'}</Descriptions.Item>
                <Descriptions.Item label="营业地址" span={2}>{data.address || '-'}</Descriptions.Item>
                <Descriptions.Item label="营业范围" span={2}>{data.businessScope || '-'}</Descriptions.Item>
                <Descriptions.Item label="营业执照号">{data.businessLicense || '-'}</Descriptions.Item>
                <Descriptions.Item label="营业面积">{data.businessArea ? `${data.businessArea}㎡` : '-'}</Descriptions.Item>
                <Descriptions.Item label="商户类型">
                  <Tag color="blue">{{ 1: '个人', 2: '企业', 3: '门店' }[data.businessType as 1 | 2 | 3] ?? '-'}</Tag>
                </Descriptions.Item>
                <Descriptions.Item label="登录用户名">{data.username || '-'}</Descriptions.Item>
              </Descriptions>
            </Card>

            {data.businessLicensePhoto && (
              <Card variant="borderless" style={{ borderRadius: 16, boxShadow: '0 2px 12px rgba(0,0,0,0.06)', marginTop: 16 }}
                    title={<Space><AuditOutlined style={{ color: '#667eea' }} /><span style={{ fontWeight: 700 }}>营业执照</span></Space>}>
                <Image src={data.businessLicensePhoto} width={200} style={{ borderRadius: 10, border: '1px solid #e5e7eb' }} />
              </Card>
            )}
          </Col>
        </Row>
      </div>
    </div>
  )
}
