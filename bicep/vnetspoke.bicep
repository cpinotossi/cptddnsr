targetScope = 'resourceGroup'

param prefix string
param postfix string
param location string
param cidervnet string
param cidersubnet string

resource vnethub 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: prefix
}
resource vnet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: '${prefix}${postfix}'
  location: location
  properties: {
    subnets: [
      {
        name: prefix
        properties: {
          addressPrefix: cidersubnet
          serviceEndpoints:[
            {
              locations:[
                location
              ]
              service:'Microsoft.Storage'
            }
          ]
        }
      }
    ]
    addressSpace: {
      addressPrefixes: [
        cidervnet
      ]
    }
  }
}

resource pdns 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: '${prefix}.org'
}

resource pdnslink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: pdns
  name: '${prefix}${postfix}'
  location: 'global'
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource peeringspoke2hub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-03-01' = {
  name: '${vnet.name}/spoke2hub'
  properties: {
    remoteVirtualNetwork: {
      id: vnethub.id
    }
  }
}

resource peeringhub2spoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-03-01' = {
  name: '${vnethub.name}/hub2spoke'
  properties: {
    remoteVirtualNetwork: {
      id: vnet.id
    }
  }
}

@description('VNet Name')
output vnetname string = vnet.name



