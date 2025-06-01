<#
.SYNOPSIS
    Bulk updates user properties in Microsoft Entra ID (Azure AD) from a CSV file.

.DESCRIPTION
    This script reads a CSV containing UserPrincipalName, JobTitle, and Department,
    then updates those values for each user using Microsoft Graph PowerShell SDK.

.PARAMETER CSVPath
    Path to the CSV file

.EXAMPLE
    .\Update-UserPropertiesFromCSV.ps1 -CSVPath "C:\path\to\azure_user_property_updates.csv"
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$CSVPath
)

# Ensure required module
$module = 'Microsoft.Graph.Users'
if (-not (Get-Module -ListAvailable -Name $module)) {
    Install-Module -Name $module -Force -Scope CurrentUser
}
Import-Module $module

# Connect to Graph if not already connected
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes "User.ReadWrite.All"
}

# Import CSV
$users = Import-Csv -Path $CSVPath

foreach ($user in $users) {
    $upn = $user.UserPrincipalName
    $title = $user.JobTitle
    $dept = $user.Department

    try {
        Update-MgUser -UserId $upn -JobTitle $title -Department $dept
        Write-Host "✅ Updated $upn -> Title: $title | Department: $dept" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to update ${upn}: $($_.Exception.Message)" -ForegroundColor Red
    }
}
