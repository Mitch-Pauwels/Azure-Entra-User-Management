# Create a Microsoft Entra ID security group using Microsoft Graph PowerShell SDK (v2+)

# Prerequisite:
# Connect-MgGraph -Scopes "Group.ReadWrite.All", "Directory.ReadWrite.All"

$groupParams = @{
    DisplayName     = "Marketing Team"
    MailEnabled     = $false
    MailNickname    = "marketingteam"
    SecurityEnabled = $true
    GroupTypes      = @()
}

$group = New-MgGroup @groupParams
