targetScope='subscription'
// targetScope = 'managementGroup'

param prefix string
// param location string = deployment().location
param location string
param myobjectid string
param myip string
param oprgname string
param opvnetname string
param opdnsip string
param opfqdn string

var username = 'chpinoto'
var password = 'demo!pass123'
var opdnsiparray = [
  {
    ipaddress: opdnsip
    port: 53
  }
]

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: prefix
  location: location
}

module vnethubmodule 'azbicep/bicep/vnetpdnsr.bicep' = {
  name: 'vnethubdeploy'
  scope: resourceGroup(prefix)
  params: {
    postfix: 'hub'
    prefix: prefix
    location: location
    cidervnet: '10.2.0.0/16'
    cidersubnet: '10.2.0.0/24'
    ciderbastion: '10.2.1.0/24'
    ciderdnsrin: '10.2.2.0/28'
    ciderdnsrout: '10.2.2.16/28'
  }
  dependsOn:[
    rg
  ]
}

module vnetspoke1module 'azbicep/bicep/vnetspoke.bicep' = {
  name: 'vnetspoke1deploy'
  scope: resourceGroup(prefix)
  params: {
    prefix: prefix
    postfix: 'spoke1'
    location: location
    cidervnet: '10.3.0.0/16'
    cidersubnet: '10.3.0.0/24'
  }
  dependsOn:[
    vnethubmodule
  ]
}

module pdnshubmodule 'azbicep/bicep/pdns.bicep' = {
  name: 'pdnshubdeploy'
  scope: resourceGroup(prefix)
  params: {
    vnetname: vnethubmodule.outputs.vnetname
    prefix: prefix
    autoreg: true
    fqdn: '${prefix}.org'
  }
  dependsOn:[
    vnethubmodule
  ]
}

module pdnsspoke1module 'azbicep/bicep/pdns.bicep' = {
  name: 'pdnsspoke1deploy'
  scope: resourceGroup(prefix)
  params: {
    vnetname: vnetspoke1module.outputs.vnetname
    prefix: prefix
    autoreg: true
    fqdn: '${prefix}.org'
  }
  dependsOn:[
    vnetspoke1module
  ]
}

module vmhubmodule 'azbicep/bicep/vm.bicep' = {
  name: 'vmhubdeploy'
  scope: resourceGroup(prefix)
  params: {
    prefix: prefix
    postfix: 'hub'
    vnetname: vnethubmodule.outputs.vnetname
    location: location
    username: username
    password: password
    myObjectId: myobjectid
    privateip: '10.2.0.4'
    imageRef: 'linux'
  }
  dependsOn:[
    vnetspoke1module
  ]
}

module vmspoke1module 'azbicep/bicep/vm.bicep' = {
  name: 'vmspoke1deploy'
  scope: resourceGroup(prefix)
  params: {
    prefix: prefix
    postfix: 'spoke1'
    vnetname: vnetspoke1module.outputs.vnetname
    location: location
    username: username
    password: password
    myObjectId: myobjectid
    privateip: '10.3.0.4'
    imageRef: 'linux'
  }
  dependsOn:[
    vnetspoke1module
  ]
}

module peeringhub2spoke 'azbicep/bicep/vpeer.bicep' = {
  name: 'peeringhub2spoke'
  scope: resourceGroup(prefix)
  params: {
    rgsourcename: prefix
    rgtargetname: prefix
    vnetsourcename: vnethubmodule.outputs.vnetname
    vnettargetname: vnetspoke1module.outputs.vnetname
    useremotegateway: false
  }
  dependsOn:[
    vnethubmodule
    vnetspoke1module
  ]
}

module peeringspoke2hub 'azbicep/bicep/vpeer.bicep' = {
  name: 'peeringspoke2hub'
  scope: resourceGroup(prefix)
  params: {
    rgsourcename: prefix
    rgtargetname: prefix
    vnetsourcename: vnetspoke1module.outputs.vnetname
    vnettargetname: vnethubmodule.outputs.vnetname
    useremotegateway: false
  }
  dependsOn:[
    vnethubmodule
    vnetspoke1module
  ]
}

module peeringhub2op 'azbicep/bicep/vpeer.bicep' = {
  name: 'peeringhub2op'
  scope: resourceGroup(prefix)
  params: {
    rgsourcename: prefix
    rgtargetname: oprgname
    vnetsourcename: vnethubmodule.outputs.vnetname
    vnettargetname: opvnetname
    useremotegateway: false
  }
  dependsOn:[
    vnethubmodule
  ]
}

module peeringop2hub 'azbicep/bicep/vpeer.bicep' = {
  name: 'peeringop2hub'
  scope: resourceGroup(oprgname)
  params: {
    rgsourcename: oprgname
    rgtargetname: prefix
    vnetsourcename: opvnetname
    vnettargetname: vnethubmodule.outputs.vnetname
    useremotegateway: false
  }
  dependsOn:[
    vnethubmodule
  ]
}

module pdnsrmodule 'azbicep/bicep/pdnsr.bicep' = {
  name: 'pdnsrmodule'
  scope: resourceGroup(prefix)
  params: {
    location: location
    resolverVNETName: vnethubmodule.outputs.vnetname
    dnsResolverName: prefix
    dnsrsubnetoutname: vnethubmodule.outputs.dnsrsubnetoutname
    dnsrsubnetinname: vnethubmodule.outputs.dnsrsubnetinname
    forwardingRuleName: prefix
    forwardingRulesetName: prefix
    resolvervnetlink:prefix
    targetDNS:opdnsiparray
    DomainName: opfqdn
  }
  dependsOn:[
    vnethubmodule
  ]
}

module sab 'azbicep/bicep/sab.bicep' = {
  name: 'sabdeploy'
  scope: resourceGroup(prefix)
  params: {
    prefix: prefix
    location: location
    myObjectId: myobjectid
    postfix: ''
  }
}


