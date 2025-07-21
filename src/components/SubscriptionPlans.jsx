import { useState, useEffect } from 'react'
import { useAuth } from './AuthManager'
import { Button } from '../../components/ui/button.jsx'
import { Card, CardContent, CardHeader, CardTitle } from '../../components/ui/card.jsx'
import { Badge } from '../../components/ui/badge.jsx'
import { Check, Crown, Zap, Star } from 'lucide-react'

const SubscriptionPlans = () => {
  const { currentUser, isAuthenticated } = useAuth()
  const [subscriptionStatus, setSubscriptionStatus] = useState(null)
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    if (isAuthenticated) {
      fetchSubscriptionStatus()
    }
  }, [isAuthenticated])

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

  const subscribeToPlan = async (planType) => {
    if (!isAuthenticated) {
      alert('Please sign in to subscribe')
      return
    }
    
    if (currentUser?.provider === 'guest') {
      alert('Please sign in with a real account to subscribe. Guest users cannot subscribe.')
      return
    }

    setLoading(true)
    try {
      const response = await fetch('/stripe/create-checkout-session', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ plan_type: planType })
      })

      const data = await response.json()

      if (response.ok && data.checkout_url) {
        window.location.href = data.checkout_url
      } else {
        alert('Error creating checkout session: ' + (data.error || 'Unknown error'))
      }
    } catch (error) {
      console.error('Error subscribing:', error)
      alert('Error subscribing to plan')
    } finally {
      setLoading(false)
    }
  }

  const cancelSubscription = async () => {
    if (!confirm('Are you sure you want to cancel your subscription?')) {
      return
    }

    try {
      const response = await fetch('/stripe/cancel-subscription', {
        method: 'POST'
      })

      const data = await response.json()

      if (response.ok) {
        alert('Subscription canceled successfully')
        fetchSubscriptionStatus()
      } else {
        alert('Error canceling subscription: ' + (data.error || 'Unknown error'))
      }
    } catch (error) {
      console.error('Error canceling subscription:', error)
      alert('Error canceling subscription')
    }
  }

  const plans = [
    {
      id: 'basic',
      name: 'Basic Plan',
      price: '$9.99',
      period: 'month',
      icon: <Zap className="w-6 h-6" />,
      features: [
        'Basic AI agent access',
        'Limited terminal sessions',
        'Community support',
        'Standard features'
      ],
      popular: false
    },
    {
      id: 'pro',
      name: 'Pro Plan',
      price: '$29.99',
      period: 'month',
      icon: <Crown className="w-6 h-6" />,
      features: [
        'Full AI agent access',
        'Unlimited terminal sessions',
        'Priority support',
        'Advanced features',
        'Custom integrations'
      ],
      popular: true
    },
    {
      id: 'enterprise',
      name: 'Enterprise Plan',
      price: '$99.99',
      period: 'month',
      icon: <Star className="w-6 h-6" />,
      features: [
        'Everything in Pro',
        'Custom integrations',
        'Dedicated support',
        'SLA guarantee',
        'Advanced analytics'
      ],
      popular: false
    }
  ]

  const isCurrentPlan = (planId) => {
    return subscriptionStatus?.status === 'active' && subscriptionStatus?.plan === planId
  }

  return (
    <div className="space-y-6">
      <div className="text-center">
        <h2 className="text-3xl font-bold text-white mb-2">Choose Your Plan</h2>
        <p className="text-gray-400">Unlock the full potential of Tubby AI</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {plans.map((plan) => (
          <Card
            key={plan.id}
            className={`relative bg-gray-800 border-gray-700 text-white ${
              plan.popular ? 'ring-2 ring-blue-500' : ''
            }`}
          >
            {plan.popular && (
              <div className="absolute -top-3 left-1/2 transform -translate-x-1/2">
                <Badge className="bg-blue-600">Most Popular</Badge>
              </div>
            )}

            <CardHeader className="text-center pb-4">
              <div className="flex justify-center mb-2">
                <div className="p-2 bg-blue-600 rounded-lg">
                  {plan.icon}
                </div>
              </div>
              <CardTitle className="text-xl">{plan.name}</CardTitle>
              <div className="text-3xl font-bold text-white">
                {plan.price}
                <span className="text-lg text-gray-400">/{plan.period}</span>
              </div>
            </CardHeader>

            <CardContent className="space-y-4">
              <ul className="space-y-2">
                {plan.features.map((feature, index) => (
                  <li key={index} className="flex items-center space-x-2">
                    <Check className="w-4 h-4 text-green-500 flex-shrink-0" />
                    <span className="text-sm text-gray-300">{feature}</span>
                  </li>
                ))}
              </ul>

              {isCurrentPlan(plan.id) ? (
                <div className="space-y-2">
                  <Button
                    className="w-full bg-green-600 hover:bg-green-700"
                    disabled
                  >
                    Current Plan
                  </Button>
                  <Button
                    onClick={cancelSubscription}
                    variant="outline"
                    className="w-full border-gray-600 text-gray-300 hover:bg-gray-700"
                  >
                    Cancel Subscription
                  </Button>
                </div>
              ) : (
                <Button
                  onClick={() => subscribeToPlan(plan.id)}
                  className={`w-full ${
                    plan.popular
                      ? 'bg-blue-600 hover:bg-blue-700'
                      : 'bg-gray-700 hover:bg-gray-600'
                  }`}
                  disabled={loading || currentUser?.provider === 'guest'}
                >
                  {currentUser?.provider === 'guest' ? 'Sign in Required' : (loading ? 'Processing...' : 'Subscribe')}
                </Button>
              )}
            </CardContent>
          </Card>
        ))}
      </div>

      {subscriptionStatus && (
        <div className="text-center">
          <p className="text-gray-400">
            Current status: {subscriptionStatus.status}
            {subscriptionStatus.plan && ` (${subscriptionStatus.plan})`}
          </p>
        </div>
      )}
    </div>
  )
}

export default SubscriptionPlans 