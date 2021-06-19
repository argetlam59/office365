<# 
This script is for disableing authenticated smtp from an email address so that you can setup scan to email for a printer. 

This is not designed for an account with MFA; if you have an account that has MFA, setup an app password and use that for the scanner. 

TODO


Changelog: 
1.2 - Release - 19/06/2021
    Removed Bloat
1.1 - Relase - 18/11/2020
    Added admin elevation. 
    Added ex policy
1.0 - Release 17/11/2020
    Created Script
#>

#Requires -Module ExchangeOnlineManagement

Connect-ExchangeOnline
Write-Host "Did you just get a bunch of red Errors? That likely means you need to install exchange powershell again."
Enable-OrganizationCustomization
Pause
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
$account = [Microsoft.VisualBasic.Interaction]::InputBox("UserName DKIM", "Enter the email address of the account for scan2email")
Set-CASMailbox -Identity $account -SmtpClientAuthenticationDisabled $false
Pause
Disconnect-ExchangeOnline
Set-ExecutionPolicy Restricted -Force