targetScope = 'subscription'

@description('Name of the Resource Group to ensure exists')
param rgName string

@description('Azure region for the Resource Group')
param rgLocation string

@description('Environment name used for tagging (e.g. dev, test, prod)')
param environment string = 'dev'

var tags = {
  environment: environment
}

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: rgLocation
  tags: tags
}

output resourceGroupName string = rg.name
output resourceGroupLocation string = rg.location
