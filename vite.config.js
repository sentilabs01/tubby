import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    port: 3001,
    proxy: {
      '/api': {
        target: process.env.VITE_API_URL || 'http://localhost:5004',
        changeOrigin: true,
        secure: false
      },
      '/auth': {
        target: process.env.VITE_API_URL || 'http://localhost:5004',
        changeOrigin: true,
        secure: false
      },
      '/socket.io': {
        target: process.env.VITE_API_URL || 'http://localhost:5004',
        changeOrigin: true,
        ws: true,
        secure: false
      },
      '/stripe': {
        target: process.env.VITE_API_URL || 'http://localhost:5004',
        changeOrigin: true,
        secure: false
      }
    }
  },
  build: {
    outDir: 'dist',
    assetsDir: 'assets'
  }
}) 