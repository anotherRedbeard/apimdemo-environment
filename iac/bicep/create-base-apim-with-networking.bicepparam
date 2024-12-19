using './create-base-apim-with-networking.bicep'

param apimName = '<your-apim-name>'
param location = '<azure-region>'
param orgName = '<orginization-name>'
param adminEmail = '<administrator-email>'
param apimSku = 'Developer'
param apimCapacity = 1
param vnetName = 'vnetName'
param publicSubnetName  = 'publicSubnetName'
param privateSubnetName  = 'privateSubnetName'
param vnetAddressPrefix = '<vnetAddressPrefix>'
param publicSubnetAddressPrefix = '<publicSubnetAddressPrefix>'
param privateSubnetAddressPrefix = '<privateSubnetAddressPrefix>'

