targetScope='resourceGroup'

//var parameters = json(loadTextContent('parameters.json'))
param location string
var username = 'chpinoto'
var password = 'demo!pass123'
param prefix string
param myobjectid string
// param myip string

module vnethubmodule 'vnethub.bicep' = {
  name: 'vnethubdeploy'
  params: {
    postfix: 'hub'
    prefix: prefix
    location: location
    cidervnet: '10.5.0.0/16'
    cidersubnet: '10.5.0.0/24'
    ciderbastion: '10.5.1.0/24'
    ciderdnsrin: '10.5.2.0/28'
    ciderdnsrout: '10.5.2.16/28'
  }
}

module vnetspoke1module 'vnetspoke1.bicep' = {
  name: 'vnetspoke1deploy'
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

module vnetspoke2module 'vnetspoke2.bicep' = {
  name: 'vnetspoke2deploy'
  params: {
    prefix: prefix
    postfix: 'spoke2'
    location: location
    cidervnet: '10.4.0.0/16'
    cidersubnet: '10.4.0.0/24'
    ciderbastion: '10.4.1.0/24'
  }
}

module pdnshub 'pdns.bicep' = {
  name: 'pdnshubdeploy'
  params: {
    postfix: 'hub'
    prefix: prefix
    autoreg: false
    fqdn: '${prefix}.org'
  }
  dependsOn:[
    vnetspoke1module
    vnetspoke2module
  ]
}

module pdnsspoke1 'pdns.bicep' = {
  name: 'pdnsspoke1deploy'
  params: {
    postfix: 'spoke1'
    prefix: prefix
    autoreg: true
    fqdn: '${prefix}.org'
  }
  dependsOn:[
    pdnshub
  ]
}

module pdnsspoke2 'pdns.bicep' = {
  name: 'pdnsspoke2deploy'
  params: {
    postfix: 'spoke2'
    prefix: prefix
    autoreg: true
    fqdn: '${prefix}.org'
  }
  dependsOn:[
    pdnsspoke1
  ]
}

module vmspoke1module 'vm.bicep' = {
  name: 'vmspoke1deploy'
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

module vmspoke2module 'vm.bicep' = {
  name: 'vmspoke2deploy'
  params: {
    prefix: prefix
    postfix: 'spoke2'
    vnetname: vnetspoke2module.outputs.vnetname
    location: location
    username: username
    password: password
    myObjectId: myobjectid
    privateip: '10.4.0.4'
    imageRef: 'linux'
  }
  dependsOn:[
    vnetspoke1module
  ]
}

module peeringhubspoke1 'peer.bicep' = {
  name: 'peeringhubspoke1'
  params: {
    hub:'hub' 
    prefix: prefix
    spoke: 'spoke1'
  }
  dependsOn:[
    vnethubmodule
    vnetspoke1module
  ]
}

// module sab 'sab.bicep' = {
//   name: 'sabdeploy'
//   params: {
//     prefix: prefix
//     location: location
//     myip: myip
//     myObjectId: myobjectid
//   }
// }
