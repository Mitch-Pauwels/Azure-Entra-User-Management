<#
.SYNOPSIS
    Assign a Microsoft 365 license to an Entra ID group using Microsoft Graph

.DESCRIPTION
    This script allows you to assign an available Microsoft 365 license (SKU) to a security group.
    All users within that group will automatically inherit the license.

.NOTES
    - Requires Microsoft.Graph modules and appropriate permissions
    - Make sure the group exists and is a security group
#>

# Load required modules
Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Groups
Import-Module Microsoft.Graph.Identity.DirectoryManagement

# Connect to Microsoft Graph if not already connected
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes "Group.ReadWrite.All", "Directory.ReadWrite.All"
}

# Select group
$groups = Get-MgGroup -All | Where-Object { $_.SecurityEnabled -eq $true -and $_.GroupTypes.Count -eq 0 } | Sort-Object DisplayName

$groupChoices = $groups | Select-Object DisplayName, Id
$selectedGroup = $groupChoices | Out-GridView -Title "Select Group to Assign License To" -PassThru

if (-not $selectedGroup) {
    Write-Host "No group selected. Exiting." -ForegroundColor Yellow
    exit
}

# Select license
$licenses = Get-MgSubscribedSku | Where-Object { $_.PrepaidUnits.Enabled -gt $_.ConsumedUnits }
$licenseOptions = $licenses | ForEach-Object {
    [PSCustomObject]@{
        Name = $_.SkuPartNumber
        ID   = $_.SkuId
        Available = $_.PrepaidUnits.Enabled - $_.ConsumedUnits
    }
}

$selectedLicense = $licenseOptions | Out-GridView -Title "Select Microsoft 365 License to Assign" -PassThru

if (-not $selectedLicense) {
    Write-Host "No license selected. Exiting." -ForegroundColor Yellow
    exit
}

# Assign license to the group
$body = @{
    AddLicenses = @(@{SkuId = $selectedLicense.ID})
    RemoveLicenses = @()
}

try {
    Set-MgGroupLicense -GroupId $selectedGroup.Id -BodyParameter $body
    Write-Host "✅ Successfully assigned license '$($selectedLicense.Name)' to group '$($selectedGroup.DisplayName)'" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to assign license: $($_.Exception.Message)" -ForegroundColor Red
}
