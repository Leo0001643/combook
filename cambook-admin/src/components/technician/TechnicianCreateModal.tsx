import { useState, useEffect } from 'react'
import {
  Modal, Form, Input, Select, Upload, Button, Row, Col,
  Divider, message, Avatar, Progress, Typography, Tag, Space, InputNumber,
  Tooltip,
} from 'antd'
import {
  UserOutlined, PhoneOutlined, LockOutlined, ManOutlined,
  EnvironmentOutlined, GlobalOutlined, FileTextOutlined,
  PictureOutlined, VideoCameraOutlined, TagsOutlined,
  PercentageOutlined, IdcardOutlined, CameraOutlined,
  PlusOutlined, LoadingOutlined, StarOutlined, SendOutlined,
  ColumnHeightOutlined, DashboardOutlined, CalendarOutlined, HeartOutlined,
  AppstoreOutlined, InfoCircleOutlined,
} from '@ant-design/icons'
import type { UploadFile, UploadProps } from 'antd'
import { technicianApi, uploadApi, merchantPortalApi } from '../../api/api'
import { useServiceCategories } from '../../hooks/useServiceCategories'
import { useAuthStore } from '../../store/authStore'
import { useDict } from '../../hooks/useDict'
import RichTextInput from '../common/RichTextInput'

const { Text } = Typography

/** 字典兜底数据（字典 API 未就绪时的预设选项） */
const CITY_FALLBACK    = ['金边','暹粒','西哈努克港','磅湛','马德望','菩萨省','茶胶省'].map(v => ({ value: v, label: v }))
const LANG_FALLBACK    = [
  { value: '中文', label: '中文' }, { value: '英语', label: '英语' },
  { value: '柬语', label: '柬语' }, { value: '越南语', label: '越南语' },
  { value: '泰语', label: '泰语' },
]
const BUST_FALLBACK    = ['A','B','C','D','E','F'].map(v => ({ value: v, label: `${v} 罩杯` }))
const CURRENCY_FALLBACK = [
  { value: 'USD', label: 'USD 美元' }, { value: 'KHR', label: 'KHR 瑞尔' }, { value: 'CNY', label: 'CNY 人民币' },
]
const SETTLE_FALLBACK  = [
  { value: 1, label: '日结' }, { value: 2, label: '周结' }, { value: 3, label: '月结' },
]
const COMM_TYPE_FALLBACK = [
  { value: 1, label: '百分比提成' }, { value: 2, label: '固定金额' },
]
const NATION_FALLBACK = [
  { dictValue: 'CN', labelZh: '🇨🇳 中国', remark: '🇨🇳' },
  { dictValue: 'KH', labelZh: '🇰🇭 柬埔寨', remark: '🇰🇭' },
  { dictValue: 'VN', labelZh: '🇻🇳 越南', remark: '🇻🇳' },
  { dictValue: 'TH', labelZh: '🇹🇭 泰国', remark: '🇹🇭' },
  { dictValue: 'MM', labelZh: '🇲🇲 缅甸', remark: '🇲🇲' },
  { dictValue: 'PH', labelZh: '🇵🇭 菲律宾', remark: '🇵🇭' },
  { dictValue: 'OTHER', labelZh: '其他', remark: '' },
]


interface Props {
  open: boolean
  onClose: () => void
  onSuccess: () => void
  /** 编辑时传入的记录（有值则为编辑模式，否则为新增模式） */
  editRecord?: Record<string, any> | null
  /** 管理员视角时传入商户 ID，用于加载该商户的服务类目；商户视角忽略此参数 */
  merchantId?: number
  /** 自定义创建函数（由 usePortalScope 注入，支持 admin 和 merchant 两种上下文） */
  createFn?: (data: any) => Promise<any>
  /** 自定义更新函数 */
  updateFn?: (data: any) => Promise<any>
}

export default function TechnicianCreateModal({ open, onClose, onSuccess, editRecord, merchantId, createFn, updateFn }: Props) {
  const isEdit = !!editRecord
  const { isMerchant } = useAuthStore()
  const [form] = Form.useForm()
  const { categories: dbCategories } = useServiceCategories(merchantId)
  const { opts: cityOpts }        = useDict('service_city')
  const { items: nationItems }    = useDict('nationality')
  const { opts: langOpts }        = useDict('language')
  const { opts: bustOpts }        = useDict('bust_size')
  const { opts: currencyOpts }    = useDict('currency')
  const { opts: settleModeOpts }  = useDict('settlement_mode')
  const { opts: commTypeOpts }    = useDict('commission_type')
  const [submitting, setSubmitting] = useState(false)
  const [avatarUrl, setAvatarUrl]   = useState<string>()
  const [avatarLoading, setAvatarLoading] = useState(false)
  const [photoList, setPhotoList]   = useState<UploadFile[]>([])
  const [videoUrl, setVideoUrl]     = useState<string>()
  const [videoLoading, setVideoLoading] = useState(false)
  const [uploadProgress, setUploadProgress] = useState(0)

  // 技师专属定价：serviceItemId → price（null=使用系统指导价）
  const [pricingMap, setPricingMap] = useState<Record<number, number | null>>({})

  // 编辑模式：打开时回填表单
  useEffect(() => {
    if (open && isEdit && editRecord) {
      form.setFieldsValue({
        realName:       editRecord.realName,
        nickname:       editRecord.nickname,
        mobile:         editRecord.mobile,
        gender:         editRecord.gender,
        nationality:    editRecord.nationality,
        serviceCity:    editRecord.serviceCity,
        lang:           editRecord.lang ?? 'zh',
        introZh:        editRecord.introZh,
        skillTags:      editRecord.skillTags
                          ? (() => {
                              try {
                                return editRecord.skillTags.startsWith('[')
                                  ? JSON.parse(editRecord.skillTags).join(', ')
                                  : editRecord.skillTags
                              } catch { return editRecord.skillTags }
                            })()
                          : undefined,
        serviceItemIds:     editRecord.serviceItemIds ?? [],
        commissionRate:     editRecord.commissionRate,
        settlementMode:     editRecord.settlementMode ?? 3,
        commissionType:     editRecord.commissionType ?? 0,
        commissionRatePct:  editRecord.commissionRatePct,
        commissionCurrency: editRecord.commissionCurrency ?? 'USD',
        height:         editRecord.height,
        weight:         editRecord.weight,
        age:            editRecord.age,
        bust:           editRecord.bust,
        telegram:       editRecord.telegram,
        province:       editRecord.province,
      })
      setAvatarUrl(editRecord.avatar)
      setVideoUrl(editRecord.videoUrl)
      // 回填相册
      if (editRecord.photos) {
        try {
          const urls: string[] = JSON.parse(editRecord.photos)
          setPhotoList(urls.map((url, i) => ({
            uid: `existing-${i}`,
            name: `photo-${i + 1}`,
            status: 'done' as const,
            url,
            response: { url },
          })))
        } catch { setPhotoList([]) }
      } else {
        setPhotoList([])
      }
      // 仅商户可加载/编辑技师专属定价
      if (isMerchant) {
        merchantPortalApi.technicianPricingList(editRecord.id)
          .then(res => {
            const list: { serviceItemId: number; price: number }[] = res.data?.data ?? []
            const map: Record<number, number | null> = {}
            list.forEach(p => { map[p.serviceItemId] = Number(p.price) })
            setPricingMap(map)
          })
          .catch(() => setPricingMap({}))
      }
    } else if (open && !isEdit) {
      form.resetFields()
      setAvatarUrl(undefined)
      setPhotoList([])
      setVideoUrl(undefined)
      setPricingMap({})
    }
  }, [open, isEdit, editRecord])

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
    const timer = setInterval(() => {
      setUploadProgress(p => Math.min(p + 10, 90))
    }, 200)
    try {
      const res = await uploadApi.video(file as File)
      clearInterval(timer)
      setUploadProgress(100)
      const url = res.data?.data as string
      setVideoUrl(url)
      form.setFieldValue('videoUrl', url)
      ok?.({})
      message.success('视频上传成功')
    } catch (e: any) {
      clearInterval(timer)
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
      const photoUrls = photoList
        .filter(f => f.response?.url || f.url)
        .map(f => f.response?.url ?? f.url)
      const payload = {
        ...values,
        avatar:   avatarUrl,
        photos:   photoUrls.length ? JSON.stringify(photoUrls) : undefined,
        videoUrl,
      }

      let techId: number | undefined
      if (isEdit) {
        const doUpdate = updateFn ?? technicianApi.update
        await doUpdate({ id: editRecord!.id, ...payload })
        techId = editRecord!.id
        message.success('技师信息已更新！')
      } else {
        const doCreate = createFn ?? technicianApi.create
        const res = await doCreate(payload)
        techId = res?.data?.data?.id ?? res?.data?.data
        message.success('技师添加成功！')
      }

      // 保存技师专属定价（仅商户模式下的特殊项目）
      if (techId && isMerchant) {
        const pricingItems = Object.entries(pricingMap)
          .filter(([sid, price]) => {
            const svc = dbCategories.find(s => s.id === +sid)
            return svc?.isSpecial === 1 && price != null && price > 0
          })
          .map(([sid, price]) => ({ serviceItemId: +sid, price: price! }))
        if (pricingItems.length > 0) {
          try {
            await merchantPortalApi.technicianPricingSaveAll(techId, pricingItems)
          } catch {
            message.warning('技师基本信息已保存，但专属定价保存失败，请在详情页重新设置')
          }
        }
      }

      form.resetFields()
      setAvatarUrl(undefined)
      setPhotoList([])
      setVideoUrl(undefined)
      setPricingMap({})
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
            <div style={{ color: '#fff', fontWeight: 800, fontSize: 16 }}>{isEdit ? '编辑技师' : '新增技师'}</div>
            <div style={{ color: 'rgba(255,255,255,0.8)', fontSize: 12, marginTop: 2 }}>
              {isEdit ? '✏️ 修改技师档案信息' : '🎉 欢迎成为技师团队的一员，创造属于你的辉煌！'}
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
      <Form form={form} layout="vertical" size="middle" initialValues={{ gender: 2, lang: 'zh', password: '123456', commissionRate: 70, settlementMode: 3, commissionType: 0, commissionRatePct: 60 }}>

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
              <Select placeholder="请选择国籍" allowClear
                options={(nationItems.length > 0 ? nationItems : NATION_FALLBACK)
                  .filter(i => (i as any).status !== 0)
                  .map(i => ({ value: i.labelZh, label: `${i.remark ?? ''} ${i.labelZh}`.trim() }))} />
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
                options={bustOpts().length > 0 ? bustOpts() : BUST_FALLBACK}
              />
            </Form.Item>
          </Col>
          <Col span={8}>
            <Form.Item name="province" label="籍贯">
              <Input
                prefix={<EnvironmentOutlined style={{ color: '#06b6d4' }} />}
                placeholder="如：广东省"
              />
            </Form.Item>
          </Col>
          <Col span={8}>
            <Form.Item name="mobile" label="登录手机号" rules={isEdit ? [] : [
              { required: true, message: '请输入手机号' },
              { pattern: /^\+?[0-9]{8,20}$/, message: '手机号格式不正确' },
            ]}>
              <Input prefix={<PhoneOutlined style={{ color: '#52c41a' }} />} placeholder="+855xxxxxxxx" disabled={isEdit} />
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
          {!isEdit && (
            <Col span={8}>
              <Form.Item name="password" label="初始密码" rules={[{ required: true }]}>
                <Input.Password prefix={<LockOutlined style={{ color: '#fa8c16' }} />} placeholder="默认 123456" />
              </Form.Item>
            </Col>
          )}
        </Row>

        <Divider style={{ margin: '8px 0 16px' }} />

        {/* ── 服务信息 ── */}
        {sectionLabel(<EnvironmentOutlined />, '服务信息')}
        <Row gutter={16}>
          <Col span={8}>
            <Form.Item name="serviceCity" label="服务城市">
              <Select placeholder="请选择城市" allowClear
                options={cityOpts().length > 0 ? cityOpts() : CITY_FALLBACK}
                suffixIcon={<EnvironmentOutlined style={{ color: '#1677ff' }} />} />
            </Form.Item>
          </Col>
          <Col span={8}>
            <Form.Item name="lang" label="常用语言">
              <Select suffixIcon={<GlobalOutlined style={{ color: '#722ed1' }} />}
                options={langOpts().length > 0 ? langOpts() : LANG_FALLBACK} />
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

        {/* ── 服务项目 ── */}
        {sectionLabel(<AppstoreOutlined />, '服务项目')}

        {/* 隐藏的 Form 字段，用于持久化 serviceItemIds 数组到 form store */}
        <Form.Item name="serviceItemIds" hidden noStyle>
          <Select mode="multiple" options={[]} style={{ display: 'none' }} />
        </Form.Item>
        <Form.Item noStyle shouldUpdate>
          {() => {
            const selectedIds: number[] = form.getFieldValue('serviceItemIds') ?? []

            const toggleItem = (id: number) => {
              const cur: number[] = form.getFieldValue('serviceItemIds') ?? []
              const next = cur.includes(id) ? cur.filter(x => x !== id) : [...cur, id]
              form.setFieldValue('serviceItemIds', next)
              // 清除被取消选中项的专属定价
              if (!next.includes(id)) {
                setPricingMap(prev => { const m = { ...prev }; delete m[id]; return m })
              }
            }

            if (dbCategories.length === 0) {
              return (
                <div style={{
                  border: '1.5px dashed #e5e7eb', borderRadius: 12, padding: '24px 0',
                  textAlign: 'center', color: '#9ca3af', marginBottom: 16,
                }}>
                  <AppstoreOutlined style={{ fontSize: 28, marginBottom: 8, display: 'block' }} />
                  <div style={{ fontSize: 13, fontWeight: 600 }}>暂无服务项目</div>
                  <div style={{ fontSize: 11, marginTop: 4 }}>请先在「服务类目」页面添加子类目</div>
                </div>
              )
            }

            return (
              <div style={{ marginBottom: 16 }}>
                {/* 已选统计 */}
                <div style={{
                  display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                  marginBottom: 10,
                }}>
                  <span style={{ fontSize: 12, color: '#6b7280' }}>
                    共 {dbCategories.length} 项服务，点击卡片选择/取消
                  </span>
                  {selectedIds.length > 0 && (
                    <span style={{
                      fontSize: 12, fontWeight: 700, color: '#6366f1',
                      background: '#eef2ff', padding: '2px 10px', borderRadius: 20,
                      border: '1px solid #c7d2fe',
                    }}>
                      已选 {selectedIds.length} 项
                    </span>
                  )}
                </div>

                {/* 卡片网格 — 紧凑横排 4列 */}
                <div style={{
                  display: 'grid',
                  gridTemplateColumns: 'repeat(4, 1fr)',
                  gap: 6,
                  maxHeight: 240,
                  overflowY: 'auto',
                  paddingRight: 2,
                }}>
                  {dbCategories.map(s => {
                    const selected = selectedIds.includes(s.id)
                    const isSpecial = s.isSpecial === 1
                    return (
                      <div
                        key={s.id}
                        onClick={() => toggleItem(s.id)}
                        style={{
                          position: 'relative',
                          borderRadius: 8,
                          border: selected ? '1.5px solid #6366f1' : '1.5px solid #e5e7eb',
                          background: selected
                            ? 'linear-gradient(135deg,#eef2ff 0%,#f5f3ff 100%)'
                            : '#fff',
                          padding: '7px 8px 6px',
                          cursor: 'pointer',
                          transition: 'border-color 0.15s, background 0.15s, box-shadow 0.15s',
                          boxShadow: selected
                            ? '0 0 0 2.5px rgba(99,102,241,0.13), 0 2px 8px rgba(99,102,241,0.10)'
                            : '0 1px 3px rgba(0,0,0,0.04)',
                          userSelect: 'none',
                          display: 'flex',
                          flexDirection: 'column',
                          gap: 4,
                        }}
                        onMouseEnter={e => {
                          if (!selected) {
                            const el = e.currentTarget as HTMLDivElement
                            el.style.borderColor = '#a5b4fc'
                            el.style.boxShadow = '0 2px 10px rgba(99,102,241,0.12)'
                          }
                        }}
                        onMouseLeave={e => {
                          if (!selected) {
                            const el = e.currentTarget as HTMLDivElement
                            el.style.borderColor = '#e5e7eb'
                            el.style.boxShadow = '0 1px 3px rgba(0,0,0,0.04)'
                          }
                        }}
                      >
                        {/* 顶部: 图标 + 选中圆 */}
                        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                          {/* 图标气泡 */}
                          <div style={{
                            width: 26, height: 26, borderRadius: 8, flexShrink: 0,
                            background: selected
                              ? 'linear-gradient(135deg,#6366f1,#8b5cf6)'
                              : 'linear-gradient(135deg,#f1f5f9,#e2e8f0)',
                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                            fontSize: 13,
                            boxShadow: selected ? '0 2px 6px rgba(99,102,241,0.4)' : 'none',
                            transition: 'all 0.15s',
                          }}>
                            {s.icon
                              ? <span style={{ lineHeight: 1 }}>{s.icon}</span>
                              : <AppstoreOutlined style={{ color: selected ? '#fff' : '#94a3b8', fontSize: 12 }} />
                            }
                          </div>
                          {/* 选中圆 */}
                          <div style={{
                            width: 15, height: 15, borderRadius: '50%', flexShrink: 0,
                            border: selected ? 'none' : '1.5px solid #d1d5db',
                            background: selected ? '#6366f1' : '#fff',
                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                            transition: 'all 0.15s',
                          }}>
                            {selected && (
                              <svg width="9" height="7" viewBox="0 0 9 7" fill="none">
                                <path d="M1 3.5L3.5 6L8 1" stroke="#fff" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"/>
                              </svg>
                            )}
                          </div>
                        </div>

                        {/* 名称 */}
                        <div style={{
                          fontWeight: 600, fontSize: 11, lineHeight: 1.35,
                          color: selected ? '#4338ca' : '#1e293b',
                          overflow: 'hidden',
                          display: '-webkit-box',
                          WebkitLineClamp: 2,
                          WebkitBoxOrient: 'vertical' as const,
                        }}>
                          {s.nameZh}
                        </div>

                        {/* 底部: 类型标签 + 价格 */}
                        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 2 }}>
                          {isSpecial ? (
                            <span style={{
                              fontSize: 9, padding: '0 4px', borderRadius: 4, lineHeight: '14px',
                              background: '#fff7ed', color: '#ea580c',
                              border: '1px solid #fed7aa', fontWeight: 700,
                            }}>特殊</span>
                          ) : (
                            <span style={{
                              fontSize: 9, padding: '0 4px', borderRadius: 4, lineHeight: '14px',
                              background: '#f0fdf4', color: '#16a34a',
                              border: '1px solid #bbf7d0', fontWeight: 700,
                            }}>常规</span>
                          )}
                          <span style={{
                            fontSize: 10, fontWeight: 700,
                            color: selected ? '#6366f1' : (s.price != null ? '#374151' : '#cbd5e1'),
                          }}>
                            {s.price != null ? `$${s.price}` : s.duration ? `${s.duration}′` : '—'}
                          </span>
                        </div>
                      </div>
                    )
                  })}
                </div>
              </div>
            )
          }}
        </Form.Item>

        {/* ── 服务定价（选中服务项目后显示） ── */}
        <Form.Item noStyle shouldUpdate>
          {() => {
            const selectedIds: number[] = form.getFieldValue('serviceItemIds') ?? []
            const selectedSvcs = dbCategories.filter(s => selectedIds.includes(s.id))
            const specialSvcs = selectedSvcs.filter(s => s.isSpecial === 1)
            if (selectedSvcs.length === 0) return null
            return (
              <div style={{
                marginBottom: 16, borderRadius: 10,
                border: '1.5px solid #e0e7ff',
                overflow: 'hidden',
              }}>
                {/* 表头 */}
                <div style={{
                  display: 'grid', gridTemplateColumns: '1fr 90px 120px',
                  gap: 8, padding: '8px 14px',
                  background: 'linear-gradient(135deg,#eef2ff,#f5f3ff)',
                  fontSize: 11, color: '#6366f1', fontWeight: 700,
                }}>
                  <span>服务项目</span>
                  <span style={{ textAlign: 'right' }}>系统指导价</span>
                  <span style={{ textAlign: 'right' }}>
                    本店定价
                    <Tooltip title="🟢 常规项目：使用系统统一定价，不可修改。⭐ 特殊项目：商户可为该技师单独设置价格。">
                      <InfoCircleOutlined style={{ marginLeft: 4, cursor: 'pointer' }} />
                    </Tooltip>
                  </span>
                </div>
                {selectedSvcs.map((s, idx) => {
                  const currentPrice = pricingMap[s.id]
                  const isSpecial = s.isSpecial === 1
                  return (
                    <div key={s.id} style={{
                      display: 'grid', gridTemplateColumns: '1fr 90px 120px',
                      gap: 8, padding: '10px 14px', alignItems: 'center',
                      background: idx % 2 === 0 ? '#fff' : '#fafbff',
                      borderTop: '1px solid #eef0f8',
                    }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                        <span style={{ fontSize: 15 }}>{s.icon ?? '💆'}</span>
                        <div>
                          <div style={{ fontWeight: 600, fontSize: 12, color: '#111827', display: 'flex', alignItems: 'center', gap: 4 }}>
                            {s.nameZh}
                            {isSpecial
                              ? <span style={{ fontSize: 9, padding: '1px 5px', borderRadius: 10, background: '#fff7ed', color: '#f97316', border: '1px solid #fed7aa', fontWeight: 700 }}>特殊</span>
                              : <span style={{ fontSize: 9, padding: '1px 5px', borderRadius: 10, background: '#f0fdf4', color: '#16a34a', border: '1px solid #bbf7d0', fontWeight: 700 }}>常规</span>
                            }
                          </div>
                          {s.duration && <div style={{ fontSize: 10, color: '#9ca3af' }}>{s.duration}min</div>}
                        </div>
                      </div>
                      <div style={{ textAlign: 'right', fontSize: 13, color: '#6b7280', fontWeight: 600 }}>
                        {s.price != null ? `$${s.price}` : '—'}
                      </div>
                      <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
                        {isSpecial ? (
                          <InputNumber
                            size="small"
                            min={0}
                            precision={2}
                            value={currentPrice ?? undefined}
                            placeholder={s.price != null ? String(s.price) : '输入价格'}
                            prefix="$"
                            style={{
                              width: 110,
                              borderColor: currentPrice != null ? '#6366f1' : undefined,
                              background: currentPrice != null ? '#eef2ff' : undefined,
                            }}
                            onChange={v => setPricingMap(prev => ({ ...prev, [s.id]: v ?? null }))}
                          />
                        ) : (
                          <span style={{ fontSize: 12, color: '#9ca3af', fontStyle: 'italic' }}>统一定价</span>
                        )}
                      </div>
                    </div>
                  )
                })}
                {specialSvcs.length > 0 && (
                  <div style={{
                    padding: '6px 14px',
                    background: 'linear-gradient(135deg,#eef2ff,#f5f3ff)',
                    borderTop: '1px solid #e0e7ff',
                    fontSize: 11, color: '#6366f1',
                  }}>
                    ⭐ 已设专属价：
                    <strong>{specialSvcs.filter(s => pricingMap[s.id] != null).length}</strong> / {specialSvcs.length} 项特殊服务
                  </div>
                )}
              </div>
            )
          }}
        </Form.Item>

        <Divider style={{ margin: '8px 0 16px' }} />

        {/* ── 工资结算配置 ── */}
        {sectionLabel(<CalendarOutlined />, '工资结算配置')}
        <Row gutter={12}>
          <Col span={8}>
            <Form.Item name="settlementMode" label="结算方式"
              tooltip="决定多久汇总一次工资：每笔单独结，或按日/周/月批量结算">
              <Select placeholder="选择结算周期"
                options={settleModeOpts().length > 0
                  ? settleModeOpts().map(o => ({ ...o, value: Number(o.value) }))
                  : SETTLE_FALLBACK} />
            </Form.Item>
          </Col>
          <Col span={8}>
            <Form.Item name="commissionType" label="提成类型"
              tooltip="按比例：每单按营业额比例计算；固定金额：每单固定提成">
              <Select placeholder="选择提成类型"
                options={commTypeOpts().length > 0
                  ? commTypeOpts().map(o => ({ ...o, value: Number(o.value) }))
                  : COMM_TYPE_FALLBACK} />
            </Form.Item>
          </Col>
          <Col span={8}>
            <Form.Item
              noStyle
              shouldUpdate={(prev, cur) => prev.commissionType !== cur.commissionType}
            >
              {({ getFieldValue }) => {
                const type = getFieldValue('commissionType')
                return type === 1 ? (
                  <Form.Item name="commissionCurrency" label="固定金额币种">
                    <Select placeholder="结算币种"
                      options={currencyOpts().length > 0 ? currencyOpts() : CURRENCY_FALLBACK} />
                  </Form.Item>
                ) : (
                  <Form.Item name="commissionRatePct" label="提成比例 (%)">
                    <InputNumber min={0} max={100} step={0.5} style={{ width: '100%' }}
                      formatter={v => `${v}%`} parser={v => v?.replace('%', '') as any}
                      placeholder="如：60" />
                  </Form.Item>
                )
              }}
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
            multiple
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
            {isEdit ? '保存修改' : '确认新增'}
          </Button>
        </div>
      </Form>
    </Modal>
  )
}
