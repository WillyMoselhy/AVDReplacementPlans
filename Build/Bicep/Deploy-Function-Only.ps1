# This script assumes you have pre-deployed the required app service plan, storage account and log analytics workspace within your subscription.

$ResourceGroupName = 'rg-us1-avd-session-host-functions'
$params = @{

    SubscriptionId    = '<subscription-id>'
    ResourceGroupName = 'rg-us1-avd-session-host-functions' # Resource group where you want to create the function app
    Location          = 'EastUs'
    AssignPermissions = $false
    BicepParams       = @{

        # Existing Storage Account
        StorageAccountName                  = '<storage-account-name>'

        # Existing Log Analytics Workspace
        LogAnalyticsWorkspaceName           = '<log-analytics-name>'

        #Existing App Service Plan Name
        AppServicePlanName                  = '<app-plan-name>'

        # Existing Subnet Name | Required if private vNet integration is required
        functionSubnetId                    = '/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Network/virtualNetworks/<vnet-name>/subnets/<subnet-name>' # Must be /28 and delegated to Azure Function
        # Key Vault Name
        keyVaultName                        = '<kv-name>'
        # Key Vault Resource Group
        keyVaultResourceGroup               = '<kv-rg>'
        #FunctionApp Name
        FunctionAppName                     = '<function-name>'

        # AVD Settings
        HostPoolResourceGroupName           = '<hostpool-rg>'
        HostPoolName                        = '<hostpool-name>'
        TagIncludeInAutomation              = 'IncludeInAutoReplace'
        TagDeployTimestamp                  = 'AutoReplaceDeployTimestamp'
        TagPendingDrainTimestamp            = 'AutoReplacePendingDrainTimestamp'
        TargetVMAgeDays                     = 30
        TagScalingPlanExclusionTag          = 'ExcludeReplacement'
        DrainGracePeriodHours               = 12
        FixSessionHostTags                  = $true
        SHRDeploymentPrefix                 = "AVDSessionHostReplacer"
        TargetSessionHostCount              = 1
        MaxSimultaneousDeployments          = 2
        SessionHostNamePrefix               = "<host-name>"
        SessionHostTemplateUri              = "https://raw.githubusercontent.com/WillyMoselhy/AVDReplacementPlans/main/SampleSessionHostTemplate/sessionhost.json"
        FunctionAppZipUrl                   = 'https://github.com/Thomas-Butterfield/AVDReplacementPlans/releases/download/v0.1.4(beta)/FunctionApp-V0.1.4-beta.zip'
        ADOrganizationalUnitPath            = '<ad-ou-path>'
        SubnetId                            = "/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Network/virtualNetworks/<vnet-name>/subnets/<subnet-name>"
        SessionHostInstanceNumberPadding    = 2 # This results in a session host name like AVD-WE-D01-01,02,03

        # Session Host Parameters
        SessionHostParameters = @{
            VMSize                = 'Standard_E8ds_v5'
            TimeZone              = 'Central Standard Time'
            AdminUsername         = 'AVDAdmin'

            #AvailabilityZone      = '1' #TODO Distribute on AZs if supported

            AcceleratedNetworking = $true

            Tags                  = @{}

            ImageReference        = @{
                Id = '/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Compute/galleries/<gallery-name>/images/<image-definition>'
            }

            WVDArtifactsURL       = 'https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_09-08-2022.zip'

            #Domain Join
            DomainJoinObject      = @{
                DomainType = 'ActiveDirectory' # ActiveDirectory or AzureActiveDirectory
                DomainName = 'contoso.com'
                OUPath     = '<ad-ou-path>'
                UserName   = '<username>'
            }
            DomainJoinPassword    = @{
                reference = @{
                    keyVault = @{
                        id         = '/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.KeyVault/vaults/<kv-name>'
                    }
                    secretName = 'AVDDomainJoin'
                }
            }
        }
    }
}

$params.BicepParams.SessionHostParameters = $params.BicepParams.SessionHostParameters | ConvertTo-Json -Depth 10 -Compress
$paramsNewAzResourceGroupDeployment = @{
    # Cmdlet parameters
    TemplateFile            = ".\Build\Bicep\Deploy-Function-Only.bicep"
    Name                    = "DeployFunctionApp-$($params.BicepParams.FunctionAppName)"
    ResourceGroupName       = $ResourceGroupName
    TemplateParameterObject = $params.BicepParams
}

New-AzResourceGroupDeployment @paramsNewAzResourceGroupDeployment -Verbose