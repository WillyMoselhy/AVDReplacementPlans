function Deploy-SHRSessionHost {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string[]] $ExistingSessionHostVMNames = @(),

        [Parameter(Mandatory = $true)]
        [int] $NewSessionHostsCount,

        [Parameter()]
        [string] $ResourceGroupName = $env:_HostPoolResourceGroupName,

        [Parameter()]
        [string] $HostPoolName = $env:_HostPoolName,

        [Parameter()]
        [string] $SessionHostNamePrefix = $env:_SessionHostNamePrefix,

        [Parameter()]
        [int] $SessionHostInstanceNumberPadding = $env:_SessionHostInstanceNumberPadding,

        [Parameter()]
        [string] $DeploymentPrefix = $env:_SHRDeploymentPrefix,

        [Parameter()]
        [string] $SessionHostTemplateUri = $env:_SessionHostTemplateUri,

        [Parameter()]
        [string] $SessionHostTemplateParametersPS1Uri = $env:_SessionHostTemplateParametersPS1Uri,

        [Parameter()]
        [string] $ADOrganizationalUnitPath = $env:_ADOrganizationalUnitPath,

        [Parameter()]
        [string] $SubnetId = $env:_SubnetId,

        [Parameter()]
        [string] $TagIncludeInAutomation = $env:_Tag_IncludeInAutomation,
        [Parameter()]
        [string] $TagDeployTimestamp = $env:_Tag_DeployTimestamp
    )
    Write-PSFMessage -Level Host -Message "Generating new token for the host pool {0}" -StringValues $HostPoolName
    $hostPoolToken = New-AzWvdRegistrationInfo -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName -ExpirationTime (Get-Date).AddHours(2) -ErrorAction Stop

    # Download template paramter PS1 file
    Write-PSFMessage -Level Host -Message "Downloading template parameter PS1 file from {0} (SAS redacted)" -StringValues ($SessionHostTemplateParametersPS1Uri -replace '\?.+','')
    $sessionHostParametersPS1 = Invoke-RestMethod -Uri $SessionHostTemplateParametersPS1Uri -ErrorAction Stop

    $sessionHostParameters = Invoke-Expression $sessionHostParametersPS1
    $sessionHostParameters['HostPoolName'] = $HostPoolName
    $sessionHostParameters['HostPoolToken'] = $hostPoolToken.Token
    $sessionHostParameters['Tags'][$TagIncludeInAutomation] = $true
    $sessionHostParameters['Tags'][$TagDeployTimestamp] = (Get-Date -AsUTC -Format 'o')
    $sessionHostParameters['SubnetId'] = $SubnetId

    if($sessionHostParameters.DomainJoinObject.DomainType -eq 'ActiveDirectory') {
        $sessionHostParameters.DomainJoinObject.OUPath = $ADOrganizationalUnitPath
    }


    $deploymentTimestamp = Get-Date -AsUTC -Format 'FileDateTime'
    $deploymentJobs = for ($i = 0; $i -lt $NewSessionHostsCount; $i++) {
        Write-PSFMessage -Level Host -Message "i= $i - Existing session host VM names: {0}" -StringValues ($ExistingSessionHostVMNames -join ',')
        $vmNumber = 1
        While (("$SessionHostNamePrefix-{0:d$SessionHostInstanceNumberPadding}" -f $vmNumber) -in $ExistingSessionHostVMNames) {
            $vmNumber++
        }
        $vmName = "$SessionHostNamePrefix-{0:d$SessionHostInstanceNumberPadding}" -f $vmNumber
        $ExistingSessionHostVMNames += $vmName
        Write-PSFMessage -Level Host -Message "i= $i - Creating session host {0}" -StringValues $vmName

        $deploymentName = "{0}_{1}_{2}" -f $DeploymentPrefix, $deploymentTimestamp, $vmName
        Write-PSFMessage -Level Host -Message "i= $i - Deployment name: {0}" -StringValues $deploymentName

        $sessionHostParameters['VMName'] = $vmName
        $sessionHostParameters['AdminPassword'] = Get-RandomPassword
        Write-PSFMessage -Level Host -Message "i= $i - SessionHost VMName = {0}" -StringValues $sessionHostParameters['VMName']

        $paramNewAzResourceGroupDeployment = @{
            Name = $deploymentName
            ResourceGroupName = $ResourceGroupName
            TemplateUri = $SessionHostTemplateUri
            TemplateParameterObject = $sessionHostParameters
        }
        New-AzResourceGroupDeployment @paramNewAzResourceGroupDeployment -AsJob
        Write-PSFMessage -Level Host -Message 'Sleeping for 10 seconds before starting next deployment.' # We had an issue where if we don't sleep it reuses the same VM name
        Start-Sleep -Seconds 10
    }

    Write-PSFMessage -Level Host -Message "Sleep for 60 seconds to allow the deployments to start."
    Start-Sleep -Seconds 60

    # Check deployment status, if any has failed we report an error
    if($deploymentJobs.Error){
        Write-PSFMessage -Level Error "DeploymentFailed" -EnableException $true
        throw $deploymentJobs.Error
    }
}