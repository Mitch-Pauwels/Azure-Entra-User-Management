# Azure AD User Update Script
# Updates JobTitle, Department, and Office Location for a specified user

# Check if Microsoft.Graph module is installed
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Host "Microsoft.Graph module is not installed. Installing..." -ForegroundColor Yellow
    Install-Module -Name Microsoft.Graph -Scope CurrentUser -Force
}

# Import required modules
Import-Module Microsoft.Graph.Users

try {
    # Connect to Microsoft Graph
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Green
    Connect-MgGraph -Scopes "User.ReadWrite.All"
    
    # Prompt for User Principal Name
    $UserPrincipalName = Read-Host "Enter the User Principal Name (UPN) of the user to update"
    
    # Validate that UPN was provided
    if ([string]::IsNullOrWhiteSpace($UserPrincipalName)) {
        Write-Host "Error: User Principal Name cannot be empty." -ForegroundColor Red
        exit 1
    }
    
    # Check if user exists and get current properties
    Write-Host "Checking if user exists..." -ForegroundColor Yellow
    try {
        $User = Get-MgUser -UserId $UserPrincipalName -Property "DisplayName,JobTitle,Department,OfficeLocation" -ErrorAction Stop
        Write-Host "User found: $($User.DisplayName)" -ForegroundColor Green
    }
    catch {
        Write-Host "Error: User with UPN '$UserPrincipalName' not found." -ForegroundColor Red
        exit 1
    }
    
    # Define the new values
    $JobTitle = "Senior Cloud Engineer"
    $Department = "IT"
    $OfficeLocation = "Swansea Office"
    
    # Display current values
    Write-Host "`nCurrent user details:" -ForegroundColor Cyan
    Write-Host "Display Name: $($User.DisplayName)"
    Write-Host "Current Job Title: $($User.JobTitle)"
    Write-Host "Current Department: $($User.Department)"
    Write-Host "Current Office Location: $($User.OfficeLocation)"
    
    # Display new values
    Write-Host "`nNew values to be set:" -ForegroundColor Cyan
    Write-Host "Job Title: $JobTitle"
    Write-Host "Department: $Department"
    Write-Host "Office Location: $OfficeLocation"
    
    # Confirm before updating
    $Confirmation = Read-Host "`nDo you want to proceed with the update? (Y/N)"
    if ($Confirmation -ne 'Y' -and $Confirmation -ne 'y') {
        Write-Host "Update cancelled by user." -ForegroundColor Yellow
        exit 0
    }
    
    # Update user properties using individual calls for better reliability
    Write-Host "`nUpdating user properties..." -ForegroundColor Green
    
    try {
        # Update JobTitle
        Update-MgUser -UserId $UserPrincipalName -JobTitle $JobTitle
        Write-Host "✓ Job Title updated" -ForegroundColor Green
        
        # Update Department
        Update-MgUser -UserId $UserPrincipalName -Department $Department
        Write-Host "✓ Department updated" -ForegroundColor Green
        
        # Update Office Location
        Update-MgUser -UserId $UserPrincipalName -OfficeLocation $OfficeLocation
        Write-Host "✓ Office Location updated" -ForegroundColor Green
        
        Write-Host "`nAll user properties updated successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "Error updating user properties: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
    
    # Verify the update
    Write-Host "`nVerifying updates..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2  # Brief pause to allow for replication
    $UpdatedUser = Get-MgUser -UserId $UserPrincipalName -Property "DisplayName,JobTitle,Department,OfficeLocation"
    
    Write-Host "`nUpdated user details:" -ForegroundColor Cyan
    Write-Host "Display Name: $($UpdatedUser.DisplayName)"
    Write-Host "Job Title: $($UpdatedUser.JobTitle)"
    Write-Host "Department: $($UpdatedUser.Department)"
    Write-Host "Office Location: $($UpdatedUser.OfficeLocation)"
    
}
catch {
    Write-Host "An error occurred: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
finally {
    # Disconnect from Microsoft Graph
    Write-Host "`nDisconnecting from Microsoft Graph..." -ForegroundColor Yellow
    Disconnect-MgGraph
    Write-Host "Script completed." -ForegroundColor Green
}