# PowerShell deployment
## AVD Replacement plan with basic options
### PowerShell
```PowerShell
$ResourceGroupName = 'rg-avd-weu-avd1-service-objects'
$bicepParams = @{

    #FunctionApp
    FunctionAppName           = 'func-avdreplacementplan-weu-230131' # Name must be globally unique
    HostPoolName              = 'vdpool-weu-avd1-001'
    TargetSessionHostCount    = 2 # Replace this with your target number of session hosts in the pool
    SessionHostNamePrefix     = "AVD-WE-D01"
    SessionHostTemplateUri    = "https://raw.githubusercontent.com/WillyMoselhy/AVDReplacementPlans/main/SampleSessionHostTemplate/sessionhost.json"
    ADOrganizationalUnitPath  = "OU=AVD,DC=contoso,DC=local"
    SubnetId                  = "/subscriptions/2cc55a8e-7e60-4bba-b1e1-2241e5249d46/resourceGroups/rg-ActiveDirectory-01/providers/Microsoft.Network/virtualNetworks/rg-ActiveDirectory-01-vnet/subnets/default"

    # Supporting Resources
    StorageAccountName        = 'stavdreplacehost230131' # Make sure this is a unique name
    LogAnalyticsWorkspaceName = 'law-avdreplacementplan'
    # Session Host Parameters
    SessionHostParameters     = @{
        VMSize                = 'Standard_B2ms'
        TimeZone              = 'GMT Standard Time'
        AdminUsername         = 'AVDAdmin'

        AcceleratedNetworking = $false

        ImageReference        = @{
            publisher = 'MicrosoftWindowsDesktop'
            offer     = 'Windows-11'
            sku       = 'win11-22h2-avd'
            version   = 'latest'
        }

        #Domain Join
        DomainJoinObject      = @{
            DomainType  ='ActiveDirectory'
            DomainName = 'contoso.local'
            UserName   = 'AzureAdmin'
        }
        DomainJoinPassword    = @{
            reference = @{
                keyVault = @{ # Update this with the id of your key vault and secret name.
                    id         = '/subscriptions/2cc55a8e-7e60-4bba-b1e1-2241e5249d46/resourceGroups/rg-ActiveDirectory-01/providers/Microsoft.KeyVault/vaults/kv-contoso-we-01'
                }
                secretName = 'AVDDomainJoin'
            }
        }

        Tags                  = @{}
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