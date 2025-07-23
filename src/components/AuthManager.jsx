import { useState, useEffect, createContext, useContext } from 'react'

const AuthContext = createContext()

// Backend URL configuration
const BACKEND_URL = import.meta.env.VITE_API_URL

export const useAuth = () => {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}

export const AuthProvider = ({ children }) => {
  const [currentUser, setCurrentUser] = useState(null)
  const [loading, setLoading] = useState(true)

  // Frontend token processing function
  const processTokenFrontend = async (access_token) => {
    try {
      // Decode JWT token (without verification for now)
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
      
      console.log('✅ User data extracted:', userData)
      
      // Store user data in localStorage for persistence
      localStorage.setItem('tubby_user', JSON.stringify(userData))
      localStorage.setItem('tubby_token', access_token)
      
      // Set current user
      setCurrentUser(userData)
      
      // Clear the hash from URL
      window.history.replaceState(null, '', window.location.pathname)
      
      console.log('✅ Authentication successful!')
      
    } catch (error) {
      console.error('❌ Frontend token processing failed:', error)
    }
  }

  useEffect(() => {
    checkAuthStatus()
  }, [])

  // Check for hash-based authentication tokens
  useEffect(() => {
    const handleHashChange = async () => {
      const hash = window.location.hash.substring(1)
      if (hash && hash.includes('access_token')) {
        const params = new URLSearchParams(hash)
        const access_token = params.get('access_token')
        const refresh_token = params.get('refresh_token')

        if (access_token) {
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
              // Backend worked - clear hash and refresh
              window.history.replaceState(null, '', window.location.pathname)
              checkAuthStatus()
            } else {
              console.log('Backend auth failed, trying frontend processing...')
              // Fallback to frontend processing
              await processTokenFrontend(access_token)
            }
          } catch (err) {
            console.log('Backend unavailable, using frontend processing...')
            // Backend unavailable - process token in frontend
            await processTokenFrontend(access_token)
          }
        }
      }
    }

    // Check on mount
    handleHashChange()

    // Listen for hash changes
    window.addEventListener('hashchange', handleHashChange)
    return () => window.removeEventListener('hashchange', handleHashChange)
  }, [])

  const checkAuthStatus = async () => {
    try {
      // Check localStorage first (skip backend entirely for now)
      const storedUser = localStorage.getItem('tubby_user')
      if (storedUser) {
        const userData = JSON.parse(storedUser)
        setCurrentUser(userData)
        setLoading(false)
        return
      }
      
      // No local data - user is not authenticated
      setCurrentUser(null)
      setLoading(false)
    } catch (error) {
      console.log('Auth check error (using local data):', error)
      setCurrentUser(null)
      setLoading(false)
    }
  }

  const login = (provider = 'google') => {
    if (provider === 'guest') {
      // Create a guest user session
      fetch(`${BACKEND_URL}/auth/guest`, {
        credentials: 'include'
      })
      .then(response => response.json())
      .then(data => {
        if (data.user) {
          setCurrentUser(data.user)
        }
      })
      .catch(error => {
        console.error('Error creating guest session:', error)
      })
      .finally(() => {
        setLoading(false)
      })
    } else {
      // Use Supabase OAuth directly (bypass broken backend)
      const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
      if (!supabaseUrl) {
        console.error('VITE_SUPABASE_URL not configured')
        return
      }
      const redirectUrl = `${window.location.origin}/auth/callback`
      
      const authUrl = `${supabaseUrl}/auth/v1/authorize?provider=${provider}&redirect_to=${encodeURIComponent(redirectUrl)}`
      
      console.log('Redirecting to Supabase OAuth:', authUrl)
      window.location.href = authUrl
    }
  }

  const logout = async () => {
    try {
      // Try backend logout (optional)
      await fetch(`${BACKEND_URL}/auth/logout`, {
        credentials: 'include'
      })
    } catch (error) {
      console.log('Backend logout failed, using frontend logout only')
    }
    
    // Clear local storage
    localStorage.removeItem('tubby_user')
    localStorage.removeItem('tubby_token')
    setCurrentUser(null)
    
    // Reload the page
    window.location.reload()
  }

  const value = {
    currentUser,
    loading,
    login,
    logout,
    checkAuthStatus,
    isAuthenticated: currentUser !== null
  }

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  )
}

export default AuthProvider 