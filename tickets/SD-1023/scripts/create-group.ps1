# Create a Microsoft Entra ID security group using Microsoft Graph PowerShell SDK (v2+)

# Safe module import
Import-Module Microsoft.Graph.Groups -ErrorAction SilentlyContinue

# Prerequisite: Connect-MgGraph with appropriate scopes before running this script
# Connect-MgGraph -Scopes "Group.ReadWrite.All", "Directory.ReadWrite.All"

$groupParams = @{
    DisplayName     = "Marketing Team"
    MailEnabled     = $false
    MailNickname    = "marketingteam"
    SecurityEnabled = $true
    GroupTypes      = @()
}

$group = New-MgGroup @groupParams
