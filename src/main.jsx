import React from 'react'
import ReactDOM from 'react-dom/client'
import App from '../App.jsx'
import './index.css'

// Import offline mode manager for production
import './utils/offlineMode.js'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
) 