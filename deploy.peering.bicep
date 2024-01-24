targetScope='subscription'

param rgsourcename string
param rgtargetname string
param vnetsourcename string
param vnettargetname string

module peeringhub2op 'azbicep/bicep/vpeer.bicep' = {
  name: 'peeringhub2op'
  scope: resourceGroup(rgsourcename)
  params: {
    rgsourcename: rgsourcename
    rgtargetname: rgtargetname
    vnetsourcename: vnetsourcename
    vnettargetname: vnettargetname
    useremotegateway: false
  }
}

module peeringop2hub 'azbicep/bicep/vpeer.bicep' = {
  name: 'peeringop2hub'
  scope: resourceGroup(rgtargetname)
  params: {
    rgsourcename: rgtargetname
    rgtargetname: rgsourcename
    vnetsourcename: vnettargetname
    vnettargetname: vnetsourcename
    useremotegateway: false
  }
}

