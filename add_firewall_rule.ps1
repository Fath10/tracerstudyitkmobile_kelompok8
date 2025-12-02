# Add Windows Firewall rule for Django development server
# This script must be run as Administrator

Write-Host "Adding firewall rule for Django Dev Server on port 8000..." -ForegroundColor Cyan

try {
    # Check if rule already exists
    $existingRule = Get-NetFirewallRule -DisplayName "Django Dev Server" -ErrorAction SilentlyContinue
    
    if ($existingRule) {
        Write-Host "Firewall rule already exists. Removing old rule..." -ForegroundColor Yellow
        Remove-NetFirewallRule -DisplayName "Django Dev Server"
    }
    
    # Add new firewall rule
    New-NetFirewallRule -DisplayName "Django Dev Server" `
                        -Direction Inbound `
                        -Protocol TCP `
                        -LocalPort 8000 `
                        -Action Allow `
                        -Enabled True `
                        -Profile Any
    
    Write-Host "✅ Firewall rule added successfully!" -ForegroundColor Green
    Write-Host "Port 8000 is now accessible from other devices on the network." -ForegroundColor Green
    
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
    Write-Host "Make sure you run this script as Administrator!" -ForegroundColor Yellow
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
