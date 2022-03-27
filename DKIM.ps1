Clear-Host
Write-Host "Well Hi there, So you want to setup some DKIM. This file has been created in order to help you create the required DNS records for your domain."
Pause
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
$domain = [Microsoft.VisualBasic.Interaction]::InputBox("Domain that you want to setup DKIM", "Domain that you want to setup DKIM")
$maindomain = [Microsoft.VisualBasic.Interaction]::InputBox("Please enter the orginal .onmicrosoft.com domain", "Please enter the orginal .onmicrosoft.com domain")
$domainKey = $domain -replace '\W','-'
Write-Host "



Host name:                     selector1._domainkey
Points to address or value:    selector1-$domainKey._domainkey.$maindomain
TTL:                           3600

Host name:                     selector2._domainkey
Points to address or value:    selector2-$domainKey._domainkey.$maindomain
TTL:                           3600

Now you need to take the above and create CNAME records for the above values. If these domains are in 365 then you will be able to do the next step immedatly.
Once the CNAMES are setup then you will be able to start the next file: DKIM2.ps1
The next file needs to be run from a EXOPS session. cd to the dir and run the file. 


If you would also like to setup DMARC add the following TXT record to your DNS zone:
Host name:                     _dmarc
Points to address or value:    v=DMARC1; p=quarantine; rua=mailto:support@$domain; ruf=mailto:support@$domain; fo=1
TTL:                           3600

"
Pause