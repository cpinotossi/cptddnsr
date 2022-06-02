targetScope = 'resourceGroup'

param prefix string
param postfix string
param location string
param cidervnet string
param cidersubnet string
param ciderdnsrin string
param ciderdnsrout string

resource vnet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: prefix
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
      {
        name: 'dnsrin'
        properties: {
          addressPrefix: ciderdnsrin
        }
      }
      {
        name: 'dnsrout'
        properties: {
          addressPrefix: ciderdnsrout
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


resource rt 'Microsoft.Network/routeTables@2021-05-01' = {
  name: '${prefix}${postfix}'
  location: location
  properties: {
    disableBgpRoutePropagation: false
    routes: []
  }
}

resource pdns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: '${prefix}.org'
  location: 'global'
}

resource pdnslink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: pdns
  name: prefix
  location: 'global'
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: vnet.id
    }
  }
}

@description('VNet Name')
output vnetname string = vnet.name
