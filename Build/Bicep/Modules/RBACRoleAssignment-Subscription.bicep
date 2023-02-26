param PrinicpalId string
param RoleDefinitionId string
param SubscriptionId string

targetScope = 'subscription'

resource RBACFunctionAppMSIhasVritualDesktopVMContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(SubscriptionId, PrinicpalId, RoleDefinitionId)
  properties: {
    principalId: PrinicpalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', RoleDefinitionId)
  }
}

