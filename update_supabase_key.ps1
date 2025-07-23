# PowerShell script to update Supabase service role key
$newSupabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJlbXNzZmJhZGNmcnZzYmdqbHVhIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzA0NzI5MiwiZXhwIjoyMDY4NjIzMjkyfQ.Gt_JefY-aTNSrbKKuP-i46Wj8_Blm9HQiZuRd-LUED8"

Write-Host "Updating Supabase Service Role Key..." -ForegroundColor Green

# Read the current .env file
$envContent = Get-Content .env

# Replace the Supabase service role key
$updatedContent = $envContent -replace "SUPABASE_SERVICE_ROLE_KEY=.*", "SUPABASE_SERVICE_ROLE_KEY=$newSupabaseKey"

# Write back to .env file
$updatedContent | Set-Content .env

Write-Host "Supabase Service Role Key updated successfully!" -ForegroundColor Green
Write-Host "New key: $($newSupabaseKey.Substring(0,20))...$($newSupabaseKey.Substring($newSupabaseKey.Length-4))" -ForegroundColor Yellow

Write-Host ""
Write-Host "Testing Supabase connection..." -ForegroundColor Cyan

# Test the Supabase connection
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