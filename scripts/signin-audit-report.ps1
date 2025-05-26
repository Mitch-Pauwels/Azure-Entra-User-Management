Connect-MgGraph -Scopes "AuditLog.Read.All"
Get-MgAuditLogSignIn -Top 20 | Select UserDisplayName, UserPrincipalName, CreatedDateTime, Status, IPAddress
