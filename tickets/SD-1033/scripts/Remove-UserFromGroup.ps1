<#
.SYNOPSIS
    Removes a user from a Microsoft Entra security group
.DESCRIPTION
    This script prompts for a user and group, validates both exist, confirms membership,
    and removes the user from the specified group using Microsoft Graph PowerShell SDK.
#>

param()

function Write-ColoredOutput {
    param (
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Groups
Connect-MgGraph -Scopes "User.Read.All", "Group.ReadWrite.All", "Directory.Read.All"

$userUpn = Read-Host "Enter the UPN of the user to remove (e.g., john.sanders@domainjoined.xyz)"
$groupName = Read-Host "Enter the display name of the group (e.g., IT Team)"

# Get user
$user = Get-MgUser -UserId $userUpn -ErrorAction SilentlyContinue
if (-not $user) {
    Write-ColoredOutput "User not found: $userUpn" "Red"
    exit 1
}

# Get group
$groups = Get-MgGroup -Filter "displayName eq '$groupName'" -ConsistencyLevel eventual
$group = $groups | Where-Object { $_.DisplayName -eq $groupName }

if (-not $group) {
    Write-ColoredOutput "Group not found: $groupName" "Red"
    exit 1
}

# Check if user is a member
$members = Get-MgGroupMember -GroupId $group.Id -All
$userMember = $members | Where-Object { $_.Id -eq $user.Id }

if (-not $userMember) {
    Write-ColoredOutput "User '$userUpn' is not a member of group '$groupName'" "Yellow"
    exit 0
}

# Remove from group
try {
    Remove-MgGroupMemberByRef -GroupId $group.Id -DirectoryObjectId $user.Id
    Write-ColoredOutput "SUCCESS: Removed '$($user.DisplayName)' from group '$groupName'" "Green"
} catch {
    Write-ColoredOutput "ERROR: $($_.Exception.Message)" "Red"
}
