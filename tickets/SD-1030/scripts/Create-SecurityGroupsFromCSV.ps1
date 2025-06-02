<#
.SYNOPSIS
    Creates Microsoft Entra ID (Azure AD) security groups from a CSV file with full configuration support.
.DESCRIPTION
    This script reads extended group attributes from a CSV file and creates each group if it does not already exist.
    Supports assignment of group type, mailNickname, membership type, role assignability, and description.
.PARAMETER CSVPath
    Path to a CSV file containing 'DisplayName' and optionally: Description, MailNickname, GroupType, MembershipType, AssignEntraRole
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$CSVPath
)

Import-Module Microsoft.Graph.Groups
Import-Module Microsoft.Graph.Authentication

Connect-MgGraph -Scopes "Group.ReadWrite.All"

$groups = Import-Csv -Path $CSVPath

foreach ($g in $groups) {
    $displayName = $g.DisplayName.Trim()
    if (-not $displayName) {
        Write-Host "✖ Skipping row: DisplayName is required." -ForegroundColor Red
        continue
    }

    $mailNickname = if (![string]::IsNullOrWhiteSpace($g.MailNickname)) {
        $g.MailNickname.Trim()
    } else {
        $displayName -replace '\s', '-' -replace '[^a-zA-Z0-9-]', '' | ForEach-Object { $_.ToLower() }
    }

    $groupType = $g.GroupType.Trim().ToLower()
    $membershipType = $g.MembershipType.Trim().ToLower()
    $description = $g.Description
    $isAssignableToRole = if ($g.AssignEntraRole -eq 'true') { $true } else { $false }

    # Check if group already exists
    $existing = Get-MgGroup -Filter "displayName eq '$displayName'" -ConsistencyLevel eventual

    if ($existing) {
        Write-Host "ℹ Group '$displayName' already exists. Skipping." -ForegroundColor Cyan
        continue
    }

    # Configure base parameters
    $params = @{
        DisplayName         = $displayName
        Description         = $description
        MailEnabled         = $false
        MailNickname        = $mailNickname
        SecurityEnabled     = $true
        GroupTypes          = @()
        IsAssignableToRole  = $isAssignableToRole
    }

    # Handle group types
    if ($groupType -eq "microsoft365") {
        $params.MailEnabled = $true
        $params.SecurityEnabled = $false
        $params.GroupTypes = @("Unified")
    }

    # Membership type (dynamic logic placeholder)
    if ($membershipType -eq "dynamicuser" -or $membershipType -eq "dynamicdevice") {
        Write-Host "⚠ Dynamic group types are not supported in this script yet. Group will be created as assigned." -ForegroundColor Yellow
    }

    try {
        $newGroup = New-MgGroup -BodyParameter $params
        Write-Host "✔ Created group '$($newGroup.DisplayName)' [MailNickname: $mailNickname]" -ForegroundColor Green
    }
    catch {
        Write-Host "✖ Failed to create group '$displayName': $_" -ForegroundColor Red
    }
}
