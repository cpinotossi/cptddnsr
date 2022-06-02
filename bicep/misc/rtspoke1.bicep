param routeTables_cptdvnet_name string = 'cptdvnet'

resource routeTables_cptdvnet_name_resource 'Microsoft.Network/routeTables@2020-11-01' = {
  name: routeTables_cptdvnet_name
  location: 'eastus'
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'spoke1tohub'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '10.0.3.4'
          hasBgpOverride: false
        }
      }
    ]
  }
}

resource routeTables_cptdvnet_name_spoke1tohub 'Microsoft.Network/routeTables/routes@2020-11-01' = {
  parent: routeTables_cptdvnet_name_resource
  name: 'spoke1tohub'
  properties: {
    addressPrefix: '0.0.0.0/0'
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: '10.0.3.4'
    hasBgpOverride: false
  }
}