from supabase import create_client, Client
from cryptography.fernet import Fernet
import base64
import os
from config import Config

class SupabaseManager:
    def __init__(self):
        self.supabase: Client = create_client(Config.SUPABASE_URL, Config.SUPABASE_ANON_KEY)
        self.encryption_key = self._get_or_create_encryption_key()
        self.cipher = Fernet(self.encryption_key)
    
    def _get_or_create_encryption_key(self):
        """Get existing encryption key or create new one"""
        key = os.getenv('ENCRYPTION_KEY')
        if not key:
            # Generate new key (in production, this should be stored securely)
            key = Fernet.generate_key()
            print(f"Generated new encryption key: {key.decode()}")
        else:
            key = key.encode()
        return key
    
    def encrypt_api_key(self, api_key: str) -> str:
        """Encrypt API key before storage"""
        return self.cipher.encrypt(api_key.encode()).decode()
    
    def decrypt_api_key(self, encrypted_key: str) -> str:
        """Decrypt API key for use"""
        return self.cipher.decrypt(encrypted_key.encode()).decode()
    
    def save_api_key(self, user_id: str, service: str, api_key: str) -> bool:
        """Save encrypted API key to Supabase"""
        try:
            encrypted_key = self.encrypt_api_key(api_key)
            
            # Upsert API key (update if exists, insert if not)
            result = self.supabase.table('api_keys').upsert({
                'user_id': user_id,
                'service': service,
                'encrypted_key': encrypted_key,
                'updated_at': 'now()'
            }).execute()
            
            return len(result.data) > 0
        except Exception as e:
            print(f"Error saving API key: {e}")
            return False
    
    def get_api_key(self, user_id: str, service: str) -> str:
        """Retrieve and decrypt API key from Supabase"""
        try:
            result = self.supabase.table('api_keys').select('encrypted_key').eq('user_id', user_id).eq('service', service).execute()
            
            if result.data:
                encrypted_key = result.data[0]['encrypted_key']
                return self.decrypt_api_key(encrypted_key)
            return None
        except Exception as e:
            print(f"Error retrieving API key: {e}")
            return None
    
    def list_user_api_keys(self, user_id: str) -> list:
        """List all API keys for a user (without decryption)"""
        try:
            result = self.supabase.table('api_keys').select('service, updated_at').eq('user_id', user_id).execute()
            return result.data
        except Exception as e:
            print(f"Error listing API keys: {e}")
            return []
    
    def delete_api_key(self, user_id: str, service: str) -> bool:
        """Delete API key from Supabase"""
        try:
            result = self.supabase.table('api_keys').delete().eq('user_id', user_id).eq('service', service).execute()
            return len(result.data) > 0
        except Exception as e:
            print(f"Error deleting API key: {e}")
            return False

# Global instance - lazy loaded
_supabase_manager = None

def get_supabase_manager():
    global _supabase_manager
    if _supabase_manager is None:
        _supabase_manager = SupabaseManager()
    return _supabase_manager

# For backward compatibility
supabase_manager = get_supabase_manager() 