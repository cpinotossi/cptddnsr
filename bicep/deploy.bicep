targetScope='resourceGroup'

//var parameters = json(loadTextContent('parameters.json'))
param location string
var username = 'chpinoto'
var password = 'demo!pass123'
param prefix string
param myobjectid string
param myip string

module vnethubmodule 'vnethub.bicep' = {
  name: 'vnethubdeploy'
  params: {
    prefix: prefix
    location: location
    cidervnet: '10.2.0.0/16'
    cidersubnet: '10.2.0.0/24'
    ciderbastion: '10.2.1.0/24'
    ciderdnsrin: '10.2.2.0/28'
    ciderdnsrout: '10.2.2.16/28'
  }
}

module vnetspokemodule 'vnetspoke.bicep' = {
  name: 'vnetspokedeploy'
  params: {
    prefix: prefix
    postfix: 'spoke'
    location: location
    cidervnet: '10.3.0.0/16'
    cidersubnet: '10.3.1.0/24'
  }
}


module vmspokemodule 'vm.bicep' = {
  name: 'vmdeploy'
  params: {
    prefix: prefix
    postfix: ''
    vnetname: vnetspokemodule.outputs.vnetname
    location: location
    username: username
    password: password
    myObjectId: myobjectid
    privateip: '10.3.1.4'
    imageRef: 'windows'
  }
  dependsOn:[
    vnetspokemodule
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
