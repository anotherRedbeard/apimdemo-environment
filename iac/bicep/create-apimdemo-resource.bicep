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

@description('The name of the event hub namespace.')
param eventHubNS string = 'eventHubNS'

@description('The name of the eventhub instance.')
param eventHubName string = 'eventHubName'

//event hub resource
module namespace 'br/public:avm/res/event-hub/namespace:0.4.0' = {
  name: 'namespaceDeployment'
  params: {
    // Required parameters
    name: eventHubNS
    // Non-required parameters
    location: location
    managedIdentities: {
      systemAssigned: true
    }
    requireInfrastructureEncryption: true
    skuName: 'Basic'
    authorizationRules: [
      {
        name: 'RootManageSharedAccessKey'
        rights: [
          'Listen'
          'Manage'
          'Send'
        ]
      }
    ]
    eventhubs: [
      {
        name: eventHubName
        messageRetentionInDays: 1
        retentionDescriptionCleanupPolicy: 'Delete'
        retentionDescriptionRetentionTimeInHours: 3
        partitionCount: 2
        status: 'Active'
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
