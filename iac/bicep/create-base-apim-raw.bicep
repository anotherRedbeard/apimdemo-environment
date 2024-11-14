@description('The name of the API Management service instance')
param apimName string = 'apiservice${uniqueString(resourceGroup().id)}'

@description('The email address of the owner of the service')
@minLength(1)
param adminEmail string

@description('The name of the owner of the service')
@minLength(1)
param orgName string

@description('The pricing tier of this API Management service')
@allowed([
  'Consumption'
  'Developer'
  'Basic'
  'Basicv2'
  'Standard'
  'Standardv2'
  'Premium'
])
param apimSku string = 'Developer'

@description('The instance size of this API Management service.')
@allowed([
  0
  1
  2
])
param apimCapacity int = 1

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Location for all resources.')
@allowed([
  'Enabled'
  'Disabled'
])
param developerPortalStatus string = 'Enabled'

resource apiManagementService 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: apimName
  location: location
  sku: {
    name: apimSku
    capacity: apimCapacity
  }
  properties: {
    publisherEmail: adminEmail
    publisherName: orgName
    developerPortalStatus: developerPortalStatus
  }
}
