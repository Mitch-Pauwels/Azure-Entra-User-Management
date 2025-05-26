Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All"
$users = Import-Csv "offboarding-users.csv"
foreach ($user in $users) {
    Write-Host "Disabling: $($user.UserPrincipalName)"
    Update-MgUser -UserId $user.UserPrincipalName -AccountEnabled $false
}
