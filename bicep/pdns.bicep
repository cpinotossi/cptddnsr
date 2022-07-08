targetScope = 'resourceGroup'

param prefix string
param postfix string

resource vnethub 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  name: prefix
}
resource vnetspoke 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  name: '${prefix}${postfix}'
}

resource pdns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: '${prefix}.org'
  location: 'global'
}

resource pdnshublink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: pdns
  name: prefix
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnethub.id
    }
  }
}

resource pdnsspokelink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: pdns
  name: '${prefix}${postfix}'
  location: 'global'
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: vnetspoke.id
    }
  }
}
