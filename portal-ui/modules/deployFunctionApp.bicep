/*
This solution is made up of:
1- AppServicePlan - Used to host all functions
2- Azure Function: AVDSessionHostReplacer
4- StorageAccount - To store FunctionApp
5- LogAnalyticsWorkspace - Used to store Logs, and AppService insights
*/

//------ Parameters ------//
@description('Required: No | Region of the Function App. This does not need to be the same as the location of the Azure Virtual Desktop Host Pool. | Default: Location of the resource group.')
param Location string = resourceGroup().location

//Storage Account
@description('Required: Yes | Name of the storage account used by the Function App. This name must be unique across all existing storage account names in Azure. It must be 3 to 24 characters in length and use numbers and lower-case letters only.')
param StorageAccountName string

//Log Analytics Workspace
@description('Required: Yes | Name of the Log Analytics Workspace used by the Function App Insights.')
param LogAnalyticsWorkspaceName string

//FunctionApp
@description('Required: Yes | Name of the Function App.')
param FunctionAppName string

@description('Required: No | URL of the FunctionApp.zip file. This is the zip file containing the Function App code. | Default: The latest release of the Function App code.')
param FunctionAppZipUrl string = 'https://github.com/WillyMoselhy/AVDReplacementPlans/raw/Development/Nightly/FunctionApp.zip'

@description('Required: No | App Service Plan Name | Default: Y1 for consumption based plan')
param AppPlanName string = 'Y1'

@description('Required: No | App Service Plan Tier | Default: Dynamic for consumption based plan')
param AppPlanTier string = 'Dynamic'



@description('''Required: Yes | The following settings are mandatory. Rest are optional.
[
  {
    name: '_HostPoolResourceGroupName'
    value: 'string'
  }
  {
    name: '_HostPoolName'
    value: 'string'
  }
  {
    name: '_RemoveAzureADDevice'
    value: 'bool'
  }
  {
    name: '_SessionHostTemplate'
    value: 'string'
  }
  {
    name: '_SessionHostParameters'
    value: 'hashtable'
  }
  {
    name: '_SubscriptionId'
    value: 'string'
  }
  {
    name: '_TargetSessionHostCount'
    value: 'int'
  }
  {
    name: '_SessionHostNamePrefix'
    value: 'string'
  }
]''')
param ReplacementPlanSettings array

//-------//

//------ Variables ------//
var varFunctionAppSettings = [
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: '~4'
  }
  {
    name: 'FUNCTIONS_WORKER_RUNTIME'
    value: 'powershell'
  }
  {
    name: 'AzureWebJobsStorage'
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
  }
  {
    name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
  }
  {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: appInsights.properties.InstrumentationKey
  }
  {
    name: 'WEBSITE_CONTENTSHARE'
    value: toLower(FunctionAppName)
  }
]
var varFunctionAppSettingsAndReplacementPlanSettings = union(varFunctionAppSettings,ReplacementPlanSettings)

var varAppServicePlanName = '${FunctionAppName}-asp'
//-------//

//------ Resources ------//

// Deploy Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: StorageAccountName
  location: Location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    // TODO: Discuss securing the storage account (firewall)
  }
}

// Deploy Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: LogAnalyticsWorkspaceName
  location: Location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Deploy App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: varAppServicePlanName
  location: Location
  sku: {
    name: AppPlanName
    tier: AppPlanTier
  }
}

// Deploy App Insights for App Service Plan
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: varAppServicePlanName
  location: Location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

// Create ReplaceSessionHost function with Managed System Identity (MSI)
resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: FunctionAppName
  location: Location
  kind: 'functionApp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    httpsOnly: true
    serverFarmId: appServicePlan.id
    siteConfig: {
      use32BitWorkerProcess: false
      powerShellVersion: '7.2'
      netFrameworkVersion: 'v6.0'
      appSettings: varFunctionAppSettingsAndReplacementPlanSettings
      ftpsState: 'Disabled'
    }
  }
  resource deployFromZip 'extensions@2022-03-01' = {
    name: 'MSDeploy'
    properties: {
      packageUri: FunctionAppZipUrl
    }
  }
}
//------//

/*
resource deployTemplateSpec 'Microsoft.Resources/templateSpecs@2022-02-01' = {
  name: 'spec-avd-session-hosts'
  location: Location
  properties: {
    description: 'This is the template used by AVD Replacement Plan to deploy session hosts.'
    displayName: 'AVD Session Host Template'
  }
  resource deployTemplateSpecVersion 'versions@2022-02-01' = {
    name: 'deployTemplateSpecVersion'
    location: Location
    properties: {
      mainTemplate: any('')//loadJsonContent('../../../arm/avdSessionHosts.json')
    }
  }
}
*/
/*
module RBACFunctionAppDesktopVirtualizationVirtualMachineContributor './.bicep/roleAssignment.bicep' = {
  name: 'RBACFunctionAppDesktopVirtualizationVirtualMachineContributor'
  params: {
    PrinicpalId: functionApp.identity.principalId
    RoleDefinitionId: 'b24988ac-6180-42a0-ab88-20f7382dd24c' // Contributor
    Scope: resourceGroup().id
  }
}
module RBACFunctionApphasReaderOnTemplateSpec './.bicep/roleAssignment.bicep' = if (startsWith(SessionHostTemplate, '/subscriptions/')) {
  name: 'RBACFunctionApphasReaderOnTemplateSpec'
  params: {
    PrinicpalId: functionApp.identity.principalId
    RoleDefinitionId: 'acdd72a7-3385-48ef-bd42-f606fba81ae7' // Reader
    Scope: SessionHostTemplate
  }
}
*/

//----- Outputs ------//
output functionAppPrincipalId string = functionApp.identity.principalId
