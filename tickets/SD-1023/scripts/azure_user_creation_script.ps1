<#
.SYNOPSIS
    Creates Azure AD users from a CSV file using Microsoft Graph API
    
.DESCRIPTION
    This script reads user information from a CSV file and creates users in Azure AD using Microsoft Graph PowerShell SDK.
    It validates required properties and handles optional properties gracefully.
    
.PARAMETER CSVPath
    Path to the CSV file containing user information
    
.PARAMETER WhatIf
    Shows what users would be created without actually creating them
    
.EXAMPLE
    .\Create-AzureADUsersFromCSV.ps1 -CSVPath "C:\Users\users.csv"
    
.EXAMPLE
    .\Create-AzureADUsersFromCSV.ps1 -CSVPath "C:\Users\users.csv" -WhatIf
    
.NOTES
    Required CSV Columns (case-sensitive):
    - DisplayName: The display name for the user
    - UserPrincipalName: The UPN (email format) for the user
    - MailNickname: The mail alias for the user
    - Password: The initial password for the user (optional - will be auto-generated if not provided)
    - AccountEnabled: True/False to enable/disable the account
    
    Optional CSV Columns:
    - GivenName: First name
    - Surname: Last name  
    - JobTitle: User's job title
    - Department: User's department
    - OfficeLocation: Office location
    - EmployeeId: Employee ID
    - UsageLocation: Two-letter country code (e.g., "US", "GB")
    - StreetAddress: Street address
    - City: City
    - State: State/Province
    - PostalCode: Postal/ZIP code
    - Country: Country
    - PhoneNumber: Business phone number
    - MobilePhone: Mobile phone number
    - ForceChangePasswordNextSignIn: True/False (default: True)
    - EmployeeHireDate: Employee start date in YYYY-MM-DD format (e.g., "2024-01-15")
    - Manager: Manager's UserPrincipalName/email (e.g., "manager@company.com")
    
    Prerequisites:
    - PowerShell 5.1 or later
    - Administrator privileges (for module installation if needed)
    - Appropriate permissions in Azure AD (User.ReadWrite.All or Directory.ReadWrite.All)
    - Internet connection (for module installation if needed)
    
    Note: The script will automatically check for and install required modules if missing.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({Test-Path $_})]
    [string]$CSVPath
)

# Required PowerShell modules for the script
$RequiredModules = @(
    'Microsoft.Graph.Authentication',
    'Microsoft.Graph.Users'
)

# Required properties for user creation based on Microsoft Graph API documentation
$RequiredProperties = @(
    'DisplayName',
    'UserPrincipalName', 
    'MailNickname',
    'AccountEnabled'
)

# Optional properties that can be included in user creation
$OptionalProperties = @(
    'GivenName',
    'Surname',
    'JobTitle', 
    'Department',
    'OfficeLocation',
    'EmployeeId',
    'UsageLocation',
    'StreetAddress',
    'City',
    'State',
    'PostalCode', 
    'Country',
    'PhoneNumber',
    'MobilePhone',
    'ForceChangePasswordNextSignIn',
    'Password',
    'EmployeeHireDate',
    'Manager'
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

function New-RandomPassword {
    param(
        [int]$Length = 12,
        [bool]$IncludeSymbols = $true
    )
    
    # Define character sets
    $lowercase = 'abcdefghijklmnopqrstuvwxyz'
    $uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    $numbers = '0123456789'
    $symbols = '!@#$%^&*()_+-=[]{}|;:,.<>?'
    
    # Ensure password meets complexity requirements (at least one from each set)
    $password = ""
    $allChars = $lowercase + $uppercase + $numbers
    
    if ($IncludeSymbols) {
        $allChars += $symbols
    }
    
    # Guarantee at least one character from each required set
    $password += Get-Random -InputObject $lowercase.ToCharArray()
    $password += Get-Random -InputObject $uppercase.ToCharArray()
    $password += Get-Random -InputObject $numbers.ToCharArray()
    
    if ($IncludeSymbols) {
        $password += Get-Random -InputObject $symbols.ToCharArray()
        $remainingLength = $Length - 4
    } else {
        $remainingLength = $Length - 3
    }
    
    # Fill the rest with random characters
    for ($i = 0; $i -lt $remainingLength; $i++) {
        $password += Get-Random -InputObject $allChars.ToCharArray()
    }
    
    # Shuffle the password to avoid predictable patterns
    $passwordArray = $password.ToCharArray()
    for ($i = $passwordArray.Length - 1; $i -gt 0; $i--) {
        $j = Get-Random -Maximum ($i + 1)
        $temp = $passwordArray[$i]
        $passwordArray[$i] = $passwordArray[$j]
        $passwordArray[$j] = $temp
    }
    
    return -join $passwordArray
}

function Get-UserIdByUPN {
    param([string]$UserPrincipalName)
    
    if ([string]::IsNullOrWhiteSpace($UserPrincipalName)) {
        return $null
    }
    
    try {
        $user = Get-MgUser -UserId $UserPrincipalName -ErrorAction SilentlyContinue
        if ($user) {
            return $user.Id
        }
        else {
            Write-ColoredOutput "Warning: Manager not found with UPN: $UserPrincipalName" "Yellow"
            return $null
        }
    }
    catch {
        Write-ColoredOutput "Warning: Error looking up manager $UserPrincipalName : $($_.Exception.Message)" "Yellow"
        return $null
    }
}

function Test-GraphConnection {
    try {
        $context = Get-MgContext
        if ($null -eq $context) {
            Write-ColoredOutput "Not connected to Microsoft Graph. Attempting to connect..." "Yellow"
            Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All"
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

function Test-CSVStructure {
    param([object[]]$CSVData)
    
    $csvColumns = $CSVData[0].PSObject.Properties.Name
    $missingColumns = @()
    
    # Check for required columns
    foreach ($requiredProp in $RequiredProperties) {
        if ($requiredProp -notin $csvColumns) {
            $missingColumns += $requiredProp
        }
    }
    
    if ($missingColumns.Count -gt 0) {
        Write-ColoredOutput "ERROR: CSV file is missing required columns: $($missingColumns -join ', ')" "Red"
        Write-ColoredOutput "Required columns are: $($RequiredProperties -join ', ')" "Yellow"
        return $false
    }
    
    Write-ColoredOutput "CSV structure validation passed." "Green"
    return $true
}

function Test-UserProperties {
    param(
        [PSCustomObject]$User,
        [int]$RowNumber
    )
    
    $missingRequiredProps = @()
    $validationErrors = @()
    
    # Check required properties
    foreach ($prop in $RequiredProperties) {
        $value = $User.$prop
        if ([string]::IsNullOrWhiteSpace($value)) {
            $missingRequiredProps += $prop
        }
    }
    
    if ($missingRequiredProps.Count -gt 0) {
        $validationErrors += "Row $RowNumber - Missing required properties: $($missingRequiredProps -join ', ')"
    }
    
    # Validate specific formats if values are present
    if (![string]::IsNullOrWhiteSpace($User.UserPrincipalName)) {
        if ($User.UserPrincipalName -notmatch '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$') {
            $validationErrors += "Row $RowNumber - Invalid UserPrincipalName format: $($User.UserPrincipalName)"
        }
    }
    
    if (![string]::IsNullOrWhiteSpace($User.AccountEnabled)) {
        if ($User.AccountEnabled -notin @('True', 'False', 'true', 'false', '1', '0')) {
            $validationErrors += "Row $RowNumber - AccountEnabled must be True or False: $($User.AccountEnabled)"
        }
    }
    
    if (![string]::IsNullOrWhiteSpace($User.UsageLocation)) {
        if ($User.UsageLocation.Length -ne 2) {
            $validationErrors += "Row $RowNumber - UsageLocation must be a 2-character country code: $($User.UsageLocation)"
        }
    }
    
    # Validate EmployeeHireDate format if provided
    if (![string]::IsNullOrWhiteSpace($User.EmployeeHireDate)) {
        try {
            $null = [DateTime]::ParseExact($User.EmployeeHireDate, 'yyyy-MM-dd', $null)
        }
        catch {
            $validationErrors += "Row $RowNumber - EmployeeHireDate must be in YYYY-MM-DD format: $($User.EmployeeHireDate)"
        }
    }
    
    return $validationErrors
}

function ConvertTo-GraphUserObject {
    param([PSCustomObject]$CSVUser)
    
    # Generate password if not provided
    $userPassword = if (![string]::IsNullOrWhiteSpace($CSVUser.Password)) {
        $CSVUser.Password
    } else {
        $generatedPassword = New-RandomPassword -Length 14 -IncludeSymbols $true
        Write-ColoredOutput "Generated password for $($CSVUser.DisplayName): $generatedPassword" "Yellow"
        $generatedPassword
    }
    
    # Create the user object with required properties
    $userObject = @{
        DisplayName = $CSVUser.DisplayName.Trim()
        UserPrincipalName = $CSVUser.UserPrincipalName.Trim()
        MailNickname = $CSVUser.MailNickname.Trim()
        AccountEnabled = [bool]::Parse($CSVUser.AccountEnabled)
        PasswordProfile = @{
            Password = $userPassword
            ForceChangePasswordNextSignIn = if (![string]::IsNullOrWhiteSpace($CSVUser.ForceChangePasswordNextSignIn)) { 
                [bool]::Parse($CSVUser.ForceChangePasswordNextSignIn) 
            } else { 
                $true 
            }
        }
    }
    
    # Add optional properties if they exist and are not empty
    foreach ($prop in $OptionalProperties) {
        if ($prop -in @('ForceChangePasswordNextSignIn', 'Password', 'Manager')) { continue } # Manager handled separately
        
        $value = $CSVUser.$prop
        if (![string]::IsNullOrWhiteSpace($value)) {
            switch ($prop) {
                'PhoneNumber' { $userObject['BusinessPhones'] = @($value.Trim()) }
                'EmployeeId' { $userObject['EmployeeId'] = $value.Trim() }
                'EmployeeHireDate' { 
                    try {
                        $hireDate = [DateTime]::ParseExact($value.Trim(), 'yyyy-MM-dd', $null)
                        $userObject['EmployeeHireDate'] = $hireDate.ToString('yyyy-MM-ddT00:00:00Z')
                    }
                    catch {
                        Write-ColoredOutput "Warning: Invalid EmployeeHireDate format for $($CSVUser.DisplayName): $value" "Yellow"
                    }
                }
                default { $userObject[$prop] = $value.Trim() }
            }
        }
    }
    
    return $userObject
}

function New-GraphUser {
    param(
        [PSCustomObject]$CSVUser,
        [int]$RowNumber
    )
    
    try {
        $userObject = ConvertTo-GraphUserObject -CSVUser $CSVUser
        
        if ($PSCmdlet.ShouldProcess("User: $($userObject.DisplayName) ($($userObject.UserPrincipalName))", "Create Azure AD User")) {
            # Create the user first
            $newUser = New-MgUser -BodyParameter $userObject
            Write-ColoredOutput "SUCCESS: Created user '$($newUser.DisplayName)' with ID: $($newUser.Id)" "Green"
            
            # Set manager if specified
            if (![string]::IsNullOrWhiteSpace($CSVUser.Manager)) {
                $managerId = Get-UserIdByUPN -UserPrincipalName $CSVUser.Manager.Trim()
                if ($managerId) {
                    try {
                        $managerReference = @{
                            "@odata.id" = "https://graph.microsoft.com/v1.0/users/$managerId"
                        }
                        Set-MgUserManagerByRef -UserId $newUser.Id -BodyParameter $managerReference
                        Write-ColoredOutput "SUCCESS: Set manager for '$($newUser.DisplayName)' to '$($CSVUser.Manager)'" "Green"
                    }
                    catch {
                        Write-ColoredOutput "WARNING: Failed to set manager for '$($newUser.DisplayName)': $($_.Exception.Message)" "Yellow"
                    }
                } else {
                    Write-ColoredOutput "WARNING: Could not find manager '$($CSVUser.Manager)' for user '$($newUser.DisplayName)'" "Yellow"
                }
            }
            
            return $true
        } else {
            $managerText = if (![string]::IsNullOrWhiteSpace($CSVUser.Manager)) { ", Manager: $($CSVUser.Manager)" } else { "" }
            Write-ColoredOutput "WHATIF: Would create user - DisplayName: '$($userObject.DisplayName)', UPN: '$($userObject.UserPrincipalName)'$managerText" "Cyan"
            return $true
        }
    }
    catch {
        Write-ColoredOutput "ERROR: Failed to create user from row $RowNumber - $($_.Exception.Message)" "Red"
        return $false
    }
}

# Main script execution
Write-ColoredOutput "=== Azure AD User Creation Script ===" "Cyan"
Write-ColoredOutput "CSV File: $CSVPath" "White"

# Check prerequisites first
if (-not (Test-Prerequisites)) {
    Write-ColoredOutput "Prerequisites check failed. Exiting." "Red"
    exit 1
}

# Test Graph connection
if (-not (Test-GraphConnection)) {
    exit 1
}

# Import and validate CSV
try {
    Write-ColoredOutput "Importing CSV file..." "Yellow"
    $csvData = Import-Csv -Path $CSVPath
    Write-ColoredOutput "Found $($csvData.Count) user(s) in CSV file." "Green"
}
catch {
    Write-ColoredOutput "ERROR: Failed to import CSV file: $($_.Exception.Message)" "Red"
    exit 1
}

# Validate CSV structure
if (-not (Test-CSVStructure -CSVData $csvData)) {
    exit 1
}

# Validate each user's data
Write-ColoredOutput "Validating user data..." "Yellow"
$allValidationErrors = @()
$validUsers = @()

for ($i = 0; $i -lt $csvData.Count; $i++) {
    $user = $csvData[$i]
    $rowNumber = $i + 2  # +2 because CSV row 1 is headers, and we want 1-based indexing
    
    $validationErrors = Test-UserProperties -User $user -RowNumber $rowNumber
    
    if ($validationErrors.Count -eq 0) {
        $validUsers += @{ User = $user; RowNumber = $rowNumber }
    } else {
        $allValidationErrors += $validationErrors
    }
}

# Report validation results
if ($allValidationErrors.Count -gt 0) {
    Write-ColoredOutput "Validation errors found:" "Red"
    foreach ($error in $allValidationErrors) {
        Write-ColoredOutput "  $error" "Red"
    }
}

if ($validUsers.Count -eq 0) {
    Write-ColoredOutput "No valid users found to create. Exiting." "Red"
    exit 1
}

Write-ColoredOutput "Validation complete. $($validUsers.Count) user(s) are valid for creation." "Green"

if ($allValidationErrors.Count -gt 0) {
    $response = Read-Host "Some users have validation errors. Continue with valid users only? (y/N)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-ColoredOutput "Operation cancelled by user." "Yellow"
        exit 0
    }
}

# Create users
Write-ColoredOutput "Creating users..." "Yellow"
$successCount = 0
$failureCount = 0

foreach ($validUser in $validUsers) {
    if (New-GraphUser -CSVUser $validUser.User -RowNumber $validUser.RowNumber) {
        $successCount++
    } else {
        $failureCount++
    }
}

# Summary
Write-ColoredOutput "=== Summary ===" "Cyan"
if ($WhatIfPreference) {
    Write-ColoredOutput "WHATIF MODE: $($validUsers.Count) user(s) would be created." "Cyan"
} else {
    Write-ColoredOutput "Successfully created: $successCount user(s)" "Green"
    if ($failureCount -gt 0) {
        Write-ColoredOutput "Failed to create: $failureCount user(s)" "Red"
    }
}

if ($allValidationErrors.Count -gt 0) {
    Write-ColoredOutput "Users with validation errors: $($allValidationErrors.Count)" "Yellow"
}

Write-ColoredOutput "Script execution completed." "Cyan"