<#
.SYNOPSIS
    Select multiple Microsoft Entra security groups and display their members with type resolution.
.DESCRIPTION
    Prompts for selecting multiple groups and shows the members of each one, resolving unknown types if necessary.
#>

Import-Module Microsoft.Graph.Groups
Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Authentication

Connect-MgGraph -Scopes "Group.Read.All", "Directory.Read.All"

# Get all groups
$groups = Get-MgGroup -All | Where-Object { $_.SecurityEnabled -eq $true }

if ($groups.Count -eq 0) {
    Write-Host "No security groups found." -ForegroundColor Red
    exit
}

$selectedGroups = @()

do {
    Write-Host "`nAvailable Groups:`n" -ForegroundColor Cyan
    for ($i = 0; $i -lt $groups.Count; $i++) {
        Write-Host "$($i + 1). $($groups[$i].DisplayName)"
    }

    $index = Read-Host "`nSelect a group number to inspect"
    $selectedGroup = $groups[$index - 1]
    $selectedGroups += $selectedGroup

    Write-Host "`n✔ Added group: $($selectedGroup.DisplayName)" -ForegroundColor Green

    $again = Read-Host "Add another group? (y/n)"
} while ($again -match "^(y|yes)$")

# List members for each selected group
foreach ($g in $selectedGroups) {
    Write-Host "`n--- Members of '$($g.DisplayName)' ---" -ForegroundColor Cyan
    $members = Get-MgGroupMember -GroupId $g.Id -All

    if (-not $members) {
        Write-Host "(No members found)" -ForegroundColor DarkGray
        continue
    }

    foreach ($m in $members) {
        $type = $m.'@odata.type'

        if ($type -eq "#microsoft.graph.user") {
            $user = Get-MgUser -UserId $m.Id -Property DisplayName, UserPrincipalName
            Write-Host "- 👤 $($user.DisplayName) <$($user.UserPrincipalName)>"
        } elseif ($type -eq "#microsoft.graph.group") {
            $nestedGroup = Get-MgGroup -GroupId $m.Id
            Write-Host "- 👥 [Group] $($nestedGroup.DisplayName)"
        } else {
            # Try resolving unknown type
            try {
                $resolvedUser = Get-MgUser -UserId $m.Id -Property DisplayName, UserPrincipalName -ErrorAction Stop
                Write-Host "- 👤 $($resolvedUser.DisplayName) <$($resolvedUser.UserPrincipalName)>"
            }
            catch {
                try {
                    $resolvedGroup = Get-MgGroup -GroupId $m.Id -ErrorAction Stop
                    Write-Host "- 👥 [Group] $($resolvedGroup.DisplayName)"
                }
                catch {
                    Write-Host "- ❓ Unknown object: $($m.Id)" -ForegroundColor DarkGray
                }
            }
        }
    }
}
