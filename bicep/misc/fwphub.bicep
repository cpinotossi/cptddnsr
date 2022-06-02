param firewallPolicies_cptdvnet_name string = 'cptdvnet'

resource firewallPolicies_cptdvnet_name_resource 'Microsoft.Network/firewallPolicies@2020-11-01' = {
  name: firewallPolicies_cptdvnet_name
  location: 'eastus'
  properties: {
    sku: {
      tier: 'Premium'
    }
    threatIntelMode: 'Alert'
    intrusionDetection: {
      mode: 'Off'
    }
  }
}

resource firewallPolicies_cptdvnet_name_firewallPolicies_cptdvnet_name 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2020-11-01' = {
  parent: firewallPolicies_cptdvnet_name_resource
  name: '${firewallPolicies_cptdvnet_name}'
  location: 'eastus'
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
        name: 'cptdvnet'
        priority: 2000
      }
    ]
  }
}