import { useState } from 'react'
import {
  Modal, Form, Input, Select, Upload, Button, Row, Col,
  message, Avatar, Progress, Typography, Space, Tag, Tabs,
} from 'antd'
import {
  ShopOutlined, PhoneOutlined, LockOutlined, UserOutlined,
  EnvironmentOutlined, HomeOutlined, FileTextOutlined,
  PictureOutlined, VideoCameraOutlined, PercentageOutlined,
  PlusOutlined, LoadingOutlined, CameraOutlined,
  BankOutlined, ContactsOutlined, GlobalOutlined,
  SafetyCertificateOutlined, IdcardOutlined, ApartmentOutlined,
  ExpandOutlined, CheckCircleOutlined,
} from '@ant-design/icons'
import type { UploadFile, UploadProps } from 'antd'
import { merchantApi, uploadApi } from '../../api/api'
import RichTextInput from '../common/RichTextInput'

const { Text } = Typography


const CITIES = ['金边', '暹粒', '西哈努克', '贡布', '白马', '磅湛', '菩萨', '茶胶', '柴桢', '磅清扬']

interface Props {
  open: boolean
  onClose: () => void
  onSuccess: () => void
}

// ── Section Header ───────────────────────────────────────────────────────────
function SectionHeader({ icon, title, subtitle, color = '#0ea5e9' }: {
  icon: React.ReactNode; title: string; subtitle?: string; color?: string
}) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 10,
      padding: '10px 14px', borderRadius: 10, marginBottom: 14,
      background: `linear-gradient(135deg,${color}10,${color}05)`,
      borderLeft: `3px solid ${color}`,
    }}>
      <div style={{
        width: 32, height: 32, borderRadius: 8, flexShrink: 0,
        background: `linear-gradient(135deg,${color},${color}cc)`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: `0 3px 8px ${color}40`,
      }}>
        <span style={{ color: '#fff', fontSize: 15 }}>{icon}</span>
      </div>
      <div>
        <div style={{ fontWeight: 700, fontSize: 13, color: '#1a1a2e' }}>{title}</div>
        {subtitle && <div style={{ fontSize: 11, color: '#888', marginTop: 1 }}>{subtitle}</div>}
      </div>
    </div>
  )
}

// ── Field with icon wrapper ──────────────────────────────────────────────────
function FieldIcon({ icon, color }: { icon: React.ReactNode; color: string }) {
  return <span style={{ color }}>{icon}</span>
}

export default function MerchantCreateModal({ open, onClose, onSuccess }: Props) {
  const [form] = Form.useForm()
  const [submitting, setSubmitting] = useState(false)
  const [activeTab, setActiveTab]   = useState('basic')

  // Logo
  const [logoUrl, setLogoUrl]         = useState<string>()
  const [logoLoading, setLogoLoading] = useState(false)

  // License photo
  const [licPicUrl, setLicPicUrl]         = useState<string>()
  const [licPicLoading, setLicPicLoading] = useState(false)

  // Album
  const [photoList, setPhotoList] = useState<UploadFile[]>([])

  // Video
  const [videoUrl, setVideoUrl]           = useState<string>()
  const [videoLoading, setVideoLoading]   = useState(false)
  const [videoProgress, setVideoProgress] = useState(0)

  // ── Upload helpers ─────────────────────────────────────────────────────────
  const makeImageUploader = (
    setUrl: (u: string) => void,
    setLoading: (b: boolean) => void,
    fieldName: string,
    label: string,
  ): UploadProps['customRequest'] => async ({ file, onSuccess: ok, onError }) => {
    setLoading(true)
    try {
      const res = await uploadApi.image(file as File)
      const url = res.data?.data as string
      setUrl(url)
      form.setFieldValue(fieldName, url)
      ok?.({})
      message.success(`${label}上传成功`)
    } catch (e: any) {
      onError?.(e)
      message.error(`${label}上传失败`)
    } finally {
      setLoading(false)
    }
  }

  const handleAlbumUpload: UploadProps['customRequest'] = async ({ file, onSuccess: ok, onError }) => {
    try {
      const res = await uploadApi.image(file as File)
      ok?.({ url: res.data?.data })
    } catch (e: any) { onError?.(e); message.error('图片上传失败') }
  }

  const handleVideoUpload: UploadProps['customRequest'] = async ({ file, onSuccess: ok, onError }) => {
    setVideoLoading(true); setVideoProgress(0)
    try {
      const t = setInterval(() => setVideoProgress(p => Math.min(p + 8, 90)), 300)
      const res = await uploadApi.video(file as File)
      clearInterval(t); setVideoProgress(100)
      const url = res.data?.data as string
      setVideoUrl(url); form.setFieldValue('videoUrl', url)
      ok?.({}); message.success('视频上传成功')
    } catch (e: any) { onError?.(e); message.error('视频上传失败') }
    finally { setVideoLoading(false) }
  }

  // ── Submit ─────────────────────────────────────────────────────────────────
  const handleSubmit = async () => {
    try {
      const values = await form.validateFields()
      setSubmitting(true)
      const photoUrls = photoList.filter(f => f.response?.url).map(f => f.response.url)
      await merchantApi.create({
        ...values,
        logo: logoUrl,
        businessLicensePic: licPicUrl,
        photos: photoUrls.length ? JSON.stringify(photoUrls) : undefined,
        videoUrl,
      })
      message.success('商户添加成功！')
      handleReset()
      onSuccess(); onClose()
    } catch (e: any) {
      if (e?.response?.data?.message) message.error(e.response.data.message)
      else if (!e?.errorFields) message.error('提交失败，请检查网络')
    } finally { setSubmitting(false) }
  }

  const handleReset = () => {
    form.resetFields()
    setLogoUrl(undefined); setLicPicUrl(undefined)
    setPhotoList([]); setVideoUrl(undefined)
    setActiveTab('basic')
  }

  // ── Tab content ────────────────────────────────────────────────────────────
  const tabBasic = (
    <div>
      {/* Logo upload */}
      <div style={{ textAlign: 'center', marginBottom: 20 }}>
        <Upload showUploadList={false} accept="image/*"
          customRequest={makeImageUploader(setLogoUrl, setLogoLoading, 'logo', 'Logo')}>
          <div style={{ cursor: 'pointer', display: 'inline-flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
            <div style={{ position: 'relative' }}>
              <Avatar
                src={logoUrl} size={84}
                icon={logoLoading ? <LoadingOutlined /> : <ShopOutlined />}
                shape="square"
                style={{
                  background: logoUrl ? 'transparent' : 'linear-gradient(135deg,#0ea5e9,#6366f1)',
                  border: '3px solid #e0f2fe', borderRadius: 18,
                  boxShadow: '0 6px 20px rgba(14,165,233,0.22)',
                }}
              />
              <div style={{
                position: 'absolute', bottom: -4, right: -4,
                width: 24, height: 24, borderRadius: '50%',
                background: 'linear-gradient(135deg,#0ea5e9,#6366f1)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                boxShadow: '0 2px 8px rgba(14,165,233,0.5)',
              }}>
                <CameraOutlined style={{ color: '#fff', fontSize: 12 }} />
              </div>
            </div>
            <Text style={{ color: '#0ea5e9', fontSize: 12, fontWeight: 600 }}>
              {logoUrl ? '✓ 已上传，点击更换' : '点击上传商户 Logo'}
            </Text>
          </div>
        </Upload>
        <Form.Item name="logo" hidden><Input /></Form.Item>
      </div>

      <SectionHeader icon={<ShopOutlined />} title="商户名称 & 经营信息" subtitle="支持多语言名称" color="#0ea5e9" />
      <Row gutter={16}>
        <Col span={8}>
          <Form.Item name="merchantNameZh" label="商户名称（中文）" rules={[{ required: true, message: '请输入商户中文名称' }]}>
            <Input prefix={<FieldIcon icon={<ShopOutlined />} color="#0ea5e9" />} placeholder="如：名玺休闲洗浴中心" />
          </Form.Item>
        </Col>
        <Col span={8}>
          <Form.Item name="merchantNameEn" label="商户名称（英文）">
            <Input prefix={<FieldIcon icon={<GlobalOutlined />} color="#52c41a" />} placeholder="English name (optional)" />
          </Form.Item>
        </Col>
        <Col span={8}>
          <Form.Item name="businessType" label="经营类型">
            <Select options={[
              { value: 1, label: <><UserOutlined style={{ color: '#722ed1', marginRight: 6 }} />个人商户</> },
              { value: 2, label: <><BankOutlined style={{ color: '#1677ff', marginRight: 6 }} />企业商户</> },
            ]} />
          </Form.Item>
        </Col>
        <Col span={8}>
          <Form.Item name="city" label="所在城市">
            <Select placeholder="请选择城市" allowClear
              options={CITIES.map(c => ({ value: c, label: c }))}
              suffixIcon={<FieldIcon icon={<EnvironmentOutlined />} color="#1677ff" />} />
          </Form.Item>
        </Col>
        <Col span={8}>
          <Form.Item name="businessArea" label="营业面积 / 规模">
            <Input prefix={<FieldIcon icon={<ExpandOutlined />} color="#eb2f96" />} placeholder="如：200㎡、中型" />
          </Form.Item>
        </Col>
        <Col span={8}>
          <Form.Item name="addressZh" label="详细地址">
            <Input prefix={<FieldIcon icon={<HomeOutlined />} color="#fa8c16" />} placeholder="请输入商户详细地址" />
          </Form.Item>
        </Col>
      </Row>

      <SectionHeader icon={<FileTextOutlined />} title="营业范围" subtitle="描述商户经营的服务类型" color="#f59e0b" />
      <Form.Item name="businessScope">
        <RichTextInput
          placeholder="请描述商户的营业范围，如：足疗、按摩、推拿、正骨、SPA护理等..."
          minHeight={130}
        />
      </Form.Item>
    </div>
  )

  const tabLicense = (
    <div>
      <SectionHeader icon={<SafetyCertificateOutlined />} title="营业执照信息"
        subtitle="以下信息均为选填，用于平台资质审核" color="#52c41a" />

      <Row gutter={14}>
        <Col span={24}>
          <Form.Item name="businessLicenseNo" label="营业执照号码">
            <Input
              prefix={<FieldIcon icon={<IdcardOutlined />} color="#52c41a" />}
              placeholder="请输入营业执照统一社会信用代码"
              maxLength={50}
            />
          </Form.Item>
        </Col>
      </Row>

      <Form.Item label="营业执照照片">
        <div style={{
          border: '2px dashed #d9f7be', borderRadius: 12, padding: 16,
          background: 'linear-gradient(135deg,#f6ffed,#fcfffe)',
          textAlign: 'center',
        }}>
          {licPicUrl ? (
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10 }}>
              <img src={licPicUrl} alt="营业执照"
                style={{ maxWidth: '100%', maxHeight: 200, borderRadius: 8, objectFit: 'contain',
                  boxShadow: '0 4px 16px rgba(0,0,0,0.1)' }} />
              <Space>
                <Tag color="success" icon={<CheckCircleOutlined />}>已上传</Tag>
                <Upload showUploadList={false} accept="image/*"
                  customRequest={makeImageUploader(setLicPicUrl, setLicPicLoading, 'businessLicensePic', '营业执照')}>
                  <Button size="small" style={{ borderRadius: 6 }}>重新上传</Button>
                </Upload>
              </Space>
            </div>
          ) : (
            <Upload showUploadList={false} accept="image/*"
              customRequest={makeImageUploader(setLicPicUrl, setLicPicLoading, 'businessLicensePic', '营业执照')}>
              <div style={{ cursor: 'pointer', padding: '20px 0' }}>
                {licPicLoading ? (
                  <LoadingOutlined style={{ fontSize: 36, color: '#52c41a' }} />
                ) : (
                  <SafetyCertificateOutlined style={{ fontSize: 36, color: '#52c41a' }} />
                )}
                <div style={{ marginTop: 10, color: '#52c41a', fontWeight: 600 }}>
                  {licPicLoading ? '上传中...' : '点击上传营业执照照片'}
                </div>
                <div style={{ color: '#999', fontSize: 12, marginTop: 4 }}>支持 JPG、PNG 格式，最大 10MB</div>
              </div>
            </Upload>
          )}
        </div>
        <Form.Item name="businessLicensePic" hidden><Input /></Form.Item>
      </Form.Item>

      {/* 联系信息也放在这个 tab */}
      <SectionHeader icon={<ContactsOutlined />} title="联系信息" color="#1677ff" />
      <Row gutter={16}>
        <Col span={12}>
          <Form.Item name="contactPerson" label="联系人姓名">
            <Input prefix={<FieldIcon icon={<UserOutlined />} color="#6366f1" />} placeholder="负责人/联系人姓名" />
          </Form.Item>
        </Col>
        <Col span={12}>
          <Form.Item name="contactMobile" label="联系人手机">
            <Input prefix={<FieldIcon icon={<PhoneOutlined />} color="#52c41a" />} placeholder="+855xxxxxxxx" />
          </Form.Item>
        </Col>
      </Row>
    </div>
  )

  const tabAccount = (
    <div>
      <SectionHeader icon={<LockOutlined />} title="账号设置" subtitle="商户登录凭证配置" color="#f43f5e" />
      <Row gutter={16}>
        <Col span={8}>
          <Form.Item name="username" label={
            <span>登录用户名 <Text type="secondary" style={{ fontSize: 11 }}>（选填）</Text></span>
          } rules={[
            { pattern: /^[a-zA-Z0-9]{4,20}$/, message: '只允许字母和数字，4-20位' },
          ]}>
            <Input
              prefix={<FieldIcon icon={<UserOutlined />} color="#6366f1" />}
              placeholder="字母 + 数字，4-20位"
              maxLength={20}
            />
          </Form.Item>
        </Col>
        <Col span={8}>
          <Form.Item name="mobile" label="登录手机号" rules={[
            { required: true, message: '请输入手机号' },
            { pattern: /^\+?[0-9]{8,20}$/, message: '手机号格式不正确' },
          ]}>
            <Input prefix={<FieldIcon icon={<PhoneOutlined />} color="#52c41a" />} placeholder="+855xxxxxxxx" />
          </Form.Item>
        </Col>
        <Col span={8}>
          <Form.Item name="password" label="初始密码" rules={[{ required: true, message: '请输入初始密码' }]}>
            <Input.Password prefix={<FieldIcon icon={<LockOutlined />} color="#fa8c16" />} placeholder="默认 123456" />
          </Form.Item>
        </Col>
        <Col span={8}>
          <Form.Item name="commissionRate" label="平台佣金比例">
            <Input
              type="number" min={0} max={100}
              prefix={<FieldIcon icon={<PercentageOutlined />} color="#722ed1" />}
              suffix={<Text type="secondary">%</Text>}
              placeholder="20"
            />
          </Form.Item>
        </Col>
      </Row>

      {/* 提示卡片 */}
      <div style={{
        background: 'linear-gradient(135deg,#fff7ed,#fffbf0)',
        border: '1px solid #fde68a', borderRadius: 10, padding: '12px 16px',
        display: 'flex', alignItems: 'flex-start', gap: 10,
      }}>
        <span style={{ fontSize: 18 }}>💡</span>
        <div style={{ fontSize: 12, color: '#92400e', lineHeight: 1.6 }}>
          <strong>账号说明：</strong>商户可通过手机号或用户名登录。初始密码为 <code style={{ background: '#fef3c7', padding: '1px 6px', borderRadius: 4 }}>123456</code>，建议提醒商户登录后及时修改。
        </div>
      </div>
    </div>
  )

  const tabMedia = (
    <div>
      <SectionHeader icon={<PictureOutlined />} title="商户相册" subtitle="最多上传 9 张展示图片" color="#8b5cf6" />
      <Upload
        listType="picture-card"
        fileList={photoList}
        customRequest={handleAlbumUpload}
        onChange={({ fileList }) => setPhotoList(fileList)}
        accept="image/*" maxCount={9}
        style={{ marginBottom: 16 }}
      >
        {photoList.length < 9 && (
          <div>
            <PlusOutlined style={{ color: '#8b5cf6', fontSize: 18 }} />
            <div style={{ marginTop: 6, fontSize: 12, color: '#8b5cf6', fontWeight: 500 }}>上传图片</div>
          </div>
        )}
      </Upload>

      <div style={{ height: 16 }} />

      <SectionHeader icon={<VideoCameraOutlined />} title="展示视频" subtitle="最大 200MB，支持 mp4/mov/webm" color="#ef4444" />
      {videoUrl ? (
        <div style={{
          border: '2px solid #fecaca', borderRadius: 10, padding: 16,
          background: 'linear-gradient(135deg,#fff5f5,#fffbfb)',
          display: 'flex', alignItems: 'center', gap: 12,
        }}>
          <VideoCameraOutlined style={{ fontSize: 28, color: '#ef4444' }} />
          <div style={{ flex: 1 }}>
            <Tag color="error" style={{ marginBottom: 4 }}>视频已上传</Tag>
            <div style={{ fontSize: 11, color: '#888' }}>{videoUrl.split('/').pop()}</div>
          </div>
          <Button size="small" danger onClick={() => { setVideoUrl(undefined); form.setFieldValue('videoUrl', undefined) }}>
            重新上传
          </Button>
        </div>
      ) : (
        <Upload showUploadList={false} customRequest={handleVideoUpload} accept="video/*" maxCount={1}>
          <div style={{
            border: '2px dashed #fca5a5', borderRadius: 10, padding: '20px 0',
            textAlign: 'center', cursor: 'pointer', background: '#fff5f5',
            transition: 'all 0.2s',
          }}>
            {videoLoading
              ? <LoadingOutlined style={{ fontSize: 32, color: '#ef4444' }} />
              : <VideoCameraOutlined style={{ fontSize: 32, color: '#ef4444' }} />}
            <div style={{ marginTop: 8, color: '#ef4444', fontWeight: 600 }}>
              {videoLoading ? `正在上传 ${videoProgress}%` : '点击选择视频文件'}
            </div>
            <div style={{ color: '#999', fontSize: 12, marginTop: 4 }}>支持 MP4、MOV、WebM 格式</div>
          </div>
        </Upload>
      )}
      {videoLoading && <Progress percent={videoProgress} size="small" style={{ marginTop: 10 }} strokeColor="#ef4444" />}
      <Form.Item name="videoUrl" hidden><Input /></Form.Item>
    </div>
  )

  const tabs = [
    { key: 'basic',   label: <span><ShopOutlined />基本信息</span>,             children: tabBasic   },
    { key: 'license', label: <span><SafetyCertificateOutlined />执照 & 联系</span>, children: tabLicense },
    { key: 'account', label: <span><LockOutlined />账号设置</span>,              children: tabAccount },
    { key: 'media',   label: <span><PictureOutlined />媒体资料</span>,           children: tabMedia   },
  ]

  return (
    <Modal
      title={
        <div style={{
          background: 'linear-gradient(135deg,#0ea5e9 0%,#6366f1 60%,#8b5cf6 100%)',
          margin: '-20px -24px 0',
          padding: '20px 28px 16px',
          borderRadius: '8px 8px 0 0',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <div style={{
              width: 46, height: 46, borderRadius: 12,
              background: 'rgba(255,255,255,0.2)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              backdropFilter: 'blur(10px)',
              boxShadow: '0 2px 12px rgba(0,0,0,0.15)',
            }}>
              <ShopOutlined style={{ color: '#fff', fontSize: 22 }} />
            </div>
            <div>
              <div style={{ color: '#fff', fontWeight: 800, fontSize: 17, letterSpacing: 0.5 }}>新增商户</div>
              <div style={{ color: 'rgba(255,255,255,0.82)', fontSize: 12, marginTop: 2 }}>
                🎉 欢迎加入商户大家庭，共创财富新传奇！
              </div>
            </div>
          </div>
        </div>
      }
      open={open}
      onCancel={() => { handleReset(); onClose() }}
      width={880}
      footer={null}
      destroyOnHidden
      styles={{ body: { paddingTop: 0, maxHeight: 'calc(85vh - 120px)', overflowY: 'auto', overflowX: 'hidden' } }}
    >
      <Form form={form} layout="vertical" size="middle"
        initialValues={{ businessType: 1, password: '123456', commissionRate: 20 }}>

        <Tabs
          activeKey={activeTab}
          onChange={setActiveTab}
          items={tabs}
          style={{ marginTop: 4 }}
          tabBarStyle={{ marginBottom: 16, fontWeight: 600 }}
        />

        {/* Footer */}
        <div style={{
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          paddingTop: 14, borderTop: '1px solid #f0f0f0', marginTop: 4,
        }}>
          <Space>
            {['basic', 'license', 'account', 'media'].map((k) => (
              <div key={k} onClick={() => setActiveTab(k)} style={{
                width: 8, height: 8, borderRadius: '50%', cursor: 'pointer',
                background: activeTab === k ? '#0ea5e9' : '#e0e0e0',
                transition: 'all 0.2s',
              }} />
            ))}
            <Text type="secondary" style={{ fontSize: 11, marginLeft: 4 }}>
              {tabs.findIndex(t => t.key === activeTab) + 1} / {tabs.length}
            </Text>
          </Space>
          <Space>
            <Button onClick={() => { handleReset(); onClose() }} style={{ borderRadius: 8 }}>
              取消
            </Button>
            <Button
              type="primary" loading={submitting} onClick={handleSubmit}
              style={{
                background: 'linear-gradient(135deg,#0ea5e9,#6366f1)',
                border: 'none', borderRadius: 8, minWidth: 110,
                boxShadow: '0 4px 14px rgba(14,165,233,0.35)',
              }}
              icon={<CheckCircleOutlined />}
            >
              确认新增商户
            </Button>
          </Space>
        </div>
      </Form>
    </Modal>
  )
}
