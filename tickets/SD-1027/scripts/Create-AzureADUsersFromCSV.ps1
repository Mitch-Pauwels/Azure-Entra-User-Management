
<#
.SYNOPSIS
    Creates Azure AD users from a CSV file using Microsoft Graph PowerShell SDK

.PARAMETER CSVPath
    Path to CSV with fields like: DisplayName, UserPrincipalName, PasswordProfile, etc.

.EXAMPLE
    .\Create-AzureADUsersFromCSV.ps1 -CSVPath .\azure_user_template-powershell.csv
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$CSVPath
)

# Ensure Microsoft Graph SDK modules
$modules = @("Microsoft.Graph.Authentication", "Microsoft.Graph.Users")
foreach ($module in $modules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Install-Module $module -Force -Scope CurrentUser -AllowClobber
    }
    Import-Module $module -Force
}

# Connect to Graph
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes "User.ReadWrite.All"
}

# Validate path and import
if (-not (Test-Path $CSVPath)) {
    Write-Host "CSV file not found: $CSVPath" -ForegroundColor Red
    exit 1
}

$csv = Import-Csv -Path $CSVPath
Write-Host "`nImported $($csv.Count) user(s) from CSV.`n" -ForegroundColor Cyan

foreach ($user in $csv) {
    try {
        $passwordProfile = @{
            Password = $user.PasswordProfile
            ForceChangePasswordNextSignIn = $true
        }

        $params = @{
            DisplayName       = $user.DisplayName
            UserPrincipalName = $user.UserPrincipalName
            MailNickname      = $user.UserPrincipalName.Split("@")[0]
            AccountEnabled    = [System.Convert]::ToBoolean($user.AccountEnabled)
            PasswordProfile   = $passwordProfile
            GivenName         = $user.GivenName
            Surname           = $user.Surname
            JobTitle          = $user.JobTitle
            Department        = $user.Department
            UsageLocation     = $user.UsageLocation
        }

        $newUser = New-MgUser -BodyParameter $params
        Write-Host "✓ Created user: $($user.DisplayName) <$($user.UserPrincipalName)>" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Failed to create user: $($user.UserPrincipalName)" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor DarkGray
    }
}
