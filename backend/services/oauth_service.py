import os
import jwt
import requests
from datetime import datetime, timedelta
from supabase import create_client, Client

# Optional Google imports - will be imported only if available
try:
    from google.auth.transport import requests as google_requests
    from google.oauth2 import id_token
    from google_auth_oauthlib.flow import Flow
    GOOGLE_AVAILABLE = True
except ImportError:
    GOOGLE_AVAILABLE = False
    print("Google OAuth dependencies not available. Google OAuth will be disabled.")

class OAuthService:
    def __init__(self):
        self.google_client_id = os.getenv('GOOGLE_CLIENT_ID')
        self.google_client_secret = os.getenv('GOOGLE_CLIENT_SECRET')
        self.google_redirect_uri = os.getenv('GOOGLE_REDIRECT_URI')
        self.jwt_secret = os.getenv('JWT_SECRET_KEY')
        self.jwt_algorithm = os.getenv('JWT_ALGORITHM', 'HS256')
        self.jwt_expiration_hours = int(os.getenv('JWT_EXPIRATION_HOURS', 24))
        
        # Initialize Supabase client
        supabase_url = os.getenv('SUPABASE_URL', 'https://bemssfbadcfrvsbgjlua.supabase.co')
        supabase_key = os.getenv('SUPABASE_ANON_KEY', 'placeholder_key')
        
        try:
            self.supabase: Client = create_client(supabase_url, supabase_key)
        except Exception as e:
            print(f"Warning: Could not initialize Supabase client: {e}")
            self.supabase = None
        
    def create_google_flow(self):
        """Create Google OAuth flow"""
        if not GOOGLE_AVAILABLE:
            raise Exception("Google OAuth dependencies not available")
        
        flow = Flow.from_client_config(
            {
                "web": {
                    "client_id": self.google_client_id,
                    "client_secret": self.google_client_secret,
                    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                    "token_uri": "https://oauth2.googleapis.com/token",
                    "redirect_uris": [self.google_redirect_uri]
                }
            },
            scopes=['openid', 'email', 'profile']
        )
        flow.redirect_uri = self.google_redirect_uri
        return flow
    
    def get_google_auth_url(self):
        """Generate Google OAuth authorization URL"""
        if not GOOGLE_AVAILABLE:
            # Return a placeholder URL that will show an error message
            return f"{os.getenv('FRONTEND_URL', 'http://localhost:3007')}/auth/error?provider=google&message=Google OAuth not configured"
        
        try:
            flow = self.create_google_flow()
            auth_url, _ = flow.authorization_url(prompt='consent')
            return auth_url
        except Exception as e:
            print(f"Error creating Google auth URL: {e}")
            return f"{os.getenv('FRONTEND_URL', 'http://localhost:3007')}/auth/error?provider=google&message=Google OAuth configuration error"
    
    def verify_google_token(self, code):
        """Verify Google OAuth token and return user info"""
        if not GOOGLE_AVAILABLE:
            return None
            
        try:
            flow = self.create_google_flow()
            flow.fetch_token(code=code)
            
            # Get user info from Google
            credentials = flow.credentials
            user_info_response = requests.get(
                'https://www.googleapis.com/oauth2/v2/userinfo',
                headers={'Authorization': f'Bearer {credentials.token}'}
            )
            
            if user_info_response.status_code == 200:
                return user_info_response.json()
            else:
                return None
                
        except Exception as e:
            print(f"Error verifying Google token: {e}")
            return None
    
    def generate_jwt_token(self, user_data):
        """Generate JWT token for authenticated user"""
        payload = {
            'user_id': user_data.get('id'),
            'email': user_data.get('email'),
            'name': user_data.get('name'),
            'picture': user_data.get('picture'),
            'exp': datetime.utcnow() + timedelta(hours=self.jwt_expiration_hours),
            'iat': datetime.utcnow()
        }
        
        token = jwt.encode(payload, self.jwt_secret, algorithm=self.jwt_algorithm)
        return token
    
    def verify_jwt_token(self, token):
        """Verify JWT token and return user data"""
        try:
            payload = jwt.decode(token, self.jwt_secret, algorithms=[self.jwt_algorithm])
            return payload
        except jwt.ExpiredSignatureError:
            return None
        except jwt.InvalidTokenError:
            return None
    
    def get_supabase_auth_url(self, provider='google'):
        """Get Supabase OAuth URL for the specified provider"""
        if not self.supabase:
            return None
            
        try:
            # Use the correct frontend URL based on current setup
            frontend_url = os.getenv('FRONTEND_URL', 'http://localhost:3015')
            redirect_url = f"{frontend_url}/auth/callback"
            
            print(f"Generating auth URL for {provider} with redirect: {redirect_url}")
            
            auth_url = self.supabase.auth.sign_in_with_oauth({
                'provider': provider,
                'options': {
                    'redirect_to': redirect_url
                }
            })
            return auth_url.url
        except Exception as e:
            print(f"Error getting Supabase auth URL: {e}")
            import traceback
            traceback.print_exc()
            return None
    
    def verify_supabase_token(self, access_token):
        """Verify Supabase access token and return user data. Fallback to local decode if Supabase client is not available."""
        try:
            # Preferred: use Supabase client if available
            if self.supabase:
                user_response = self.supabase.auth.get_user(access_token)
                if user_response and user_response.user:
                    return self._format_supabase_user(user_response.user)
            # Fallback: decode JWT without verifying signature
            import jwt
            decoded = jwt.decode(access_token, options={
                'verify_signature': False,
                'verify_exp': False,
                'verify_aud': False,
                'verify_iss': False
            })
            return {
                'id': decoded.get('sub') or decoded.get('user_id') or decoded.get('id'),
                'email': decoded.get('email') or 'unknown@example.com',
                'name': decoded.get('name') or decoded.get('email', '').split('@')[0] or 'Unknown',
                'picture': decoded.get('picture'),
                'provider': decoded.get('provider') or decoded.get('iss', 'oauth'),
                'verified_email': decoded.get('email_confirmed_at') is not None
            }
        except Exception as e:
            print(f"Token verification failed (fallback): {e}")
            return None 

    def _format_supabase_user(self, supabase_user):
        """Convert Supabase user object to unified dict"""
        return {
            'id': supabase_user.id,
            'email': supabase_user.email,
            'name': supabase_user.user_metadata.get('full_name') or supabase_user.email.split('@')[0],
            'picture': supabase_user.user_metadata.get('avatar_url'),
            'provider': supabase_user.app_metadata.get('provider', 'oauth'),
            'verified_email': supabase_user.email_confirmed_at is not None
        } 