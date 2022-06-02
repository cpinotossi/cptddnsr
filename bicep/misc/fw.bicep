targetScope='resourceGroup'

param prefix string = 'cptd'
param location string = 'eastus'


resource pubipfw 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
  name: '${prefix}firewall'
  location: location
  sku: {
    name:'Standard'
  }
  properties: {
    publicIPAllocationMethod:'Static'
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' existing = {
  name: '${prefix}hub'
}

resource fw 'Microsoft.Network/azureFirewalls@2020-05-01' = {
  name: prefix
  location: location
  properties: {
    ipConfigurations: [
      {
        name: prefix
        properties: {
          subnet: {
            id: '${vnet.id}/subnets/AzureFirewallSubnet'
          }
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses',pubipfw.name)
          }
        }
      }
    ]
    sku: {
      tier: 'Premium'
    }
    firewallPolicy: {
      id: resourceId('Microsoft.Network/firewallPolicies',fwpolicies.name)
    }
  }
}

resource fwpolicies 'Microsoft.Network/firewallPolicies@2020-11-01' = {
  name: prefix
  properties: {
    sku: {
      tier: 'Premium'
    }
    intrusionDetection: {
      mode: 'Off'
    }
  }
  location: location
}

resource fwrule 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2020-11-01' = {
  parent: fwpolicies
  name: prefix
  properties: {
    priority: 2000
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'spoke1'
            ipProtocols: [
              'ICMP'
            ]
            sourceAddresses: [
              '10.2.0.0/16'
            ]
            sourceIpGroups: []
            destinationAddresses: [
              '*'
            ]
            destinationIpGroups: []
            destinationFqdns: []
            destinationPorts: [
              '*'
            ]
          }
          {
            ruleType: 'NetworkRule'
            name: 'spoke2'
            ipProtocols: [
              'ICMP'
            ]
            sourceAddresses: [
              '192.168.0.0/16'
            ]
            sourceIpGroups: []
            destinationAddresses: [
              '*'
            ]
            destinationIpGroups: []
            destinationFqdns: []
            destinationPorts: [
              '*'
            ]
          }
        ]
        name: prefix
        priority: 2000
      }
    ]
  }
}
