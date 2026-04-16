import { useState, useEffect } from 'react'
import { Form, Input, Button, Card, Typography, message, Divider, Space, Segmented, Tooltip } from 'antd'
import {
  LockOutlined, MobileOutlined, ShopOutlined, ArrowLeftOutlined,
  SafetyOutlined, TeamOutlined, UserOutlined, NumberOutlined,
  CheckCircleFilled,
} from '@ant-design/icons'
import { useNavigate, Link } from 'react-router-dom'
import { useAuthStore } from '../../store/authStore'
import { merchantPortalApi } from '../../api/api'

const { Title, Text } = Typography

type LoginMode = 'owner' | 'staff'

/** localStorage key for remembering the last-used merchant code */
const MERCHANT_NO_KEY = 'cambook_last_merchant_no'

const getSavedNo  = () => localStorage.getItem(MERCHANT_NO_KEY) ?? ''
const saveNo      = (no: string) => no ? localStorage.setItem(MERCHANT_NO_KEY, no.trim()) : undefined

export default function MerchantLoginPage() {
  const navigate  = useNavigate()
  const authStore = useAuthStore()
  const [loading,   setLoading]   = useState(false)
  const [mode,      setMode]      = useState<LoginMode>(() => getSavedNo() ? 'staff' : 'owner')
  const [remembered, setRemembered] = useState(false) // tracks if current merchantNo was auto-filled
  const [form] = Form.useForm()

  // On mount: pre-fill saved merchant code if exists
  useEffect(() => {
    const no = getSavedNo()
    if (no) {
      form.setFieldValue('merchantNo', no)
      setRemembered(true)
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const handleLogin = async (values: { merchantNo?: string; account: string; password: string }) => {
    setLoading(true)
    try {
      const merchantNo = mode === 'staff' ? (values.merchantNo ?? '') : undefined
      const res  = await merchantPortalApi.login({ merchantNo, account: values.account, password: values.password })
      const data = res.data?.data

      // Persist the merchant code for next visit
      if (mode === 'staff' && merchantNo) saveNo(merchantNo)

      authStore.updateToken(data.token)

      let menus: any[] = []
      try {
        const menusRes = await merchantPortalApi.menus()
        menus = menusRes.data?.data ?? []
      } catch { /* 菜单加载失败降级为空 */ }

      authStore.setMerchantLogin(
        {
          merchantId:     data.userId,
          merchantName:   data.merchantName  ?? '商户',
          merchantLogo:   data.merchantLogo,
          merchantMobile: data.merchantMobile,
        },
        data.token,
        menus,
      )

      const displayName = data.staffName ?? data.merchantName ?? '商户'
      message.success(`欢迎回来，${displayName}！`)
      navigate('/merchant/dashboard')
    } catch {
      // errors handled in interceptor
    } finally {
      setLoading(false)
    }
  }

  const handleModeChange = (val: string) => {
    const newMode = val as LoginMode
    setMode(newMode)
    // Preserve the merchantNo field when switching to staff mode; clear other fields
    form.resetFields(['account', 'password'])
    if (newMode === 'staff') {
      const no = getSavedNo()
      if (no) { form.setFieldValue('merchantNo', no); setRemembered(true) }
    }
  }

  const handleMerchantNoChange = () => {
    // Once the user manually edits the field, clear the "remembered" indicator
    setRemembered(false)
  }

  return (
    <div style={{
      minHeight: '100vh',
      background: 'linear-gradient(135deg, #0f2027 0%, #203a43 40%, #2c5364 100%)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      position: 'relative',
      overflow: 'hidden',
    }}>
      {/* 装饰圆环 */}
      {[
        { w: 500, h: 500, top: '-100px', left: '-100px', color: 'rgba(41,182,246,0.06)' },
        { w: 350, h: 350, bottom: '-80px', right: '-50px', color: 'rgba(38,198,218,0.08)' },
        { w: 200, h: 200, top: '40%', right: '15%', color: 'rgba(0,229,255,0.04)' },
      ].map((s, i) => (
        <div key={i} style={{
          position: 'absolute', borderRadius: '50%',
          width: s.w, height: s.h, background: s.color,
          ...(s.top ? { top: s.top } : {}), ...(s.bottom ? { bottom: s.bottom } : {}),
          ...(s.left ? { left: s.left } : {}), ...(s.right ? { right: s.right } : {}),
          pointerEvents: 'none',
        }} />
      ))}

      {/* 返回管理员登录 */}
      <div style={{ position: 'absolute', top: 24, left: 32 }}>
        <Link to="/login">
          <Button
            type="text"
            icon={<ArrowLeftOutlined />}
            style={{ color: 'rgba(255,255,255,0.6)', fontSize: 13 }}
          >
            管理员登录
          </Button>
        </Link>
      </div>

      {/* 登录卡片 */}
      <Card
        style={{
          width: 480,
          borderRadius: 24,
          boxShadow: '0 32px 80px rgba(0,0,0,0.6)',
          background: 'rgba(255,255,255,0.97)',
          border: 'none',
          zIndex: 1,
        }}
        styles={{ body: { padding: '44px 44px 36px' } }}
      >
        {/* Logo */}
        <div style={{ textAlign: 'center', marginBottom: 28 }}>
          <div style={{
            width: 76, height: 76,
            background: 'linear-gradient(135deg, #29B6F6 0%, #0288D1 100%)',
            borderRadius: 20,
            display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 12px 32px rgba(41,182,246,0.45)',
            marginBottom: 16,
          }}>
            <ShopOutlined style={{ fontSize: 36, color: '#fff' }} />
          </div>
          <Title level={3} style={{ margin: '0 0 4px', color: '#1a2940', fontSize: 22, fontWeight: 800 }}>
            商户管理后台
          </Title>
          <Text type="secondary" style={{ fontSize: 13 }}>
            CamBook 商户专属管理平台
          </Text>
        </div>

        {/* 登录身份切换 */}
        <div style={{ marginBottom: 24 }}>
          <Segmented
            block
            value={mode}
            onChange={handleModeChange}
            options={[
              { label: <span><UserOutlined style={{ marginRight: 6 }} />商户主账号</span>,  value: 'owner' },
              { label: <span><TeamOutlined style={{ marginRight: 6 }} />员工账号</span>,    value: 'staff' },
            ]}
            style={{ borderRadius: 10, padding: 3 }}
          />
          <div style={{
            marginTop: 8,
            padding: '7px 12px',
            background: mode === 'owner' ? '#f0f9ff' : '#fff7ed',
            borderRadius: 8,
            border: `1px solid ${mode === 'owner' ? '#bae6fd' : '#fed7aa'}`,
          }}>
            <Text style={{ fontSize: 12, color: mode === 'owner' ? '#0369a1' : '#c2410c' }}>
              {mode === 'owner'
                ? '商户主直接使用注册手机号或用户名登录，无需填写商户编号'
                : '员工账号须先填写商户编号，确保账号归属正确、数据安全隔离'}
            </Text>
          </div>
        </div>

        <Divider style={{ margin: '0 0 24px', borderColor: '#e8f4fc' }}>
          <Text style={{ color: '#29B6F6', fontSize: 12, fontWeight: 600 }}>
            <SafetyOutlined style={{ marginRight: 4 }} />安全登录
          </Text>
        </Divider>

        <Form
          form={form}
          onFinish={handleLogin}
          size="large"
          autoComplete="off"
        >
          {/* 员工模式才显示商户编号 */}
          {mode === 'staff' && (
            <Form.Item
              name="merchantNo"
              rules={[{ required: true, message: '请输入商户编号' }]}
              extra={
                remembered
                  ? (
                    <span style={{ fontSize: 12, color: '#16a34a', display: 'flex', alignItems: 'center', gap: 4, marginTop: 4 }}>
                      <CheckCircleFilled style={{ fontSize: 12 }} />
                      已记住上次使用的商户编号
                    </span>
                  )
                  : null
              }
            >
              <Input
                prefix={<NumberOutlined style={{ color: '#f97316' }} />}
                placeholder="商户编号（由商户负责人提供）"
                style={{ borderRadius: 12, height: 50, fontSize: 14 }}
                onChange={handleMerchantNoChange}
                suffix={
                  remembered
                    ? (
                      <Tooltip title="已自动填入上次使用的商户编号">
                        <CheckCircleFilled style={{ color: '#16a34a', fontSize: 14 }} />
                      </Tooltip>
                    )
                    : null
                }
              />
            </Form.Item>
          )}

          <Form.Item
            name="account"
            rules={[{ required: true, message: '请输入手机号或用户名' }]}
          >
            <Input
              prefix={<MobileOutlined style={{ color: '#29B6F6' }} />}
              placeholder={mode === 'owner' ? '注册手机号 / 用户名' : '手机号 / 用户名'}
              style={{ borderRadius: 12, height: 50, fontSize: 14 }}
            />
          </Form.Item>

          <Form.Item
            name="password"
            rules={[{ required: true, message: '请输入密码' }]}
            style={{ marginBottom: 28 }}
          >
            <Input.Password
              prefix={<LockOutlined style={{ color: '#29B6F6' }} />}
              placeholder="登录密码"
              style={{ borderRadius: 12, height: 50, fontSize: 14 }}
            />
          </Form.Item>

          <Form.Item style={{ marginBottom: 16 }}>
            <Button
              type="primary"
              htmlType="submit"
              loading={loading}
              block
              style={{
                height: 54,
                borderRadius: 14,
                fontSize: 16,
                fontWeight: 700,
                background: 'linear-gradient(135deg, #29B6F6, #0288D1)',
                border: 'none',
                boxShadow: '0 8px 24px rgba(41,182,246,0.45)',
                letterSpacing: 2,
              }}
            >
              {loading ? '登录中...' : '进 入 商 户 后 台'}
            </Button>
          </Form.Item>
        </Form>

        <Space orientation="vertical" size={6} style={{ width: '100%', textAlign: 'center' }}>
          <Text type="secondary" style={{ fontSize: 11, color: '#bbb' }}>
            © 2026 CamBook. All rights reserved.
          </Text>
        </Space>
      </Card>
    </div>
  )
}
