# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' property is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}


# Get session hosts and update tags if needed.
$sessionHosts = Get-SHRSessionHost -FixSessionHostTags:(Get-FunctionConfig _FixSessionHostTags)
Write-PSFMessage -Level Host -Message "Found {0} session hosts" -StringValues $sessionHosts.Count

# Filter to Session hosts that are included in auto replace
$sessionHostsFiltered = $sessionHosts | Where-Object { $_.IncludeInAutomation }
Write-PSFMessage -Level Host -Message "Filtered to {0} session hosts enabled for automatic replacement: {1}" -StringValues $sessionHostsFiltered.Count, ($sessionHostsFiltered.VMName -join ',')

# Get running deployments, if any
$runningDeployments = Get-SHRRunningDeployment
Write-PSFMessage -Level Host -Message "Found {0} running deployments" -StringValues $runningDeployments.Count

# load session host parameters
$sessionHostParameters = (Get-FunctionConfig _SessionHostParameters)

# Get latest version of session host image
Write-PSFMessage -Level Host -Message "Getting latest image version using Image Reference: {0}" -StringValues ($sessionHostParameters.ImageReference | Out-String)
$latestImageVersion = Get-SHRLatestImageVersion -ImageReference $sessionHostParameters.ImageReference

# Get number session hosts to deploy
$hostPoolDecisions = Get-SHRHostPoolDecision -SessionHosts $sessionHostsFiltered -RunningDeployments $runningDeployments -LatestImageVersion $latestImageVersion

# Deploy new session hosts
if ($hostPoolDecisions.PossibleDeploymentsCount -gt 0) {
    Write-PSFMessage -Level Host -Message "We will deploy {0} session hosts" -StringValues $hostPoolDecisions.PossibleDeploymentsCount
    # Deploy session hosts
    $existingSessionHostVMNames = (@($sessionHosts.VMName) + @($hostPoolDecisions.ExistingSessionHostVMNames)) | Sort-Object | Select-Object -Unique
    if ([string]::IsNullOrEmpty((Get-FunctionConfig _SessionHostResourceGroupName))) {
        $resourceGroupName =     Get-FunctionConfig _HostPoolResourceGroupName
    }
    else
    {
        $resourceGroupName = Get-FunctionConfig _SessionHostResourceGroupName
    }
    Write-PSFMessage -Level Host -Message "Deploying to Resource Group: {0}" -StringValues "$resourceGroupName"
    Deploy-SHRSessionHost -NewSessionHostsCount $hostPoolDecisions.PossibleDeploymentsCount -ExistingSessionHostVMNames $existingSessionHostVMNames -SessionHostParameters $sessionHostParameters -ResourceGroupName $resourceGroupName
}

# Delete expired session hosts
if ($hostPoolDecisions.AllowSessionHostDelete -and $hostPoolDecisions.SessionHostsPendingDelete.Count -gt 0) {
    Write-PSFMessage -Level Host -Message "We will decommission {0} session hosts: {1}" -StringValues $hostPoolDecisions.SessionHostsPendingDelete.Count, ($hostPoolDecisions.SessionHostsPendingDelete.VMName -join ',')
    # Decommission session hosts
    $removeAzureDevice = if ($sessionHostParameters.DomainJoinObject.DomainType -eq 'AzureActiveDirectory') { $true } else { $false } #TODO: This should move inside the Remove-SHRSessionHost function once we move to config
    Remove-SHRSessionHost -SessionHostsPendingDelete $hostPoolDecisions.SessionHostsPendingDelete -RemoveAzureDevice $removeAzureDevice
}


# Write an information log with the current time.
Write-Host "PowerShell timer trigger function finished! TIME: $currentUTCtime"
