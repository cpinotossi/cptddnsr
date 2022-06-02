targetScope='resourceGroup'

param prefix string = 'cptd'
param location string = 'eastus'

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: prefix
  location: location
  properties: {
    securityRules: [
      {
        name: 'http'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    ]
  }
}

resource prefix_http 'Microsoft.Network/networkSecurityGroups/securityRules@2020-11-01' = {
  parent: nsg
  name: 'http'
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '80'
    sourceAddressPrefix: '*'
    destinationAddressPrefix: '*'
    access: 'Allow'
    priority: 100
    direction: 'Inbound'
    sourcePortRanges: []
    destinationPortRanges: []
    sourceAddressPrefixes: []
    destinationAddressPrefixes: []
  }
}
