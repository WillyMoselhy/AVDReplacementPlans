# Azure Functions profile.ps1
#
# This profile.ps1 will get executed every "cold start" of your Function App.
# "cold start" occurs when:
#
# * A Function App starts up for the very first time
# * A Function App starts up after being de-allocated due to inactivity
#
# You can define helper functions, run commands, or specify environment variables
# NOTE: any variables defined that are not environment variables will get reset after the first execution


Import-Module 'PSFrameWork' ,'Az.Resources' ,'Az.Compute' ,'Az.DesktopVirtualization', 'SessionHostReplacer' -ErrorAction Stop

# Configure PSFramework settings
Set-PSFConfig -FullName PSFramework.Message.style.NoColor -Value $true #This is required for logs to look good in FunctionApp Logs


# Authenticate with Azure PowerShell using MSI.
if ($env:MSI_SECRET) {
    Disable-AzContextAutosave -Scope Process | Out-Null
    Connect-AzAccount -Identity -SubscriptionId $env:_SubscriptionId
}
else{
    Set-AzContext -SubscriptionId $env:_SubscriptionId
}
$ErrorActionPreference = 'Stop'

# Version Banner #
Write-PSFMessage -Level Host -Message "This is SessionHostReplacer version {0}" -StringValues '0.1.5'
