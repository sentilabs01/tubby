import os
from dotenv import load_dotenv

# Load .env from parent directory (project root)
load_dotenv('../.env')

class Config:
    # Supabase Configuration
    SUPABASE_URL = os.getenv('SUPABASE_URL', 'https://ewrbezytnhuovvmkepeg.supabase.co')
    SUPABASE_ANON_KEY = os.getenv('SUPABASE_ANON_KEY', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV3cmJlenl0bmh1b3Z2bWtlcGVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI5Njg4MjksImV4cCI6MjA2ODU0NDgyOX0.WagV4Mmud1Co1SvRZ1nCVTLJt7DTIa7KlMqqHcjlHVs')
    
    # Flask Configuration
    SECRET_KEY = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')
    FLASK_ENV = os.getenv('FLASK_ENV', 'development')
    
    # Redis Configuration
    REDIS_HOST = os.getenv('REDIS_HOST', 'redis')
    REDIS_PORT = int(os.getenv('REDIS_PORT', 6379))
    
    # Docker Configuration
    DOCKER_NETWORK = os.getenv('DOCKER_NETWORK', 'runmvpwithdockerandrequiredtools_ai-agent-network') 