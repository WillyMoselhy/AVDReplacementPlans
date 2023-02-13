# Deployment
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
            DomainType  ='ActiveDirectory' # the other option is AzureActiveDirectory and remove all other attributes and DomainJoinPassword parameter.
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
### Assign permissions
#### Key Vault (for Active Directory Joined)
If your session hosts are joining domain using a secret stored in a Key Vault, the FucntionApp requires the following permissions,
- **Key Vault Secrets User**, this is required on the secret item.
- **Key Vault resource manager template deployment operator**, this is required at the Key Vault level.
> This role is not built-in so you will need to create a custom role following the instructions [here](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/key-vault-parameter?tabs=azure-cli#grant-deployment-access-to-the-secrets).

#### Azure AD (for Azure AD Joined)
If your session hosts are Azure AD Joined (not hybrid), the FunctionApp requires permissions against GraphAPI in order to delete the devices when deleting session hosts. Without this cleanup, creating a new session host with the same name will fail.
- **Graph API: Device.Read.All**, this is required to query Azure AD for devices.
- **Cloud Device Administrator Role**, this Azure AD is required to delete the devices from Azure AD.

Assigning Graph API permissions to a system managed identity cannot be done from the portal. You may use the script below to assign the permissions,
```PowerShell
$FunctionAppSP = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' # The ID of the system managed identity of the function app

$GraphAppId = "00000003-0000-0000-c000-000000000000"
$graphSP = Get-MgServicePrincipal -Search "AppId:$GraphAppId" -ConsistencyLevel eventual
$msGraphPermissions = @(
    'Device.Read.All' #Used to read user and group permissions
)
$msGraphAppRoles = $graphSP.AppRoles | Where-Object { $_.Value -in $msGraphPermissions }

$msGraphAppRoles | ForEach-Object {
    $params = @{
        PrincipalId = $FunctionAppSP
        ResourceId  = $graphSP.Id
        AppRoleId   = $_.Id
    }
    New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $FunctionSP -BodyParameter $params
}
```
#### Network
Only one of these permissions are required to allow the FunctionApp to join the newly created VM to the virtual network.
- **Network Contributor** or
- **Custom role for /subnet/join action**
