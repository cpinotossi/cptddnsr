param azureFirewalls_cptdvnet_name string = 'cptdvnet'
param publicIPAddresses_cptdvnetfirewall_externalid string = '/subscriptions/4896a771-b1ab-4411-bd94-3c8467f1991e/resourceGroups/cptdvnet/providers/Microsoft.Network/publicIPAddresses/cptdvnetfirewall'
param virtualNetworks_cptdvnethub_externalid string = '/subscriptions/4896a771-b1ab-4411-bd94-3c8467f1991e/resourceGroups/cptdvnet/providers/Microsoft.Network/virtualNetworks/cptdvnethub'
param firewallPolicies_cptdvnet_externalid string = '/subscriptions/4896a771-b1ab-4411-bd94-3c8467f1991e/resourceGroups/cptdvnet/providers/Microsoft.Network/firewallPolicies/cptdvnet'

resource azureFirewalls_cptdvnet_name_resource 'Microsoft.Network/azureFirewalls@2020-11-01' = {
  name: azureFirewalls_cptdvnet_name
  location: 'eastus'
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Premium'
    }
    threatIntelMode: 'Alert'
    additionalProperties: {}
    ipConfigurations: [
      {
        name: azureFirewalls_cptdvnet_name
        properties: {
          publicIPAddress: {
            id: publicIPAddresses_cptdvnetfirewall_externalid
          }
          subnet: {
            id: '${virtualNetworks_cptdvnethub_externalid}/subnets/AzureFirewallSubnet'
          }
        }
      }
    ]
    networkRuleCollections: []
    applicationRuleCollections: []
    natRuleCollections: []
    firewallPolicy: {
      id: firewallPolicies_cptdvnet_externalid
    }
  }
}