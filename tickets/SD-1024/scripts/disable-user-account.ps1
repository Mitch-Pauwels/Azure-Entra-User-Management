param (
    [string]$UserPrincipalName
)

# Prompt if not provided
if (-not $UserPrincipalName) {
    $UserPrincipalName = Read-Host "UserPrincipalName (e.g. oliver.smith@domainjoined.xyz)"
}

# Get the user
$user = Get-MgUser -Filter "userPrincipalName eq '$UserPrincipalName'"

if (-not $user) {
    Write-Host "❌ User not found: $UserPrincipalName" -ForegroundColor Red
    exit 1
}

# Disable the user
try {
    Update-MgUser -UserId $user.Id -AccountEnabled:$false

    # Re-fetch with specific property to verify
    $updatedUser = Get-MgUser -UserId $user.Id -Property "accountEnabled"

    if ($updatedUser.AccountEnabled -eq $false) {
        Write-Host "✅ User $UserPrincipalName successfully disabled." -ForegroundColor Green
    } else {
        Write-Host "⚠️ Attempted to disable $UserPrincipalName, but status did not change." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "❌ Failed to disable user: $_" -ForegroundColor Red
}
