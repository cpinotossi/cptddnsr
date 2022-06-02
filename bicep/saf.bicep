targetScope='resourceGroup'

param prefix string
param location string
param myObjectId string
param myip string

resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' existing = {
  name: prefix
}

resource sa 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: prefix
  location: location
  sku: {
    name: 'Standard_ZRS'
  }
  kind: 'StorageV2'
  properties: {
    // isNfsV3Enabled: true
    // isHnsEnabled: true
    networkAcls: {
      resourceAccessRules: []
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: '${vnet.id}/subnets/${prefix}'
          action: 'Allow'
        }
      ]
      ipRules: [
        {
          value: myip
          action: 'Allow'
        }
      ]
      defaultAction: 'Deny'
    }
    accessTier: 'Hot'
  }
}

// resource fs 'Microsoft.Storage/storageAccounts/fileServices@2021-04-01' = {
//   name: 'default'
//   parent: sa
//   properties: {
//     shareDeleteRetentionPolicy: {
//       enabled: false
//       days: 0
//     }
//   }
// }

// resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-08-01' = {
//   name: prefix
//   parent: fs
//   properties: {
//     accessTier: 'TransactionOptimized'
//     shareQuota: 5120
//     enabledProtocols: 'SMB'
//   }
// }

// var roleStorageBlobDataContributorName = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' //Storage Blob Data Contributor
var storageFileDataSMBShareContributorId = '0c867c2a-1d8c-454a-a3db-ab2ea1bdc8bb'

resource rasmbcontributor 'Microsoft.Authorization/roleAssignments@2018-01-01-preview' = {
  name: guid(resourceGroup().id,'rasmbcontributort')
  scope: sa
  properties: {
    principalId: myObjectId
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/RoleDefinitions',storageFileDataSMBShareContributorId)
  }
}
