import { useState, useEffect, createContext, useContext } from 'react'

const AuthContext = createContext()

// Backend URL configuration
const BACKEND_URL = import.meta.env.VITE_BACKEND_URL || 'http://localhost:5001'

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

  useEffect(() => {
    checkAuthStatus()
  }, [])

  const checkAuthStatus = async () => {
    try {
      const response = await fetch(`${BACKEND_URL}/auth/user`, {
        credentials: 'include'
      })
      if (response.ok) {
        const data = await response.json()
        setCurrentUser(data.user)
      } else {
        setCurrentUser(null)
      }
    } catch (error) {
      console.error('Error checking auth status:', error)
      setCurrentUser(null)
    } finally {
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
      // Redirect to OAuth endpoint
      window.location.href = `${BACKEND_URL}/auth/${provider}`
    }
  }

  const logout = async () => {
    try {
      await fetch(`${BACKEND_URL}/auth/logout`, {
        credentials: 'include'
      })
      setCurrentUser(null)
      // Optionally reload the page
      window.location.reload()
    } catch (error) {
      console.error('Error logging out:', error)
    }
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