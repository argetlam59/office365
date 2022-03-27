[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
$domain = [Microsoft.VisualBasic.Interaction]::InputBox("Domain that you want to setup DKIM", "Domain that you want to setup DKIM")

New-DkimSigningConfig -DomainName $domain -Enabled $true