targetScope='resourceGroup'

param prefix string = 'cptd'
param location string = 'eastus'

resource fw 'Microsoft.Network/azureFirewalls@2021-05-01' existing = {
  name: prefix
}

resource subnetspoke1 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = {
  name: '${prefix}spoke1/${prefix}'
}

resource rthub1 'Microsoft.Network/routeTables@2020-11-01' = {
  name: '${prefix}hub1'
  location: location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'spoke1tohub'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: fw.properties.hubIPAddresses.privateIPAddress
          hasBgpOverride: false
        }
      }
    ]
  }
}

resource rthub2 'Microsoft.Network/routeTables@2020-11-01' = {
  name: '${prefix}hub2'
  location: location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'spoke2tohub'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: fw.properties.hubIPAddresses.privateIPAddress
          hasBgpOverride: false
        }
      }
    ]
  }
}
