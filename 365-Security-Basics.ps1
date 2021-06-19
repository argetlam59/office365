<# 
This Script is ment for the inital deployment of a new 365 teneancy. 
It will go through all the inital setup steps that need to be done to configure the tenancy properly. 

TODO

Commands to remember: 
Connect-EXOPSSession

Changelog: 

1.3.1 - Release - 19/06/2021
    Added Requires flags to the front of the script. 
    Added Execution policy Toggle at the end
    Quick Tidy
    Security Defaults isn't going to be able to work in this current state. v2 will be DSC I think, or Azure App.
1.3 - Release - 19/05/2021
    Added pause after enableing customisation
    This line is added as a test for versioning. 
1.2 - Release - 19/11/2020
    Added DKIM support.
    Removed iassist useless branding. 
1.1 - Release - 18/11/2020
    Added admin elevation.
1.0 - Release 
    Script is approved for use by Jason. 
    Added exchange install
    Added Partner setup
#>
#List of Requirments

#Requires -Module @{ ModuleName = 'ExchangeOnlineManagement'; ModuleVersion = '2.0.5' }
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
    if ($elevated) {
        # tried to elevate, did not work, aborting
    } else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    }
    exit
}

#Variables for General Public
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
$partnerLink = [Microsoft.VisualBasic.Interaction]::InputBox("Partner Link for adding to MPN", "Partner Link for adding to MPN")
$alertEmail = [Microsoft.VisualBasic.Interaction]::InputBox("Email for recieving alerts", "Email for recieving alerts")

$msg = 'Do you need to install exchange powershell?'
do {
    choice /c yn /m $msg
    $response = $LASTEXITCODE
    if ($response -eq 1) {
        Install-Module -Name ExchangeOnlineManagement
        Update-Module -Name ExchangeOnlineManagement
    }
        $response = 2
} until ($response -eq 2)
Clear-Host
$msg = 'Do you need to add the tenancy into our partner portal? 

PLEASE NOTE: If you say yes it will open a incogito window for CHROME. 
If you are signed into another tenancy it will add it to the wrong instance.

'
do {
    choice /c yn /m $msg
    $response = $LASTEXITCODE
    if ($response -eq 1) {
        Start-Process "chrome" -ArgumentList "-incognito --new-window $partnerLink" 
    }
        $response = 2
} until ($response -eq 2)


Pause
Connect-ExchangeOnline -Credential
Write-Host "Did you just get a bunch of red Errors? That likely means you need to install exchange powershell again. Close this window and restart as admin."
Pause
Enable-OrganizationCustomization
#pause here as there seems to be bug if you try and do anything straight after enabling customisation? 
Write-Host "Please wait on this screen for 20 seconds."
Pause
Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true

$msg = 'Do you want to use Enable Bulk mail filtering?'
do {
    choice /c yn /m $msg
    $response = $LASTEXITCODE
    if ($response -eq 1) {
        New-TransportRule -Name "Bulk email filtering - RegEx" -SubjectOrBodyMatchesPatterns "If you are unable to view the content of this email\, please", "\>(safe )?unsubscribe( here)?\</a\>", "If you do not wish to receive further communications like this\, please", "\<img height\=", "To stop receiving these+emails\:http\://", "To unsubscribe from \w+ (e\-?letter|e?-?mail|newsletter)", "no longer (wish )?(to )?(be sent|receive) w+ email", "If you are unable to view the content of this email\, please click here", "To ensure you receive (your daily deals|our e-?mails)\, add", "If you no longer wish to receive these emails", "to change your (subscription preferences|preferences or unsubscribe)", "click (here to|the) unsubscribe" -SetSCL 6
        New-TransportRule -Name "Bulk email filtering - Words" -SubjectOrBodyContainsWords "to change your preferences or unsubscribe","Modify email preferences or unsubscribe","This is a promotional email","You are receiving this email because you requested a subscription","click here to unsubscribe","You have received this email because you are subscribed","If you no longer wish to receive our email newsletter","to unsubscribe from this newsletter","If you have trouble viewing this email","This is an advertisement","you would like to unsubscribe or change your","view this email as a webpage","You are receiving this email because you are subscribed" -SetSCL 9
    }
        $response = 2
} until ($response -eq 2)

$msg = 'Do you want to use the fuck off bitcoin rule?'
do {
    choice /c yn /m $msg
    $response = $LASTEXITCODE
    if ($response -eq 1) {
        New-TransportRule -Name bitcoin -Enabled $true -SetSCL 9 -SubjectOrBodyContainsWords bitcoin, bitc0in, b1tcoin      }
        $response = 2
} until ($response -eq 2)

$msg = 'Do you want to use the  Malware filter'
do {
    choice /c yn /m $msg
    $response = $LASTEXITCODE
    if ($response -eq 1) {
        Set-MalwareFilterPolicy -Identity "Default" -Action DeleteMessage -EnableInternalSenderAdminNotifications $true -InternalSenderAdminAddress $alertEmail -EnableFileFilter $true     }
        $response = 2
} until ($response -eq 2)

$msg = 'Do you want to use the  SPAM filter'
do {
    choice /c yn /m $msg
    $response = $LASTEXITCODE
    if ($response -eq 1) {
        Set-HostedContentFilterPolicy -Identity "Default" -HighConfidenceSpamAction MoveToJmf -BulkThreshold 6 -QuarantineRetentionPeriod 30 -EnableEndUserSpamNotifications 3 }
        $response = 2
} until ($response -eq 2)

$msg = 'Do you want to use the  outbound SPAM filter'
do {
    choice /c yn /m $msg
    $response = $LASTEXITCODE
    if ($response -eq 1) {
        Set-HostedOutboundSpamFilterPolicy -Identity Default -RecipientLimitExternalPerHour 500 -RecipientLimitInternalPerHour 500 -RecipientLimitPerDay 1000 -ActionWhenThresholdReached BlockUser -AutoForwardingMode Off -NotifyOutboundSpam $true -NotifyOutboundSpamRecipients $alertEmail
        $response = 2
    }
} until ($response -eq 2)

$msg = 'Do you want to use the  Phish filter'
do {
    choice /c yn /m $msg
    $response = $LASTEXITCODE
    if ($response -eq 1) {
        New-AntiPhishPolicy -Name "Phishy1" -Enabled $true -AuthenticationFailAction Quarantine -EnableSpoofIntelligence $true -EnableUnauthenticatedSender $true
        $response = 2
    }
} until ($response -eq 2)

$msg = 'Do you want to use Enable DKIM?'
do {
    choice /c yn /m $msg
    $response = $LASTEXITCODE
    if ($response -eq 1) {
        Clear-Host
        Write-Host "
        This file has been created in order to help you create the required DNS records for your domain.
        There will be two dialog boxes open up asking you to enter the domain info.

        In the second, it is imporant that you include the '.onmicrosoft.com' section. 
        If DNS managment isn't with 365 yet; then propergation may take 1-24 hours. 
        "
        Pause
        [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
        $domain = [Microsoft.VisualBasic.Interaction]::InputBox("Domain that you want to setup DKIM", "Domain that you want to setup DKIM")
        $maindomain = [Microsoft.VisualBasic.Interaction]::InputBox("Please enter the orginal .onmicrosoft.com domain", "Please enter the orginal .onmicrosoft.com domain")
        $stupiddomain = $domain -replace '\W','-'
        Write-Host "
        
        
        
        Host name:            selector1._domainkey
        Points to address or value:    selector1-$stupiddomain._domainkey.$maindomain
        TTL:                3600
        
        Host name:            selector2._domainkey
        Points to address or value:    selector2-$stupiddomain._domainkey.$maindomain
        TTL:                3600
        "
        Write-Host "
        Now you need to take the above and create CNAME records for the above values. 
        If these domains are in 365 then you will be able to do the next step immedatly.
        If not then you will need to run 'dkim.ps1' "
        #whitespace
        Write-Host "       
        "
        Pause
            $msg = 'Have you added the DKIM records?'
            do {
                choice /c yn /m $msg
                $response = $LASTEXITCODE
                if ($response -eq 1) {
                    New-DkimSigningConfig -DomainName $domain -Enabled $true
                $response = 2
            }
        } until ($response -eq 2)
        $response = 2
    }
} until ($response -eq 2)

Connect-IPPSSession
Write-Host "Creating Protection alerts"
New-ProtectionAlert -Name "MailRedirect created" -Category Mailflow -ThreatType Activity -Operation MailRedirect -Severity Medium -NotifyUser $alertEmail  -AggregationType None  -Description "Email forward created"
New-ProtectionAlert -Name "User Restricted from sending email" -Category Mailflow -ThreatType Activity -Operation CompromisedAccount -Severity Medium -NotifyUser $alertEmail  -AggregationType None  -Description "Email forward created"
Pause
#Set Execution Policy Clear
do {
    choice /c yn /m "Do you want to change your Execution Policy to restricted again?"
    $response = $LASTEXITCODE
    if ($response -eq 1) {
        Set-ExecutionPolicy Restricted -Force
    $response = 2
}
} until ($response -eq 2)

Disconnect-ExchangeOnline
Write-Host "Finished!"
Pause