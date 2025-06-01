<#
.SYNOPSIS
    Assigns Azure AD users to security groups using Microsoft Graph API
    
.DESCRIPTION
    This script allows you to assign users to Azure AD security groups interactively.
    You can select users from a CSV file or enter them manually, choose from available groups,
    and assign users to the selected group.
    
.PARAMETER CSVPath
    Optional path to CSV file containing user information (UserPrincipalName column required)
    
.PARAMETER UserPrincipalName
    Single user principal name to assign to a group
    
.PARAMETER GroupDisplayName
    Optional group display name to pre-select (if not provided, interactive selection will be shown)
    
.PARAMETER WhatIf
    Shows what assignments would be made without actually making them
    
.EXAMPLE
    .\Assign-UsersToGroup.ps1
    Interactive mode - select users and groups from lists
    
.EXAMPLE
    .\Assign-UsersToGroup.ps1 -CSVPath "C:\Users\users.csv"
    Load users from CSV and select group interactively
    
.EXAMPLE
    .\Assign-UsersToGroup.ps1 -UserPrincipalName "john.doe@company.com"
    Assign specific user to an interactively selected group
    
.EXAMPLE
    .\Assign-UsersToGroup.ps1 -CSVPath "C:\Users\users.csv" -GroupDisplayName "Marketing Team" -WhatIf
    Show what would happen when assigning CSV users to Marketing Team group
    
.NOTES
    CSV Requirements (if using CSV input):
    - UserPrincipalName: Required column containing user email addresses
    - Other columns are ignored
    
    Prerequisites:
    - PowerShell 5.1 or later
    - Administrator privileges (for module installation if needed)
    - Appropriate permissions in Azure AD (Group.ReadWrite.All, User.Read.All, Directory.Read.All)
    - Internet connection (for module installation if needed)
    
    The script will automatically check for and install required modules if missing.
    Only security groups are shown for selection (not distribution lists or Microsoft 365 groups).
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $false)]
    [ValidateScript({
        if ($_ -and !(Test-Path $_)) {
            throw "CSV file not found: $_"
        }
        return $true
    })]
    [string]$CSVPath,
    
    [Parameter(Mandatory = $false)]
    [ValidatePattern('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')]
    [string]$UserPrincipalName,
    
    [Parameter(Mandatory = $false)]
    [string]$GroupDisplayName
)

# Required PowerShell modules for the script
$RequiredModules = @(
    'Microsoft.Graph.Authentication',
    'Microsoft.Graph.Users',
    'Microsoft.Graph.Groups'
)

function Test-Prerequisites {
    Write-ColoredOutput "Checking prerequisites..." "Yellow"
    
    # Check PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -lt 5) {
        Write-ColoredOutput "ERROR: PowerShell 5.1 or later is required. Current version: $($psVersion)" "Red"
        return $false
    }
    Write-ColoredOutput "PowerShell version check passed: $($psVersion)" "Green"
    
    # Check and install required modules
    $modulesInstalled = $true
    
    foreach ($moduleName in $RequiredModules) {
        Write-ColoredOutput "Checking module: $moduleName" "White"
        
        $module = Get-Module -ListAvailable -Name $moduleName
        if (-not $module) {
            Write-ColoredOutput "Module '$moduleName' not found. Attempting to install..." "Yellow"
            
            try {
                # Check if running as administrator for installation
                $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
                $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
                
                if ($isAdmin) {
                    Install-Module -Name $moduleName -Force -AllowClobber -Scope AllUsers
                    Write-ColoredOutput "Successfully installed module '$moduleName' for all users." "Green"
                } else {
                    Install-Module -Name $moduleName -Force -AllowClobber -Scope CurrentUser
                    Write-ColoredOutput "Successfully installed module '$moduleName' for current user." "Green"
                }
            }
            catch {
                Write-ColoredOutput "ERROR: Failed to install module '$moduleName': $($_.Exception.Message)" "Red"
                Write-ColoredOutput "Please try running PowerShell as Administrator or install manually using:" "Yellow"
                Write-ColoredOutput "Install-Module -Name $moduleName -Force" "Yellow"
                $modulesInstalled = $false
            }
        } else {
            Write-ColoredOutput "Module '$moduleName' is already installed. Version: $($module.Version -join ', ')" "Green"
        }
    }
    
    if (-not $modulesInstalled) {
        Write-ColoredOutput "Some required modules could not be installed. Please install them manually and re-run the script." "Red"
        return $false
    }
    
    # Import modules
    foreach ($moduleName in $RequiredModules) {
        try {
            Import-Module -Name $moduleName -Force
            Write-ColoredOutput "Successfully imported module: $moduleName" "Green"
        }
        catch {
            Write-ColoredOutput "ERROR: Failed to import module '$moduleName': $($_.Exception.Message)" "Red"
            return $false
        }
    }
    
    Write-ColoredOutput "All prerequisites met!" "Green"
    return $true
}

function Write-ColoredOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Test-GraphConnection {
    try {
        $context = Get-MgContext
        if ($null -eq $context) {
            Write-ColoredOutput "Not connected to Microsoft Graph. Attempting to connect..." "Yellow"
            Connect-MgGraph -Scopes "Group.ReadWrite.All", "User.Read.All", "Directory.Read.All"
            Write-ColoredOutput "Successfully connected to Microsoft Graph." "Green"
        } else {
            Write-ColoredOutput "Already connected to Microsoft Graph as: $($context.Account)" "Green"
        }
        return $true
    }
    catch {
        Write-ColoredOutput "Failed to connect to Microsoft Graph: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Get-UsersFromInput {
    $users = @()
    
    if ($CSVPath) {
        Write-ColoredOutput "Loading users from CSV file: $CSVPath" "Yellow"
        try {
            $csvData = Import-Csv -Path $CSVPath
            
            # Check if UserPrincipalName column exists
            $csvColumns = $csvData[0].PSObject.Properties.Name
            if ('UserPrincipalName' -notin $csvColumns) {
                Write-ColoredOutput "ERROR: CSV file must contain 'UserPrincipalName' column" "Red"
                return $null
            }
            
            foreach ($row in $csvData) {
                if (![string]::IsNullOrWhiteSpace($row.UserPrincipalName)) {
                    $users += $row.UserPrincipalName.Trim()
                }
            }
            Write-ColoredOutput "Found $($users.Count) users in CSV file." "Green"
        }
        catch {
            Write-ColoredOutput "ERROR: Failed to import CSV file: $($_.Exception.Message)" "Red"
            return $null
        }
    }
    elseif ($UserPrincipalName) {
        $users += $UserPrincipalName
        Write-ColoredOutput "Using provided user: $UserPrincipalName" "Green"
    }
    else {
        # Interactive user selection
        Write-ColoredOutput "No users specified. Enter user principal names (email addresses):" "Yellow"
        Write-ColoredOutput "Enter one email per line. Press Enter on empty line to finish." "White"
        
        do {
            $userInput = Read-Host "User email"
            if (![string]::IsNullOrWhiteSpace($userInput)) {
                $userInput = $userInput.Trim()
                if ($userInput -match '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$') {
                    $users += $userInput
                    Write-ColoredOutput "Added: $userInput" "Green"
                } else {
                    Write-ColoredOutput "Invalid email format: $userInput" "Red"
                }
            }
        } while (![string]::IsNullOrWhiteSpace($userInput))
        
        if ($users.Count -eq 0) {
            Write-ColoredOutput "No valid users entered." "Yellow"
            return $null
        }
    }
    
    return $users
}

function Get-ValidUsers {
    param([string[]]$UserPrincipalNames)
    
    Write-ColoredOutput "Validating users in Azure AD..." "Yellow"
    $validUsers = @()
    $invalidUsers = @()
    
    foreach ($upn in $UserPrincipalNames) {
        try {
            $user = Get-MgUser -UserId $upn -ErrorAction Stop
            $validUsers += @{
                Id = $user.Id
                DisplayName = $user.DisplayName
                UserPrincipalName = $user.UserPrincipalName
            }
            Write-ColoredOutput "✓ Found: $($user.DisplayName) ($($user.UserPrincipalName))" "Green"
        }
        catch {
            $invalidUsers += $upn
            Write-ColoredOutput "✗ Not found: $upn" "Red"
        }
    }
    
    if ($invalidUsers.Count -gt 0) {
        Write-ColoredOutput "WARNING: $($invalidUsers.Count) user(s) not found in Azure AD:" "Yellow"
        foreach ($invalidUser in $invalidUsers) {
            Write-ColoredOutput "  - $invalidUser" "Yellow"
        }
    }
    
    if ($validUsers.Count -eq 0) {
        Write-ColoredOutput "ERROR: No valid users found in Azure AD." "Red"
        return $null
    }
    
    Write-ColoredOutput "Found $($validUsers.Count) valid user(s) in Azure AD." "Green"
    return $validUsers
}

function Get-SecurityGroups {
    Write-ColoredOutput "Retrieving security groups from Azure AD..." "Yellow"
    
    try {
        # Get all groups first, then filter to security groups only
        # This avoids complex OData filter syntax issues
        $allGroups = Get-MgGroup -All
        
        # Filter to security groups only (exclude Microsoft 365 groups and distribution lists)
        $groups = $allGroups | Where-Object { 
            $_.SecurityEnabled -eq $true -and 
            ($_.GroupTypes -eq $null -or $_.GroupTypes.Count -eq 0 -or 'Unified' -notin $_.GroupTypes)
        } | Sort-Object DisplayName
        
        if ($groups.Count -eq 0) {
            Write-ColoredOutput "No security groups found in Azure AD." "Yellow"
            return $null
        }
        
        Write-ColoredOutput "Found $($groups.Count) security group(s)." "Green"
        return $groups
    }
    catch {
        Write-ColoredOutput "ERROR: Failed to retrieve groups: $($_.Exception.Message)" "Red"
        return $null
    }
}

function Select-SecurityGroup {
    param([object[]]$Groups)
    
    if ($GroupDisplayName) {
        $selectedGroup = $Groups | Where-Object { $_.DisplayName -eq $GroupDisplayName }
        if ($selectedGroup) {
            Write-ColoredOutput "Using pre-selected group: $($selectedGroup.DisplayName)" "Green"
            return $selectedGroup
        } else {
            Write-ColoredOutput "WARNING: Group '$GroupDisplayName' not found. Showing available groups..." "Yellow"
        }
    }
    
    # Interactive group selection
    Write-ColoredOutput "`nAvailable Security Groups:" "Cyan"
    Write-ColoredOutput "=========================" "Cyan"
    
    for ($i = 0; $i -lt $Groups.Count; $i++) {
        $group = $Groups[$i]
        Write-ColoredOutput "$($i + 1). $($group.DisplayName)" "White"
        if (![string]::IsNullOrWhiteSpace($group.Description)) {
            Write-ColoredOutput "   Description: $($group.Description)" "Gray"
        }
    }
    
    do {
        $selection = Read-Host "`nSelect group number (1-$($Groups.Count))"
        if ($selection -match '^\d+$') {
            $index = [int]$selection - 1
            if ($index -ge 0 -and $index -lt $Groups.Count) {
                $selectedGroup = $Groups[$index]
                Write-ColoredOutput "Selected: $($selectedGroup.DisplayName)" "Green"
                return $selectedGroup
            }
        }
        Write-ColoredOutput "Invalid selection. Please enter a number between 1 and $($Groups.Count)." "Red"
    } while ($true)
}

function Test-GroupMembership {
    param(
        [string]$GroupId,
        [string]$UserId
    )
    
    try {
        $member = Get-MgGroupMember -GroupId $GroupId -Filter "id eq '$UserId'" -ErrorAction SilentlyContinue
        return $null -ne $member
    }
    catch {
        return $false
    }
}

function Add-UserToGroup {
    param(
        [object]$User,
        [object]$Group
    )
    
    try {
        # Check if user is already a member
        if (Test-GroupMembership -GroupId $Group.Id -UserId $User.Id) {
            Write-ColoredOutput "INFO: User '$($User.DisplayName)' is already a member of '$($Group.DisplayName)'" "Cyan"
            return $true
        }
        
        if ($PSCmdlet.ShouldProcess("User: $($User.DisplayName) -> Group: $($Group.DisplayName)", "Add to Group")) {
            $memberReference = @{
                "@odata.id" = "https://graph.microsoft.com/v1.0/users/$($User.Id)"
            }
            
            New-MgGroupMember -GroupId $Group.Id -BodyParameter $memberReference
            Write-ColoredOutput "SUCCESS: Added '$($User.DisplayName)' to '$($Group.DisplayName)'" "Green"
            return $true
        } else {
            Write-ColoredOutput "WHATIF: Would add '$($User.DisplayName)' to '$($Group.DisplayName)'" "Cyan"
            return $true
        }
    }
    catch {
        Write-ColoredOutput "ERROR: Failed to add '$($User.DisplayName)' to '$($Group.DisplayName)': $($_.Exception.Message)" "Red"
        return $false
    }
}

# Main script execution
Write-ColoredOutput "=== Azure AD Group Assignment Script ===" "Cyan"

# Check prerequisites first
if (-not (Test-Prerequisites)) {
    Write-ColoredOutput "Prerequisites check failed. Exiting." "Red"
    exit 1
}

# Test Graph connection
if (-not (Test-GraphConnection)) {
    exit 1
}

# Get users from input
$userPrincipalNames = Get-UsersFromInput
if (-not $userPrincipalNames) {
    Write-ColoredOutput "No users to process. Exiting." "Yellow"
    exit 0
}

# Validate users exist in Azure AD
$validUsers = Get-ValidUsers -UserPrincipalNames $userPrincipalNames
if (-not $validUsers) {
    exit 1
}

# Get available security groups
$securityGroups = Get-SecurityGroups
if (-not $securityGroups) {
    exit 1
}

# Select target group
$selectedGroup = Select-SecurityGroup -Groups $securityGroups
if (-not $selectedGroup) {
    Write-ColoredOutput "No group selected. Exiting." "Yellow"
    exit 0
}

# Confirm operation
Write-ColoredOutput "`n=== Assignment Summary ===" "Cyan"
Write-ColoredOutput "Target Group: $($selectedGroup.DisplayName)" "White"
Write-ColoredOutput "Users to assign:" "White"
foreach ($user in $validUsers) {
    Write-ColoredOutput "  - $($user.DisplayName) ($($user.UserPrincipalName))" "White"
}

if (-not $WhatIfPreference) {
    $confirm = Read-Host "`nProceed with group assignment? (y/N)"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        Write-ColoredOutput "Operation cancelled by user." "Yellow"
        exit 0
    }
}

# Perform group assignments
Write-ColoredOutput "`nAssigning users to group..." "Yellow"
$successCount = 0
$skipCount = 0
$failureCount = 0

foreach ($user in $validUsers) {
    $result = Add-UserToGroup -User $user -Group $selectedGroup
    if ($result) {
        if (Test-GroupMembership -GroupId $selectedGroup.Id -UserId $user.Id) {
            $skipCount++  # User was already a member
        } else {
            $successCount++
        }
    } else {
        $failureCount++
    }
}

# Summary
Write-ColoredOutput "`n=== Assignment Results ===" "Cyan"
if ($WhatIfPreference) {
    Write-ColoredOutput "WHATIF MODE: $($validUsers.Count) user(s) would be processed for group assignment." "Cyan"
} else {
    Write-ColoredOutput "Successfully assigned: $successCount user(s)" "Green"
    if ($skipCount -gt 0) {
        Write-ColoredOutput "Already members: $skipCount user(s)" "Cyan"
    }
    if ($failureCount -gt 0) {
        Write-ColoredOutput "Failed assignments: $failureCount user(s)" "Red"
    }
}

Write-ColoredOutput "Group assignment completed." "Cyan"