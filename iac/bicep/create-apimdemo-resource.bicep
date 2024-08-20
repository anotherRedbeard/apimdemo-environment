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

@description('Client Id for the identity provider.')
param clientId string = '<clientId>'

@description('Client Secret for the identity provider.')
@secure()
param clientSecret string

@description('The tenant name for the identity provider.')
param tenantName string = '<tenantName>'

@description('The main endpoint url for the auth server.')
param authServerEndpointUrl string = '<authServerEndpointUrl>'

@description('Name of the APIM keyvault.')
param apimKeyVaultName string = '<apimKeyVaultName>'

@description('Name of the log analytics workspace.')
param lawName string = '<lawName>'

@description('Name of the app insights resource.')
param appInsightsName string = '<appInsightsName>'

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
    authorizationServers: {
      secureList: [
        {
          authorizationEndpoint: '${authServerEndpointUrl}/oauth2/v2.0/authorize'
          authorizationMethods: [
            'GET'
            'POST'
          ]
          clientAuthenticationMethod: [
            'Body'
          ]
          clientId: clientId
          clientRegistrationEndpoint: 'https://localhost'
          clientSecret: clientSecret
          defaultScope: 'User.Read'
          grantTypes: [
            'authorizationCode'
            'authorizationCodeWithPkce'
          ]
          name: 'AAD-OAuth'
          tokenEndpoint: '${authServerEndpointUrl}/oauth2/v2.0/token'
        }
      ]
    }
    identityProviders: [
      {
        allowedTenants: [
          tenantName
        ]
        authority: 'login.windows.net'
        clientId: clientId
        clientSecret: clientSecret
        clientLibrary: 'MSAL-2'
        name: 'aad'
        signinTenant: tenantName
      }
    ]
    location: location
    managedIdentities: {
      systemAssigned: true
    }
    sku: apimSku
    skuCount: apimCapacity
  }
}

module vault 'br/public:avm/res/key-vault/vault:0.7.1' = {
  name: 'vaultDeployment'
  params: {
    // Required parameters
    name: apimKeyVaultName
    // Non-required parameters
    enablePurgeProtection: false
    enableRbacAuthorization: true
    location: location
    roleAssignments: [
      {
        principalId: service.outputs.systemAssignedMIPrincipalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Key Vault Secrets User'
      }
    ]
    secrets: [
      {
        contentType: 'Id'
        name: 'favoritePerson'
        value: '3'
      }
    ]
  }
}

module workspace 'br/public:avm/res/operational-insights/workspace:0.5.0' = {
  name: 'workspaceDeployment'
  params: {
    // Required parameters
    name: lawName
    // Non-required parameters
    location: location
  }
}

module component 'br/public:avm/res/insights/component:0.4.0' = {
  name: 'componentDeployment'
  params: {
    // Required parameters
    name: appInsightsName
    workspaceResourceId: workspace.outputs.resourceId
    // Non-required parameters
    location: location
  }
}
