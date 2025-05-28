param (
    [string]$DisplayName,
    [string]$UserPrincipalName,
    [string]$MailNickname
)

# Prompt with examples
if (-not $DisplayName) {
    $DisplayName = Read-Host "DisplayName (e.g. Oliver Smith)"
}
if (-not $UserPrincipalName) {
    $UserPrincipalName = Read-Host "UserPrincipalName (e.g. oliver.smith@domainjoined.xyz)"
}
if (-not $MailNickname) {
    $MailNickname = Read-Host "MailNickname (e.g. oliver.smith)"
}

# Generate a secure temporary password
function New-RandomPassword {
    $length = 12
    $chars = @{
        upper   = [char[]]'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        lower   = [char[]]'abcdefghijklmnopqrstuvwxyz'
        digit   = [char[]]'0123456789'
        special = [char[]]'!@#$%^&*()-_=+[]{}'
    }

    $password = @(
        $chars.upper | Get-Random
        $chars.lower | Get-Random
        $chars.digit | Get-Random
        $chars.special | Get-Random
    )

    $allChars = ($chars.upper + $chars.lower + $chars.digit + $chars.special)
    for ($i = $password.Count; $i -lt $length; $i++) {
        $password += $allChars | Get-Random
    }

    return -join ($password | Sort-Object {Get-Random})
}

$password = New-RandomPassword
$password | Set-Clipboard
Write-Host "🔐 Temp password copied to clipboard: $password"

# Create password profile object
$passwordProfile = [Microsoft.Graph.PowerShell.Models.MicrosoftGraphPasswordProfile]::new()
$passwordProfile.Password = $password
$passwordProfile.ForceChangePasswordNextSignIn = $true

# Try to create the user
try {
    $newUser = New-MgUser -AccountEnabled:$true `
        -DisplayName $DisplayName `
        -MailNickname $MailNickname `
        -UserPrincipalName $UserPrincipalName `
        -PasswordProfile $passwordProfile

    if ($null -ne $newUser) {
        Write-Host "✅ User $DisplayName successfully created." -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to create user $DisplayName (no user object returned)." -ForegroundColor Red
    }
}
catch {
    Write-Host "❌ Exception occurred while creating user $DisplayName." -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor DarkRed
}
