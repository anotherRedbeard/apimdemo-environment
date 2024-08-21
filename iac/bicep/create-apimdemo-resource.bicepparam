using './create-apimdemo-resource.bicep'

param apimName = '<your-apim-name>'
param location = '<azure-region>'
param orgName = '<orginization-name>'
param adminEmail = '<administrator-email>'
param apimSku = 'Developer'
param apimCapacity = 1
param eventHubNS = 'eventHubNS'
param eventHubName = 'eventHubName'
param clientId = '<clientId>'
param clientSecret = '<clientSecret>'
param tenantName = '<tenantName>'
param authServerEndpointUrl = '<authServerEndpointUrl>'
param apimKeyVaultName = '<apimKeyVaultName>'
param lawName = '<lawName>'
param appInsightsName = '<appInsightsName>'
param aoaiResources = [
  {
    aoaiName: 'aoaiResourceName'
    location: 'aoaiResourceLocation'
    deployments: {
      model: {
        format: 'aoaiDeploymentModelFormat'
        name: 'aoaiDeploymentModelName'
        version: 'aoaiDeploymentModelVersion'
      }
      name: 'aoaiDeploymentName'
      sku: {
        name: 'skuName'
        capacity: 'skuCapacity'
      }
    }
  }
]

