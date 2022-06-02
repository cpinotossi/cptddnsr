targetScope='resourceGroup'

param prefix string = 'cptd'
param location string = 'eastus'
var name = '${prefix}spoke'

resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' existing = {
  name: name
}

resource nic 'Microsoft.Network/networkInterfaces@2020-08-01' existing = {
  name: name
}

resource pubip 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
  name: '${prefix}lb'
  location: location
  sku: {
    name:'Standard'
  }
  properties: {
    publicIPAllocationMethod:'Static'
  }
}

resource lb 'Microsoft.Network/loadBalancers@2021-03-01' = {
  name: name
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: name
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pubip.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name:name
        properties: {
          loadBalancerBackendAddresses: [
            {
              name:name
              properties:{
                ipAddress: '10.2.0.4'
                loadBalancerFrontendIPConfiguration: {
                  id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', name, name)
                }
                virtualNetwork: {
                  id: vnet.id
                }
                subnet: {
                  id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, name)
                }
              }
            }
          ]
        }
      }
    ]
    loadBalancingRules: []
    probes: [
      {
        name: name
        properties: {
          protocol: 'Http'
          port: 80
          requestPath: '/'
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
    inboundNatRules: [
      {
        name: name
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', name, name)
          }
          backendPort: 80
          enableFloatingIP: false
          enableTcpReset: false

          frontendPort: 80
          protocol: 'Tcp'
        }
      }
    ]
    inboundNatPools: []
    outboundRules: [
      {
        name: name
        properties: {
          allocatedOutboundPorts: 0
          protocol: 'All'
          enableTcpReset: true
          idleTimeoutInMinutes: 4
          
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', name, name)
          }
          frontendIPConfigurations: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', name, name)
            }
          ]

        }
      }
    ]
  }
}



