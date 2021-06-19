<# 
This script is for installing and running ORCA report on a tenancy. 

Office 365 Advanced Threat Protection Recommended Configuration Analyzer (ORCA)

TODO
Test

Changelog: 

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

$msg = 'Do you need to install ORCA for the first time?'
do {
    choice /c yn /m $msg
    $response = $LASTEXITCODE
    if ($response -eq 1) {
        Install-Module -Name ORCA
    }
        $response = 2
} until ($response -eq 2)
cls

Connect-ExchangeOnline
Write-Host "

Did you just get a bunch of red Errors? 

That likely means you need to install exchange powershell again. Close this window and restart."
Pause
Get-ORCAReport
Pause
Disconnect-ExchangeOnline
Set-ExecutionPolicy Restricted -Force