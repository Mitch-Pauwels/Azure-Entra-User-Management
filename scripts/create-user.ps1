# Create a Microsoft Entra ID user using Microsoft Graph PowerShell SDK (v2+)

# Safe module imports
Import-Module Microsoft.Graph.Users -ErrorAction SilentlyContinue

# Prerequisite: Connect-MgGraph with appropriate scopes before running this script
# Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All"

New-MgUser -BodyParameter @{
    accountEnabled = $true
    displayName = "Emily Carter"
    mailNickname = "emily.carter"
    userPrincipalName = "emily.carter@domainjoined.xyz"
    passwordProfile = @{
        forceChangePasswordNextSignIn = $true
        password = "P@ssw0rd123!"
    }
}
