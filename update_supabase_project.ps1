# PowerShell script to update Supabase configuration to use the bemssfbadcfrvzbgjlu project
Write-Host "Updating Supabase configuration to use bemssfbadcfrvzbgjlu project..." -ForegroundColor Green

# Read the current .env file
$envContent = Get-Content .env

# Update Supabase URL to use the bemssfbadcfrvzbgjlu project
$envContent = $envContent -replace "SUPABASE_URL=.*", "SUPABASE_URL=https://bemssfbadcfrvzbgjlu.supabase.co"

# Update Supabase anon key (you'll need to provide this from the bemssfbadcfrvzbgjlu project)
Write-Host "Please provide the anon key from the bemssfbadcfrvzbgjlu project:" -ForegroundColor Yellow
Write-Host "Go to: https://supabase.com/dashboard/project/bemssfbadcfrvzbgjlu/settings/api" -ForegroundColor Cyan
Write-Host "Copy the 'anon' key and paste it here:" -ForegroundColor Cyan

# For now, we'll use a placeholder that you can update
$envContent = $envContent -replace "SUPABASE_ANON_KEY=.*", "SUPABASE_ANON_KEY=your-anon-key-from-bemssfbadcfrvzbgjlu-project"

# Update service role key (you already provided this)
$serviceRoleKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJlbXNzZmJhZGNmcnZzYmdqbHVhIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzA0NzI5MiwiZXhwIjoyMDY4NjIzMjkyfQ.Gt_JefY-aTNSrbKKuP-i46Wj8_Blm9HQiZuRd-LUED8"
$envContent = $envContent -replace "SUPABASE_SERVICE_ROLE_KEY=.*", "SUPABASE_SERVICE_ROLE_KEY=$serviceRoleKey"

# Write back to .env file
$envContent | Set-Content .env

Write-Host "Supabase configuration updated!" -ForegroundColor Green
Write-Host "URL: https://bemssfbadcfrvzbgjlu.supabase.co" -ForegroundColor Yellow
Write-Host "Service Role Key: Updated" -ForegroundColor Yellow
Write-Host "Anon Key: Please update with the correct anon key from the bemssfbadcfrvzbgjlu project" -ForegroundColor Red

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Get the anon key from: https://supabase.com/dashboard/project/bemssfbadcfrvzbgjlu/settings/api" -ForegroundColor White
Write-Host "2. Update the SUPABASE_ANON_KEY in your .env file" -ForegroundColor White
Write-Host "3. Test the connection" -ForegroundColor White 