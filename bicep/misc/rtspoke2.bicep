param routeTables_cptdvnet2_name string = 'cptdvnet2'

resource routeTables_cptdvnet2_name_resource 'Microsoft.Network/routeTables@2020-11-01' = {
  name: routeTables_cptdvnet2_name
  location: 'eastus'
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'spoke2tohub'
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

resource routeTables_cptdvnet2_name_spoke2tohub 'Microsoft.Network/routeTables/routes@2020-11-01' = {
  parent: routeTables_cptdvnet2_name_resource
  name: 'spoke2tohub'
  properties: {
    addressPrefix: '0.0.0.0/0'
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: '10.0.3.4'
    hasBgpOverride: false
  }
}