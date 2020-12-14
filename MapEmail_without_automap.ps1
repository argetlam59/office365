<# 
This script is for adding manage permissions to a mailbox without the mailbox appearing in the Users outlook. 

TODO
add check to make sure that users exist in the tenancy before continueing. Catch mispelling. 

Changelog: 
 
1.0 - Release 14/12/2020
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
Write-Host "
Did you just get a bunch of red Errors? That likely means you need to install exchange powershell again. Close this window and restart as admin."
Pause

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
$user = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the email address USER", "PERMISSIONS")

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
$admin = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the email address ADMIN", "PERMISSIONS")

Add-MailboxPermission -Identity $user -User $admin -AccessRights FullAccess -AutoMapping $false

Pause
Disconnect-ExchangeOnline
Set-ExecutionPolicy Restricted -Force