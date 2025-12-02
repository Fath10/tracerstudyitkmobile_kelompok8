# Complete Backend Connectivity Test Script
# Tests all backend endpoints to ensure mobile app will work

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "BACKEND CONNECTIVITY TEST" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$BaseUrl = "http://192.168.0.105:8000"
$TestsPassed = 0
$TestsFailed = 0

function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Url,
        [string]$Method = "GET",
        [hashtable]$Body = $null
    )
    
    Write-Host "Testing: $Name" -NoNewline
    try {
        $params = @{
            Uri = $Url
            Method = $Method
            TimeoutSec = 5
            ContentType = "application/json"
        }
        
        if ($Body) {
            $params.Body = ($Body | ConvertTo-Json)
        }
        
        $response = Invoke-RestMethod @params
        Write-Host " ✅ PASS" -ForegroundColor Green
        $script:TestsPassed++
        return $response
    }
    catch {
        Write-Host " ❌ FAIL" -ForegroundColor Red
        Write-Host "   Error: $_" -ForegroundColor Red
        $script:TestsFailed++
        return $null
    }
}

# Test 1: Backend is running
Write-Host "`n1. BACKEND SERVER STATUS" -ForegroundColor Yellow
Write-Host "-------------------------" -ForegroundColor Yellow
Test-Endpoint -Name "Server Health Check" -Url "$BaseUrl/api/roles/"

# Test 2: Roles endpoint (required for user management)
Write-Host "`n2. ROLES ENDPOINT" -ForegroundColor Yellow
Write-Host "-------------------------" -ForegroundColor Yellow
$roles = Test-Endpoint -Name "Get Roles" -Url "$BaseUrl/api/roles/"
if ($roles) {
    Write-Host "   Found $($roles.Count) roles: $($roles.name -join ', ')" -ForegroundColor Gray
}

# Test 3: Program Studies endpoint
Write-Host "`n3. PROGRAM STUDIES ENDPOINT" -ForegroundColor Yellow
Write-Host "-------------------------" -ForegroundColor Yellow
$programs = Test-Endpoint -Name "Get Program Studies" -Url "$BaseUrl/api/unit/program-studies/"
if ($programs) {
    Write-Host "   Found $($programs.Count) program studies" -ForegroundColor Gray
}

# Test 4: Users endpoint
Write-Host "`n4. USERS ENDPOINT" -ForegroundColor Yellow
Write-Host "-------------------------" -ForegroundColor Yellow
$users = Test-Endpoint -Name "Get Users" -Url "$BaseUrl/api/users/"
if ($users) {
    Write-Host "   Found $($users.Count) users" -ForegroundColor Gray
}

# Test 5: Surveys endpoint
Write-Host "`n5. SURVEYS ENDPOINT" -ForegroundColor Yellow
Write-Host "-------------------------" -ForegroundColor Yellow
$surveys = Test-Endpoint -Name "Get Surveys" -Url "$BaseUrl/api/surveys/"
if ($surveys) {
    Write-Host "   Found $($surveys.Count) surveys" -ForegroundColor Gray
}

# Test 6: Network accessibility
Write-Host "`n6. NETWORK CONFIGURATION" -ForegroundColor Yellow
Write-Host "-------------------------" -ForegroundColor Yellow
Write-Host "   Your computer's IP: 192.168.1.107" -ForegroundColor Gray
Write-Host "   Backend URL: $BaseUrl" -ForegroundColor Gray
Write-Host "   Mobile app config: Check lib/config/api_config.dart" -ForegroundColor Gray

# Test 7: Firewall check
Write-Host "`n7. FIREWALL CHECK" -ForegroundColor Yellow
Write-Host "-------------------------" -ForegroundColor Yellow
$firewallRule = Get-NetFirewallRule -DisplayName "Django Dev Server" -ErrorAction SilentlyContinue
if ($firewallRule) {
    Write-Host "   ✅ Firewall rule exists" -ForegroundColor Green
    Write-Host "   Rule Status: $($firewallRule.Enabled)" -ForegroundColor Gray
} else {
    Write-Host "   ❌ Firewall rule NOT found" -ForegroundColor Red
    Write-Host "   Action needed: Run add_firewall_rule.ps1 as Administrator" -ForegroundColor Yellow
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TEST SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Tests Passed: $TestsPassed" -ForegroundColor Green
Write-Host "Tests Failed: $TestsFailed" -ForegroundColor Red

if ($TestsFailed -eq 0) {
    Write-Host "`n✅ ALL TESTS PASSED! Backend is ready." -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Ensure firewall rule is added (run add_firewall_rule.ps1 as Admin)" -ForegroundColor White
    Write-Host "2. Connect your phone to the same Wi-Fi network" -ForegroundColor White
    Write-Host "3. Run the Flutter app on your physical device" -ForegroundColor White
    Write-Host "4. Test all features: login, user management, surveys" -ForegroundColor White
} else {
    Write-Host "`n⚠️  SOME TESTS FAILED. Fix issues above." -ForegroundColor Yellow
}

Write-Host "`n========================================`n" -ForegroundColor Cyan
