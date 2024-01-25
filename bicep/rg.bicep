targetScope = 'subscription'

param location string
param name string
resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: name
  location: location
}
