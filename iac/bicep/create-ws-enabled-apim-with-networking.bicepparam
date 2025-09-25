using './create-ws-enabled-apim-with-networking.bicep'

param apimName = 'aaa-scus-premium-apim-dev'
param location = 'eastus2'
param apimSku = 'Premium'
param apimCapacity = 1
param vnetName = 'aaa-scus-premium-apim-vnet'
param privateSubnetName2  = 'apim-subnet-private1'
param privateSubnetName1  = 'apim-subnet-private2'
param vnetAddressPrefix = '10.23.0.0/16'
param publicSubnetAddressPrefix = '10.23.1.0/24'
param privateSubnetAddressPrefix = '10.23.2.0/24'
