targetScope='resourceGroup'

@description('name of the new virtual network where DNS resolver will be created')
param resolverVNETName string

@description('name of the dns private resolver')
param dnsResolverName string

@description('the location for resolver VNET and dns private resolver - Azure DNS Private Resolver available in specific region, refer the documenation to select the supported region for this deployment. For more information https://docs.microsoft.com/azure/dns/dns-private-resolver-overview#regional-availability')
param location string

@description('name of the subnet that will be used for private resolver inbound endpoint')
param dnsrsubnetinname string = 'snet-inbound'

@description('name of the subnet that will be used for private resolver outbound endpoint')
param dnsrsubnetoutname string

@description('name of the vnet link that links outbound endpoint with forwarding rule set')
param resolvervnetlink string

@description('name of the forwarding ruleset')
param forwardingRulesetName string

@description('name of the forwarding rule name')
param forwardingRuleName string

@description('the target domain name for the forwarding ruleset')
param DomainName string

@description('the list of target DNS servers ip address and the port number for conditional forwarding')
param targetDNS array

resource resolver 'Microsoft.Network/dnsResolvers@2022-07-01' = {
  name: dnsResolverName
  location: location
  properties: {
    virtualNetwork: {
      id: resolverVnet.id
    }
  }
}

resource inEndpoint 'Microsoft.Network/dnsResolvers/inboundEndpoints@2022-07-01' = {
  parent: resolver
  name: dnsrsubnetinname
  location: location
  properties: {
    ipConfigurations: [
      {
        privateIpAllocationMethod: 'Dynamic'
        subnet: {
          id: '${resolverVnet.id}/subnets/${dnsrsubnetinname}'
        }
      }
    ]
  }
}

resource outEndpoint 'Microsoft.Network/dnsResolvers/outboundEndpoints@2022-07-01' = {
  parent: resolver
  name: dnsrsubnetoutname
  location: location
  properties: {
    subnet: {
      id: '${resolverVnet.id}/subnets/${dnsrsubnetoutname}'
    }
  }
}

resource fwruleSet 'Microsoft.Network/dnsForwardingRulesets@2022-07-01' = {
  name: forwardingRulesetName
  location: location
  properties: {
    dnsResolverOutboundEndpoints: [
      {
        id: outEndpoint.id
      }
    ]
  }
}

resource resolverLink 'Microsoft.Network/dnsForwardingRulesets/virtualNetworkLinks@2022-07-01' = {
  parent: fwruleSet
  name: resolvervnetlink
  properties: {
    virtualNetwork: {
      id: resolverVnet.id
    }
  }
}

resource fwRules 'Microsoft.Network/dnsForwardingRulesets/forwardingRules@2022-07-01' = {
  parent: fwruleSet
  name: forwardingRuleName
  properties: {
    domainName: DomainName
    targetDnsServers: targetDNS
  }
}

resource resolverVnet 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  name: resolverVNETName
}
