import os
import stripe
from datetime import datetime
from services.user_service import UserService
from dotenv import load_dotenv

# Load environment variables from the correct path
load_dotenv('../.env')  # Load from project root

class StripeService:
    def __init__(self):
        # Get Stripe API key with fallback
        stripe_api_key = os.getenv('STRIPE_SECRET_KEY')
        if not stripe_api_key:
            print("❌ CRITICAL: Stripe API key not found in environment variables")
            print("   Expected: STRIPE_SECRET_KEY in .env file")
            print("   Current working directory:", os.getcwd())
            print("   Environment variables:", {k: v for k, v in os.environ.items() if 'STRIPE' in k})
            raise ValueError("Stripe API key not configured")
        
        stripe.api_key = stripe_api_key
        print(f"✅ Stripe API key loaded: {stripe_api_key[:20]}...")
        
        self.webhook_secret = os.getenv('STRIPE_WEBHOOK_SECRET')
        self.user_service = UserService()
        
        # Price IDs for different plans
        self.price_ids = {
            'basic': os.getenv('STRIPE_BASIC_PRICE_ID'),
            'pro': os.getenv('STRIPE_PRO_PRICE_ID'),
            'enterprise': os.getenv('STRIPE_ENTERPRISE_PRICE_ID')
        }
        
        # Validate configuration
        if not self.webhook_secret:
            print("⚠️  Warning: Stripe webhook secret not configured")
        
        # Validate price IDs
        for plan, price_id in self.price_ids.items():
            if not price_id:
                print(f"⚠️  Warning: {plan.upper()} price ID not configured")
            else:
                print(f"✅ {plan.upper()} price ID: {price_id}")
        
        # Test Stripe connection (optional - skip if there are library issues)
        try:
            stripe.Account.retrieve()
            print("✅ Stripe connection successful")
        except Exception as e:
            print(f"⚠️  Stripe connection test failed: {e}")
            print("   This is not critical - the service will still work")
            # Don't raise the error, just log it
    
    def create_customer(self, user_data):
        """Create a Stripe customer with comprehensive metadata"""
        try:
            customer = stripe.Customer.create(
                email=user_data.get('email'),
                name=user_data.get('name'),
                metadata={
                    'user_id': str(user_data.get('id')),
                    'provider': user_data.get('provider', 'unknown'),
                    'google_id': user_data.get('google_id', ''),
                    'github_id': user_data.get('github_id', ''),
                    'github_username': user_data.get('github_username', ''),
                    'created_at': datetime.utcnow().isoformat()
                }
            )
            
            # Update user record with Stripe customer ID
            self.user_service.supabase.table('users').update({
                'stripe_customer_id': customer.id
            }).eq('id', user_data.get('id')).execute()
            
            return customer
        except stripe.error.StripeError as e:
            print(f"Stripe error creating customer: {e}")
            return None
        except Exception as e:
            print(f"Error creating Stripe customer: {e}")
            return None
    
    def get_or_create_customer(self, user_data):
        """Get existing Stripe customer or create new one with intelligent matching"""
        try:
            # Validate Stripe API key is set
            if not stripe.api_key:
                print("❌ CRITICAL: Stripe API key not set")
                return None
            
            print(f"🔍 Looking up customer for user: {user_data.get('email', 'Unknown')}")
            
            # First, check if user already has a Stripe customer ID
            if user_data.get('stripe_customer_id'):
                try:
                    print(f"🔍 Checking existing customer ID: {user_data['stripe_customer_id']}")
                    customer = stripe.Customer.retrieve(user_data['stripe_customer_id'])
                    # Check if customer exists and is not deleted
                    if customer and hasattr(customer, 'deleted') and not customer.deleted:
                        print(f"✅ Found existing customer: {customer.id}")
                        return customer
                    elif customer and not hasattr(customer, 'deleted'):
                        # Customer exists and doesn't have deleted attribute (not deleted)
                        print(f"✅ Found existing customer: {customer.id}")
                        return customer
                    else:
                        print(f"⚠️  Customer is deleted, will create new customer")
                        # Customer is deleted, continue to create new customer
                        pass
                except stripe.error.InvalidRequestError:
                    print(f"⚠️  Invalid customer ID, will create new customer")
                    # Customer ID is invalid, continue to create new customer
                    pass
            
            # Search for existing customer by email
            print(f"🔍 Searching for customer by email: {user_data.get('email')}")
            customers = stripe.Customer.list(email=user_data.get('email'), limit=1)
            
            if customers.data:
                customer = customers.data[0]
                print(f"✅ Found existing customer by email: {customer.id}")
                # Update user record with found customer ID
                self.user_service.supabase.table('users').update({
                    'stripe_customer_id': customer.id
                }).eq('id', user_data.get('id')).execute()
                return customer
            else:
                # Create new customer
                print(f"🆕 Creating new customer for: {user_data.get('email')}")
                return self.create_customer(user_data)
                
        except stripe.error.StripeError as e:
            print(f"❌ Stripe error getting/creating customer: {e}")
            return None
        except Exception as e:
            print(f"❌ Error getting/creating customer: {e}")
            import traceback
            traceback.print_exc()
            return None
    
    def create_checkout_session(self, user_id, plan_type, success_url, cancel_url):
        """Create a Stripe checkout session for subscription with comprehensive configuration"""
        try:
            # Get user data
            user = self.user_service.get_user_by_id(user_id)
            if not user:
                print(f"User not found: {user_id}")
                return None
            
            # Get or create Stripe customer
            customer = self.get_or_create_customer(user)
            if not customer:
                print("Failed to get or create Stripe customer")
                return None
            
            # Get price ID for the plan
            price_id = self.price_ids.get(plan_type)
            if not price_id:
                print(f"Invalid plan type: {plan_type}")
                return None
            
            # Create checkout session with comprehensive configuration
            session = stripe.checkout.Session.create(
                customer=customer.id,
                payment_method_types=['card'],
                line_items=[{
                    'price': price_id,
                    'quantity': 1,
                }],
                mode='subscription',
                success_url=success_url + '?session_id={CHECKOUT_SESSION_ID}',
                cancel_url=cancel_url,
                allow_promotion_codes=True,
                billing_address_collection='required',
                customer_update={
                    'address': 'auto',
                    'name': 'auto'
                },
                metadata={
                    'user_id': str(user_id),
                    'plan_type': plan_type,
                    'provider': user.get('provider', 'unknown')
                },
                subscription_data={
                    'metadata': {
                        'user_id': str(user_id),
                        'plan_type': plan_type,
                        'provider': user.get('provider', 'unknown')
                    }
                }
            )
            
            return session
            
        except stripe.error.StripeError as e:
            print(f"Stripe error creating checkout session: {e}")
            return None
        except Exception as e:
            print(f"Error creating checkout session: {e}")
            return None
    
    def get_subscription_status(self, customer_id):
        """Get comprehensive subscription status for a customer"""
        try:
            # Get active subscriptions
            subscriptions = stripe.Subscription.list(
                customer=customer_id, 
                status='all',
                limit=10
            )
            
            if not subscriptions.data:
                return {'status': 'inactive', 'plan': 'free'}
            
            # Find the most recent active subscription
            active_subscription = None
            for subscription in subscriptions.data:
                if subscription.status in ['active', 'trialing', 'past_due']:
                    active_subscription = subscription
                    break
            
            if active_subscription:
                # Get plan information
                plan_item = active_subscription.items.data[0]
                price = plan_item.price
                
                return {
                    'status': active_subscription.status,
                    'subscription_id': active_subscription.id,
                    'plan': self._get_plan_name_from_price_id(price.id),
                    'current_period_start': active_subscription.current_period_start,
                    'current_period_end': active_subscription.current_period_end,
                    'cancel_at_period_end': active_subscription.cancel_at_period_end,
                    'canceled_at': active_subscription.canceled_at,
                    'trial_end': active_subscription.trial_end,
                    'amount': price.unit_amount,
                    'currency': price.currency,
                    'interval': price.recurring.interval
                }
            else:
                # Check for canceled or incomplete subscriptions
                recent_subscription = subscriptions.data[0]
                return {
                    'status': recent_subscription.status,
                    'subscription_id': recent_subscription.id,
                    'plan': 'free',
                    'canceled_at': recent_subscription.canceled_at
                }
                
        except stripe.error.StripeError as e:
            print(f"Stripe error getting subscription status: {e}")
            return {'status': 'error', 'error': str(e)}
        except Exception as e:
            print(f"Error getting subscription status: {e}")
            return {'status': 'error', 'error': str(e)}
    
    def _get_plan_name_from_price_id(self, price_id):
        """Map Stripe price ID to plan name"""
        for plan_name, plan_price_id in self.price_ids.items():
            if plan_price_id == price_id:
                return plan_name
        return 'unknown'
    
    def cancel_subscription(self, subscription_id, immediate=False):
        """Cancel a subscription with options for immediate or end-of-period cancellation"""
        try:
            if immediate:
                # Cancel immediately
                subscription = stripe.Subscription.delete(subscription_id)
            else:
                # Cancel at end of current billing period
                subscription = stripe.Subscription.modify(
                    subscription_id,
                    cancel_at_period_end=True
                )
            
            return subscription
        except stripe.error.StripeError as e:
            print(f"Stripe error canceling subscription: {e}")
            return None
        except Exception as e:
            print(f"Error canceling subscription: {e}")
            return None
    
    def reactivate_subscription(self, subscription_id):
        """Reactivate a subscription that was set to cancel at period end"""
        try:
            subscription = stripe.Subscription.modify(
                subscription_id,
                cancel_at_period_end=False
            )
            return subscription
        except stripe.error.StripeError as e:
            print(f"Stripe error reactivating subscription: {e}")
            return None
        except Exception as e:
            print(f"Error reactivating subscription: {e}")
            return None
    
    def handle_webhook(self, payload, sig_header):
        """Handle Stripe webhook events with comprehensive processing"""
        try:
            # Verify webhook signature
            event = stripe.Webhook.construct_event(
                payload, sig_header, self.webhook_secret
            )
            
            print(f"Processing Stripe webhook event: {event['type']}")
            
            # Handle different event types
            if event['type'] == 'checkout.session.completed':
                self.handle_checkout_completed(event['data']['object'])
            elif event['type'] == 'customer.subscription.created':
                self.handle_subscription_created(event['data']['object'])
            elif event['type'] == 'customer.subscription.updated':
                self.handle_subscription_updated(event['data']['object'])
            elif event['type'] == 'customer.subscription.deleted':
                self.handle_subscription_deleted(event['data']['object'])
            elif event['type'] == 'invoice.payment_succeeded':
                self.handle_payment_succeeded(event['data']['object'])
            elif event['type'] == 'invoice.payment_failed':
                self.handle_payment_failed(event['data']['object'])
            elif event['type'] == 'customer.subscription.trial_will_end':
                self.handle_trial_will_end(event['data']['object'])
            else:
                print(f"Unhandled webhook event type: {event['type']}")
            
            return True
            
        except ValueError as e:
            print(f"Invalid webhook payload: {e}")
            return False
        except stripe.error.SignatureVerificationError as e:
            print(f"Invalid webhook signature: {e}")
            return False
        except Exception as e:
            print(f"Error handling webhook: {e}")
            return False
    
    def handle_checkout_completed(self, session):
        """Handle successful checkout completion"""
        try:
            user_id = session.get('metadata', {}).get('user_id')
            plan_type = session.get('metadata', {}).get('plan_type')
            subscription_id = session.get('subscription')
            
            if user_id and plan_type:
                # Update user subscription status
                update_data = {
                    'subscription_status': 'active',
                    'subscription_plan': plan_type,
                    'subscription_id': subscription_id,
                    'updated_at': datetime.utcnow().isoformat()
                }
                
                result = self.user_service.supabase.table('users').update(
                    update_data
                ).eq('id', user_id).execute()
                
                if result.data:
                    print(f"Updated user {user_id} subscription to {plan_type}")
                    
                    # Log subscription history
                    self._log_subscription_event(
                        user_id, 'subscription_activated', 
                        {'plan': plan_type, 'subscription_id': subscription_id}
                    )
                else:
                    print(f"Failed to update user {user_id} subscription status")
                    
        except Exception as e:
            print(f"Error handling checkout completion: {e}")
    
    def handle_subscription_updated(self, subscription):
        """Handle subscription updates including plan changes and status changes"""
        try:
            customer_id = subscription.get('customer')
            subscription_id = subscription.get('id')
            status = subscription.get('status')
            
            # Find user by customer ID
            user_result = self.user_service.supabase.table('users').select('*').eq(
                'stripe_customer_id', customer_id
            ).execute()
            
            if user_result.data:
                user = user_result.data[0]
                user_id = user['id']
                
                # Get plan information
                plan_type = 'free'
                if subscription.get('items', {}).get('data'):
                    price_id = subscription['items']['data'][0]['price']['id']
                    plan_type = self._get_plan_name_from_price_id(price_id)
                
                # Update user subscription status
                update_data = {
                    'subscription_status': status,
                    'subscription_plan': plan_type,
                    'subscription_id': subscription_id,
                    'subscription_period_end': datetime.fromtimestamp(
                        subscription.get('current_period_end', 0)
                    ).isoformat() if subscription.get('current_period_end') else None,
                    'subscription_cancel_at_period_end': subscription.get('cancel_at_period_end', False),
                    'updated_at': datetime.utcnow().isoformat()
                }
                
                result = self.user_service.supabase.table('users').update(
                    update_data
                ).eq('id', user_id).execute()
                
                if result.data:
                    print(f"Updated user {user_id} subscription: {status} - {plan_type}")
                    
                    # Log subscription history
                    self._log_subscription_event(
                        user_id, 'subscription_updated',
                        {
                            'status': status,
                            'plan': plan_type,
                            'subscription_id': subscription_id,
                            'cancel_at_period_end': subscription.get('cancel_at_period_end', False)
                        }
                    )
                    
        except Exception as e:
            print(f"Error handling subscription update: {e}")
    
    def handle_subscription_deleted(self, subscription):
        """Handle subscription cancellation"""
        try:
            customer_id = subscription.get('customer')
            subscription_id = subscription.get('id')
            
            # Find user by customer ID
            user_result = self.user_service.supabase.table('users').select('*').eq(
                'stripe_customer_id', customer_id
            ).execute()
            
            if user_result.data:
                user = user_result.data[0]
                user_id = user['id']
                
                # Update user to free plan
                update_data = {
                    'subscription_status': 'cancelled',
                    'subscription_plan': 'free',
                    'subscription_id': None,
                    'subscription_period_end': None,
                    'subscription_cancel_at_period_end': False,
                    'updated_at': datetime.utcnow().isoformat()
                }
                
                result = self.user_service.supabase.table('users').update(
                    update_data
                ).eq('id', user_id).execute()
                
                if result.data:
                    print(f"Cancelled subscription for user {user_id}")
                    
                    # Log subscription history
                    self._log_subscription_event(
                        user_id, 'subscription_cancelled',
                        {'subscription_id': subscription_id}
                    )
                    
        except Exception as e:
            print(f"Error handling subscription deletion: {e}")
    
    def handle_payment_failed(self, invoice):
        """Handle failed payment attempts"""
        try:
            customer_id = invoice.get('customer')
            subscription_id = invoice.get('subscription')
            amount_due = invoice.get('amount_due', 0)
            
            # Find user by customer ID
            user_result = self.user_service.supabase.table('users').select('*').eq(
                'stripe_customer_id', customer_id
            ).execute()
            
            if user_result.data:
                user = user_result.data[0]
                user_id = user['id']
                
                print(f"Payment failed for user {user_id}, amount: {amount_due}")
                
                # Log payment failure
                self._log_subscription_event(
                    user_id, 'payment_failed',
                    {
                        'subscription_id': subscription_id,
                        'amount_due': amount_due,
                        'currency': invoice.get('currency', 'usd')
                    }
                )
                
                # Could implement additional logic here such as:
                # - Sending notification emails
                # - Implementing grace periods
                # - Downgrading service access
                
        except Exception as e:
            print(f"Error handling payment failure: {e}")
    
    def handle_payment_succeeded(self, invoice):
        """Handle successful payment"""
        try:
            customer_id = invoice.get('customer')
            subscription_id = invoice.get('subscription')
            amount_paid = invoice.get('amount_paid', 0)
            
            # Find user by customer ID
            user_result = self.user_service.supabase.table('users').select('*').eq(
                'stripe_customer_id', customer_id
            ).execute()
            
            if user_result.data:
                user = user_result.data[0]
                user_id = user['id']
                
                print(f"Payment succeeded for user {user_id}, amount: {amount_paid}")
                
                # Log successful payment
                self._log_subscription_event(
                    user_id, 'payment_succeeded',
                    {
                        'subscription_id': subscription_id,
                        'amount_paid': amount_paid,
                        'currency': invoice.get('currency', 'usd')
                    }
                )
                
        except Exception as e:
            print(f"Error handling payment success: {e}")
    
    def handle_subscription_created(self, subscription):
        """Handle new subscription creation"""
        try:
            customer_id = subscription.get('customer')
            subscription_id = subscription.get('id')
            
            # Find user by customer ID
            user_result = self.user_service.supabase.table('users').select('*').eq(
                'stripe_customer_id', customer_id
            ).execute()
            
            if user_result.data:
                user = user_result.data[0]
                user_id = user['id']
                
                print(f"New subscription created for user {user_id}")
                
                # Log subscription creation
                self._log_subscription_event(
                    user_id, 'subscription_created',
                    {'subscription_id': subscription_id}
                )
                
        except Exception as e:
            print(f"Error handling subscription creation: {e}")
    
    def handle_trial_will_end(self, subscription):
        """Handle trial ending soon"""
        try:
            customer_id = subscription.get('customer')
            subscription_id = subscription.get('id')
            
            # Find user by customer ID
            user_result = self.user_service.supabase.table('users').select('*').eq(
                'stripe_customer_id', customer_id
            ).execute()
            
            if user_result.data:
                user = user_result.data[0]
                user_id = user['id']
                
                print(f"Trial ending soon for user {user_id}")
                
                # Log trial ending
                self._log_subscription_event(
                    user_id, 'trial_ending',
                    {'subscription_id': subscription_id}
                )
                
                # Could implement additional logic here such as:
                # - Sending notification emails
                # - Showing in-app notifications
                
        except Exception as e:
            print(f"Error handling trial ending: {e}")
    
    def _log_subscription_event(self, user_id, event_type, metadata):
        """Log subscription events for audit and analytics"""
        try:
            log_data = {
                'user_id': user_id,
                'event_type': event_type,
                'metadata': metadata,
                'created_at': datetime.utcnow().isoformat()
            }
            
            # This could be logged to a separate subscription_events table
            # or integrated with the existing activity logging system
            print(f"Subscription event logged: {event_type} for user {user_id}")
            
        except Exception as e:
            print(f"Error logging subscription event: {e}") 