import os
from supabase import create_client, Client

class UserService:
    def __init__(self):
        supabase_url = os.getenv('SUPABASE_URL', 'https://bemssfbadcfrvsbgjlua.supabase.co')
        # Use service role key for database operations to bypass RLS
        supabase_key = os.getenv('SUPABASE_SERVICE_ROLE_KEY', os.getenv('SUPABASE_ANON_KEY', 'placeholder_key'))
        
        # Check if we're using service role key
        key_type = 'service_role' if 'SUPABASE_SERVICE_ROLE_KEY' in os.environ else 'anon'
        
        print(f"🔧 UserService: Using key type: {key_type}")
        print(f"🔧 UserService: Key starts with: {supabase_key[:20]}...")
        
        try:
            self.supabase: Client = create_client(supabase_url, supabase_key)
            print(f"✅ UserService initialized with service role key")
        except Exception as e:
            print(f"Warning: Could not initialize Supabase client in UserService: {e}")
            self.supabase = None
    
    def create_or_update_user(self, google_user_data):
        """Create or update user in Supabase"""
        if not self.supabase:
            return None
            
        try:
            user_data = {
                'google_id': google_user_data.get('id'),
                'email': google_user_data.get('email'),
                'name': google_user_data.get('name'),
                'picture': google_user_data.get('picture'),
                'verified_email': google_user_data.get('verified_email', False)
            }
            
            # Check if user exists
            existing_user = self.supabase.table('users').select('*').eq('google_id', user_data['google_id']).execute()
            
            if existing_user.data:
                # Update existing user
                result = self.supabase.table('users').update(user_data).eq('google_id', user_data['google_id']).execute()
                return result.data[0] if result.data else None
            else:
                # Create new user
                result = self.supabase.table('users').insert(user_data).execute()
                return result.data[0] if result.data else None
                
        except Exception as e:
            print(f"Error managing user: {e}")
            return None
    
    def get_user_by_id(self, user_id):
        """Get user by ID"""
        if not self.supabase:
            return None
            
        try:
            result = self.supabase.table('users').select('*').eq('id', user_id).execute()
            return result.data[0] if result.data else None
        except Exception as e:
            print(f"Error getting user: {e}")
            return None
    
    def get_user_by_google_id(self, google_id):
        """Get user by Google ID"""
        if not self.supabase:
            return None
            
        try:
            result = self.supabase.table('users').select('*').eq('google_id', google_id).execute()
            return result.data[0] if result.data else None
        except Exception as e:
            print(f"Error getting user by Google ID: {e}")
            return None
    
    def get_user_by_supabase_id(self, supabase_id):
        """Get user by Supabase ID - CRITICAL FIX FOR AUTH BUG"""
        if not self.supabase:
            print(f"Supabase client not initialized for user lookup: {supabase_id}")
            return None
            
        try:
            print(f"Looking up user by Supabase ID: {supabase_id}")
            result = self.supabase.table('users').select('*').eq('supabase_id', supabase_id).execute()
            if result.data:
                print(f"✅ User found: {result.data[0].get('email', 'Unknown')}")
                return result.data[0]
            else:
                print(f"❌ User not found by Supabase ID: {supabase_id}")
                return None
        except Exception as e:
            print(f"Error getting user by Supabase ID {supabase_id}: {e}")
            return None
    
    def create_user_from_oauth(self, user_data):
        """Create user from OAuth data if not exists - CRITICAL FIX FOR AUTH BUG"""
        if not self.supabase:
            print("Supabase client not initialized for user creation")
            return None
            
        try:
            print(f"Creating user from OAuth data: {user_data.get('email', 'Unknown')}")
            user = {
                'supabase_id': user_data.get('id'),
                'email': user_data.get('email'),
                'name': user_data.get('name'),
                'provider': user_data.get('provider'),
                'picture': user_data.get('picture'),
                'verified_email': user_data.get('verified_email', False),
                'subscription_plan': 'free',
                'subscription_status': 'free'
            }
            
            # Validate required fields
            if not user.get('supabase_id'):
                print("Error: Missing supabase_id for user creation")
                return None
            if not user.get('email'):
                print("Error: Missing email for user creation")
                return None
            
            result = self.supabase.table('users').insert(user).execute()
            if result.data:
                print(f"✅ User created successfully: {result.data[0].get('email', 'Unknown')}")
                return result.data[0]
            else:
                print("❌ No data returned from user creation")
                return None
        except Exception as e:
            print(f"Error creating user from OAuth: {e}")
            import traceback
            traceback.print_exc()
            return None
    
    def update_user_subscription(self, user_id, subscription_data):
        """Update user subscription information"""
        if not self.supabase:
            return None
            
        try:
            update_data = {
                'subscription_status': subscription_data.get('status', 'free'),
                'subscription_id': subscription_data.get('subscription_id'),
                'stripe_customer_id': subscription_data.get('customer_id'),
                'subscription_plan': subscription_data.get('plan'),
                'subscription_period_end': subscription_data.get('period_end'),
                'subscription_cancel_at_period_end': subscription_data.get('cancel_at_period_end', False)
            }
            
            result = self.supabase.table('users').update(update_data).eq('id', user_id).execute()
            return result.data[0] if result.data else None
            
        except Exception as e:
            print(f"Error updating user subscription: {e}")
            return None
    
    def create_or_update_user_from_supabase(self, supabase_user_data):
        """Create or update user from Supabase auth data"""
        if not self.supabase:
            print("Supabase client not initialized")
            return None
            
        try:
            print(f"Processing Supabase user data: {type(supabase_user_data)}")
            print(f"User data keys: {supabase_user_data.keys() if hasattr(supabase_user_data, 'keys') else 'Not a dict'}")
            
            # Handle both User objects and dictionaries
            if hasattr(supabase_user_data, 'id'):
                # It's a Supabase User object
                print("Processing as Supabase User object")
                user_data = {
                    'supabase_id': str(supabase_user_data.id),  # Convert to string
                    'email': supabase_user_data.email,
                    'name': (getattr(supabase_user_data.user_metadata, 'full_name', None) or 
                            getattr(supabase_user_data.user_metadata, 'name', None) or
                            supabase_user_data.email.split('@')[0]) if supabase_user_data.email else 'Unknown',
                    'picture': getattr(supabase_user_data.user_metadata, 'avatar_url', None),
                    'provider': getattr(supabase_user_data.app_metadata, 'provider', 'unknown'),
                    'verified_email': supabase_user_data.email_confirmed_at is not None
                }
            else:
                # It's a dictionary
                print("Processing as dictionary")
                user_data = {
                    'supabase_id': str(supabase_user_data.get('id')),  # Convert to string
                    'email': supabase_user_data.get('email'),
                    'name': supabase_user_data.get('user_metadata', {}).get('full_name') or 
                           supabase_user_data.get('user_metadata', {}).get('name') or
                           supabase_user_data.get('email', '').split('@')[0],
                    'picture': supabase_user_data.get('user_metadata', {}).get('avatar_url'),
                    'provider': supabase_user_data.get('app_metadata', {}).get('provider', 'unknown'),
                    'verified_email': supabase_user_data.get('email_confirmed_at') is not None
                }
            
            print(f"Processed user data: {user_data}")
            
            # Validate required fields
            if not user_data.get('supabase_id'):
                print("Error: Missing supabase_id")
                return None
            if not user_data.get('email'):
                print("Error: Missing email")
                return None
            
            # Check if user exists by Supabase ID
            print(f"Checking if user exists: {user_data['supabase_id']}")
            existing_user = self.supabase.table('users').select('*').eq('supabase_id', user_data['supabase_id']).execute()
            
            if existing_user.data:
                print(f"Updating existing user: {user_data['supabase_id']}")
                # Update existing user
                result = self.supabase.table('users').update(user_data).eq('supabase_id', user_data['supabase_id']).execute()
                if result.data:
                    print(f"User updated successfully: {result.data[0]}")
                    return result.data[0]
                else:
                    print("No data returned from update")
                    return None
            else:
                print(f"Creating new user: {user_data['supabase_id']}")
                # Create new user
                result = self.supabase.table('users').insert(user_data).execute()
                if result.data:
                    print(f"User created successfully: {result.data[0]}")
                    return result.data[0]
                else:
                    print("No data returned from insert")
                    return None
                
        except Exception as e:
            print(f"Error managing user from Supabase: {e}")
            import traceback
            traceback.print_exc()
            return None 