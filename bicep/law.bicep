targetScope='resourceGroup'

param prefix string
param location string

resource law 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: prefix
  location: location
  properties: {
    sku:{
      name: 'PerGB2018'
    }
    retentionInDays:30
  }
}
