<#
Hands off 365 Security Script for Security Defaults. 
#>
#region Variables
$partnerLink = 'Your Partner Center Link'
$notifcationEmail = 'Email Address for Notifications' #this is the email address that will receive the notifications sent from 365
$businessName = 'Your Business Name'
#endregion

#region Azure App Secrets
$ApplicationId = 'APPID'
$ApplicationSecret = 'SmallSecret' | ConvertTo-SecureString -Force -AsPlainText
$RefreshToken = 'SuperLongrefreshToken'
#endregion

#region Dependencies
if (Get-InstalledModule -Name 'ExchangeOnlineManagement','AzureAD','MSOnline')
{
    Write-Host -ForegroundColor Green "The required Modules are already installed."
}
else 
{
    Write-Host -ForegroundColor Red "The required Modules are not installed. Installing Now."
    $modules = @(
    'ExchangeOnlineManagement'
    'AzureAD'
    'MSOnline'
    'PartnerCenter'
    'PSWriteHTML'
    )
foreach ($item in $modules) {
    Write-Host "Installing Module $item"
    Install-Module -Name $item -Scope CurrentUser
}
}
#endregion

#region Connections
Connect-ExchangeOnline
Connect-MsolService
Connect-IPPSSession
#endregion

#region Auto Variables
$CustomerTenant = Get-AcceptedDomain | Where-Object {$_.Name -like "*onmicrosoft*"} | Select-Object -ExpandProperty Domainname
$PrimaryDomain = Get-AcceptedDomain | Where-Object {$_.Default -eq $true} | Select-Object -ExpandProperty Domainname
#endregion

#region  Failsafe
if ($CustomerTenant -eq 'XXX.onmicrosoft.com') {
    Write-Error "XXX is not supported with this script"
    Disconnect-ExchangeOnline
    Pause
    Exit
} 
#endregion

#region Functions
function EnableSecureDefaults() {
    ########################## Script Settings  ############################
    $Baseuri = "https://graph.microsoft.com/beta"
    write-host "Generating token to log into Azure AD." -ForegroundColor Green
    $credential = New-Object System.Management.Automation.PSCredential($ApplicationId, $ApplicationSecret)
    $CustGraphToken = New-PartnerAccessToken -ApplicationId $ApplicationId -Credential $credential -RefreshToken $refreshToken -Scopes "https://graph.microsoft.com/.default" -ServicePrincipal -Tenant $CustomerTenant
    $Header = @{
        Authorization = "Bearer $($CustGraphToken.AccessToken)"
    }
    
    $SecureDefaultsState = (Invoke-RestMethod -Uri "$baseuri/policies/identitySecurityDefaultsEnforcementPolicy" -Headers $Header -Method get -ContentType "application/json")
    if ($SecureDefaultsState.IsEnabled -eq $true) {
        write-host "Secure Defaults is already enabled for $CustomerTenant. Taking no action."-ForegroundColor Green
    }
    else {
        write-host "Secure Defaults is disabled. Enabling for $CustomerTenant" -ForegroundColor Yellow
        $body = '{ "isEnabled": true }'
        (Invoke-RestMethod -Uri "$baseuri/policies/identitySecurityDefaultsEnforcementPolicy" -Headers $Header -Method patch -Body $body -ContentType "application/json")
    }
}
function CustomEnable {
    $a = Get-OrganizationConfig
    if ($a.IsDehydrated -like 'True') {
        try {
            Write-Host "Trying to enable customisation" -ForegroundColor Green
            Enable-OrganizationCustomization -ErrorAction Stop
        }
        catch {
            Write-Host -ForegroundColor Yellow "Error: $($_.Exception.Message)"
            choice /c yn /m "Do you want to try again?"
            $response = $LASTEXITCODE
            if ($response -eq 1) {
                Write-Host "Enabling Customisation" -ForegroundColor Green
                CustomEnable
            }
            ($response = 2)
        }
    Write-Host "No Action required"
    }
}
#endregion

#region Script
Write-Host "Opening new Browser windows to add client into partner." -ForegroundColor Green
Start-Process "chrome" -ArgumentList "-incognito --new-window $partnerLink" 
Start-Process "msedge" -ArgumentList "-inprivate --new-window $partnerLink" | Out-Null
Write-Host "Enabling Cusomisation" -ForegroundColor Green
CustomEnable
Write-Host "Starting Sleep 30 Seconds" -ForegroundColor Red
Start-Sleep -s 30
Write-Host "Enabling Unified Audit Log" -ForegroundColor Green
Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true
Write-Host "Creating Junk Filtering Rules" -ForegroundColor Green
New-TransportRule -Name "Bulk email filtering - RegEx" -SubjectOrBodyMatchesPatterns "If you are unable to view the content of this email\, please", "\>(safe )?unsubscribe( here)?\</a\>", "If you do not wish to receive further communications like this\, please", "\<img height\=", "To stop receiving these+emails\:http\://", "To unsubscribe from \w+ (e\-?letter|e?-?mail|newsletter)", "no longer (wish )?(to )?(be sent|receive) w+ email", "If you are unable to view the content of this email\, please click here", "To ensure you receive (your daily deals|our e-?mails)\, add", "If you no longer wish to receive these emails", "to change your (subscription preferences|preferences or unsubscribe)", "click (here to|the) unsubscribe" -SetSCL 6
New-TransportRule -Name "Bulk email filtering - Words" -SubjectOrBodyContainsWords "to change your preferences or unsubscribe","Modify email preferences or unsubscribe","This is a promotional email","You are receiving this email because you requested a subscription","click here to unsubscribe","You have received this email because you are subscribed","If you no longer wish to receive our email newsletter","to unsubscribe from this newsletter","If you have trouble viewing this email","This is an advertisement","you would like to unsubscribe or change your","view this email as a webpage","You are receiving this email because you are subscribed","If you would like to continue to receive communications","Update your preferences","You have received this email because you","If you no longer wish to receive these","Unsubscribe from this list","unsubscribe and stop receiving these emails" -SetSCL 9
New-TransportRule -Name bitcoin -Enabled $true -SetSCL 9 -SubjectOrBodyContainsWords bitcoin, bitc0in, b1tcoin
New-TransportRule -Name "Domain Spoofing Rule" -Enabled $true -FromScope NotInOrganization -SenderDomainIs $PrimaryDomain -SetSCL 7
New-TransportRule -Name "TLD Filter" -Enabled $true -FromScope NotInOrganization -SetSCL 8 -ExceptIfFromAddressMatchesPatterns ".aws",".org",".net",".au",".com"
Set-MalwareFilterPolicy -Identity "Default" -Action DeleteMessage -EnableInternalSenderAdminNotifications $true -InternalSenderAdminAddress $notifcationEmail -EnableFileFilter $true
Set-HostedContentFilterPolicy -Identity "Default" -HighConfidenceSpamAction MoveToJmf -BulkThreshold 6 -QuarantineRetentionPeriod 30 -EnableEndUserSpamNotifications 3
Set-HostedOutboundSpamFilterPolicy -Identity Default -RecipientLimitExternalPerHour 500 -RecipientLimitInternalPerHour 500 -RecipientLimitPerDay 1000 -ActionWhenThresholdReached BlockUser -AutoForwardingMode Off -NotifyOutboundSpam $true -NotifyOutboundSpamRecipients $notifcationEmail
New-AntiPhishPolicy -Name "Phishy1" -Enabled $true -AuthenticationFailAction Quarantine -EnableSpoofIntelligence $true -EnableUnauthenticatedSender $true
#Create Admin User
Write-Host "Creating Admin User" -ForegroundColor Green
New-Mailbox -Shared -Name "$businessName Support" -DisplayName "$businessName Support" -Alias "security"
Start-Sleep -s 5
Set-Mailbox -Identity "$businessName Support" -EmailAddresses @{add="support@$PrimaryDomain","compilance@$PrimaryDomain"} -ForwardingsmtpAddress $notifcationEmail -HiddenFromAddressListsEnabled $true
Write-Host "Starting Sleep for 20 Seconds" -ForegroundColor Red
Start-Sleep -Seconds 20
New-HostedOutboundSpamFilterPolicy -Name "$businessName Support" -AutoForwardingMode On -AdminDisplayName "Outbound policy to allow auto forward for support@" 
Start-Sleep -s 5
$user =  Get-EXOCasMailbox -Anr $businessName
New-HostedOutboundSpamFilterRule -Name "$businessName Support Rule" -Enabled $true -HostedOutboundSpamFilterPolicy "$businessName Support" -From $user.primarySmtpAddress
Write-Host "Starting Sleep for 20 Seconds" -ForegroundColor Red
Start-Sleep -Seconds 20
Add-MsolRoleMember -RoleName "Company Administrator" -RoleMemberEmailAddress "security@$PrimaryDomain"
Write-Host "Starting Sleep for 5 Seconds" -ForegroundColor Red
Start-Sleep -s 5
Set-MsolUser -UserPrincipalName "security@$PrimaryDomain" -BlockCredential $true
Write-Host "Enable Secure Defaults" -ForegroundColor Green
EnableSecureDefaults
Disconnect-ExchangeOnline
Write-Host "Finished!" -ForegroundColor Green 
#endregion