import { useState, useEffect } from 'react'
import { useAuth } from './AuthManager'
import { Button } from '../../components/ui/button.jsx'
import { Card, CardContent, CardHeader, CardTitle } from '../../components/ui/card.jsx'
import { Badge } from '../../components/ui/badge.jsx'
import { Alert, AlertDescription } from '../../components/ui/alert.jsx'
import { Check, Crown, Zap, Star, AlertCircle } from 'lucide-react'

const BACKEND_URL = import.meta.env.VITE_BACKEND_URL || 'http://localhost:5004'

const SubscriptionPlans = () => {
  const { currentUser, isAuthenticated, isGuest } = useAuth()
  const [subscriptionStatus, setSubscriptionStatus] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  useEffect(() => {
    if (isAuthenticated && !isGuest) {
      loadSubscriptionStatus()
    }
  }, [isAuthenticated, isGuest])

  const loadSubscriptionStatus = async () => {
    try {
      const response = await fetch(`${BACKEND_URL}/stripe/subscription-status`, {
        credentials: 'include'
      })
      
      if (response.ok) {
        const data = await response.json()
        setSubscriptionStatus(data)
      }
    } catch (error) {
      console.error('Error loading subscription status:', error)
    }
  }

  const subscribeToPlan = async (planId) => {
    if (!isAuthenticated) {
      setError('Please sign in to subscribe to a plan')
      return
    }

    if (isGuest) {
      setError('Guest users cannot subscribe. Please sign in with Google or GitHub.')
      return
    }

    setLoading(true)
    setError(null)

    try {
      const response = await fetch(`${BACKEND_URL}/stripe/create-checkout-session`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        credentials: 'include',
        body: JSON.stringify({ plan_type: planId })
      })

      const data = await response.json()

      if (response.ok && data.checkout_url) {
        window.location.href = data.checkout_url
      } else {
        setError(data.error || 'Failed to create checkout session')
      }
    } catch (error) {
      console.error('Error subscribing:', error)
      setError('Network error while processing subscription')
    } finally {
      setLoading(false)
    }
  }

  const cancelSubscription = async () => {
    if (!confirm('Are you sure you want to cancel your subscription?')) {
      return
    }

    setLoading(true)
    setError(null)

    try {
      const response = await fetch(`${BACKEND_URL}/stripe/cancel-subscription`, {
        method: 'POST',
        credentials: 'include'
      })

      const data = await response.json()

      if (response.ok) {
        setError(null)
        await loadSubscriptionStatus()
        // Show success message
      } else {
        setError(data.error || 'Failed to cancel subscription')
      }
    } catch (error) {
      console.error('Error canceling subscription:', error)
      setError('Network error while canceling subscription')
    } finally {
      setLoading(false)
    }
  }

  const reactivateSubscription = async () => {
    if (!confirm('Are you sure you want to reactivate your subscription?')) {
      return
    }

    setLoading(true)
    setError(null)

    try {
      const response = await fetch(`${BACKEND_URL}/stripe/reactivate-subscription`, {
        method: 'POST',
        credentials: 'include'
      })

      const data = await response.json()

      if (response.ok) {
        setError(null)
        await loadSubscriptionStatus()
        // Show success message
      } else {
        setError(data.error || 'Failed to reactivate subscription')
      }
    } catch (error) {
      console.error('Error reactivating subscription:', error)
      setError('Network error while reactivating subscription')
    } finally {
      setLoading(false)
    }
  }

  const plans = [
    {
      id: 'basic',
      name: 'Basic Plan',
      price: '$9.99',
      interval: 'month',
      features: [
        'Basic AI agent access',
        'Limited terminal sessions',
        'Community support',
        'Basic integrations'
      ]
    },
    {
      id: 'pro',
      name: 'Pro Plan',
      price: '$29.99',
      interval: 'month',
      popular: true,
      features: [
        'Full AI agent access',
        'Unlimited terminal sessions',
        'Priority support',
        'Advanced features',
        'Custom integrations',
        'Analytics dashboard'
      ]
    },
    {
      id: 'enterprise',
      name: 'Enterprise Plan',
      price: '$99.99',
      interval: 'month',
      features: [
        'Everything in Pro',
        'Custom integrations',
        'Dedicated support',
        'SLA guarantee',
        'Advanced security',
        'Custom deployment'
      ]
    }
  ]

  const getPlanIcon = (planId) => {
    switch (planId) {
      case 'basic':
        return <Zap className="w-6 h-6" />
      case 'pro':
        return <Crown className="w-6 h-6" />
      case 'enterprise':
        return <Star className="w-6 h-6" />
      default:
        return <Zap className="w-6 h-6" />
    }
  }

  const formatDate = (timestamp) => {
    if (!timestamp) return null
    return new Date(timestamp * 1000).toLocaleDateString()
  }

  return (
    <div className="space-y-6">
      {error && (
        <Alert className="bg-red-900 border-red-700">
          <AlertCircle className="h-4 w-4" />
          <AlertDescription className="text-red-200">
            {error}
          </AlertDescription>
        </Alert>
      )}

      {subscriptionStatus && subscriptionStatus.status === 'active' && (
        <Card className="bg-green-900 border-green-700">
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-green-200 font-medium">Active Subscription</h3>
                <p className="text-green-300 text-sm">
                  {subscriptionStatus.plan} plan
                  {subscriptionStatus.cancel_at_period_end && ' (Canceling at period end)'}
                </p>
                {subscriptionStatus.current_period_end && (
                  <p className="text-green-300 text-xs">
                    Next billing: {formatDate(subscriptionStatus.current_period_end)}
                  </p>
                )}
              </div>
              <div className="space-x-2">
                {subscriptionStatus.cancel_at_period_end && (
                  <Button
                    onClick={reactivateSubscription}
                    disabled={loading}
                    className="bg-green-600 hover:bg-green-700"
                  >
                    Reactivate
                  </Button>
                )}
                <Button
                  onClick={cancelSubscription}
                  disabled={loading}
                  className="bg-red-600 hover:bg-red-700"
                >
                  Cancel Subscription
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      <div className="text-center">
        <h2 className="text-3xl font-bold text-white mb-2">Choose Your Plan</h2>
        <p className="text-gray-400">Unlock the full potential of Tubby AI</p>
      </div>

      <div className="grid md:grid-cols-3 gap-6">
        {plans.map((plan) => (
          <Card 
            key={plan.id} 
            className={`bg-black border-gray-800 relative ${
              plan.popular ? 'ring-2 ring-blue-500' : ''
            }`}
          >
            {plan.popular && (
              <div className="absolute -top-3 left-1/2 transform -translate-x-1/2">
                <Badge className="bg-blue-600 text-white">Most Popular</Badge>
              </div>
            )}
            
            <CardHeader className="text-center">
              <div className="flex justify-center mb-4">
                <div className="p-3 bg-blue-600 rounded-lg">
                  {getPlanIcon(plan.id)}
                </div>
              </div>
              <CardTitle className="text-white text-xl">{plan.name}</CardTitle>
              <div className="text-3xl font-bold text-white">
                {plan.price}
                <span className="text-sm text-gray-400">/{plan.interval}</span>
              </div>
            </CardHeader>
            
            <CardContent className="space-y-4">
              <ul className="space-y-2">
                {plan.features.map((feature, index) => (
                  <li key={index} className="text-gray-300 text-sm flex items-center">
                    <Check className="w-4 h-4 text-green-500 mr-2" />
                    {feature}
                  </li>
                ))}
              </ul>
              
              <Button
                onClick={() => subscribeToPlan(plan.id)}
                disabled={loading || (subscriptionStatus?.status === 'active') || isGuest}
                className={`w-full ${
                  plan.popular 
                    ? 'bg-blue-600 hover:bg-blue-700' 
                    : 'bg-gray-700 hover:bg-gray-600'
                } text-white`}
              >
                {subscriptionStatus?.status === 'active' ? 'Current Plan' : 
                 isGuest ? 'Sign in Required' : 
                 loading ? 'Processing...' : 'Subscribe'}
              </Button>
            </CardContent>
          </Card>
        ))}
      </div>

      {!isAuthenticated && (
        <Card className="bg-yellow-900 border-yellow-700">
          <CardContent className="pt-6">
            <p className="text-yellow-200 text-center">
              Please sign in to subscribe to a plan and access premium features.
            </p>
          </CardContent>
        </Card>
      )}

      {isGuest && (
        <Card className="bg-yellow-900 border-yellow-700">
          <CardContent className="pt-6">
            <p className="text-yellow-200 text-center">
              You're using a guest account. Sign in with Google or GitHub to save your preferences and access premium features.
            </p>
          </CardContent>
        </Card>
      )}
    </div>
  )
}

export default SubscriptionPlans 