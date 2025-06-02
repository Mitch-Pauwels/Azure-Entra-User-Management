<#
.SYNOPSIS
    Assigns Azure AD users to security groups based on a CSV file.
.DESCRIPTION
    This script reads user UPNs and corresponding group names from a CSV file
    and assigns each user to the specified group if they exist.
.PARAMETER CSVPath
    Path to CSV file containing 'UserPrincipalName' and 'GroupDisplayName' columns.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$CSVPath
)

Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Groups

Connect-MgGraph -Scopes "Group.ReadWrite.All", "User.Read.All", "Directory.Read.All"

if (!(Test-Path $CSVPath)) {
    Write-Host "CSV file not found: $CSVPath" -ForegroundColor Red
    exit 1
}

$csvData = Import-Csv -Path $CSVPath

foreach ($entry in $csvData) {
    $upn = $entry.UserPrincipalName.Trim()
    $groupName = $entry.GroupDisplayName.Trim()

    if (-not $upn -or -not $groupName) {
        Write-Host "Skipping invalid row with missing data." -ForegroundColor Yellow
        continue
    }

    # Validate user
    try {
        $user = Get-MgUser -UserId $upn -ErrorAction Stop
    } catch {
        Write-Host "User not found: $upn" -ForegroundColor Red
        continue
    }

    # Validate or fetch group
    try {
        $group = Get-MgGroup -Filter "displayName eq '$groupName'" -ConsistencyLevel eventual -ErrorAction Stop
        if (-not $group) {
            Write-Host "Group not found: $groupName" -ForegroundColor Red
            continue
        }
    } catch {
        Write-Host "Failed to retrieve group: $groupName" -ForegroundColor Red
        continue
    }

    # Check membership
    try {
        $members = Get-MgGroupMember -GroupId $group.Id
        $alreadyMember = $members | Where-Object { $_.Id -eq $user.Id }

        if ($alreadyMember) {
            Write-Host "User '$upn' is already a member of '$groupName'" -ForegroundColor Cyan
            continue
        }

        # Add user to group
        $ref = @{ "@odata.id" = "https://graph.microsoft.com/v1.0/users/$($user.Id)" }
        New-MgGroupMember -GroupId $group.Id -BodyParameter $ref
        Write-Host "✔ Added $upn to $groupName" -ForegroundColor Green
    } catch {
        Write-Host "✖ Failed to add $upn to ${groupName}: $_" -ForegroundColor Red
    }
}
