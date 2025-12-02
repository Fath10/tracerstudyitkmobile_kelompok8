# Quick Backend Test and Start Script
# Run this to verify everything is working

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TRACER STUDY ITK - QUICK START" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$BackendPath = "c:\Code\Flutter\Tracer Study ITK\Backend\capstone_backend"
$BaseUrl = "http://192.168.0.105:8000"

# Step 1: Check if backend is running
Write-Host "Step 1: Checking backend status..." -ForegroundColor Yellow
$running = Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue
if ($running) {
    Write-Host "✅ Backend is RUNNING on port 8000" -ForegroundColor Green
} else {
    Write-Host "❌ Backend is NOT running" -ForegroundColor Red
    Write-Host "`nStarting backend server..." -ForegroundColor Yellow
    Write-Host "Command: cd '$BackendPath'; python manage.py runserver 0.0.0.0:8000" -ForegroundColor Gray
    Write-Host "`nPlease run the command above in a separate terminal.`n" -ForegroundColor Yellow
    exit
}

# Step 2: Check IP address
Write-Host "`nStep 2: Checking network configuration..." -ForegroundColor Yellow
$ip = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Wi-Fi*" -ErrorAction SilentlyContinue | Select-Object -First 1).IPAddress
if (!$ip) {
    $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -like "192.168.*" } | Select-Object -First 1).IPAddress
}
if ($ip -eq "192.168.0.105") {
    Write-Host "✅ IP address is correct: $ip" -ForegroundColor Green
} else {
    Write-Host "⚠️  IP address changed!" -ForegroundColor Yellow
    Write-Host "   Current IP: $ip" -ForegroundColor Gray
    Write-Host "   Configured: 192.168.0.105" -ForegroundColor Gray
    Write-Host "   Update lib/config/api_config.dart if needed" -ForegroundColor Gray
}

# Step 3: Test backend endpoints
Write-Host "`nStep 3: Testing backend endpoints..." -ForegroundColor Yellow

$tests = @(
    @{Name="Roles"; Endpoint="/api/roles/"},
    @{Name="Users"; Endpoint="/api/users/"},
    @{Name="Programs"; Endpoint="/api/unit/program-studies/"},
    @{Name="Surveys"; Endpoint="/api/surveys/"}
)

$allPassed = $true
foreach ($test in $tests) {
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl$($test.Endpoint)" -Method GET -TimeoutSec 3
        $count = if ($response -is [Array]) { $response.Count } else { $response.results.Count }
        Write-Host "✅ $($test.Name): $count items" -ForegroundColor Green
    } catch {
        Write-Host "❌ $($test.Name): FAILED" -ForegroundColor Red
        $allPassed = $false
    }
}

# Step 4: Test authentication
Write-Host "`nStep 4: Testing authentication..." -ForegroundColor Yellow
try {
    $body = @{ id = "admin"; password = "admin123" } | ConvertTo-Json
    $response = Invoke-RestMethod -Uri "$BaseUrl/accounts/login/" -Method POST -Body $body -ContentType "application/json" -TimeoutSec 3
    Write-Host "✅ Login: Success" -ForegroundColor Green
    Write-Host "   User: $($response.user.username)" -ForegroundColor Gray
    Write-Host "   Role: $($response.user.role.name)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Login: FAILED" -ForegroundColor Red
    $allPassed = $false
}

# Step 5: Firewall check
Write-Host "`nStep 5: Checking firewall..." -ForegroundColor Yellow
$firewall = Get-NetFirewallRule -DisplayName "*Django*" -ErrorAction SilentlyContinue
if ($firewall -and $firewall.Enabled -eq "True") {
    Write-Host "✅ Firewall rule enabled" -ForegroundColor Green
} else {
    Write-Host "⚠️  Firewall rule not found or disabled" -ForegroundColor Yellow
    Write-Host "   Run add_firewall_rule.ps1 as Administrator if needed" -ForegroundColor Gray
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($allPassed) {
    Write-Host "✅ ALL TESTS PASSED!" -ForegroundColor Green
    Write-Host "`nYou can now:" -ForegroundColor Cyan
    Write-Host "1. Connect your phone to WiFi (same network as this PC)" -ForegroundColor White
    Write-Host "2. Run: flutter run" -ForegroundColor White
    Write-Host "3. Login with: admin / admin123" -ForegroundColor White
    Write-Host "`nBackend URL: $BaseUrl" -ForegroundColor Gray
} else {
    Write-Host "⚠️  SOME TESTS FAILED" -ForegroundColor Yellow
    Write-Host "Check the errors above and fix before running app" -ForegroundColor Yellow
}

Write-Host "`n========================================`n" -ForegroundColor Cyan
