import { useEffect, useState } from 'react'
import { Modal, Form, Input, Select, Avatar, Upload, Button, message } from 'antd'
import {
  UserOutlined, ManOutlined, WomanOutlined,
  PlusOutlined, LoadingOutlined, EditOutlined,
} from '@ant-design/icons'
import { uploadApi } from '../../api/api'
import type { MemberDetailVO } from './MemberDetailDrawer'

const { Option } = Select

interface Props {
  open: boolean
  member: MemberDetailVO | null
  onClose: () => void
  onSuccess: () => void
  updateFn: (data: any) => Promise<any>
}

export default function MemberEditModal({ open, member, onClose, onSuccess, updateFn }: Props) {
  const [form] = Form.useForm()
  const [submitting, setSubmitting] = useState(false)
  const [avatarUrl, setAvatarUrl] = useState<string>()
  const [avatarLoading, setAvatarLoading] = useState(false)

  useEffect(() => {
    if (open && member) {
      form.setFieldsValue({
        nickname: member.nickname,
        gender:   member.gender,
        telegram: member.telegram,
        address:  member.address,
      })
      setAvatarUrl(member.avatar)
    } else if (!open) {
      form.resetFields()
      setAvatarUrl(undefined)
    }
  }, [open, member])

  const handleAvatarUpload: any = async ({ file, onSuccess: ok, onError }: any) => {
    setAvatarLoading(true)
    try {
      const res = await uploadApi.image(file as File)
      const url = res.data?.data as string
      setAvatarUrl(url)
      ok?.({})
      message.success('头像上传成功')
    } catch (e: any) {
      onError?.(e)
      message.error('头像上传失败')
    } finally {
      setAvatarLoading(false)
    }
  }

  const handleSubmit = async () => {
    try {
      const values = await form.validateFields()
      setSubmitting(true)
      await updateFn({
        id:       member!.id,
        avatar:   avatarUrl,
        nickname: values.nickname,
        gender:   values.gender,
        telegram: values.telegram ?? null,
        address:  values.address  ?? null,
      })
      message.success('会员信息已更新！')
      onSuccess()
      onClose()
    } catch (e: any) {
      if (e?.response?.data?.message) message.error(e.response.data.message)
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <Modal
      title={
        <div style={{
          background: 'linear-gradient(135deg,#38bdf8,#0ea5e9)',
          margin: '-20px -24px 20px',
          padding: '18px 24px',
          borderRadius: '8px 8px 0 0',
          display: 'flex', alignItems: 'center', gap: 12,
        }}>
          <div style={{
            width: 38, height: 38, borderRadius: 10,
            background: 'rgba(255,255,255,0.2)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <EditOutlined style={{ color: '#fff', fontSize: 18 }} />
          </div>
          <div>
            <div style={{ color: '#fff', fontWeight: 800, fontSize: 16 }}>编辑会员</div>
            <div style={{ color: 'rgba(255,255,255,0.85)', fontSize: 12, marginTop: 2 }}>
              修改会员基本资料信息
            </div>
          </div>
        </div>
      }
      open={open}
      onCancel={onClose}
      width={480}
      footer={null}
      destroyOnHidden
    >
      {/* 头像上传 */}
      <div style={{ textAlign: 'center', marginBottom: 24 }}>
        <Upload
          showUploadList={false}
          accept="image/*"
          customRequest={handleAvatarUpload}
        >
          <div style={{ cursor: 'pointer', display: 'inline-block' }}>
            <Avatar
              src={avatarUrl}
              size={90}
              icon={<UserOutlined />}
              style={{
                border: '3px solid #e0f2fe',
                boxShadow: '0 4px 16px rgba(56,189,248,0.2)',
              }}
            />
            <div style={{
              marginTop: 8, fontSize: 12, color: '#38bdf8', fontWeight: 600,
            }}>
              {avatarLoading ? <LoadingOutlined /> : <PlusOutlined />}
              {' '}{avatarLoading ? '上传中...' : '点击更换头像'}
            </div>
          </div>
        </Upload>
      </div>

      <Form form={form} layout="vertical" size="middle">
        <Form.Item name="nickname" label="昵称" rules={[{ required: true, message: '请输入昵称' }]}>
          <Input
            prefix={<UserOutlined style={{ color: '#38bdf8' }} />}
            placeholder="请输入昵称"
            style={{ borderRadius: 8 }}
          />
        </Form.Item>

        <Form.Item name="gender" label="性别">
          <Select placeholder="请选择性别" style={{ borderRadius: 8 }}>
            <Option value={0}><span>⚪</span> 未知</Option>
            <Option value={1}><ManOutlined style={{ color: '#3b82f6' }} /> 男</Option>
            <Option value={2}><WomanOutlined style={{ color: '#ec4899' }} /> 女</Option>
          </Select>
        </Form.Item>

        <Form.Item name="telegram" label="Telegram 账号">
          <Input
            prefix={<span style={{ color: '#229ED9', fontWeight: 700 }}>@</span>}
            placeholder="不含@，如：username"
            style={{ borderRadius: 8 }}
          />
        </Form.Item>

        <Form.Item name="address" label="地址">
          <Input
            placeholder="请输入地址"
            style={{ borderRadius: 8 }}
          />
        </Form.Item>

        <div style={{
          display: 'flex', justifyContent: 'flex-end', gap: 10,
          marginTop: 8, paddingTop: 16, borderTop: '1px solid #f0f0f0',
        }}>
          <Button onClick={onClose} style={{ borderRadius: 8 }}>取消</Button>
          <Button
            type="primary" loading={submitting} onClick={handleSubmit}
            style={{
              background: 'linear-gradient(135deg,#38bdf8,#0ea5e9)',
              border: 'none', borderRadius: 8, minWidth: 100,
            }}
            icon={<EditOutlined />}
          >
            保存修改
          </Button>
        </div>
      </Form>
    </Modal>
  )
}
