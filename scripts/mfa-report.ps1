Connect-MgGraph -Scopes "Policy.Read.All", "User.Read.All"
$users = Get-MgUser -All
foreach ($user in $users) {
    $mfaState = (Get-MgUserAuthenticationMethod -UserId $user.Id | Where-Object {$_.AdditionalProperties.methods -match "MicrosoftAuthenticator"})
    [PSCustomObject]@{
        DisplayName = $user.DisplayName
        UserPrincipalName = $user.UserPrincipalName
        MFAEnabled = if ($mfaState) { "Yes" } else { "No" }
    }
}
