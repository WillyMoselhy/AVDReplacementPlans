# PowerShell deployment
## AVD Replacement plan with basic options
### PowerShell
```PowerShell
$ResourceGroupName = 'rg-avd-hostpool-01'
$bicepParams = @{

    #FunctionApp
    FunctionAppName           = 'func-avdreplacementplan-weu-230131' # Name must be globally unique
    HostPoolName              = 'HOST POOL NAME HERE'
    TargetSessionHostCount    = 10 # Replace this with your target number of session hosts in the pool
    SessionHostNamePrefix     = "AVD-WE-D01"
    SessionHostTemplateUri    = "https://github.com/WillyMoselhy/AVDReplacementPlans/blob/e28275100ee5a1645c70f0c75e10269f734f06a0/SampleSessionHostTemplate/sessionhost.json"
    ADOrganizationalUnitPath  = "PATH HERE"
    SubnetId                  = "SUBNET ID HERE"

    # Supporting Resources
    StorageAccountName        = 'stavdreplacehost230131' # Make sure this is a unique name
    LogAnalyticsWorkspaceName = 'law-avdreplacementplan'
    # Session Host Parameters
    SessionHostParameters     = @{
        VMSize                = 'Standard_D4ds_v5'
        TimeZone              = 'GMT Standard Time'
        AdminUsername         = 'AVDAdmin'

        AcceleratedNetworking = $true

        imageReference        = @{
            publisher = 'MicrosoftWindowsDesktop'
            offer     = 'Windows-11'
            sku       = 'win11-22h2-avd'
            version   = 'latest'
        }

        #Domain Join
        DomainJoinObject      = @{
            DomainName = 'contoso.com'
            UserName   = 'AVDDomainJoin'
        }
        DomainJoinPassword    = @{
            reference = @{
                keyVault = @{ # Update this with the id of your key vault and secret name.
                    id         = 'KEYVAULT RESOURCE ID'
                    secretName = 'AVDDomainJoin'
                }
            }
        }
    }
}
$bicepParams.SessionHostParameters = $bicepParams.SessionHostParameters | ConvertTo-Json -Depth 10 -Compress
$paramsNewAzResourceGroupDeployment = @{
    # Cmdlet parameters
    TemplateFile            = ".\Build\Bicep\FunctionApps.bicep"
    Name                    = "DeployFunctionApp-$($bicepParams.FunctionAppName)"
    ResourceGroupName       = $ResourceGroupName
    TemplateParameterObject = $bicepParams

}
New-AzResourceGroupDeployment @paramsNewAzResourceGroupDeployment -Verbose
```