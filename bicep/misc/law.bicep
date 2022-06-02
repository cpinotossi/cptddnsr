targetScope='resourceGroup'

var parameters = json(loadTextContent('parameters.json'))
param location string = resourceGroup().location


resource law 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: parameters.prefix
  location: location
}

resource vmhub 'Microsoft.Compute/virtualMachines@2021-07-01' existing = {
  name: '${parameters.prefix}hub'
}

resource vmspoke 'Microsoft.Compute/virtualMachines@2021-07-01' existing = {
  name: '${parameters.prefix}spoke'
}

resource vmop 'Microsoft.Compute/virtualMachines@2021-07-01' existing = {
  name: '${parameters.prefix}op'
}

resource fw 'Microsoft.Network/azureFirewalls@2021-03-01' existing = {
  name: parameters.prefix
}

resource diaagw 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: parameters.prefix
  properties: {
    workspaceId: law.id
  }
  scope: fw
}


