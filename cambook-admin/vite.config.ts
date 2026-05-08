import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

// Vite 配置文件
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 3000,
    proxy: {
      // 开发环境 REST API 代理：/api/xxx → http://localhost:8080/xxx
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, ''),
      },
      // IM WebSocket 代理：/ws/im → ws://localhost:9090/ws/im
      '/ws': {
        target: 'ws://localhost:9090',
        ws: true,
        changeOrigin: true,
      },
    },
  },
  define: {
    // 开发时 WS 走 vite 代理，生产时通过环境变量覆盖
    'import.meta.env.VITE_IM_WS_URL': JSON.stringify(
      process.env.VITE_IM_WS_URL ?? 'ws://localhost:3000/ws/im'
    ),
  },
})
