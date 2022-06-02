targetScope='resourceGroup'

//var parameters = json(loadTextContent('parameters.json'))
param location string
var username = 'chpinoto'
var password = 'demo!pass123'
param prefix string
param myobjectid string
param myip string

module vnetmodule 'vnet.bicep' = {
  name: 'vnetdeploy'
  params: {
    prefix: prefix
    postfix: ''
    location: location
    cidervnet: '10.3.0.0/16'
    cidersubnet: '10.3.1.0/24'
    ciderdnsrin: '10.3.2.0/28'
    ciderdnsrout: '10.3.2.16/28'
  }
}

module vmmodule 'vm.bicep' = {
  name: 'vmdeploy'
  params: {
    prefix: prefix
    postfix: ''
    vnetname: vnetmodule.outputs.vnetname
    location: location
    username: username
    password: password
    myObjectId: myobjectid
    privateip: '10.3.1.4'
    //customData: loadTextContent('vm.yaml')
    imageRef: 'windows'
  }
  dependsOn:[
    vnetmodule
  ]
}

module vmm2odule 'vm.bicep' = {
  name: 'vm2deploy'
  params: {
    prefix: '${prefix}2'
    postfix: ''
    vnetname: vnetmodule.outputs.vnetname
    location: location
    username: username
    password: password
    myObjectId: myobjectid
    privateip: '10.3.1.5'
    //customData: loadTextContent('vm.yaml')
    imageRef: 'windows'
  }
  dependsOn:[
    vnetmodule
  ]
}
// module law 'law.bicep' = {
//   name: 'lawdeploy'
//   params: {
//     prefix: prefix
//     location: location
//   }
// }

module sab 'sab.bicep' = {
  name: 'sabdeploy'
  params: {
    prefix: prefix
    location: location
    myip: myip
    myObjectId: myobjectid
  }
}
