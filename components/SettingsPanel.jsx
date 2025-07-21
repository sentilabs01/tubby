import React, { useState, useEffect } from 'react'
import { Button } from '../components/ui/button.jsx'
import { Input } from '../components/ui/input.jsx'
import { Card, CardContent, CardHeader, CardTitle } from '../components/ui/card.jsx'
import { Badge } from '../components/ui/badge.jsx'
import { Settings, Key, Save, Trash2, User, LogOut } from 'lucide-react'
import { useAuth } from '../src/components/AuthManager.jsx'

// Backend URL configuration
const BACKEND_URL = import.meta.env.VITE_BACKEND_URL || 'http://localhost:5004'

const SettingsPanel = ({ isOpen, onClose }) => {
  const { currentUser, isAuthenticated, logout } = useAuth()
  const [apiKeys, setApiKeys] = useState({
    gemini: '',
    anthropic: '',
    openai: ''
  })
  const [savedKeys, setSavedKeys] = useState({})
  const [loading, setLoading] = useState(false)
  const [message, setMessage] = useState('')

  useEffect(() => {
    if (isOpen) {
      loadApiKeys()
    }
  }, [isOpen])

  const loadApiKeys = async () => {
    if (!isAuthenticated) {
      setMessage('Please sign in to manage API keys')
      return
    }

    try {
      const userId = currentUser?.id || 'default_user'
      const response = await fetch(`${BACKEND_URL}/api/user/api-keys?user_id=${userId}`, {
        credentials: 'include'
      })
      const data = await response.json()
      
      if (data.success) {
        const keyStatus = {}
        data.api_keys.forEach(key => {
          keyStatus[key.service] = true
        })
        setSavedKeys(keyStatus)
      }
    } catch (error) {
      console.error('Error loading API keys:', error)
      setMessage('Error loading API keys')
    }
  }

  const saveApiKey = async (service) => {
    if (!isAuthenticated) {
      setMessage('Please sign in to save API keys')
      return
    }

    const apiKey = apiKeys[service]
    if (!apiKey.trim()) {
      setMessage(`Please enter a ${service} API key`)
      return
    }

    setLoading(true)
    setMessage('')

    try {
      const userId = currentUser?.id || 'default_user'
      const response = await fetch(`${BACKEND_URL}/api/user/api-keys`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        credentials: 'include',
        body: JSON.stringify({
          user_id: userId,
          service: service,
          api_key: apiKey
        })
      })

      const data = await response.json()
      
      if (data.success) {
        setMessage(`${service} API key saved successfully!`)
        setSavedKeys(prev => ({ ...prev, [service]: true }))
        setApiKeys(prev => ({ ...prev, [service]: '' })) // Clear input
      } else {
        setMessage(`Error: ${data.error}`)
      }
    } catch (error) {
      setMessage(`Error saving ${service} API key: ${error.message}`)
    } finally {
      setLoading(false)
    }
  }

  const deleteApiKey = async (service) => {
    if (!isAuthenticated) {
      setMessage('Please sign in to delete API keys')
      return
    }

    setLoading(true)
    setMessage('')

    try {
      const userId = currentUser?.id || 'default_user'
      const response = await fetch(`${BACKEND_URL}/api/user/api-keys/${service}?user_id=${userId}`, {
        method: 'DELETE',
        credentials: 'include'
      })

      const data = await response.json()
      
      if (data.success) {
        setMessage(`${service} API key deleted successfully!`)
        setSavedKeys(prev => ({ ...prev, [service]: false }))
      } else {
        setMessage(`Error: ${data.error}`)
      }
    } catch (error) {
      setMessage(`Error deleting ${service} API key: ${error.message}`)
    } finally {
      setLoading(false)
    }
  }

  const handleInputChange = (service, value) => {
    setApiKeys(prev => ({
      ...prev,
      [service]: value
    }))
  }

  const handleSignOut = async () => {
    try {
      await logout()
      onClose() // Close the settings panel
      setMessage('Signed out successfully')
    } catch (error) {
      setMessage('Error signing out')
    }
  }



  if (!isOpen) return null

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-black border border-gray-800 rounded-lg p-6 w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-2xl font-bold text-white flex items-center">
            <Settings className="w-6 h-6 mr-2" />
            Settings
          </h2>
          <Button
            onClick={onClose}
            variant="ghost"
            className="text-gray-400 hover:text-white"
          >
            ✕
          </Button>
        </div>

        {/* User Profile Section */}
        {isAuthenticated && currentUser && (
          <Card className="bg-black border-gray-800 mb-6">
            <CardHeader>
              <CardTitle className="text-white flex items-center justify-between">
                <div className="flex items-center">
                  <User className="w-5 h-5 mr-2" />
                  User Profile
                </div>
                <Button
                  onClick={handleSignOut}
                  variant="destructive"
                  size="sm"
                  className="flex items-center gap-2"
                >
                  <LogOut className="w-4 h-4" />
                  Sign Out
                </Button>
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-start space-x-4">
                {currentUser.picture ? (
                  <img
                    src={currentUser.picture}
                    alt="Profile"
                    className="w-16 h-16 rounded-full border-2 border-gray-600"
                  />
                ) : (
                  <div className="w-16 h-16 bg-gray-600 rounded-full flex items-center justify-center border-2 border-gray-600">
                    <User className="w-8 h-8 text-gray-400" />
                  </div>
                )}
                <div className="flex-1 space-y-2">
                  <div>
                    <h3 className="font-semibold text-white text-lg">User Profile</h3>
                  </div>
                  <div className="flex items-center gap-2">
                    {currentUser.provider && (
                      <Badge className={`${
                        currentUser.provider === 'guest' 
                          ? 'bg-orange-600 text-white' 
                          : currentUser.provider === 'google'
                          ? 'bg-blue-600 text-white'
                          : currentUser.provider === 'github'
                          ? 'bg-gray-800 text-white'
                          : 'bg-gray-600'
                      }`}>
                        {currentUser.provider === 'guest' ? 'Guest' : 
                         currentUser.provider === 'google' ? 'Google' :
                         currentUser.provider === 'github' ? 'GitHub' :
                         currentUser.provider}
                      </Badge>
                    )}
                    {currentUser.verified_email && (
                      <Badge className="bg-green-600 text-white">
                        Verified
                      </Badge>
                    )}
                  </div>
                  {currentUser.id && (
                    <p className="text-xs text-gray-500 font-mono">
                      ID: {currentUser.id}
                    </p>
                  )}
                </div>
              </div>
            </CardContent>
          </Card>
        )}

        {/* API Keys Section */}
        <Card className="bg-black border-gray-800 mb-6">
          <CardHeader>
            <CardTitle className="text-white flex items-center">
              <Key className="w-5 h-5 mr-2" />
              API Keys
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {currentUser?.provider === 'guest' && (
              <div className="bg-orange-900 border border-orange-700 text-orange-200 p-3 rounded mb-4">
                <p className="text-sm">
                  <strong>Guest User Notice:</strong> API keys are not saved for guest users. 
                  Please sign in with a real account to permanently save your API keys.
                </p>
              </div>
            )}
            {Object.entries(apiKeys).map(([service, value]) => (
              <div key={service} className="space-y-2">
                <div className="flex items-center justify-between">
                  <label className="text-white font-medium capitalize">
                    {service} API Key
                  </label>
                  <div className="flex items-center gap-2">
                    {savedKeys[service] && (
                      <Badge variant="default" className="bg-green-600">
                        Saved
                      </Badge>
                    )}
                    {savedKeys[service] && (
                      <Button
                        onClick={() => deleteApiKey(service)}
                        variant="destructive"
                        size="sm"
                        disabled={loading}
                      >
                        <Trash2 className="w-4 h-4" />
                      </Button>
                    )}
                  </div>
                </div>
                <div className="flex gap-2">
                  <Input
                    type="password"
                    value={value}
                    onChange={(e) => handleInputChange(service, e.target.value)}
                    placeholder={`Enter your ${service} API key`}
                    className="bg-black border-gray-700 text-white"
                    disabled={loading}
                  />
                  {!savedKeys[service] && (
                    <Button
                      onClick={() => saveApiKey(service)}
                      disabled={loading || !value.trim()}
                      size="sm"
                    >
                      <Save className="w-4 h-4" />
                    </Button>
                  )}
                </div>
              </div>
            ))}
          </CardContent>
        </Card>



        {/* Message Display */}
        {message && (
          <div className={`p-3 rounded ${
            message.includes('Error') 
              ? 'bg-red-900 border border-red-700 text-red-200' 
              : 'bg-green-900 border border-green-700 text-green-200'
          }`}>
            {message}
          </div>
        )}

        {/* Close Button */}
        <div className="flex justify-end mt-6">
          <Button
            onClick={onClose}
            className="bg-gray-800 hover:bg-gray-700 text-white"
          >
            Close
          </Button>
        </div>
      </div>
    </div>
  )
}

export default SettingsPanel 