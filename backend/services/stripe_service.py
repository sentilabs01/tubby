import os
import stripe
from services.user_service import UserService

class StripeService:
    def __init__(self):
        stripe.api_key = os.getenv('STRIPE_SECRET_KEY')
        self.webhook_secret = os.getenv('STRIPE_WEBHOOK_SECRET')
        self.user_service = UserService()
        
        # Price IDs for different plans
        self.price_ids = {
            'basic': os.getenv('STRIPE_BASIC_PRICE_ID'),
            'pro': os.getenv('STRIPE_PRO_PRICE_ID'),
            'enterprise': os.getenv('STRIPE_ENTERPRISE_PRICE_ID')
        }
    
    def create_customer(self, user_data):
        """Create a Stripe customer"""
        try:
            customer = stripe.Customer.create(
                email=user_data.get('email'),
                name=user_data.get('name'),
                metadata={
                    'user_id': user_data.get('id'),
                    'google_id': user_data.get('google_id')
                }
            )
            return customer
        except Exception as e:
            print(f"Error creating Stripe customer: {e}")
            return None
    
    def create_checkout_session(self, user_id, plan_type, success_url, cancel_url):
        """Create a Stripe checkout session for subscription"""
        try:
            # Get user data
            user = self.user_service.get_user_by_id(user_id)
            if not user:
                return None
            
            # Get or create Stripe customer
            customer = self.get_or_create_customer(user)
            if not customer:
                return None
            
            # Get price ID for the plan
            price_id = self.price_ids.get(plan_type)
            if not price_id:
                return None
            
            # Create checkout session
            session = stripe.checkout.Session.create(
                customer=customer.id,
                payment_method_types=['card'],
                line_items=[{
                    'price': price_id,
                    'quantity': 1,
                }],
                mode='subscription',
                success_url=success_url,
                cancel_url=cancel_url,
                metadata={
                    'user_id': user_id,
                    'plan_type': plan_type
                }
            )
            
            return session
            
        except Exception as e:
            print(f"Error creating checkout session: {e}")
            return None
    
    def get_or_create_customer(self, user_data):
        """Get existing Stripe customer or create new one"""
        try:
            # Try to find existing customer by email
            customers = stripe.Customer.list(email=user_data.get('email'), limit=1)
            
            if customers.data:
                return customers.data[0]
            else:
                return self.create_customer(user_data)
                
        except Exception as e:
            print(f"Error getting/creating customer: {e}")
            return None
    
    def get_subscription_status(self, customer_id):
        """Get customer's subscription status"""
        try:
            subscriptions = stripe.Subscription.list(customer=customer_id, status='active', limit=1)
            
            if subscriptions.data:
                subscription = subscriptions.data[0]
                return {
                    'status': subscription.status,
                    'plan': subscription.items.data[0].price.nickname or 'Unknown',
                    'current_period_end': subscription.current_period_end,
                    'cancel_at_period_end': subscription.cancel_at_period_end
                }
            else:
                return {'status': 'inactive'}
                
        except Exception as e:
            print(f"Error getting subscription status: {e}")
            return {'status': 'error'}
    
    def cancel_subscription(self, subscription_id):
        """Cancel a subscription"""
        try:
            subscription = stripe.Subscription.modify(
                subscription_id,
                cancel_at_period_end=True
            )
            return subscription
        except Exception as e:
            print(f"Error canceling subscription: {e}")
            return None
    
    def handle_webhook(self, payload, sig_header):
        """Handle Stripe webhook events"""
        try:
            event = stripe.Webhook.construct_event(
                payload, sig_header, self.webhook_secret
            )
            
            # Handle different event types
            if event['type'] == 'checkout.session.completed':
                self.handle_checkout_completed(event['data']['object'])
            elif event['type'] == 'customer.subscription.updated':
                self.handle_subscription_updated(event['data']['object'])
            elif event['type'] == 'customer.subscription.deleted':
                self.handle_subscription_deleted(event['data']['object'])
            elif event['type'] == 'invoice.payment_failed':
                self.handle_payment_failed(event['data']['object'])
            
            return True
            
        except ValueError as e:
            print(f"Invalid payload: {e}")
            return False
        except stripe.error.SignatureVerificationError as e:
            print(f"Invalid signature: {e}")
            return False
    
    def handle_checkout_completed(self, session):
        """Handle successful checkout completion"""
        try:
            user_id = session.get('metadata', {}).get('user_id')
            plan_type = session.get('metadata', {}).get('plan_type')
            
            if user_id:
                # Update user subscription status in database
                subscription_data = {
                    'status': plan_type,
                    'subscription_id': session.get('subscription'),
                    'customer_id': session.get('customer'),
                    'plan': plan_type
                }
                self.user_service.update_user_subscription(user_id, subscription_data)
                
        except Exception as e:
            print(f"Error handling checkout completion: {e}")
    
    def handle_subscription_updated(self, subscription):
        """Handle subscription updates"""
        try:
            customer_id = subscription.get('customer')
            status = subscription.get('status')
            
            # Find user by customer ID and update status
            # This requires storing customer_id in user table
            
        except Exception as e:
            print(f"Error handling subscription update: {e}")
    
    def handle_subscription_deleted(self, subscription):
        """Handle subscription cancellation"""
        try:
            customer_id = subscription.get('customer')
            
            # Update user to free plan
            # This requires storing customer_id in user table
            
        except Exception as e:
            print(f"Error handling subscription deletion: {e}")
    
    def handle_payment_failed(self, invoice):
        """Handle failed payments"""
        try:
            customer_id = invoice.get('customer')
            
            # Notify user of payment failure
            # Optionally downgrade to free plan after grace period
            
        except Exception as e:
            print(f"Error handling payment failure: {e}") 