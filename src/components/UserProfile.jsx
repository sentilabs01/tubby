import { useState, useEffect } from 'react'
import { useAuth } from './AuthManager'
import { Button } from '../../components/ui/button.jsx'
import { Card, CardContent, CardHeader, CardTitle } from '../../components/ui/card.jsx'
import { Badge } from '../../components/ui/badge.jsx'
import { LogOut, Crown, User } from 'lucide-react'

const UserProfile = () => {
  const { currentUser, logout } = useAuth()
  const [subscriptionStatus, setSubscriptionStatus] = useState(null)
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    if (currentUser) {
      fetchSubscriptionStatus()
    }
  }, [currentUser])

  const fetchSubscriptionStatus = async () => {
    try {
      const response = await fetch('/stripe/subscription-status')
      if (response.ok) {
        const data = await response.json()
        setSubscriptionStatus(data)
      }
    } catch (error) {
      console.error('Error fetching subscription status:', error)
    }
  }

  const getSubscriptionBadge = (status) => {
    switch (status) {
      case 'active':
        return <Badge className="bg-green-600">Pro</Badge>
      case 'inactive':
        return <Badge className="bg-gray-600">Free</Badge>
      default:
        return <Badge className="bg-gray-600">Free</Badge>
    }
  }

  if (!currentUser) {
    return null
  }

  return (
    <Card className="bg-gray-800 border-gray-700 text-white">
      <CardHeader className="pb-3">
        <CardTitle className="text-lg flex items-center space-x-2">
          <User className="w-5 h-5" />
          <span>Profile</span>
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="flex items-center space-x-3">
          {currentUser.picture ? (
            <img
              src={currentUser.picture}
              alt="Profile"
              className="w-12 h-12 rounded-full"
            />
          ) : (
            <div className="w-12 h-12 bg-gray-600 rounded-full flex items-center justify-center">
              <User className="w-6 h-6 text-gray-400" />
            </div>
          )}
                      <div className="flex-1">
              <h3 className="font-semibold text-white">{currentUser.name}</h3>
              <p className="text-sm text-gray-400">{currentUser.email}</p>
              <div className="flex items-center gap-2 mt-1">
                {subscriptionStatus && currentUser.provider !== 'guest' && (
                  <div>
                    {getSubscriptionBadge(subscriptionStatus.status)}
                  </div>
                )}
                {currentUser.provider && (
                  <Badge className={`text-xs ${
                    currentUser.provider === 'guest' 
                      ? 'bg-orange-600 text-white' 
                      : 'bg-gray-600'
                  }`}>
                    {currentUser.provider === 'guest' ? 'Guest' : currentUser.provider}
                  </Badge>
                )}
              </div>
            </div>
        </div>
        
        <div className="pt-3 border-t border-gray-700">
          <Button
            onClick={logout}
            variant="outline"
            className="w-full border-gray-600 text-gray-300 hover:bg-gray-700 hover:text-white"
          >
            <LogOut className="w-4 h-4 mr-2" />
            Sign Out
          </Button>
        </div>
      </CardContent>
    </Card>
  )
}

export default UserProfile 