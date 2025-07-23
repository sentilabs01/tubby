# Smoke Test Script for Tubby AI
Write-Host "🧪 Running Smoke Tests for Tubby AI" -ForegroundColor Green

# Test Backend Health
Write-Host "Testing Backend Health..." -ForegroundColor Cyan
try {
    $backendResponse = Invoke-WebRequest -Uri "http://localhost:5004/health" -UseBasicParsing
    if ($backendResponse.StatusCode -eq 200) {
        Write-Host "✅ Backend Health Check: PASSED" -ForegroundColor Green
        Write-Host "   Response: $($backendResponse.Content)" -ForegroundColor Gray
    } else {
        Write-Host "❌ Backend Health Check: FAILED (Status: $($backendResponse.StatusCode))" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Backend Health Check: FAILED (Connection Error)" -ForegroundColor Red
}

# Test Frontend
Write-Host "Testing Frontend..." -ForegroundColor Cyan
try {
    $frontendResponse = Invoke-WebRequest -Uri "http://localhost:3001" -UseBasicParsing
    if ($frontendResponse.StatusCode -eq 200) {
        Write-Host "✅ Frontend Check: PASSED" -ForegroundColor Green
    } else {
        Write-Host "❌ Frontend Check: FAILED (Status: $($frontendResponse.StatusCode))" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Frontend Check: FAILED (Connection Error)" -ForegroundColor Red
}

# Test Network Access
Write-Host "Testing Network Access..." -ForegroundColor Cyan
try {
    $networkResponse = Invoke-WebRequest -Uri "http://192.168.4.22:3001" -UseBasicParsing
    if ($networkResponse.StatusCode -eq 200) {
        Write-Host "✅ Network Access: PASSED" -ForegroundColor Green
        Write-Host "   Mobile can access: http://192.168.4.22:3001" -ForegroundColor Yellow
    } else {
        Write-Host "❌ Network Access: FAILED (Status: $($networkResponse.StatusCode))" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Network Access: FAILED (Connection Error)" -ForegroundColor Red
}

Write-Host ""
Write-Host "📱 Mobile Testing URLs:" -ForegroundColor Yellow
Write-Host "   Frontend: http://192.168.4.22:3001" -ForegroundColor White
Write-Host "   Backend:  http://192.168.4.22:5004" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Ready for deployment!" -ForegroundColor Green 