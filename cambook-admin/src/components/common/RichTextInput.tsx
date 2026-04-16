/**
 * RichTextInput — 精美富文本编辑器组件
 *
 * 基于 react-quill，封装成与 Ant Design Form.Item 兼容的受控组件。
 * 支持：加粗 / 斜体 / 下划线 / 列表 / 链接 / 颜色 / 对齐 / 清空
 */
import ReactQuill from 'react-quill-new'
import 'react-quill-new/dist/quill.snow.css'

interface Props {
  value?: string
  onChange?: (v: string) => void
  placeholder?: string
  minHeight?: number
}

const TOOLBAR = [
  [{ header: [1, 2, 3, false] }],
  ['bold', 'italic', 'underline', 'strike'],
  [{ color: [] }, { background: [] }],
  [{ list: 'ordered' }, { list: 'bullet' }],
  [{ align: [] }],
  ['link'],
  ['clean'],
]

const FORMATS = [
  'header', 'bold', 'italic', 'underline', 'strike',
  'color', 'background',
  'list',
  'align',
  'link',
]

export default function RichTextInput({ value, onChange, placeholder, minHeight = 140 }: Props) {
  return (
    <div className="rich-text-input-wrap" style={{ lineHeight: 'normal' }}>
      <style>{`
        .rich-text-input-wrap .ql-toolbar.ql-snow {
          border: 1.5px solid #e5e7eb;
          border-bottom: none;
          border-radius: 10px 10px 0 0;
          background: linear-gradient(135deg, #f8faff 0%, #f3f4f6 100%);
          padding: 6px 10px;
          display: flex;
          flex-wrap: wrap;
          gap: 2px;
        }
        .rich-text-input-wrap .ql-container.ql-snow {
          border: 1.5px solid #e5e7eb;
          border-radius: 0 0 10px 10px;
          font-size: 14px;
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        }
        .rich-text-input-wrap .ql-editor {
          min-height: ${minHeight}px;
          padding: 12px 14px;
          color: #374151;
          line-height: 1.7;
        }
        .rich-text-input-wrap .ql-editor.ql-blank::before {
          color: #9ca3af;
          font-style: normal;
          font-size: 13px;
        }
        .rich-text-input-wrap .ql-editor:focus {
          outline: none;
        }
        .rich-text-input-wrap .ql-container.ql-snow:focus-within {
          border-color: #6366f1;
          box-shadow: 0 0 0 2px rgba(99,102,241,0.12);
          transition: all 0.2s;
        }
        .rich-text-input-wrap .ql-toolbar.ql-snow:has(+ .ql-container.ql-snow:focus-within) {
          border-color: #6366f1;
        }
        .rich-text-input-wrap .ql-toolbar .ql-formats {
          margin-right: 6px;
        }
        .rich-text-input-wrap .ql-snow .ql-stroke {
          stroke: #6b7280;
        }
        .rich-text-input-wrap .ql-snow .ql-fill {
          fill: #6b7280;
        }
        .rich-text-input-wrap .ql-snow.ql-toolbar button:hover .ql-stroke,
        .rich-text-input-wrap .ql-snow .ql-toolbar button:hover .ql-stroke {
          stroke: #6366f1;
        }
        .rich-text-input-wrap .ql-snow.ql-toolbar button:hover .ql-fill,
        .rich-text-input-wrap .ql-snow .ql-toolbar button:hover .ql-fill {
          fill: #6366f1;
        }
        .rich-text-input-wrap .ql-snow.ql-toolbar button.ql-active .ql-stroke {
          stroke: #6366f1;
        }
        .rich-text-input-wrap .ql-snow.ql-toolbar button.ql-active .ql-fill {
          fill: #6366f1;
        }
        .rich-text-input-wrap .ql-snow .ql-picker-label {
          color: #6b7280;
        }
        .rich-text-input-wrap .ql-snow .ql-picker-label:hover {
          color: #6366f1;
        }
        .rich-text-input-wrap .ql-snow .ql-picker.ql-expanded .ql-picker-label {
          color: #6366f1;
          border-color: #6366f1;
        }
        .rich-text-input-wrap .ql-snow .ql-picker-options {
          border-radius: 8px;
          box-shadow: 0 4px 20px rgba(0,0,0,0.12);
          border: 1px solid #e5e7eb;
        }
      `}</style>
      <ReactQuill
        theme="snow"
        value={value ?? ''}
        onChange={onChange}
        placeholder={placeholder}
        modules={{ toolbar: TOOLBAR }}
        formats={FORMATS}
      />
    </div>
  )
}
