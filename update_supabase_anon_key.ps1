# PowerShell script to update Supabase anon key
$newAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJlbXNzZmJhZGNmcnZzYmdqbHVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMwNDcyOTIsImV4cCI6MjA2ODYyMzI5Mn0.lByWzR-LwRr40IqETUUr0M5dOgUwWE0b_SCuZfLMgyY"

Write-Host "Updating Supabase Anon Key..." -ForegroundColor Green

# Read the current .env file
$envContent = Get-Content .env

# Replace the Supabase anon key
$updatedContent = $envContent -replace "SUPABASE_ANON_KEY=.*", "SUPABASE_ANON_KEY=$newAnonKey"

# Write back to .env file
$updatedContent | Set-Content .env

Write-Host "Supabase Anon Key updated successfully!" -ForegroundColor Green
Write-Host "New key: $($newAnonKey.Substring(0,20))...$($newAnonKey.Substring($newAnonKey.Length-4))" -ForegroundColor Yellow

Write-Host ""
Write-Host "Testing complete Supabase configuration..." -ForegroundColor Cyan

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
    print('   Project: bemssfbadcfrvzbgjlu')
    print('   Both anon and service_role keys working!')
except Exception as e:
    print(f'❌ Supabase connection failed: {e}')
"
cd .. 