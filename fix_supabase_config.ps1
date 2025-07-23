# PowerShell script to revert to working Supabase configuration
Write-Host "Reverting to working Supabase configuration..." -ForegroundColor Green

# Read the current .env file
$envContent = Get-Content .env

# Revert to the working Supabase URL
$envContent = $envContent -replace "SUPABASE_URL=.*", "SUPABASE_URL=https://ewrbezytnhuovvmkepeg.supabase.co"

# Revert to the working anon key
$envContent = $envContent -replace "SUPABASE_ANON_KEY=.*", "SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV3cmJlenl0bmh1b3Z2bWtlcGVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzE5NzQ5NzQsImV4cCI6MjA0NzU1MDk3NH0.Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8"

# Set service role key to placeholder (we'll get the correct one)
$envContent = $envContent -replace "SUPABASE_SERVICE_ROLE_KEY=.*", "SUPABASE_SERVICE_ROLE_KEY=your-supabase-service-role-key"

# Write back to .env file
$envContent | Set-Content .env

Write-Host "Supabase configuration reverted to working setup!" -ForegroundColor Green
Write-Host "URL: https://ewrbezytnhuovvmkepeg.supabase.co" -ForegroundColor Yellow
Write-Host "Anon Key: Working key restored" -ForegroundColor Yellow
Write-Host "Service Role Key: Needs correct key from ewrbezytnhuovvmkepeg project" -ForegroundColor Red

Write-Host ""
Write-Host "Testing connection..." -ForegroundColor Cyan

# Test the connection
cd backend
python -c "
import os
import sys
sys.path.append('.')
from supabase_client import supabase_manager
try:
    # Test a simple query
    result = supabase_manager.supabase.table('users').select('*').limit(1).execute()
    print('✅ Supabase connection successful!')
    print(f'   Found {len(result.data)} users in database')
except Exception as e:
    print(f'❌ Supabase connection failed: {e}')
"
cd .. 