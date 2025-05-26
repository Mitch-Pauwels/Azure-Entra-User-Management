Connect-MgGraph -Scopes "Policy.Read.All", "Directory.Read.All"
Get-MgConditionalAccessPolicy | Select DisplayName, State, Conditions
