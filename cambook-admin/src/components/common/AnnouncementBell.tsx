/**
 * AnnouncementBell — 公告铃铛通知组件（仅商户端顶栏显示）
 *
 * - 轮询 /merchant/announce/unread-count（30s 间隔）
 * - 点击铃铛弹出 Popover 展示未读公告列表
 * - 点击公告 → 标记已读 + 显示详情弹窗 + 铃铛数字 -1
 */
import { useState, useEffect, useRef, useCallback } from 'react'
import {
  Badge, Popover, Button, List, Tag, Typography, Modal, Empty,
  Spin, Space, Tooltip,
} from 'antd'
import {
  BellOutlined, SoundOutlined, GlobalOutlined, TeamOutlined,
  ClockCircleOutlined, UserOutlined, CheckCircleOutlined,
} from '@ant-design/icons'
import { merchantPortalApi, type AnnouncementVO } from '../../api/api'
import { fmtTime } from '../../utils/time'
import 'react-quill-new/dist/quill.snow.css'

const { Text, Title } = Typography

const POLL_INTERVAL = 5_000 // 5 秒

export default function AnnouncementBell() {
  const [unreadCount, setUnreadCount]   = useState(0)
  const [popOpen,     setPopOpen]       = useState(false)
  const [unreadList,  setUnreadList]    = useState<AnnouncementVO[]>([])
  const [listLoading, setListLoading]   = useState(false)
  const [viewItem,    setViewItem]      = useState<AnnouncementVO | null>(null)
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null)

  // ── 轮询未读数 ────────────────────────────────────────────────────────────
  const fetchCount = useCallback(async () => {
    try {
      const res = await merchantPortalApi.announceUnreadCount()
      if (res.data?.code === 200) {
        setUnreadCount(res.data.data ?? 0)
      }
    } catch { /* 静默失败，不影响主流程 */ }
  }, [])

  useEffect(() => {
    fetchCount()
    timerRef.current = setInterval(fetchCount, POLL_INTERVAL)
    return () => { if (timerRef.current) clearInterval(timerRef.current) }
  }, [fetchCount])

  // ── 打开弹窗：拉取未读列表 ────────────────────────────────────────────────
  const handleOpenPop = async (open: boolean) => {
    setPopOpen(open)
    if (open) {
      setListLoading(true)
      try {
        const res = await merchantPortalApi.announceUnreadList()
        if (res.data?.code === 200) setUnreadList(res.data.data ?? [])
      } finally {
        setListLoading(false)
      }
    }
  }

  // ── 点击公告：标记已读 + 查看详情 ─────────────────────────────────────────
  const handleRead = async (item: AnnouncementVO) => {
    setViewItem(item)
    setPopOpen(false)
    try {
      const res = await merchantPortalApi.announceRead(item.id)
      if (res.data?.code === 200) {
        const newCount = res.data.data ?? 0
        setUnreadCount(newCount)
        setUnreadList(prev => prev.filter(a => a.id !== item.id))
      }
    } catch { /* 静默 */ }
  }

  // ── Popover 内容 ──────────────────────────────────────────────────────────
  const popContent = (
    <div style={{ width: 360, maxHeight: 480, overflow: 'hidden auto' }}>
      {listLoading ? (
        <div style={{ textAlign: 'center', padding: '32px 0' }}><Spin /></div>
      ) : unreadList.length === 0 ? (
        <Empty
          image={Empty.PRESENTED_IMAGE_SIMPLE}
          description="暂无未读公告"
          style={{ padding: '24px 0' }}
        />
      ) : (
        <List
          dataSource={unreadList}
          renderItem={item => (
            <List.Item
              style={{
                padding: '10px 12px',
                cursor: 'pointer',
                borderRadius: 8,
                transition: 'background 0.15s',
              }}
              className="announce-bell-item"
              onClick={() => handleRead(item)}
            >
              <style>{`
                .announce-bell-item:hover { background: #f5f3ff; }
              `}</style>
              <div style={{ width: '100%' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 8 }}>
                  <Space size={5}>
                    {item.targetType === 2
                      ? <GlobalOutlined style={{ color: '#6366f1', fontSize: 12 }} />
                      : <TeamOutlined   style={{ color: '#f59e0b', fontSize: 12 }} />}
                    <Text strong style={{ fontSize: 13, lineHeight: 1.4 }}>
                      {item.title}
                    </Text>
                  </Space>
                  <Tag color="purple" style={{ fontSize: 11, borderRadius: 6, flexShrink: 0 }}>未读</Tag>
                </div>
                <div style={{ marginTop: 4, display: 'flex', gap: 12 }}>
                  <Text type="secondary" style={{ fontSize: 11 }}>
                    <ClockCircleOutlined style={{ marginRight: 3 }} />
                    {fmtTime(item.createTime, 'MM-DD HH:mm')}
                  </Text>
                  {item.createBy && (
                    <Text type="secondary" style={{ fontSize: 11 }}>
                      <UserOutlined style={{ marginRight: 3 }} />{item.createBy}
                    </Text>
                  )}
                </div>
              </div>
            </List.Item>
          )}
        />
      )}
    </div>
  )

  const popTitle = (
    <div style={{
      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
      margin: '-12px -16px 12px',
      padding: '12px 16px',
      borderRadius: '8px 8px 0 0',
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
    }}>
      <Space size={8}>
        <SoundOutlined style={{ color: '#fff', fontSize: 14 }} />
        <Text strong style={{ color: '#fff', fontSize: 13 }}>内部公告</Text>
        {unreadCount > 0 && (
          <Tag color="red" style={{ borderRadius: 10, fontSize: 11, padding: '0 6px' }}>
            {unreadCount} 条未读
          </Tag>
        )}
      </Space>
      {unreadCount === 0 && (
        <Space size={4}>
          <CheckCircleOutlined style={{ color: 'rgba(255,255,255,0.8)', fontSize: 12 }} />
          <Text style={{ color: 'rgba(255,255,255,0.8)', fontSize: 12 }}>全部已读</Text>
        </Space>
      )}
    </div>
  )

  return (
    <>
      <Popover
        open={popOpen}
        onOpenChange={handleOpenPop}
        content={popContent}
        title={popTitle}
        trigger="click"
        placement="bottomRight"
        overlayStyle={{ paddingTop: 4 }}
        overlayInnerStyle={{ padding: 12, borderRadius: 12, boxShadow: '0 8px 32px rgba(99,102,241,0.18)' }}
        arrow={false}
      >
        <Tooltip title="公告通知" placement="bottom">
          <Badge
            count={unreadCount}
            overflowCount={99}
            size="small"
            style={{ boxShadow: '0 0 0 1.5px #fff' }}
          >
            <Button
              type="text"
              icon={
                <BellOutlined style={{
                  fontSize: 18,
                  color: unreadCount > 0 ? '#6366f1' : '#6b7280',
                  transition: 'color 0.2s',
                }} />
              }
            />
          </Badge>
        </Tooltip>
      </Popover>

      {/* ── 公告详情弹窗 ── */}
      <Modal
        open={!!viewItem}
        onCancel={() => setViewItem(null)}
        footer={
          <Button
            type="primary"
            onClick={() => setViewItem(null)}
            style={{ background: 'linear-gradient(135deg,#667eea,#764ba2)', border: 'none', borderRadius: 8 }}
          >
            已阅，关闭
          </Button>
        }
        width={640}
        title={
          <div style={{
            background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
            margin: '-20px -24px 0',
            padding: '20px 24px 18px',
            borderRadius: '8px 8px 0 0',
          }}>
            <Title level={5} style={{ color: '#fff', margin: 0 }}>
              <SoundOutlined style={{ marginRight: 8 }} />
              {viewItem?.title}
            </Title>
            <div style={{ color: 'rgba(255,255,255,0.72)', fontSize: 12, marginTop: 8, display: 'flex', gap: 16, flexWrap: 'wrap' }}>
              <span>
                <ClockCircleOutlined style={{ marginRight: 4 }} />
                {fmtTime(viewItem?.createTime, 'YYYY-MM-DD HH:mm')}
              </span>
              {viewItem?.createBy && (
                <span><UserOutlined style={{ marginRight: 4 }} />{viewItem.createBy}</span>
              )}
              <span>
                {viewItem?.targetType === 2
                  ? <><GlobalOutlined style={{ marginRight: 4 }} />全商户</>
                  : <><TeamOutlined   style={{ marginRight: 4 }} />本部门</>}
              </span>
            </div>
          </div>
        }
        styles={{ body: { paddingTop: 20 } }}
      >
        {viewItem && (
          <div
            className="ql-editor"
            style={{ padding: 0, minHeight: 80, lineHeight: 1.8 }}
            dangerouslySetInnerHTML={{ __html: viewItem.content }}
          />
        )}
      </Modal>
    </>
  )
}
