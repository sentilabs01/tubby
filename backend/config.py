import os
from dotenv import load_dotenv

# Load .env from parent directory (project root)
try:
    load_dotenv('../.env')
except Exception:
    pass  # Use defaults if .env file doesn't exist or can't be loaded

class Config:
    # Supabase Configuration
    SUPABASE_URL = os.getenv('SUPABASE_URL', 'https://bemssfbadcfrvsbgjlua.supabase.co')
    SUPABASE_ANON_KEY = os.getenv('SUPABASE_ANON_KEY', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV3cmJlenl0bmh1b3Z2bWtlcGVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzE5NzQ5NzQsImV4cCI6MjA0NzU1MDk3NH0.Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8')
    SUPABASE_SERVICE_ROLE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY', 'your-supabase-service-role-key')
    
    # Flask Configuration
    SECRET_KEY = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')
    FLASK_ENV = os.getenv('FLASK_ENV', 'development')
    
    # Redis Configuration
    REDIS_HOST = os.getenv('REDIS_HOST', 'redis')
    REDIS_PORT = int(os.getenv('REDIS_PORT', 6379))
    
    # Docker Configuration
    DOCKER_NETWORK = os.getenv('DOCKER_NETWORK', 'runmvpwithdockerandrequiredtools_ai-agent-network') 