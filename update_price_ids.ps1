# PowerShell script to update Stripe price IDs
Write-Host "Updating Stripe Price IDs..." -ForegroundColor Green

# Read the current .env file
$envContent = Get-Content .env

# Update Pro price ID
$envContent = $envContent -replace "STRIPE_PRO_PRICE_ID=.*", "STRIPE_PRO_PRICE_ID=price_1RnI8LKoB6ANfJLNRNuYrViX"

# Update Enterprise price ID  
$envContent = $envContent -replace "STRIPE_ENTERPRISE_PRICE_ID=.*", "STRIPE_ENTERPRISE_PRICE_ID=price_1RnI9FKoB6ANfJLNWZTZ5M8A"

# Write back to .env file
$envContent | Set-Content .env

Write-Host "Stripe Price IDs updated successfully!" -ForegroundColor Green
Write-Host "Pro: price_1RnI8LKoB6ANfJLNRNuYrViX ($29.99)" -ForegroundColor Yellow
Write-Host "Enterprise: price_1RnI9FKoB6ANfJLNWZTZ5M8A ($99.99)" -ForegroundColor Yellow

Write-Host ""
Write-Host "Testing all price IDs..." -ForegroundColor Cyan
python test_stripe_prices.py 