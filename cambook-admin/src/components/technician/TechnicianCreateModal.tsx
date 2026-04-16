import { useState } from 'react'
import {
  Modal, Form, Input, Select, Upload, Button, Row, Col,
  Divider, message, Avatar, Progress, Typography, Tag, Space, InputNumber,
} from 'antd'
import {
  UserOutlined, PhoneOutlined, LockOutlined, ManOutlined,
  EnvironmentOutlined, GlobalOutlined, FileTextOutlined,
  PictureOutlined, VideoCameraOutlined, TagsOutlined,
  PercentageOutlined, IdcardOutlined, CameraOutlined,
  PlusOutlined, LoadingOutlined, StarOutlined, SendOutlined,
  ColumnHeightOutlined, DashboardOutlined, CalendarOutlined, HeartOutlined,
} from '@ant-design/icons'
import type { UploadFile, UploadProps } from 'antd'
import { technicianApi, uploadApi } from '../../api/api'
import RichTextInput from '../common/RichTextInput'

const { Text } = Typography


const CITIES = ['金边', '暹粒', '西哈努克', '贡布', '白马', '磅湛', '菩萨']
const NATIONALITIES = [
  { value: '中国', label: '🇨🇳 中国' },
  { value: '柬埔寨', label: '🇰🇭 柬埔寨' },
  { value: '越南', label: '🇻🇳 越南' },
  { value: '泰国', label: '🇹🇭 泰国' },
  { value: '马来西亚', label: '🇲🇾 马来西亚' },
  { value: '新加坡', label: '🇸🇬 新加坡' },
  { value: '缅甸', label: '🇲🇲 缅甸' },
  { value: '老挝', label: '🇱🇦 老挝' },
  { value: '菲律宾', label: '🇵🇭 菲律宾' },
  { value: '韩国', label: '🇰🇷 韩国' },
  { value: '日本', label: '🇯🇵 日本' },
]

interface Props {
  open: boolean
  onClose: () => void
  onSuccess: () => void
  /** 自定义创建函数（由 usePortalScope 注入，支持 admin 和 merchant 两种上下文） */
  createFn?: (data: any) => Promise<any>
}

export default function TechnicianCreateModal({ open, onClose, onSuccess, createFn }: Props) {
  const [form] = Form.useForm()
  const [submitting, setSubmitting] = useState(false)
  const [avatarUrl, setAvatarUrl]   = useState<string>()
  const [avatarLoading, setAvatarLoading] = useState(false)
  const [photoList, setPhotoList]   = useState<UploadFile[]>([])
  const [videoUrl, setVideoUrl]     = useState<string>()
  const [videoLoading, setVideoLoading] = useState(false)
  const [uploadProgress, setUploadProgress] = useState(0)

  const handleAvatarUpload: UploadProps['customRequest'] = async ({ file, onSuccess: ok, onError }) => {
    setAvatarLoading(true)
    try {
      const res = await uploadApi.image(file as File)
      const url = res.data?.data as string
      setAvatarUrl(url)
      form.setFieldValue('avatar', url)
      ok?.({})
      message.success('头像上传成功')
    } catch (e: any) {
      onError?.(e)
      message.error('头像上传失败')
    } finally {
      setAvatarLoading(false)
    }
  }

  const handlePhotoUpload: UploadProps['customRequest'] = async ({ file, onSuccess: ok, onError }) => {
    try {
      const res = await uploadApi.image(file as File)
      const url = res.data?.data as string
      ok?.({ url })
      return url
    } catch (e: any) {
      onError?.(e)
      message.error('图片上传失败')
    }
  }

  const handleVideoUpload: UploadProps['customRequest'] = async ({ file, onSuccess: ok, onError }) => {
    setVideoLoading(true)
    setUploadProgress(0)
    try {
      // 模拟进度（实际上传完成才知道）
      const timer = setInterval(() => {
        setUploadProgress(p => Math.min(p + 10, 90))
      }, 200)
      const res = await uploadApi.video(file as File)
      clearInterval(timer)
      setUploadProgress(100)
      const url = res.data?.data as string
      setVideoUrl(url)
      form.setFieldValue('videoUrl', url)
      ok?.({})
      message.success('视频上传成功')
    } catch (e: any) {
      onError?.(e)
      message.error('视频上传失败')
    } finally {
      setVideoLoading(false)
    }
  }

  const handleSubmit = async () => {
    try {
      const values = await form.validateFields()
      setSubmitting(true)
      // 将相册列表转为 JSON 数组
      const photoUrls = photoList
        .filter(f => f.response?.url)
        .map(f => f.response.url)
      // 优先使用外部注入的 createFn（商户/Admin 上下文感知），降级到 technicianApi
      const doCreate = createFn ?? technicianApi.create
      await doCreate({
        ...values,
        avatar: avatarUrl,
        photos: photoUrls.length ? JSON.stringify(photoUrls) : undefined,
        videoUrl,
      })
      message.success('技师添加成功！')
      form.resetFields()
      setAvatarUrl(undefined)
      setPhotoList([])
      setVideoUrl(undefined)
      onSuccess()
      onClose()
    } catch (e: any) {
      if (e?.response?.data?.message) message.error(e.response.data.message)
    } finally {
      setSubmitting(false)
    }
  }

  const sectionLabel = (icon: React.ReactNode, text: string) => (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 8, marginBottom: 2,
      color: '#6366f1', fontWeight: 700, fontSize: 13,
    }}>
      {icon}<span>{text}</span>
    </div>
  )

  return (
    <Modal
      title={
        <div style={{
          background: 'linear-gradient(135deg,#6366f1,#8b5cf6)',
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
            <IdcardOutlined style={{ color: '#fff', fontSize: 20 }} />
          </div>
          <div>
            <div style={{ color: '#fff', fontWeight: 800, fontSize: 16 }}>新增技师</div>
            <div style={{ color: 'rgba(255,255,255,0.8)', fontSize: 12, marginTop: 2 }}>
              🎉 欢迎成为技师团队的一员，创造属于你的辉煌！
            </div>
          </div>
        </div>
      }
      open={open}
      onCancel={onClose}
      width={880}
      footer={null}
      destroyOnHidden
      styles={{ body: { maxHeight: 'calc(85vh - 120px)', overflowY: 'auto', overflowX: 'hidden' } }}
    >
      <Form form={form} layout="vertical" size="middle" initialValues={{ gender: 2, lang: 'zh', password: '123456', commissionRate: 70 }}>

        {/* ── 头像上传 ── */}
        <div style={{ textAlign: 'center', marginBottom: 20 }}>
          <Upload
            showUploadList={false}
            accept="image/*"
            customRequest={handleAvatarUpload}
          >
            <div style={{ cursor: 'pointer', display: 'inline-block' }}>
              <Avatar
                src={avatarUrl}
                size={80}
                icon={avatarLoading ? <LoadingOutlined /> : <UserOutlined />}
                style={{
                  background: 'linear-gradient(135deg,#6366f1,#8b5cf6)',
                  border: '3px solid #ede9fe',
                  boxShadow: '0 4px 16px rgba(99,102,241,0.25)',
                }}
              />
              <div style={{
                position: 'absolute', bottom: 0, right: 0,
                width: 26, height: 26, borderRadius: '50%',
                background: '#6366f1',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                boxShadow: '0 2px 8px rgba(99,102,241,0.4)',
                marginTop: -26, marginLeft: 54,
              }}>
                <CameraOutlined style={{ color: '#fff', fontSize: 13 }} />
              </div>
              <div style={{ marginTop: 8, color: '#6366f1', fontSize: 12, fontWeight: 600 }}>
                点击上传头像
              </div>
            </div>
          </Upload>
          <Form.Item name="avatar" hidden><Input /></Form.Item>
        </div>

        {/* ── 基本信息 ── */}
        {sectionLabel(<UserOutlined />, '基本信息')}
        <Row gutter={16}>
          <Col span={8}>
            <Form.Item name="realName" label="真实姓名" rules={[{ required: true, message: '请输入真实姓名' }]}>
              <Input prefix={<IdcardOutlined style={{ color: '#6366f1' }} />} placeholder="请输入真实姓名" />
            </Form.Item>
          </Col>
          <Col span={8}>
            <Form.Item name="nickname" label="昵称（展示名）">
              <Input prefix={<StarOutlined style={{ color: '#faad14' }} />} placeholder="默认同真实姓名" />
            </Form.Item>
          </Col>
          <Col span={8}>
            <Form.Item name="gender" label="性别">
              <Select
                options={[
                  { value: 2, label: <><span style={{ color: '#ff85c2' }}>♀</span> 女</> },
                  { value: 1, label: <><ManOutlined style={{ color: '#1677ff' }} /> 男</> },
                ]}
              />
            </Form.Item>
          </Col>
          <Col span={8}>
            <Form.Item name="nationality" label="国籍">
              <Select placeholder="请选择国籍" allowClear options={NATIONALITIES} />
            </Form.Item>
          </Col>
          <Col span={8}>
            <Form.Item name="age" label="年龄">
              <InputNumber
                prefix={<CalendarOutlined style={{ color: '#f59e0b' }} />}
                placeholder="如：25" min={16} max={60} style={{ width: '100%' }}
                addonAfter="岁"
              />
            </Form.Item>
          </Col>
          <Col span={8}>
            <Form.Item name="height" label="身高">
              <InputNumber
                prefix={<ColumnHeightOutlined style={{ color: '#10b981' }} />}
                placeholder="如：165" min={140} max={200} style={{ width: '100%' }}
                addonAfter="cm"
              />
            </Form.Item>
          </Col>
          <Col span={8}>
            <Form.Item name="weight" label="体重">
              <InputNumber
                prefix={<DashboardOutlined style={{ color: '#6366f1' }} />}
                placeholder="如：50" min={30} max={150} step={0.1} style={{ width: '100%' }}
                addonAfter="kg"
              />
            </Form.Item>
          </Col>
          <Col span={8}>
            <Form.Item name="bust" label="罩杯">
              <Select
                placeholder="请选择罩杯"
                allowClear
                suffixIcon={<HeartOutlined style={{ color: '#ec4899' }} />}
                options={['A', 'B', 'C', 'D', 'E', 'F', 'G'].map(c => ({
                  value: c,
                  label: `${c} 杯`,
                }))}
              />
            </Form.Item>
          </Col>
          <Col span={8}>
            <Form.Item name="province" label="所在省份">
              <Input
                prefix={<EnvironmentOutlined style={{ color: '#06b6d4' }} />}
                placeholder="如：广东省"
              />
            </Form.Item>
          </Col>
          <Col span={8}>
            <Form.Item name="mobile" label="登录手机号" rules={[
              { required: true, message: '请输入手机号' },
              { pattern: /^\+?[0-9]{8,20}$/, message: '手机号格式不正确' },
            ]}>
              <Input prefix={<PhoneOutlined style={{ color: '#52c41a' }} />} placeholder="+855xxxxxxxx" />
            </Form.Item>
          </Col>
          <Col span={8}>
            <Form.Item name="telegram" label="Telegram账号">
              <Space.Compact style={{ width: '100%' }}>
                <span style={{
                  padding: '0 10px', border: '1px solid #d9d9d9', borderRight: 'none',
                  borderRadius: '6px 0 0 6px', background: '#fafafa',
                  display: 'flex', alignItems: 'center', color: '#229ED9', fontWeight: 600, fontSize: 14
                }}>@</span>
                <Input
                  prefix={<SendOutlined style={{ color: '#229ED9' }} />}
                  placeholder="不含@，如：username"
                  style={{ borderRadius: '0 6px 6px 0' }}
                />
              </Space.Compact>
            </Form.Item>
          </Col>
          <Col span={8}>
            <Form.Item name="password" label="初始密码" rules={[{ required: true }]}>
              <Input.Password prefix={<LockOutlined style={{ color: '#fa8c16' }} />} placeholder="默认 123456" />
            </Form.Item>
          </Col>
        </Row>

        <Divider style={{ margin: '8px 0 16px' }} />

        {/* ── 服务信息 ── */}
        {sectionLabel(<EnvironmentOutlined />, '服务信息')}
        <Row gutter={16}>
          <Col span={8}>
            <Form.Item name="serviceCity" label="服务城市">
              <Select placeholder="请选择城市" allowClear options={CITIES.map(c => ({ value: c, label: c }))}
                suffixIcon={<EnvironmentOutlined style={{ color: '#1677ff' }} />} />
            </Form.Item>
          </Col>
          <Col span={8}>
            <Form.Item name="lang" label="常用语言">
              <Select options={[
                { value: 'zh', label: '🇨🇳 中文' },
                { value: 'km', label: '🇰🇭 高棉语' },
                { value: 'en', label: '🇬🇧 English' },
                { value: 'vi', label: '🇻🇳 越南语' },
              ]} suffixIcon={<GlobalOutlined style={{ color: '#722ed1' }} />} />
            </Form.Item>
          </Col>
          <Col span={8}>
            <Form.Item name="commissionRate" label="分成比例 (%)">
              <Input type="number" min={0} max={100}
                prefix={<PercentageOutlined style={{ color: '#722ed1' }} />}
                suffix="%" placeholder="70" />
            </Form.Item>
          </Col>
          <Col span={16}>
            <Form.Item name="skillTags" label="技能标签（逗号分隔）">
              <Input prefix={<TagsOutlined style={{ color: '#eb2f96' }} />}
                placeholder='如：推拿,正骨,足疗' />
            </Form.Item>
          </Col>
        </Row>

        <Divider style={{ margin: '8px 0 16px' }} />

        {/* ── 简介 ── */}
        {sectionLabel(<FileTextOutlined />, '个人简介')}
        <Form.Item name="introZh" label="">
          <RichTextInput
            placeholder="请输入技师中文简介，介绍技能特长、从业经历、服务理念等..."
            minHeight={140}
          />
        </Form.Item>

        <Divider style={{ margin: '8px 0 16px' }} />

        {/* ── 相册上传 ── */}
        {sectionLabel(<PictureOutlined />, '相册（最多 9 张）')}
        <Form.Item>
          <Upload
            listType="picture-card"
            fileList={photoList}
            customRequest={handlePhotoUpload}
            onChange={({ fileList }) => setPhotoList(fileList)}
            accept="image/*"
            maxCount={9}
          >
            {photoList.length < 9 && (
              <div>
                <PlusOutlined style={{ color: '#6366f1' }} />
                <div style={{ marginTop: 4, fontSize: 12, color: '#6366f1' }}>上传图片</div>
              </div>
            )}
          </Upload>
        </Form.Item>

        <Divider style={{ margin: '8px 0 16px' }} />

        {/* ── 视频上传 ── */}
        {sectionLabel(<VideoCameraOutlined />, '展示视频（最大 200MB）')}
        <Form.Item name="videoUrl">
          {videoUrl ? (
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <Tag color="green" icon={<VideoCameraOutlined />}>视频已上传</Tag>
              <Text type="secondary" style={{ fontSize: 11 }}>{videoUrl.split('/').pop()}</Text>
              <Button size="small" danger onClick={() => { setVideoUrl(undefined); form.setFieldValue('videoUrl', undefined) }}>
                重新上传
              </Button>
            </div>
          ) : (
            <div>
              <Upload
                showUploadList={false}
                customRequest={handleVideoUpload}
                accept="video/*"
                maxCount={1}
              >
                <Button icon={videoLoading ? <LoadingOutlined /> : <VideoCameraOutlined style={{ color: '#ff4d4f' }} />}
                  loading={videoLoading} style={{ borderRadius: 8 }}>
                  {videoLoading ? `上传中 ${uploadProgress}%` : '选择视频文件'}
                </Button>
              </Upload>
              {videoLoading && (
                <Progress percent={uploadProgress} size="small" style={{ marginTop: 8 }} />
              )}
            </div>
          )}
        </Form.Item>

        {/* ── 提交 ── */}
        <div style={{
          display: 'flex', justifyContent: 'flex-end', gap: 10,
          marginTop: 8, paddingTop: 16, borderTop: '1px solid #f0f0f0',
        }}>
          <Button onClick={onClose} style={{ borderRadius: 8 }}>取消</Button>
          <Button
            type="primary" loading={submitting} onClick={handleSubmit}
            style={{
              background: 'linear-gradient(135deg,#6366f1,#8b5cf6)',
              border: 'none', borderRadius: 8, minWidth: 100,
            }}
            icon={<IdcardOutlined />}
          >
            确认新增
          </Button>
        </div>
      </Form>
    </Modal>
  )
}
