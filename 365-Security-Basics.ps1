<# 
This Script is ment for the inital deployment of a new 365 teneancy. 
It will go through all the inital setup steps that need to be done to configure the tenancy properly. 

To configure: 
Find and replace
%adminemail% - admin email that you want email notifcaitons to go to. 
%partnerURL% - Microsoft partner link for new tennents. 
%businessname% - Name of IT company.



TODO
DKIM
Commands to remember: 
Connect-EXOPSSession

Changelog: 

1.0 - Release 
    Added exchange install
    Added Partner setup
#>


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
cls
$msg = 'Do you need to add the tenancy into our partner portal? 

PLEASE NOTE: If you say yes it will open a incogito window for chrome. 
If you are signed into another tenancy it will add it to the wrong instance.

'
do {
    choice /c yn /m $msg
    $response = $LASTEXITCODE
    if ($response -eq 1) {
        Start-Process "chrome" -ArgumentList '-incognito --new-window %partnerURL% 
    }
        $response = 2
} until ($response -eq 2)


Pause
Connect-ExchangeOnline
Write-Host "Did you just get a bunch of red Errors? That likely means you need to install exchange powershell again. Close this window and restart as admin."
Pause
Enable-OrganizationCustomization
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

$msg = 'Do you want to use the %businessname% Malware filter'
do {
    choice /c yn /m $msg
    $response = $LASTEXITCODE
    if ($response -eq 1) {
        Set-MalwareFilterPolicy -Identity "Default" -Action DeleteMessage -EnableInternalSenderAdminNotifications $true -InternalSenderAdminAddress %adminemail% -EnableFileFilter $true     }
        $response = 2
} until ($response -eq 2)

$msg = 'Do you want to use the %businessname% SPAM filter'
do {
    choice /c yn /m $msg
    $response = $LASTEXITCODE
    if ($response -eq 1) {
        Set-HostedContentFilterPolicy -Identity "Default" -HighConfidenceSpamAction MoveToJmf -BulkThreshold 6 -QuarantineRetentionPeriod 30 -EnableEndUserSpamNotifications 3 }
        $response = 2
} until ($response -eq 2)

$msg = 'Do you want to use the %businessname% outbound SPAM filter'
do {
    choice /c yn /m $msg
    $response = $LASTEXITCODE
    if ($response -eq 1) {
        Set-HostedOutboundSpamFilterPolicy -Identity Default -RecipientLimitExternalPerHour 500 -RecipientLimitInternalPerHour 500 -RecipientLimitPerDay 1000 -ActionWhenThresholdReached BlockUser -AutoForwardingMode Off -NotifyOutboundSpam $true -NotifyOutboundSpamRecipients %adminemail%
        $response = 2
    }
} until ($response -eq 2)

$msg = 'Do you want to use the %businessname% Phish filter'
do {
    choice /c yn /m $msg
    $response = $LASTEXITCODE
    if ($response -eq 1) {
        New-AntiPhishPolicy -Name "%businessname% Phishy1" -Enabled $true -AuthenticationFailAction Quarantine -EnableAntispoofEnforcement $true -EnableUnauthenticatedSender $true
        $response = 2
    }
} until ($response -eq 2)

Connect-IPPSSession
Write-Host "Creating Protection alerts"
New-ProtectionAlert -Name "MailRedirect created" -Category Mailflow -ThreatType Activity -Operation MailRedirect -Severity Medium -NotifyUser %adminemail%  -AggregationType None  -Description "Email forward created"
New-ProtectionAlert -Name "User Restricted from sending email" -Category Mailflow -ThreatType Activity -Operation CompromisedAccount -Severity Medium -NotifyUser %adminemail%  -AggregationType None  -Description "Email forward created"
Pause
Disconnect-ExchangeOnline