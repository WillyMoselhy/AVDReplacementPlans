# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' property is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

# Validate all parameters are in place
Write-PSFMessage -Level Host -Message "Validating Parameters"
$expectedParams = @(
    '_HostPoolResourceGroupName'
    '_HostPoolName'
    '_Tag_IncludeInAutomation'
    '_Tag_DeployTimestamp'
    '_Tag_PendingDrainTimestamp'
    '_TargetVMAgeDays'
    '_DrainGracePeriodHours'
    '_FixSessionHostTags'
    '_SHRDeploymentPrefix'
    '_TargetSessionHostCount'
    '_MaxSimultaneousDeployments'
    '_SessionHostNamePrefix'
)
foreach ($param in $expectedParams) {
    if (-Not [System.Environment]::GetEnvironmentVariable($param)) {
        throw "Parameter $param is not set"
    }
    Write-Host "$param = $([System.Environment]::GetEnvironmentVariable($param))"
}

# Get session hosts and update tags if needed.
$sessionHosts = Get-SHRSessionHost -FixSessionHostTags:([bool] $env:_FixSessionHostTags)
Write-PSFMessage -Level Host -Message "Found {0} session hosts" -StringValues $sessionHosts.Count

# Filter to Session hosts that are included in auto replace
$sessionHosts = $sessionHosts | Where-Object { $_.IncludeInAutomation }
Write-PSFMessage -Level Host -Message "Filtered to {0} session hosts enabled for automatic replacement: {1}" -StringValues $sessionHosts.Count, ($sessionHosts.VMName -join ',')

# Get running deployments, if any
$runningDeployments = Get-SHRRunningDeployment
Write-PSFMessage -Level Host -Message "Found {0} running deployments" -StringValues $runningDeployments.Count

# Get number session hosts to deploy
$hostPoolDecisions = Get-SHRHostPoolDecision -SessionHosts $sessionHosts -RunningDeployments $runningDeployments
if($hostPoolDecisions.PossibleDeploymentsCount -gt 0){
    Write-PSFMessage -Level Host -Message "We will deploy {0} session hosts" -StringValues $hostPoolDecisions.PossibleDeploymentsCount
    # Deploy session hosts
    Deploy-SHRSessionHost -NewSessionHostsCount $hostPoolDecisions.PossibleDeploymentsCount -ExistingSessionHostVMNames $hostPoolDecisions.ExistingSessionHostVMNames
}

if($hostPoolDecisions.AllowSessionHostDelete -and $hostPoolDecisions.SessionHostsPendingDelete.Count -gt 0){
    Write-PSFMessage -Level Host -Message "We will decommission {0} session hosts: {1}" -StringValues $hostPoolDecisions.SessionHostsPendingDelete.Count, ($hostPoolDecisions.SessionHostsPendingDelete.VMName -join ',')
    # Decommission session hosts
    Remove-SHRSessionHost -SessionHostsPendingDelete $hostPoolDecisions.SessionHostsPendingDelete
}


# Write an information log with the current time.
Write-Host "PowerShell timer trigger function finished! TIME: $currentUTCtime"
