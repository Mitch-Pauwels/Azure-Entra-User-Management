param (
    [Parameter(Mandatory = $true)]
    [string]$UserPrincipalName
)

# Step 1: Get the user
$user = Get-MgUser -Filter "userPrincipalName eq '$UserPrincipalName'"

if ($null -eq $user) {
    Write-Host "❌ User not found: $UserPrincipalName" -ForegroundColor Red
    return
}

# Step 2: Generate a new random password
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

# Step 3: Reset password and re-enable account
Update-MgUser -UserId $user.Id -BodyParameter @{
    AccountEnabled = $true
    PasswordProfile = @{
        Password = $password
        ForceChangePasswordNextSignIn = $true
    }
}

Write-Host "✅ Password reset complete for $UserPrincipalName and account enabled." -ForegroundColor Green
