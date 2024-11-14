using './create-base-apim-raw.bicep'

param apimName = '<your-apim-name>'
param location = '<azure-region>'
param orgName = '<orginization-name>'
param adminEmail = '<administrator-email>'
param apimSku = 'Developer'
param apimCapacity = 1
param developerPortalStatus = 'Enabled'
