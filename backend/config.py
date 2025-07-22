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
    SUPABASE_ANON_KEY = os.getenv('SUPABASE_ANON_KEY', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJlbXNzZmJhZGNmcnZzYmdqbHVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMwNDcyOTIsImV4cCI6MjA2ODYyMzI5Mn0.lByWzR-LwRr40IqETUUr0M5dOgUwWE0b_SCuZfLMgyY')
    SUPABASE_SERVICE_ROLE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJlbXNzZmJhZGNmcnZzYmdqbHVhIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzA0NzI5MiwiZXhwIjoyMDY4NjIzMjkyfQ.Gt_JefY-aTNSrbKKuP-i46Wj8_Blm9HQiZuRd-LUED8')
    
    # Flask Configuration
    SECRET_KEY = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')
    FLASK_ENV = os.getenv('FLASK_ENV', 'development')
    
    # Redis Configuration
    REDIS_HOST = os.getenv('REDIS_HOST', 'redis')
    REDIS_PORT = int(os.getenv('REDIS_PORT', 6379))
    
    # Docker Configuration
    DOCKER_NETWORK = os.getenv('DOCKER_NETWORK', 'runmvpwithdockerandrequiredtools_ai-agent-network') 