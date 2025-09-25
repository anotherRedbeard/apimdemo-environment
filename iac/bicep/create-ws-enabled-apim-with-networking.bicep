@description('Provide the name of the apim instance.')
param apimName string = 'apimName'

@description('Provide the location of the apim instance.')
param location string = resourceGroup().location

@description('Provide the secondary location of the apim instance.')
param secondaryLocation string = resourceGroup().location

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
param privateSubnetName1 string = 'privateSubnetName1'

@description('The name of the private subnet.')
param privateSubnetName2 string = 'privateSubnetName2'

@description('The address prefix for the virtual network.')
param vnetAddressPrefix string

@description('The address prefix for the public subnet.')
param publicSubnetAddressPrefix string

@description('The address prefix for the private subnet.')
param privateSubnetAddressPrefix string

@description('Array of API definitions to deploy. openApiSpecUrl is used for import.')
param apis array = [
  {
    name: 'petstore-api'
    displayName: 'Pet Store API'
    description: 'Pet Store API'
    path: 'petstore'
    serviceUrl: 'https://petstore.swagger.io/v2'
    openApiSpecUrl: 'https://petstore.swagger.io/v2/swagger.json'
    subscriptionRequired: true
    protocols: [
      'https'
    ]
    apiType: 'http'
    format: 'openapi+json-link'
    subscriptionKeyParameterNames: {
      header: 'api-key'
      query: 'api-key'
    }
  }
]

@description('Array of workspace API definitions to deploy. openApiSpecUrl is used for import.')
param workspaceApis array = [
  {
    workspaceName: 'public-ws'
    name: 'ws-public-colors-api'
    displayName: 'Public Workspace Colors API'
    description: 'Public WorkspaceColors API'
    path: 'ws-public/color'
    serviceUrl: 'https://colors-api.azurewebsites.net/'
    openApiSpecUrl: 'https://colors-api.azurewebsites.net/swagger/v1/swagger.json'
    subscriptionRequired: true
    protocols: [
      'https'
    ]
    apiType: 'http'
    format: 'openapi+json-link'
    subscriptionKeyParameterNames: {
      header: 'api-key'
      query: 'api-key'
    }
  }
  {
    workspaceName: 'private-ws'
    name: 'ws-private-fake-api'
    displayName: 'Internal Workspace Fake API'
    description: 'Internal WorkspaceFake API'
    path: 'ws-private/fake'
    serviceUrl: 'https://fakerestapi.azurewebsites.net/'
    openApiSpecUrl: 'https://fakerestapi.azurewebsites.net/swagger/v1/swagger.json'
    subscriptionRequired: true
    protocols: [
      'https'
    ]
    apiType: 'http'
    format: 'openapi+json-link'
    subscriptionKeyParameterNames: {
      header: 'api-key'
      query: 'api-key'
    }
  }
]

@description('Workspace definitions. NOTE: Workspaces do not attach to subnets individually; network isolation is configured at the APIM service (gateway) level. publicNetworkAccess Disabled limits public access for that workspace scope.')
param workspaces array = [
  {
    name: 'public-ws'
    description: 'Public workspace'
    displayName: 'public workspace'
    publicNetworkAccess: 'Enabled'
  }
  {
    name: 'private-ws'
    description: 'Private (public access disabled) workspace'
    displayName: 'private workspace'
    publicNetworkAccess: 'Disabled'
  }
]

@description('Gateway definitions. Each: { name, workspaceName, virtualNetworkType (Internal|External), capacity, [skuName], [subnetId required if Internal] }')
param gateways array = [
  {
    name: 'internal-gateway'
    skuName: 'WorkspaceGatewayPremium'
    workspaceName: 'private-ws'
    virtualNetworkType: 'Internal'
    capacity: 1
    // You can hardcode a known subnetId or reference the one created in this deployment:
    // subnetId: '/subscriptions/<subId>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>/subnets/<subnet>'
    subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, privateSubnetName2)
  }
  {
    name: 'public-gateway'
    skuName: 'WorkspaceGatewayPremium'
    workspaceName: 'public-ws'
    virtualNetworkType: 'None'
    capacity: 1
  }
]

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
        name: privateSubnetName1
        addressPrefix: publicSubnetAddressPrefix
        delegation: 'Microsoft.Web/hostingEnvironments'
      }
      {
        name: privateSubnetName2
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
    additionalLocations: [
      {
        availabilityZones: [
          1
          2
          3
        ]
        disableGateway: false
        location: secondaryLocation
        sku: {
          name: apimSku
          capacity: apimCapacity
        }
      }
    ]
    apis: [for api in apis: {
      description: api.description
      displayName: api.displayName
      name: api.name
      path: api.path
      protocols: api.protocols
      serviceUrl: api.serviceUrl
    }]
    sku: apimSku
    skuCount: apimCapacity
    location: location
    managedIdentities: {
      systemAssigned: true
    }
  }
}

// Workspaces (public & private style)
module workspacesMod './modules/apim-workspaces.bicep' = {
  name: 'apimWorkspaces'
  params: {
    apimServiceName: service.outputs.name
    workspaces: workspaces
  }
  dependsOn: [
    service
  ]
}

// Gateways module
module gatewaysMod './modules/apim-workspace-gateways.bicep' = {
  name: 'apimGateways'
  params: {
    apimServiceName: service.outputs.name
    location: location
    gateways: gateways
  }
  dependsOn: [
    workspacesMod
  ]
}

// Workspace APIs (unchanged)
resource workspaceApiResources 'Microsoft.ApiManagement/service/workspaces/apis@2024-05-01' = [for wapi in workspaceApis: {
  name: '${apimName}/${wapi.workspaceName}/${wapi.name}'
  properties: {
    displayName: wapi.displayName
    description: wapi.description
    path: wapi.path
    apiType: wapi.apiType
    protocols: wapi.protocols
    format: wapi.format
    value: wapi.openApiSpecUrl
    serviceUrl: wapi.serviceUrl
    subscriptionRequired: wapi.subscriptionRequired
    subscriptionKeyParameterNames: wapi.subscriptionKeyParameterNames
  }
  dependsOn: [
    workspacesMod
  ]
}]

// ADD: map workspace name -> index (for parent lookup)
var workspaceIndexMap = reduce(workspaces, {}, (acc, ws, i) => union(acc, { '${ws.name}': i }))

// REMOVE dependsOn (illegal on existing resources)
resource existingWorkspaceProducts 'Microsoft.ApiManagement/service/workspaces/products@2024-06-01-preview' existing = [for ws in workspaces: {
  name: '${apimName}/${ws.name}/${ws.name}StarterProduct'
}]

// Add workspace product api links
resource workspaceProductApiLinks 'Microsoft.ApiManagement/service/workspaces/products/apiLinks@2024-06-01-preview' = [for (wapi, i) in workspaceApis: {
  parent: existingWorkspaceProducts[workspaceIndexMap[wapi.workspaceName]]
  name: 'link-${wapi.name}'
  properties: {
    apiId: workspaceApiResources[i].id
  }
  dependsOn: [
    workspacesMod
  ]
}]

module apiModules 'br/public:avm/res/api-management/service/api:0.1.0' = [for api in apis: {
  name: 'apiDeployment-${api.name}'
  params: {
    apiManagementServiceName: service.outputs.name
    apiType: api.apiType
    description: api.description
    displayName: api.displayName
    format: api.format
    name: api.name
    path: api.path
    protocols: api.protocols
    serviceUrl: api.serviceUrl
    subscriptionKeyParameterNames: api.subscriptionKeyParameterNames
    subscriptionRequired: api.subscriptionRequired
    value: api.openApiSpecUrl
  }
  dependsOn: [
    gatewaysMod
  ]
}]

// DNS Private Zone (unchanged)
module apimPrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.8.0' = {
  name: 'privateDnsZoneDeployment'
  params: {
    name: 'azure-api.net'
    location: 'global'
  }
}

// Existing NSGs
resource subnet1Nsg 'Microsoft.Network/networkSecurityGroups@2024-07-01' existing = {
  name: '${vnetName}-${privateSubnetName1}-nsg-${location}'
}
resource subnet2Nsg 'Microsoft.Network/networkSecurityGroups@2024-07-01' existing = {
  name: '${vnetName}-${privateSubnetName2}-nsg-${location}'
}

// Inbound rules now conditional on resolved IP
resource subnet1RuleInboundVNet 'Microsoft.Network/networkSecurityGroups/securityRules@2024-07-01' = {
  parent: subnet1Nsg
  name: 'Inbound-VNet-to-GatewayVIP'
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRanges: [
      '80'
      '443'
    ]
    sourceAddressPrefix: 'VirtualNetwork'
    destinationAddressPrefix: gatewaysMod.outputs.internalGatewayPrivateVip
    access: 'Allow'
    priority: 100
    direction: 'Inbound'
  }
  dependsOn: [
    gatewaysMod
  ]
}

resource subnet1RuleInboundAlb 'Microsoft.Network/networkSecurityGroups/securityRules@2024-07-01' = {
  parent: subnet1Nsg
  name: 'Inbound-ALB-to-GatewayVIP'
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '80'
    sourceAddressPrefix: 'AzureLoadBalancer'
    destinationAddressPrefix: gatewaysMod.outputs.internalGatewayPrivateVip
    access: 'Allow'
    priority: 110
    direction: 'Inbound'
  }
  dependsOn: [
    gatewaysMod
  ]
}

// Outbound storage rule does not depend on VIP
resource subnet1RuleOutboundStorage 'Microsoft.Network/networkSecurityGroups/securityRules@2024-07-01' = {
  parent: subnet1Nsg
  name: 'Outbound-VNet-to-Storage'
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '443'
    sourceAddressPrefix: 'VirtualNetwork'
    destinationAddressPrefix: 'Storage'
    access: 'Allow'
    priority: 120
    direction: 'Outbound'
  }
  dependsOn: [
    gatewaysMod
  ]
}

resource subnet2RuleInboundVNet 'Microsoft.Network/networkSecurityGroups/securityRules@2024-07-01' = {
  parent: subnet2Nsg
  name: 'Inbound-VNet-to-GatewayVIP'
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRanges: [
      '80'
      '443'
    ]
    sourceAddressPrefix: 'VirtualNetwork'
    destinationAddressPrefix: gatewaysMod.outputs.internalGatewayPrivateVip
    access: 'Allow'
    priority: 100
    direction: 'Inbound'
  }
  dependsOn: [
    gatewaysMod
  ]
}

resource subnet2RuleInboundAlb 'Microsoft.Network/networkSecurityGroups/securityRules@2024-07-01' =  {
  parent: subnet2Nsg
  name: 'Inbound-ALB-to-GatewayVIP'
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '80'
    sourceAddressPrefix: 'AzureLoadBalancer'
    destinationAddressPrefix: gatewaysMod.outputs.internalGatewayPrivateVip
    access: 'Allow'
    priority: 110
    direction: 'Inbound'
  }
  dependsOn: [
    gatewaysMod
  ]
}

resource subnet2RuleOutboundStorage 'Microsoft.Network/networkSecurityGroups/securityRules@2024-07-01' = {
  parent: subnet2Nsg
  name: 'Outbound-VNet-to-Storage'
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '443'
    sourceAddressPrefix: 'VirtualNetwork'
    destinationAddressPrefix: 'Storage'
    access: 'Allow'
    priority: 120
    direction: 'Outbound'
  }
  dependsOn: [
    gatewaysMod
  ]
}

// -----------------
// Outputs
// -----------------
@description('Deployed APIM service name')
output apimServiceName string = service.outputs.name

@description('Primary location of APIM service')
output apimPrimaryLocation string = location
