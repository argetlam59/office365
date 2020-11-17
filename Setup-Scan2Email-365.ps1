<# 
This script is for disableing authenticated smtp from an email address so that you can setup scan to email for a printer. 

This is not designed for an account with MFA; if you have an account that has MFA, setup an app password and use that for the scanner. 

TODO
Test

Changelog: 

1.1 - Relase - 18/11/2020
    Added admin elevation. 
    Added ex policy
1.0 - Release 17/11/2020
    Created Script
#>

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
Set-ExecutionPolicy Unrestricted -Force
$msg = 'Do you need to install exchange powershell?'
do {
    choice /c yn /m $msg
    $response = $LASTEXITCODE
    if ($response -eq 1) {
        Install-Module -Name ExchangeOnlineManagement
        Pause
        Update-Module -Name ExchangeOnlineManagement
    }
        $response = 2
} until ($response -eq 2)
cls

Connect-ExchangeOnline
Write-Host "Did you just get a bunch of red Errors? That likely means you need to install exchange powershell again. Close this window and restart as admin."
Enable-OrganizationCustomization
Pause

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
$account = [Microsoft.VisualBasic.Interaction]::InputBox("UserName DKIM", "Enter the email address of the account for scan2email")

Set-CASMailbox -Identity $account -SmtpClientAuthenticationDisabled $false

Pause
Disconnect-ExchangeOnline
Set-ExecutionPolicy Restricted -Force