$param = @{
    SubscriptionId    = '<Put your subscription Id here>'
    ResourceGroupName = 'rg-AVDReplaceHost-01'
    Location          = 'WestEurope'
    BicepParams       = @{
        #Storage Account
        StorageAccountName              = 'stavdreplacehost-221216'

        #Log Analytics Workspace
        LogAnalyticsWorkspaceName       = 'law-avdreplacehost'

        #FunctionApp
        FunctionAppName                 = 'func-avdreplacementplan-weu-001'
        HostPoolResourceGroupName       = 'rg-AVD-01'
        HostPoolName                    = 'hpool-AVD-WE-D01'
        TagIncludeInAutomation          = 'IncludeInAutoReplace'
        TagDeployTimestamp              = 'AutoReplaceDeployTimestamp'
        TagPendingDrainTimestamp        = 'AutoReplacePendingDrainTimestamp'
        TargetVMAgeDays                 = 30
        DrainGracePeriodHours           = 24
        FixSessionHostTags              = $true
        SHRDeploymentPrefix             = "AVDSessionHostReplacer"
        TargetSessionHostCount          = 3
        MaxSimultaneousDeployments      = 2
        SessionHostNamePrefix           = "AVD-WE-D01" #Azure Virtual Desktop - West Europe - FullDesktop Host Pool 01
    }

}
.\AVDSessionHostReplacer\AzureFunctions\Build\Build.ps1 @param -Verbose