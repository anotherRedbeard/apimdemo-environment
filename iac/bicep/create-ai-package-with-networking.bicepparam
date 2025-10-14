using './create-ai-package-with-networking.bicep'

param apimName = '<your-apim-name>'
param location = '<azure-region>'
param orgName = '<orginization-name>'
param adminEmail = '<administrator-email>'
param apimSku = 'Developer'
param apimCapacity = 1
param vnetName = 'vnetName'
param privateSubnetName  = 'privateSubnetName'
param privateSubnetName2  = 'privateSubnetName2'
param privateSubnetName3  = 'privateSubnetName3'
param vnetAddressPrefix = '<vnetAddressPrefix>'
param privateSubnetAddressPrefix = '<privateSubnetAddressPrefix>'
param privateSubnet2AddressPrefix = '<privateSubnet2AddressPrefix>'
param privateSubnet3AddressPrefix = '<privateSubnet3AddressPrefix>'
param foundryDnsZoneIds = [
  '<dns-zone-id-1>'
  '<dns-zone-id-2>'
]

