import React from 'react'
import { Button, Result } from 'antd'
import { BugOutlined, ReloadOutlined } from '@ant-design/icons'

interface Props {
  children: React.ReactNode
  /** 可选的自定义降级 UI；不传则使用默认卡片样式 */
  fallback?: React.ReactNode
}

interface State {
  hasError: boolean
  error: Error | null
}

/**
 * 全局错误边界
 *
 * 包裹页面级 <Outlet />，捕获子树中任何 uncaught render error，
 * 防止整个应用白屏；改为展示友好的错误提示 + 刷新按钮。
 *
 * React 错误边界只能用 class component 实现。
 */
export class ErrorBoundary extends React.Component<Props, State> {
  constructor(props: Props) {
    super(props)
    this.state = { hasError: false, error: null }
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error, info: React.ErrorInfo) {
    console.error('[ErrorBoundary] Uncaught render error:', error, info.componentStack)
  }

  handleReset = () => {
    this.setState({ hasError: false, error: null })
  }

  render() {
    if (this.state.hasError) {
      if (this.props.fallback) return <>{this.props.fallback}</>
      return (
        <div style={{
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          minHeight: 400, padding: 40,
        }}>
          <Result
            icon={<BugOutlined style={{ color: '#ef4444' }} />}
            title={<span style={{ fontSize: 18, fontWeight: 700, color: '#111827' }}>页面加载出错</span>}
            subTitle={
              <div style={{ maxWidth: 480, textAlign: 'center' }}>
                <div style={{ color: '#6b7280', fontSize: 14, marginBottom: 8 }}>
                  页面渲染时发生了意外错误，请刷新重试。
                </div>
                {this.state.error && (
                  <code style={{
                    display: 'block', fontSize: 11, color: '#ef4444',
                    background: '#fef2f2', border: '1px solid #fecaca',
                    borderRadius: 6, padding: '6px 10px', marginTop: 8,
                    wordBreak: 'break-all', textAlign: 'left',
                  }}>
                    {this.state.error.message}
                  </code>
                )}
              </div>
            }
            extra={[
              <Button
                key="reset"
                type="primary"
                icon={<ReloadOutlined />}
                onClick={this.handleReset}
                style={{ background: 'linear-gradient(135deg,#6366f1,#8b5cf6)', border: 'none', borderRadius: 8 }}
              >
                重试
              </Button>,
              <Button
                key="reload"
                onClick={() => window.location.reload()}
                style={{ borderRadius: 8 }}
              >
                刷新页面
              </Button>,
            ]}
          />
        </div>
      )
    }
    return this.props.children
  }
}

export default ErrorBoundary
