@description('Required: Yes | Resource ID of the KeyVault containing the AVDDomainJoin secret.')
param keyvaultName string

@description('Required: Yes | System Managed Id of function app to be assigned a new keyvault access policy')
param objectId string

resource accessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  name: '${keyvaultName}/add'
  properties: {
    accessPolicies: [
      {
        objectId: objectId
        tenantId: subscription().tenantId
        permissions: {
          secrets: [
            'all'
          ]
        }
      }
    ]
  }
}

