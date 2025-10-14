/**
 * @module openai-v2
 * @description This module defines the Azure Cognitive Services OpenAI resources using Bicep.
 * This is version 2 (v2) of the OpenAI Bicep module.
 */

// ------------------
//    PARAMETERS
// ------------------


@description('Configuration object for single AI Foundry (Cognitive Services AIServices kind) account')
param aiServiceConfig object = {
  name: 'foundry'
  location: resourceGroup().location
}

@description('Configuration array for the model deployments')
param modelsConfig array = []

@description('Log Analytics Workspace Id')
param lawId string = ''

@description('APIM Pricipal Id')
param  apimPrincipalId string

@description('AI Foundry project name')
param  foundryProjectName string = 'default'

@description('The instrumentation key for Application Insights')
@secure()
param appInsightsInstrumentationKey string = ''

@description('The resource ID for Application Insights')
param appInsightsId string = ''

@description('Subnet resource ID to place a private endpoint for each Cognitive Services (AI Foundry) account. Leave empty to skip private endpoint creation.')
param privateEndpointSubnetResourceId string = ''

@description('Optional array of Private DNS zone resource IDs to link to the private endpoint (e.g. privatelink.cognitiveservices.azure.com). If empty, no DNS zone group is created.')
param privateDnsZoneIds array = []


// ------------------
//    VARIABLES
// ------------------

var resourceSuffix = uniqueString(subscription().id, resourceGroup().id)
var azureRoles = loadJsonContent('../azure-roles.json')
// Built-in role definition IDs must be referenced at subscription scope (not resource group)
var cognitiveServicesUserRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', azureRoles.CognitiveServicesUser)
var aiProjectManagerRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', azureRoles.AzureAIProjectManager)


// ------------------
//    RESOURCES
// ------------------

resource cognitiveService 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: '${aiServiceConfig.name}-${resourceSuffix}'
  location: aiServiceConfig.location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'S0'
  }
  kind: 'AIServices'
  properties: {
    allowProjectManagement: true
    customSubDomainName: toLower('${aiServiceConfig.name}-${resourceSuffix}')
    disableLocalAuth: false
    publicNetworkAccess: 'Disabled'
  }
}

resource aiProject 'Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview' = {
  #disable-next-line BCP334
  name: '${foundryProjectName}-${aiServiceConfig.name}'
  parent: cognitiveService
  location: aiServiceConfig.location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {}
}


resource aiProjectManagerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: cognitiveService
  name: guid(subscription().id, aiServiceConfig.name, 'aiProjectManager')
  properties: {
    roleDefinitionId: aiProjectManagerRoleDefinitionId
    principalId: deployer().objectId
    principalType: 'User'
  }
}


// https://learn.microsoft.com/azure/templates/microsoft.insights/diagnosticsettings
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (lawId != '') {
  name: '${cognitiveService.name}-diagnostics'
  scope: cognitiveService
  properties: {
    workspaceId: lawId != '' ? lawId : null
    logs: []
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource appInsightsConnection 'Microsoft.CognitiveServices/accounts/connections@2025-06-01' = if (length(appInsightsId) > 0 && length(appInsightsInstrumentationKey) > 0) {
  parent: cognitiveService
  name: '${cognitiveService.name}-appInsights-connection'
  properties: {
    authType: 'ApiKey'
    category: 'AppInsights'
    target: appInsightsId
    useWorkspaceManagedIdentity: false
    isSharedToAll: false
    sharedUserList: []
    peRequirement: 'NotRequired'
    peStatus: 'NotApplicable'
    metadata: {
      ApiType: 'Azure'
      ResourceId: appInsightsId
    }
    credentials: {
      key: appInsightsInstrumentationKey
    }
  }
}

resource roleAssignmentCognitiveServicesUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: cognitiveService
  name: guid(subscription().id, aiServiceConfig.name, 'cogUser')
  properties: {
    roleDefinitionId: cognitiveServicesUserRoleDefinitionId
    principalId: apimPrincipalId
    principalType: 'ServicePrincipal'
  }
}

module modelDeployments 'deployments.bicep' = {
  name: take('models-${cognitiveService.name}', 64)
  params: {
    cognitiveServiceName: cognitiveService.name
    modelsConfig: modelsConfig
  }
}

// Private Endpoints (one per Cognitive Services account) if subnet supplied
resource cognitiveServicePrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = if (!empty(privateEndpointSubnetResourceId)) {
  name: '${cognitiveService.name}-pe'
  location: aiServiceConfig.location
  properties: {
    subnet: {
      id: privateEndpointSubnetResourceId
    }
    privateLinkServiceConnections: [
      {
        name: '${cognitiveService.name}-pe-conn'
        properties: {
          groupIds: [ 'account' ]
          privateLinkServiceId: cognitiveService.id
          requestMessage: 'Private endpoint access for AI Foundry account'
        }
      }
    ]
  }
}

// Optional DNS zone group attachments
resource cognitiveServicePrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = if (!empty(privateEndpointSubnetResourceId) && length(privateDnsZoneIds) > 0) {
  parent: cognitiveServicePrivateEndpoint
  name: 'ai-foundry-dns'
  properties: {
    privateDnsZoneConfigs: [for (zoneId, zi) in privateDnsZoneIds: {
      name: 'zone-${zi}'
      properties: {
        privateDnsZoneId: zoneId
      }
    }]
  }
}


// ------------------
//    OUTPUTS
// ------------------

output cognitiveServiceName string = cognitiveService.name
output cognitiveServiceId string = cognitiveService.id
output cognitiveServiceLocation string = cognitiveService.location
output projectName string = aiProject.name
output projectEndpoint string = 'https://${cognitiveService.name}.services.ai.azure.com/api/projects/${aiProject.name}'
