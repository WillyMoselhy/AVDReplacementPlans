@{

    _Tag_IncludeInAutomation                      = @{Required = $false ; Type = 'string'  ; Default = 'IncludeInAutoReplace'             ; Description = '' }
    _Tag_DeployTimestamp                          = @{Required = $false ; Type = 'string'  ; Default = 'AutoReplaceDeployTimestamp'       ; Description = '' }
    _Tag_PendingDrainTimestamp                    = @{Required = $false ; Type = 'string'  ; Default = 'AutoReplacePendingDrainTimestamp' ; Description = '' }
    _Tag_ScalingPlanExclusionTag                  = @{Required = $false ; Type = 'string'  ; Default = 'ScalingPlanExclusion'             ; Description = '' }
    _TargetVMAgeDays                              = @{Required = $false ; Type = 'int   '  ; Default = 45                                 ; Description = '' }
    _DrainGracePeriodHours                        = @{Required = $false ; Type = 'int   '  ; Default = 24                                 ; Description = '' }
    _FixSessionHostTags                           = @{Required = $false ; Type = 'bool  '  ; Default = $true                              ; Description = '' }
    _SHRDeploymentPrefix                          = @{Required = $false ; Type = 'string'  ; Default = 'AVDSessionHostReplacer'           ; Description = '' }
    _MaxSimultaneousDeployments                   = @{Required = $false ; Type = 'int   '  ; Default = 20                                 ; Description = '' }
    _ADOrganizationalUnitPath                     = @{Required = $false ; Type = 'string'  ; Default = ''                                 ; Description = '' }
    _AllowDownsizing                              = @{Required = $false ; Type = 'bool  '  ; Default = $true                              ; Description = '' }
    _SessionHostInstanceNumberPadding             = @{Required = $false ; Type = 'int   '  ; Default = 2                                  ; Description = '' }
    _ReplaceSessionHostOnNewImageVersion          = @{Required = $false ; Type = 'bool  '  ; Default = $true                              ; Description = '' }
    _ReplaceSessionHostOnNewImageVersionDelayDays = @{Required = $false ; Type = 'int   '  ; Default = 0                                  ; Description = '' }
    _HostPoolResourceGroupName                    = @{Required = $true  ; Type = 'string'                                                 ; Description = '' }
    _SessionHostResourceGroupName                 = @{Required = $false ; Type = 'string'  ; Default = ''                                 ; Description = 'Use this if you want to deploy VMs in a different Resource Group. By default it will be the same Resource Group as Host Pool' }
    _HostPoolName                                 = @{Required = $true  ; Type = 'string'                                                 ; Description = '' }
    _TargetSessionHostCount                       = @{Required = $true  ; Type = 'int   '                                                 ; Description = '' }
    _SessionHostNamePrefix                        = @{Required = $true  ; Type = 'string'                                                 ; Description = '' }
    _SessionHostTemplate                          = @{Required = $true  ; Type = 'string'                                                 ; Description = '' }
    _SessionHostParameters                        = @{Required = $true  ; Type = 'hashtable'                                              ; Description = '' }
    _SubnetId                                     = @{Required = $true  ; Type = 'string'                                                 ; Description = '' }
    _SubscriptionId                               = @{Required = $true  ; Type = 'string'                                                 ; Description = '' }
}
