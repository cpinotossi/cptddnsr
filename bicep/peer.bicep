

targetScope = 'resourceGroup'

param prefix string
param hub string
param spoke string

resource vnethub 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: '${prefix}${hub}'
}

resource vnetspoke 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: '${prefix}${spoke}'
}

resource peeringspoke2hub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-03-01' = {
  name: '${vnetspoke.name}/${spoke}${hub}'
  properties: {
    remoteVirtualNetwork: {
      id: vnethub.id
    }
  }
}

resource peeringhubspoke1 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-03-01' = {
  name: '${vnethub.name}/${hub}${spoke}'
  properties: {
    remoteVirtualNetwork: {
      id: vnetspoke.id
    }
  }
}
