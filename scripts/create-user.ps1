# Create a new Microsoft Entra ID user using Microsoft Graph PowerShell SDK

# Prerequisite: Connect using Connect-MgGraph before running this script
# Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All"

$body = @{
    accountEnabled = $true
    displayName = "Emily Carter"
    mailNickname = "emily.carter"
    userPrincipalName = "emily.carter@domainjoined.xyz"
    passwordProfile = @{
        forceChangePasswordNextSignIn = $true
        password = "P@ssw0rd123!"
    }
}

New-MgUser -BodyParameter $body
