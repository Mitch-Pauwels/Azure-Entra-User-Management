Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All"
$userUpn = "emily.carter@domainjoined.xyz"
$sku = Get-MgSubscribedSku | Where-Object {$_.SkuPartNumber -eq "DEVELOPERPACK_E5"}
Set-MgUserLicense -UserId $userUpn -AddLicenses @{SkuId = $sku.SkuId} -RemoveLicenses @()
