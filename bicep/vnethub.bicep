targetScope = 'resourceGroup'

param prefix string
param location string
param cidervnet string
param cidersubnet string
param ciderbastion string
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
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: ciderbastion
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
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

resource pubipbastion 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
  name: '${prefix}bastion'
  location: location
  sku: {
    name:'Standard'
  }
  properties: {
    publicIPAllocationMethod:'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2021-03-01' = {
  name: '${prefix}bastion'
  location: location
  sku: {
    name:'Standard'
  }
  properties: {
    dnsName:'${prefix}.bastion.azure.com'
    enableTunneling: true
    ipConfigurations: [
      {
        name: '${prefix}bastion'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pubipbastion.id
          }
          subnet: {
            id: '${vnet.id}/subnets/AzureBastionSubnet'
          }
        }
      }
    ]
  }
}

@description('VNet Name')
output vnetname string = vnet.name
