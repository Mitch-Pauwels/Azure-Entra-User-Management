<#
.SYNOPSIS
    Assigns Azure AD licenses to users using Microsoft Graph API
    
.DESCRIPTION
    This script allows you to assign licenses to Azure AD users interactively.
    You can select users from a CSV file or enter them manually, choose from available licenses,
    and assign licenses to the selected users.
    
.PARAMETER CSVPath
    Optional path to CSV file containing user information (UserPrincipalName column required)
    
.PARAMETER UserPrincipalName
    Single user principal name to assign a license to
    
.PARAMETER LicenseName
    Optional license display name to pre-select (if not provided, interactive selection will be shown)
    
.PARAMETER WhatIf
    Shows what license assignments would be made without actually making them
    
.EXAMPLE
    .\Assign-LicensesToUsers.ps1
    Interactive mode - select users and licenses from lists
    
.EXAMPLE
    .\Assign-LicensesToUsers.ps1 -CSVPath "C:\Users\users.csv"
    Load users from CSV and select license interactively
    
.EXAMPLE
    .\Assign-LicensesToUsers.ps1 -UserPrincipalName "john.doe@company.com"
    Assign license to specific user with interactive license selection
    
.EXAMPLE
    .\Assign-LicensesToUsers.ps1 -CSVPath "C:\Users\users.csv" -LicenseName "Microsoft 365 Business Premium" -WhatIf
    Show what would happen when assigning specified license to CSV users
    
.NOTES
    CSV Requirements (if using CSV input):
    - UserPrincipalName: Required column containing user email addresses
    - Other columns are ignored
    
    Prerequisites:
    - PowerShell 5.1 or later
    - Administrator privileges (for module installation if needed)
    - Appropriate permissions in Azure AD (User.ReadWrite.All, Organization.Read.All, Directory.Read.All)
    - Internet connection (for module installation if needed)
    
    The script will automatically check for and install required modules if missing.
    Only licenses with available units are shown for selection.
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
    [string]$LicenseName
)

# Required PowerShell modules for the script
$RequiredModules = @(
    'Microsoft.Graph.Authentication',
    'Microsoft.Graph.Users',
    'Microsoft.Graph.Identity.DirectoryManagement'
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
            Connect-MgGraph -Scopes "User.ReadWrite.All", "Organization.Read.All", "Directory.Read.All"
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
            $user = Get-MgUser -UserId $upn -Property "Id,DisplayName,UserPrincipalName,AssignedLicenses,UsageLocation" -ErrorAction Stop
            $validUsers += @{
                Id = $user.Id
                DisplayName = $user.DisplayName
                UserPrincipalName = $user.UserPrincipalName
                AssignedLicenses = $user.AssignedLicenses
                UsageLocation = $user.UsageLocation
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

function Get-AvailableLicenses {
    Write-ColoredOutput "Retrieving available licenses from Azure AD..." "Yellow"
    
    try {
        $subscribedSkus = Get-MgSubscribedSku -Property "Id,SkuId,SkuPartNumber,ConsumedUnits,PrepaidUnits"
        
        if ($subscribedSkus.Count -eq 0) {
            Write-ColoredOutput "No licenses found in Azure AD." "Yellow"
            return $null
        }
        
        # Filter licenses that have available units
        $availableLicenses = @()
        foreach ($sku in $subscribedSkus) {
            $availableUnits = $sku.PrepaidUnits.Enabled - $sku.ConsumedUnits
            if ($availableUnits -gt 0) {
                # Convert SKU part number to friendly name
                $friendlyName = Get-LicenseFriendlyName -SkuPartNumber $sku.SkuPartNumber
                
                $availableLicenses += @{
                    SkuId = $sku.SkuId
                    SkuPartNumber = $sku.SkuPartNumber
                    FriendlyName = $friendlyName
                    ConsumedUnits = $sku.ConsumedUnits
                    AvailableUnits = $availableUnits
                    TotalUnits = $sku.PrepaidUnits.Enabled
                }
            }
        }
        
        if ($availableLicenses.Count -eq 0) {
            Write-ColoredOutput "No licenses with available units found." "Yellow"
            return $null
        }
        
        # Sort by friendly name
        $availableLicenses = $availableLicenses | Sort-Object FriendlyName
        
        Write-ColoredOutput "Found $($availableLicenses.Count) license(s) with available units." "Green"
        return $availableLicenses
    }
    catch {
        Write-ColoredOutput "ERROR: Failed to retrieve licenses: $($_.Exception.Message)" "Red"
        return $null
    }
}

function Get-LicenseFriendlyName {
    param([string]$SkuPartNumber)
    
    # Common license SKU mappings to friendly names
    $licenseMap = @{
        'ENTERPRISEPACK' = 'Microsoft 365 E3'
        'ENTERPRISEPREMIUM' = 'Microsoft 365 E5'
        'ENTERPRISEPACK_B_PILOT' = 'Microsoft 365 E3 (Pilot)'
        'ENTERPRISEPREMIUM_NOPSTNCONF' = 'Microsoft 365 E5 (without Audio Conferencing)'
        'SPB_BUSINESS_PREMIUM' = 'Microsoft 365 Business Premium'
        'SPB_BUSINESS_STANDARD' = 'Microsoft 365 Business Standard'
        'SPB_BUSINESS_BASIC' = 'Microsoft 365 Business Basic'
        'O365_BUSINESS_ESSENTIALS' = 'Microsoft 365 Business Basic'
        'O365_BUSINESS_PREMIUM' = 'Microsoft 365 Business Premium'
        'SMB_BUSINESS' = 'Microsoft 365 Apps for business'
        'OFFICESUBSCRIPTION' = 'Microsoft 365 Apps for enterprise'
        'EXCHANGESTANDARD' = 'Exchange Online (Plan 1)'
        'EXCHANGEENTERPRISE' = 'Exchange Online (Plan 2)'
        'SHAREPOINTSTANDARD' = 'SharePoint Online (Plan 1)'
        'SHAREPOINTENTERPRISE' = 'SharePoint Online (Plan 2)'
        'MCOSTANDARD' = 'Skype for Business Online (Plan 2)'
        'POWER_BI_STANDARD' = 'Power BI (free)'
        'POWER_BI_PRO' = 'Power BI Pro'
        'PROJECTCLIENT' = 'Project Online Desktop Client'
        'PROJECTESSENTIALS' = 'Project Online Essentials'
        'PROJECTPREMIUM' = 'Project Online Premium'
        'PROJECTPROFESSIONAL' = 'Project Online Professional'
        'VISIOCLIENT' = 'Visio Online Plan 2'
        'AAD_PREMIUM' = 'Azure Active Directory Premium P1'
        'AAD_PREMIUM_P2' = 'Azure Active Directory Premium P2'
        'RIGHTSMANAGEMENT' = 'Azure Information Protection Plan 1'
        'MCOMEETADV' = 'Microsoft 365 Audio Conferencing'
        'PHONESYSTEM_VIRTUALUSER' = 'Microsoft 365 Phone System - Virtual User'
        'MCOEV' = 'Microsoft 365 Phone System'
        'WIN10_PRO_ENT_SUB' = 'Windows 10 Enterprise E3'
        'WIN10_VDA_E5' = 'Windows 10 Enterprise E5'
        'WINDOWS_STORE' = 'Windows Store for Business'
        'FLOW_FREE' = 'Microsoft Power Automate Free'
        'FLOW_P1' = 'Microsoft Power Automate Plan 1'
        'FLOW_P2' = 'Microsoft Power Automate Plan 2'
        'POWERAPPS_VIRAL' = 'Microsoft Power Apps Plan 1'
        'POWERAPPS_INDIVIDUAL_USER' = 'Microsoft Power Apps Plan 2'
        'TEAMS_EXPLORATORY' = 'Microsoft Teams Exploratory'
        'MCOPSTN1' = 'Microsoft 365 Domestic Calling Plan'
        'MCOPSTN2' = 'Microsoft 365 International Calling Plan'
        'MCOPSTN5' = 'Microsoft 365 Domestic Calling Plan (120 Minutes)'
        'MCOPSTNC' = 'Microsoft 365 Communications Credits'
        'STREAM' = 'Microsoft Stream Plan 2'
        'THREAT_INTELLIGENCE' = 'Microsoft Defender for Office 365 (Plan 2)'
        'ATP_ENTERPRISE' = 'Microsoft Defender for Office 365 (Plan 1)'
        'EMS' = 'Enterprise Mobility + Security E3'
        'EMSPREMIUM' = 'Enterprise Mobility + Security E5'
        'INTUNE_A' = 'Microsoft Intune Plan 1'
        'M365_F1' = 'Microsoft 365 F1'
        'SPE_F1' = 'Microsoft 365 F3'
    }
    
    if ($licenseMap.ContainsKey($SkuPartNumber)) {
        return $licenseMap[$SkuPartNumber]
    } else {
        return $SkuPartNumber
    }
}

function Select-License {
    param([object[]]$Licenses)
    
    if ($LicenseName) {
        $selectedLicense = $Licenses | Where-Object { $_.FriendlyName -eq $LicenseName -or $_.SkuPartNumber -eq $LicenseName }
        if ($selectedLicense) {
            Write-ColoredOutput "Using pre-selected license: $($selectedLicense.FriendlyName)" "Green"
            return $selectedLicense
        } else {
            Write-ColoredOutput "WARNING: License '$LicenseName' not found or no available units. Showing available licenses..." "Yellow"
        }
    }
    
    # Interactive license selection
    Write-ColoredOutput "`nAvailable Licenses:" "Cyan"
    Write-ColoredOutput "==================" "Cyan"
    
    for ($i = 0; $i -lt $Licenses.Count; $i++) {
        $license = $Licenses[$i]
        Write-ColoredOutput "$($i + 1). $($license.FriendlyName)" "White"
        Write-ColoredOutput "   SKU: $($license.SkuPartNumber)" "Gray"
        Write-ColoredOutput "   Available: $($license.AvailableUnits) / $($license.TotalUnits) units" "Gray"
        Write-ColoredOutput "" "White"
    }
    
    do {
        $selection = Read-Host "Select license number (1-$($Licenses.Count))"
        if ($selection -match '^\d+$') {
            $index = [int]$selection - 1
            if ($index -ge 0 -and $index -lt $Licenses.Count) {
                $selectedLicense = $Licenses[$index]
                Write-ColoredOutput "Selected: $($selectedLicense.FriendlyName)" "Green"
                return $selectedLicense
            }
        }
        Write-ColoredOutput "Invalid selection. Please enter a number between 1 and $($Licenses.Count)." "Red"
    } while ($true)
}

function Test-UserHasLicense {
    param(
        [object]$User,
        [string]$SkuId
    )
    
    if ($User.AssignedLicenses) {
        foreach ($assignedLicense in $User.AssignedLicenses) {
            if ($assignedLicense.SkuId -eq $SkuId) {
                return $true
            }
        }
    }
    return $false
}

function Test-UsageLocation {
    param([object]$User)
    
    if ([string]::IsNullOrWhiteSpace($User.UsageLocation)) {
        Write-ColoredOutput "WARNING: User '$($User.DisplayName)' does not have a usage location set." "Yellow"
        Write-ColoredOutput "A usage location is required for license assignment." "Yellow"
        
        do {
            $location = Read-Host "Enter two-letter country code for usage location (e.g., US, GB, DE) or 'skip' to skip this user"
            if ($location.ToLower() -eq 'skip') {
                return $false
            }
            if ($location -match '^[A-Za-z]{2}$') {
                try {
                    Update-MgUser -UserId $User.Id -UsageLocation $location.ToUpper()
                    Write-ColoredOutput "Updated usage location for '$($User.DisplayName)' to '$($location.ToUpper())'" "Green"
                    return $true
                }
                catch {
                    Write-ColoredOutput "ERROR: Failed to update usage location: $($_.Exception.Message)" "Red"
                    return $false
                }
            } else {
                Write-ColoredOutput "Invalid country code. Please enter a two-letter code (e.g., US, GB, DE)." "Red"
            }
        } while ($true)
    }
    return $true
}

function Add-LicenseToUser {
    param(
        [object]$User,
        [object]$License
    )
    
    try {
        # Check if user already has this license
        if (Test-UserHasLicense -User $User -SkuId $License.SkuId) {
            Write-ColoredOutput "INFO: User '$($User.DisplayName)' already has license '$($License.FriendlyName)'" "Cyan"
            return $true
        }
        
        # Check usage location
        if (-not (Test-UsageLocation -User $User)) {
            Write-ColoredOutput "SKIPPED: User '$($User.DisplayName)' - usage location not set or update failed" "Yellow"
            return $false
        }
        
        if ($PSCmdlet.ShouldProcess("User: $($User.DisplayName) -> License: $($License.FriendlyName)", "Assign License")) {
            $licenseToAssign = @{
                AddLicenses = @(
                    @{
                        SkuId = $License.SkuId
                        DisabledPlans = @()
                    }
                )
                RemoveLicenses = @()
            }
            
            Set-MgUserLicense -UserId $User.Id -BodyParameter $licenseToAssign
            Write-ColoredOutput "SUCCESS: Assigned '$($License.FriendlyName)' to '$($User.DisplayName)'" "Green"
            return $true
        } else {
            Write-ColoredOutput "WHATIF: Would assign '$($License.FriendlyName)' to '$($User.DisplayName)'" "Cyan"
            return $true
        }
    }
    catch {
        Write-ColoredOutput "ERROR: Failed to assign '$($License.FriendlyName)' to '$($User.DisplayName)': $($_.Exception.Message)" "Red"
        return $false
    }
}

# Main script execution
Write-ColoredOutput "=== Azure AD License Assignment Script ===" "Cyan"

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

# Get available licenses
$availableLicenses = Get-AvailableLicenses
if (-not $availableLicenses) {
    exit 1
}

# Select target license
$selectedLicense = Select-License -Licenses $availableLicenses
if (-not $selectedLicense) {
    Write-ColoredOutput "No license selected. Exiting." "Yellow"
    exit 0
}

# Confirm operation
Write-ColoredOutput "`n=== License Assignment Summary ===" "Cyan"
Write-ColoredOutput "Target License: $($selectedLicense.FriendlyName)" "White"
Write-ColoredOutput "Available Units: $($selectedLicense.AvailableUnits)" "White"
Write-ColoredOutput "Users to assign:" "White"
foreach ($user in $validUsers) {
    $hasLicense = Test-UserHasLicense -User $user -SkuId $selectedLicense.SkuId
    $status = if ($hasLicense) { " (already has license)" } else { "" }
    Write-ColoredOutput "  - $($user.DisplayName) ($($user.UserPrincipalName))$status" "White"
}

if (-not $WhatIfPreference) {
    $confirm = Read-Host "`nProceed with license assignment? (y/N)"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        Write-ColoredOutput "Operation cancelled by user." "Yellow"
        exit 0
    }
}

# Perform license assignments
Write-ColoredOutput "`nAssigning licenses to users..." "Yellow"
$successCount = 0
$skipCount = 0
$failureCount = 0

foreach ($user in $validUsers) {
    $result = Add-LicenseToUser -User $user -License $selectedLicense
    if ($result) {
        if (Test-UserHasLicense -User $user -SkuId $selectedLicense.SkuId) {
            if ($WhatIfPreference) {
                $successCount++
            } else {
                # Check if user had license before (skip) or just got it (success)
                $hadLicenseBefore = $false
                foreach ($assignedLicense in $user.AssignedLicenses) {
                    if ($assignedLicense.SkuId -eq $selectedLicense.SkuId) {
                        $hadLicenseBefore = $true
                        break
                    }
                }
                if ($hadLicenseBefore) {
                    $skipCount++
                } else {
                    $successCount++
                }
            }
        } else {
            $successCount++
        }
    } else {
        $failureCount++
    }
}

# Summary
Write-ColoredOutput "`n=== License Assignment Results ===" "Cyan"
if ($WhatIfPreference) {
    Write-ColoredOutput "WHATIF MODE: $($validUsers.Count) user(s) would be processed for license assignment." "Cyan"
} else {
    Write-ColoredOutput "Successfully assigned: $successCount user(s)" "Green"
    if ($skipCount -gt 0) {
        Write-ColoredOutput "Already licensed: $skipCount user(s)" "Cyan"
    }
    if ($failureCount -gt 0) {
        Write-ColoredOutput "Failed assignments: $failureCount user(s)" "Red"
    }
}

Write-ColoredOutput "License assignment completed." "Cyan"