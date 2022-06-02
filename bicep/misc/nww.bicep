targetScope='resourceGroup'

param prefix string = 'cptd'
param location string = 'eastus'
param deploy bool = true

resource watcher 'Microsoft.Network/networkWatchers@2020-11-01'  = if (deploy) {
  name: prefix
  location: location
}

resource law 'Microsoft.OperationalInsights/workspaces@2021-06-01' = if (deploy) {
  name: prefix
  location: location
}

resource fw 'Microsoft.Network/azureFirewalls@2021-03-01' existing = {
  name: prefix
}

resource diafw 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: prefix
  properties: {
    workspaceId: law.id
  }
  scope: fw
}
