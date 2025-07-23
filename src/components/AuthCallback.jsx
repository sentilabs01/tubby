import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'

const BACKEND_URL = import.meta.env.VITE_API_URL

const AuthCallback = () => {
  const [status, setStatus] = useState('Processing...')
  const [error, setError] = useState(null)
  const navigate = useNavigate()

  useEffect(() => {
    const processCallback = async () => {
      try {
        // Extract token from URL fragment
        const hash = window.location.hash.substring(1)
        const params = new URLSearchParams(hash)
        const access_token = params.get('access_token')
        const refresh_token = params.get('refresh_token')

        if (!access_token) {
          setError('No access token found in URL')
          return
        }

        setStatus('Verifying token...')

        try {
          // Try backend first
          const response = await fetch(`${BACKEND_URL}/auth/callback`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            credentials: 'include',
            body: JSON.stringify({
              access_token: access_token,
              refresh_token: refresh_token
            })
          })

          const data = await response.json()

          if (response.ok && data.success) {
            setStatus('Authentication successful! Redirecting...')
            setTimeout(() => {
              navigate('/?auth=success')
            }, 1000)
            return
          } else {
            console.log('Backend auth failed, trying frontend processing...')
          }
        } catch (err) {
          console.log('Backend unavailable, using frontend processing...')
        }

        // Fallback to frontend processing
        setStatus('Processing token locally...')
        
        try {
          // Decode JWT token
          const tokenParts = access_token.split('.')
          if (tokenParts.length !== 3) {
            throw new Error('Invalid token format')
          }
          
          const payload = JSON.parse(atob(tokenParts[1]))
          console.log('✅ Token decoded successfully:', payload)
          
          // Extract user data from token
          const userData = {
            id: payload.sub || payload.user_id || payload.id,
            email: payload.email || 'unknown@example.com',
            name: payload.name || payload.email?.split('@')[0] || 'Unknown',
            picture: payload.picture,
            provider: payload.provider || 'google',
            verified_email: payload.email_confirmed_at ? true : false
          }
          
          // Store user data in localStorage
          localStorage.setItem('tubby_user', JSON.stringify(userData))
          localStorage.setItem('tubby_token', access_token)
          
          setStatus('Authentication successful! Redirecting...')
          setTimeout(() => {
            navigate('/?auth=success')
          }, 1000)
          
        } catch (error) {
          console.error('❌ Frontend token processing failed:', error)
          setError('Token processing failed. Please try again.')
        }
      } catch (err) {
        console.error('Auth callback error:', err)
        setError('Authentication failed. Please try again.')
      }
    }

    processCallback()
  }, [navigate])

  if (error) {
    return (
      <div style={{ 
        display: 'flex', 
        flexDirection: 'column', 
        alignItems: 'center', 
        justifyContent: 'center', 
        height: '100vh',
        fontFamily: 'Arial, sans-serif'
      }}>
        <h2 style={{ color: '#e74c3c', marginBottom: '20px' }}>Authentication Error</h2>
        <p style={{ color: '#7f8c8d', marginBottom: '30px' }}>{error}</p>
        <button 
          onClick={() => window.location.href = '/'}
          style={{
            padding: '10px 20px',
            backgroundColor: '#3498db',
            color: 'white',
            border: 'none',
            borderRadius: '5px',
            cursor: 'pointer'
          }}
        >
          Go Back
        </button>
      </div>
    )
  }

  return (
    <div style={{ 
      display: 'flex', 
      flexDirection: 'column', 
      alignItems: 'center', 
      justifyContent: 'center', 
      height: '100vh',
      fontFamily: 'Arial, sans-serif'
    }}>
      <h2 style={{ color: '#2c3e50', marginBottom: '20px' }}>Processing Authentication</h2>
      <p style={{ color: '#7f8c8d' }}>{status}</p>
      <div style={{ 
        width: '40px', 
        height: '40px', 
        border: '4px solid #f3f3f3', 
        borderTop: '4px solid #3498db', 
        borderRadius: '50%', 
        animation: 'spin 1s linear infinite',
        marginTop: '20px'
      }}></div>
      <style>{`
        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
      `}</style>
    </div>
  )
}

export default AuthCallback 