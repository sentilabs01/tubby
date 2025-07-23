import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => {
  const isProduction = mode === 'production'
  
  return {
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
      assetsDir: 'assets',
      sourcemap: !isProduction,
      minify: isProduction ? 'terser' : false,
      rollupOptions: {
        output: {
          manualChunks: {
            vendor: ['react', 'react-dom'],
            router: ['react-router-dom'],
            ui: ['lucide-react']
          }
        }
      },
      terserOptions: isProduction ? {
        compress: {
          drop_console: true,
          drop_debugger: true
        }
      } : undefined
    },
    define: {
      __APP_VERSION__: JSON.stringify(process.env.npm_package_version || '1.0.0'),
      __BUILD_TIME__: JSON.stringify(new Date().toISOString())
    }
  }
}) 