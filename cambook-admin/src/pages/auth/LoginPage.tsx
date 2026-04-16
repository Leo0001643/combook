import { useState } from 'react'
import { Form, Input, Button, Card, Typography, message, Divider } from 'antd'
import { LockOutlined, UserOutlined, SafetyOutlined, ShopOutlined } from '@ant-design/icons'
import { useNavigate, Link } from 'react-router-dom'
import { useAuthStore } from '../../store/authStore'
import { authApi, type PermissionVO } from '../../api/api'

const { Title, Text } = Typography

export default function LoginPage() {
  const navigate  = useNavigate()
  const authStore = useAuthStore()
  const [loading, setLoading] = useState(false)
  const [form]    = Form.useForm()

  const handleLogin = async (values: { username: string; password: string }) => {
    setLoading(true)
    try {
      // 1. 账号密码登录，获取 token + permissions
      const loginRes = await authApi.login({ username: values.username, password: values.password })
      const loginData = loginRes.data.data

      // 2. 预先写入 token，使 request 拦截器能携带认证头
      authStore.updateToken(loginData.token)

      // 3. 拉取当前用户菜单树
      let menus: PermissionVO[] = []
      try {
        const menuRes = await authApi.menus()
        menus = menuRes.data.data ?? []
      } catch {
        // 菜单拉取失败不影响登录流程
      }

      // 4. 写入完整登录状态
      authStore.setLogin(
        { userId: loginData.userId, username: values.username },
        loginData.token,
        loginData.permissions ?? [],
        menus,
      )

      message.success('登录成功！')
      navigate('/dashboard')
    } catch {
      // 错误已在请求拦截器统一处理
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="login-container">
      {/* 装饰性浮动圆 */}
      <div style={{
        position: 'absolute', top: '15%', left: '5%',
        width: 320, height: 320, borderRadius: '50%',
        background: 'radial-gradient(circle, rgba(245,166,35,0.12) 0%, transparent 70%)',
        pointerEvents: 'none',
      }} />
      <div style={{
        position: 'absolute', bottom: '10%', right: '5%',
        width: 240, height: 240, borderRadius: '50%',
        background: 'radial-gradient(circle, rgba(249,115,22,0.10) 0%, transparent 70%)',
        pointerEvents: 'none',
      }} />

      {/* 登录卡片 */}
      <Card
        style={{
          width: 440,
          borderRadius: 20,
          boxShadow: '0 24px 80px rgba(0,0,0,0.5)',
          background: 'rgba(255,255,255,0.99)',
          border: 'none',
          zIndex: 1,
        }}
        styles={{ body: { padding: '44px 44px 36px' } }}
      >
        {/* Logo & 标题 */}
        <div style={{ textAlign: 'center', marginBottom: 36 }}>
          <div style={{
            width: 72, height: 72,
            background: 'linear-gradient(135deg, #F5A623 0%, #F97316 100%)',
            borderRadius: 20,
            display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 12px 32px rgba(245,166,35,0.45)',
            marginBottom: 16,
          }}>
            <SafetyOutlined style={{ fontSize: 32, color: '#fff' }} />
          </div>
          <Title level={3} style={{ margin: '0 0 4px', color: '#1a1f2e', fontSize: 22 }}>
            CamBook 管理后台
          </Title>
          <Text type="secondary" style={{ fontSize: 13 }}>
            上门按摩 SPA 平台运营管理系统
          </Text>
        </div>

        <Divider style={{ margin: '0 0 28px', borderColor: '#f5f0e8' }}>
          <Text style={{ color: '#f5a623', fontSize: 12 }}>安全登录</Text>
        </Divider>

        <Form
          form={form}
          onFinish={handleLogin}
          size="large"
          autoComplete="off"
          initialValues={{ username: 'admin' }}
        >
          <Form.Item
            name="username"
            rules={[{ required: true, message: '请输入账号' }]}
          >
            <Input
              prefix={<UserOutlined style={{ color: '#F5A623' }} />}
              placeholder="管理员账号"
              style={{ borderRadius: 10, height: 48 }}
            />
          </Form.Item>

          <Form.Item
            name="password"
            rules={[{ required: true, message: '请输入密码' }]}
            style={{ marginBottom: 24 }}
          >
            <Input.Password
              prefix={<LockOutlined style={{ color: '#F5A623' }} />}
              placeholder="登录密码"
              style={{ borderRadius: 10, height: 48 }}
            />
          </Form.Item>

          <Form.Item style={{ marginBottom: 16 }}>
            <Button
              type="primary"
              htmlType="submit"
              loading={loading}
              block
              style={{
                height: 52,
                borderRadius: 12,
                fontSize: 16,
                fontWeight: 700,
                background: 'linear-gradient(135deg, #F5A623, #F97316)',
                border: 'none',
                boxShadow: '0 6px 20px rgba(245,166,35,0.45)',
                letterSpacing: 2,
              }}
            >
              {loading ? '登录中...' : '登 录'}
            </Button>
          </Form.Item>
        </Form>

        <div style={{ textAlign: 'center', marginTop: 12 }}>
          <Link to="/merchant/login">
            <Button
              type="link"
              icon={<ShopOutlined />}
              style={{ color: '#F5A623', fontSize: 13, padding: 0 }}
            >
              商户登录入口
            </Button>
          </Link>
        </div>
        <div style={{ textAlign: 'center', marginTop: 8 }}>
          <Text type="secondary" style={{ fontSize: 12 }}>
            © 2026 CamBook. All rights reserved.
          </Text>
        </div>
      </Card>
    </div>
  )
}
