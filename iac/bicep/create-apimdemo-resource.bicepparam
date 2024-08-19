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
