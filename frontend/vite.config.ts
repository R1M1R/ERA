import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

const apiTarget = 'http://127.0.0.1:8000'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    host: '127.0.0.1',
    allowedHosts: true,
    proxy: {
      '/health': apiTarget,
      '/generate': apiTarget,
      '/status': apiTarget,
      '/artifacts': apiTarget,
      '/verify': apiTarget,
    },
  },
})
