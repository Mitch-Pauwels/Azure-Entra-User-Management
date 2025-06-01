<#
.SYNOPSIS
    Disables multiple Azure AD users from a CSV file.
.DESCRIPTION
    Reads a CSV file containing UserPrincipalNames and disables the corresponding users in Microsoft Entra ID.
.PARAMETER CSVPath
    Path to the CSV file containing the user list.
.EXAMPLE
    .\Disable-UsersFromCSV.ps1 -CSVPath "./azure_user_bulk-disable.csv"
.NOTES
    Requires Microsoft Graph PowerShell SDK.
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$CSVPath
)

Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Authentication

function Connect-ToGraph {
    if (-not (Get-MgContext)) {
        Connect-MgGraph -Scopes "User.ReadWrite.All"
    }
}

function Disable-User {
    param([string]$UserPrincipalName)

    try {
        $user = Get-MgUser -UserId $UserPrincipalName -ErrorAction Stop
        if ($user.AccountEnabled -eq $false) {
            Write-Host "Already disabled: $UserPrincipalName" -ForegroundColor Cyan
        } else {
            Update-MgUser -UserId $user.Id -AccountEnabled:$false
            Write-Host "Disabled: $UserPrincipalName" -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Failed to process: $UserPrincipalName - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main
Write-Host "Bulk User Disable Script Starting..." -ForegroundColor Cyan
Connect-ToGraph

if (-not (Test-Path $CSVPath)) {
    Write-Host "CSV not found: $CSVPath" -ForegroundColor Red
    exit 1
}

$users = Import-Csv -Path $CSVPath
foreach ($user in $users) {
    Disable-User -UserPrincipalName $user.UserPrincipalName
}

Write-Host "Script finished." -ForegroundColor Cyan
