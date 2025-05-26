Connect-AzAccount
Set-AzADUserPassword -UserPrincipalName "john.doe@domainjoined.xyz" `
  -Password "N3wP@ssw0rd!" `
  -ForceChangePasswordNextLogin $true
