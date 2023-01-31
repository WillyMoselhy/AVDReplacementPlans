# Deploy with bicep
Use the following example to deploy using bicep.

Create a variable with the needed parameters to create the Function App. This shows only the minimum set of required parameters. The session host parameters depend on the sample template provided.
```PowerShell
$BicepParams       = @{

    #FunctionApp
    FunctionAppName                     = 'func-avdreplacementplan-weu-001'
    HostPoolName                        = 'HOST POOL NAME HERE'
    TargetSessionHostCount              = 10 # Replace this with your target number of session hosts in the pool
    SessionHostNamePrefix               = "AVD-WE-D01"
    SessionHostTemplateUri              = "https://github.com/WillyMoselhy/AVDReplacementPlans/blob/e28275100ee5a1645c70f0c75e10269f734f06a0/SampleSessionHostTemplate/sessionhost.json"
    ADOrganizationalUnitPath            = "PATH HERE"
    SubnetId                            = "SUBNET ID HERE"

    # Supporting Resources
    StorageAccountName                  = 'stavdreplacehost221216' # Make sure this is a unique name
    LogAnalyticsWorkspaceName           = 'law-avdreplacementplan'
    # Session Host Parameters
    SessionHostParameters = @{
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

        WVDArtifactsURL       = 'https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_09-08-2022.zip'

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
```