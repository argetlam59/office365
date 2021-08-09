<#
This will check for the presence of reg key and if it doesn't exist, it will create a new registry entry to block chrome notificaionts. 
Credit to Jake Gardner from https://heresjaken.com/

09/08/2021 - ss - 'yo ho its a pirates life.' 
    Imported (read:copy/paste) code and saved into ps1
    Fixed lines that weren't working
    Tested on VM
    Tested on Prod
    Cleaned and preped for git
#>

if ((Test-Path -LiteralPath "Registry::\HKEY_CURRENT_USER\Software\Policies\Google\Chrome") -ne $true) { 

    New-Item "Registry::\HKEY_CURRENT_USER\Software\Policies\Google\Chrome" -force -ea SilentlyContinue 
    }
if ((Test-Path -LiteralPath "Registry::\HKEY_CURRENT_USER\Software\Policies\Microsoft\Edge") -ne $true) { 
    
    New-Item "Registry::\HKEY_CURRENT_USER\Software\Policies\Microsoft\Edge" -force -ea SilentlyContinue 
    }
New-ItemProperty -LiteralPath 'Registry::\HKEY_CURRENT_USER\Software\Policies\Google\Chrome' -Name 'DefaultNotificationsSetting' -Value '2' -PropertyType DWord
New-ItemProperty -LiteralPath 'Registry::\HKEY_CURRENT_USER\Software\Policies\Microsoft\Edge' -Name 'DefaultNotificationsSetting' -Value '2' -PropertyType DWord
