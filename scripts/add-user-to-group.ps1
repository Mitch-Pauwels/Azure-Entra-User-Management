# Add a user to a Microsoft Entra ID group using Microsoft Graph PowerShell SDK (v2+)

# Safe module imports
Import-Module Microsoft.Graph.Users -ErrorAction SilentlyContinue
Import-Module Microsoft.Graph.Groups -ErrorAction SilentlyContinue
Import-Module Microsoft.Graph.DirectoryObjects -ErrorAction SilentlyContinue

# Prerequisite: Connect-MgGraph with appropriate scopes before running this script
# Connect-MgGraph -Scopes "User.Read.All", "Group.ReadWrite.All", "Directory.ReadWrite.All"

# Fetch group by display name
$group = Get-MgGroup -Filter "displayName eq 'Marketing Team'"

# Fetch user ID by UPN
$userId = (Get-MgUser -Filter "userPrincipalName eq 'emily.carter@domainjoined.xyz'").Id

# Add user to group using REST-style reference
New-MgGroupMemberByRef -GroupId $group.Id -BodyParameter @{
  "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$userId"
}
