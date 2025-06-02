<#
.SYNOPSIS
    Assigns a directory role to a user scoped to a Security Group in Microsoft Entra ID.

.DESCRIPTION
    This script:
    - Prompts for a user UPN
    - Displays a list of groups for selection
    - Assigns the Password Administrator role scoped to the selected group
    - Requires Microsoft Graph PowerShell SDK

.NOTES
    Group-scoped role assignment may not be fully supported via PowerShell in all tenants.
    Requires appropriate permissions and administrative unit configuration.
#>

# Ensure Graph modules are available
$requiredModules = @(
    "Microsoft.Graph.Authentication",
    "Microsoft.Graph.Identity.DirectoryManagement", 
    "Microsoft.Graph.Users",
    "Microsoft.Graph.Groups"
)

foreach ($module in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Host "Installing required module '$module'..." -ForegroundColor Yellow
        Install-Module -Name $module -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module $module -Force
}

# Connect with required scopes
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
Connect-MgGraph -Scopes @(
    "RoleManagement.ReadWrite.Directory",
    "Directory.ReadWrite.All", 
    "User.Read.All",
    "Group.Read.All",
    "AdministrativeUnit.ReadWrite.All"
) -NoWelcome

# Verify connection
$context = Get-MgContext
if (-not $context) {
    Write-Error "Failed to connect to Microsoft Graph"
    exit 1
}

Write-Host "Connected to tenant: $($context.TenantId)" -ForegroundColor Green

# Prompt for user UPN
$assigneeUPN = Read-Host "Enter the UPN of the user to assign the role to"
$roleName = "Password Administrator"

# Get the user
try {
    Write-Host "Looking up user..." -ForegroundColor Cyan
    $user = Get-MgUser -UserId $assigneeUPN -ErrorAction Stop
    Write-Host "Found user: $($user.DisplayName)" -ForegroundColor Green
} catch {
    Write-Error "Could not find user '$assigneeUPN': $($_.Exception.Message)"
    exit 1
}

# List groups for selection (limit to security groups)
Write-Host "Retrieving groups..." -ForegroundColor Cyan
try {
    $groups = Get-MgGroup -Filter "securityEnabled eq true" -Select "DisplayName,Id" -All
    if (-not $groups -or $groups.Count -eq 0) {
        Write-Error "No security groups found in the tenant."
        exit 1
    }
} catch {
    Write-Error "Failed to retrieve groups: $($_.Exception.Message)"
    exit 1
}

Write-Host "`nAvailable Security Groups:" -ForegroundColor Cyan
$groups | ForEach-Object -Begin { $i = 1 } -Process {
    Write-Host "$i. $($_.DisplayName) (ID: $($_.Id))"
    $i++
}

do {
    $selection = Read-Host "`nEnter the number of the group to scope the role to (1-$($groups.Count))"
    $index = [int]$selection - 1
} while ($index -lt 0 -or $index -ge $groups.Count)

$selectedGroup = $groups[$index]
Write-Host "Selected group: $($selectedGroup.DisplayName)" -ForegroundColor Green

# Get role definition using the correct approach
Write-Host "Getting role definition..." -ForegroundColor Cyan
try {
    # Get the role definition from unified role definitions (newer approach)
    $roleDefinition = Get-MgRoleManagementDirectoryRoleDefinition -Filter "displayName eq '$roleName'"
    
    if (-not $roleDefinition) {
        Write-Error "Role definition '$roleName' not found."
        exit 1
    }
    
    Write-Host "Found role: $($roleDefinition.DisplayName) (ID: $($roleDefinition.Id))" -ForegroundColor Green
} catch {
    Write-Error "Failed to get role definition: $($_.Exception.Message)"
    exit 1
}

# For group-scoped assignments, we need to use Administrative Units
Write-Host "Creating scoped role assignment using Administrative Unit..." -ForegroundColor Cyan

# Administrative Unit approach
try {
    # Create or find administrative unit
    $auName = $selectedGroup.DisplayName
    $existingAU = Get-MgDirectoryAdministrativeUnit -Filter "displayName eq '$auName'" -ErrorAction SilentlyContinue
    
    if (-not $existingAU) {
        Write-Host "Creating Administrative Unit: $auName" -ForegroundColor Cyan
        $auParams = @{
            DisplayName = $auName
            Description = "Administrative Unit for $($selectedGroup.DisplayName)"
        }
        $au = New-MgDirectoryAdministrativeUnit -BodyParameter $auParams
    } else {
        $au = $existingAU
        Write-Host "Using existing Administrative Unit: $auName" -ForegroundColor Green
    }
    
    # Add the group to the AU
    Write-Host "Adding group to Administrative Unit..." -ForegroundColor Cyan
    $auMemberParams = @{
        "@odata.id" = "https://graph.microsoft.com/v1.0/groups/$($selectedGroup.Id)"
    }
    
    try {
        New-MgDirectoryAdministrativeUnitMemberByRef -AdministrativeUnitId $au.Id -BodyParameter $auMemberParams
        Write-Host "Group added to Administrative Unit" -ForegroundColor Green
    } catch {
        if ($_.Exception.Message -like "*conflicting object*" -or $_.Exception.Message -like "*already exists*") {
            Write-Host "Group already exists in Administrative Unit" -ForegroundColor Yellow
        } else {
            throw
        }
    }
    
    # Assign role scoped to the AU
    Write-Host "Assigning role scoped to Administrative Unit..." -ForegroundColor Cyan
    $auAssignmentParams = @{
        "@odata.type" = "#microsoft.graph.unifiedRoleAssignment"
        PrincipalId = $user.Id
        RoleDefinitionId = $roleDefinition.Id
        DirectoryScopeId = "/administrativeUnits/$($au.Id)"
    }
    
    $result = New-MgRoleManagementDirectoryRoleAssignment -BodyParameter $auAssignmentParams
    
    if ($result -and $result.Id) {
        Write-Host "✅ SUCCESS: Assigned '$roleName' to '$assigneeUPN' scoped to Administrative Unit containing group '$($selectedGroup.DisplayName)'" -ForegroundColor Green
        Write-Host "Assignment ID: $($result.Id)" -ForegroundColor Gray
        Write-Host "Administrative Unit: $auName" -ForegroundColor Gray
    } else {
        Write-Warning "Role assignment returned no result. Please verify manually in Entra portal."
    }
    
} catch {
    Write-Error "❌ FAILED: Could not assign '$roleName' to '$assigneeUPN': $($_.Exception.Message)"
    Write-Host "`nTroubleshooting tips:" -ForegroundColor Yellow
    Write-Host "1. Ensure you have sufficient permissions (Global Administrator or Privileged Role Administrator)" -ForegroundColor Yellow
    Write-Host "2. Verify that scoped role assignments are supported in your tenant" -ForegroundColor Yellow  
    Write-Host "3. Check that the target group is a security group" -ForegroundColor Yellow
    Write-Host "4. Consider using the Entra portal for complex scoped assignments" -ForegroundColor Yellow
    exit 1
}

Write-Host "`nScript completed. Disconnecting from Microsoft Graph..." -ForegroundColor Cyan
Disconnect-MgGraph