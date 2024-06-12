/*
This solution is made up of:
1- AppServicePlan - Used to host all functions
2- StorageAccount - To store FunctionApp
3- LogAnalyticsWorkspace - Used to store Logs, and AppService insights
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

@description('Required: Yes | Name of the Log Analytics Workspace used by the Function App Insights.')
param AppServicePlanName string

@description('Required: No | App Service Plan Name | Default Y1 for consumption based plan')
param AppPlanName string = 'Y1'

@description('Required: No | App Service Plan Tier | Default Dynamic for consumption based plan')
param AppPlanTier string = 'Dynamic'

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
  name: AppServicePlanName
  location: Location
  sku: {
    name: AppPlanName
    tier: AppPlanTier
  }
}

// Deploy App Insights for App Service Plan
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: AppServicePlanName
  location: Location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}
