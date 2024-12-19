@description('Provide the name of the apim instance.')
param apimName string = 'apimName'

@description('Provide the location of the apim instance.')
param location string = resourceGroup().location

@description('Provide the name of the organization.')
param orgName string = 'Organization Name'

@description('Provide the administrator email address.')
param adminEmail string = 'admin@email.com'

@allowed([
  'Basic'
  'BasicV2'
  'Consumption'
  'Developer'
  'Premium'
  'Standard'
  'StandardV2'
])
@description('The name of the api management sku.')
param apimSku string = 'Developer'

@description('The number of scale units to deployname of the api management sku.')
param apimCapacity int = 1

@description('The name of the virtual network.')
param vnetName string = 'vnetName'

@description('The name of the public subnet.')
param publicSubnetName string = 'publicSubnetName'

@description('The name of the private subnet.')
param privateSubnetName string = 'privateSubnetName'

@description('The address prefix for the virtual network.')
param vnetAddressPrefix string

@description('The address prefix for the public subnet.')
param publicSubnetAddressPrefix string

@description('The address prefix for the private subnet.')
param privateSubnetAddressPrefix string

module virtualNetwork 'br/public:avm/res/network/virtual-network:0.5.1' = {
  name: 'vnetDeployment'
  params: {
    name: vnetName
    location: location
    addressPrefixes: [
      vnetAddressPrefix
    ]
    subnets: [
      {
        name: publicSubnetName
        addressPrefix: publicSubnetAddressPrefix
        delegation: 'Microsoft.Web/serverFarms'
      }
      {
        name: privateSubnetName
        addressPrefix: privateSubnetAddressPrefix
        delegation: 'Microsoft.Web/hostingEnvironments'
      }
    ]
  }
}

module service 'br/public:avm/res/api-management/service:0.1.7' = {
  name: 'apimServiceDeployment'
  params: {
    // Required parameters
    name: apimName
    publisherEmail: adminEmail
    publisherName: orgName
    // Non-required parameters
    sku: apimSku
    skuCount: apimCapacity 
    location: location
    managedIdentities: {
      systemAssigned: true
    }
  }
}
