using './create-ws-enabled-apim-with-networking.bicep'

param apimName = '<your-apim-name>'
param location = '<azure-region>'
param orgName = '<orginization-name>'
param adminEmail = '<administrator-email>'
param apimSku = 'Developer'
param apimCapacity = 1
param vnetName = 'vnetName'
param privateSubnetName1  = 'privateSubnetName1'
param privateSubnetName2  = 'privateSubnetName2'
param vnetAddressPrefix = '<vnetAddressPrefix>'
param publicSubnetAddressPrefix = '<publicSubnetAddressPrefix>'
param privateSubnetAddressPrefix = '<privateSubnetAddressPrefix>'

param apis = [
  {
    name: '<api-name>'
    displayName: '<api-display-name>'
    description: '<api-description>'
    path: '<api-path>'
    serviceUrl: '<api-service-url>'
    openApiSpecUrl: '<api-openapi-spec-url>'
    subscriptionRequired: true
    protocols: [
      'https'
    ]
    apiType: 'http'
    format: 'openapi+json-link'
    subscriptionKeyParameterNames: {
      header: '<api-header>'
      query: '<api-query>'
    }
  }
]

param workspaceApis = [
  {
    workspaceName: '<workspace-name>'
    name: '<api-name>'
    displayName: '<api-display-name>'
    description: '<api-description>'
    path: '<api-path>'
    serviceUrl: '<api-service-url>'
    openApiSpecUrl: '<api-openapi-spec-url>'
    subscriptionRequired: true
    protocols: [
      'https'
    ]
    apiType: 'http'
    format: 'openapi+json-link'
    subscriptionKeyParameterNames: {
      header: '<api-header>'
      query: '<api-query>'
    }
  }
]
