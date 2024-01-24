targetScope='resourceGroup'

param vnetsourcename string
param vnettargetname string
param useremotegateway bool = false
param rgsourcename string
param rgtargetname string

resource vnetsource 'Microsoft.Network/virtualNetworks@2022-09-01' existing = {
  name: vnetsourcename
  scope: resourceGroup(rgsourcename)
}

resource vnettarget 'Microsoft.Network/virtualNetworks@2022-09-01' existing = {
  name: vnettargetname
  scope: resourceGroup(rgtargetname)
}

resource peeringsource2target 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-09-01' = {
  name: '${vnetsource.name}/${vnetsource.name}${vnettarget.name}'
  properties: {
    remoteVirtualNetwork: {
      id: vnettarget.id
    }
    allowForwardedTraffic: true
    allowVirtualNetworkAccess: true
    allowGatewayTransit: true
    useRemoteGateways: useremotegateway
  }
}
