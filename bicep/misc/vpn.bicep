targetScope='resourceGroup'

var parameters = json(loadTextContent('parameters.json'))

@description('Route based or policy based')
@allowed([
  'RouteBased'
  'PolicyBased'
])
param vpnType string = 'RouteBased'

@description('Public IP of your StrongSwan Instance')
param localGatewayIpAddress string = '1.1.1.1'


@description('The Sku of the Gateway. This must be one of Basic, Standard or HighPerformance.')
@allowed([
  'Basic'
  'Standard'
  'HighPerformance'
])

param gatewaySku string = 'Basic'

@description('Shared key (PSK) for IPSec tunnel')
@secure()
param sharedKey string = 'demo!pass123'
param location string = resourceGroup().location

var gatewaySubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets/', '${parameters.prefix}hub', 'GatewaySubnet')

resource vnethub 'Microsoft.Network/virtualNetworks@2015-06-15' existing = {
  name: '${parameters.prefix}hub'
}

resource vnetop 'Microsoft.Network/virtualNetworks@2015-06-15' existing = {
  name: '${parameters.prefix}op'
}


resource localgateway 'Microsoft.Network/localNetworkGateways@2020-08-01' = {
  name: parameters.prefix
  location: location
  properties: {
    localNetworkAddressSpace: {
      addressPrefixes: first(vnetop.properties.addressSpace.addressPrefixes)
    }
    gatewayIpAddress: localGatewayIpAddress
  }
}

resource gatewayconnection 'Microsoft.Network/connections@2020-07-01' = {
  name: parameters.prefix
  location: location
  properties: {
    virtualNetworkGateway1: {
      id: gateway.id
    }
    localNetworkGateway2: {
      id: localgateway.id
    }
    connectionType: 'IPsec'
    routingWeight: 10
    sharedKey: sharedKey
  }
}

resource pubipgateway 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: '${parameters.prefix}pubipgateway'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource gateway 'Microsoft.Network/virtualNetworkGateways@2015-06-15' = {
  name: parameters.prefix
  location: location
  properties: {
    ipConfigurations: [
      {
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: gatewaySubnetRef
          }
          publicIPAddress: {
            id: pubipgateway.id
          }
        }
        name: parameters.prefix
      }
    ]
    sku: {
      name: 'Basic'
      tier: 'Basic'
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: false
  }
}

