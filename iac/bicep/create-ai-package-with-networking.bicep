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
param apimSku string = 'Premium'

@description('The number of scale units to deploy')
param apimCapacity int = 1

@description('The name of the virtual network.')
param vnetName string = 'vnetName'

@description('The name of the public subnet.')
param privateSubnetName string = 'privateSubnetName'

@description('The name of the private subnet.')
param privateSubnetName2 string = 'privateSubnetName2'

@description('The name of the private subnet.')
param privateSubnetName3 string = 'privateSubnetName3'

@description('The address prefix for the virtual network.')
param vnetAddressPrefix string

@description('The address prefix for the public subnet.')
param privateSubnetAddressPrefix string

@description('The address prefix for the private subnet.')
param privateSubnet2AddressPrefix string

@description('The address prefix for the private subnet.')
param privateSubnet3AddressPrefix string

@description('AI Foundry project name')
param foundryProjectName string = 'default'

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

@description('Configuration object for single AI Foundry (Cognitive Services AIServices kind) account')
param aiServiceConfig object = {
  name: '${apimName}-foundry1'
  location: location
}

@description('Configuration array for the model deployments')
param modelsConfig array = [
  {
    name: 'gpt-4o'
    publisher: 'OpenAI'
    version: '2024-11-20'
    sku: 'GlobalStandard'
    capacity: 100
  }
]

@description('Foundry dns zone id array')
param foundryDnsZoneIds array = []

// =============================
// Application Gateway Parameters
// =============================
@description('Name of the Application Gateway to create.')
param applicationGatewayName string = '${apimName}-agw'

@allowed([
  'Standard_v2'
  'WAF_v2'
])
@description('SKU name for the Application Gateway.')
param appGatewaySkuName string = 'Standard_v2'

@description('Enable HTTP/2 on the Application Gateway.')
param appGatewayEnableHttp2 bool = true

@description('Minimum autoscale capacity for the Application Gateway.')
param appGatewayMinCapacity int = 1

@description('Maximum autoscale capacity for the Application Gateway.')
param appGatewayMaxCapacity int = 2

@description('Availability zones to deploy the Application Gateway into (empty array for no explicit zones).')
param appGatewayZones array = [ 1 ]

@description('Name for a new Public IP (ignored if existingPublicIpResourceId provided).')
param publicIpName string = '${apimName}-agw-pip'

@description('Backend hostname (FQDN) the Application Gateway routes to (defaults to public APIM hostname).')
param appGatewayBackendHostname string = '${apimName}.azure-api.net'

//log analytics workspace resource
module law 'br/public:avm/res/operational-insights/workspace:0.5.0' = {
  name: 'logAnalyticsWorkspaceDeployment'
  params: {
    // Required parameters
    name: '${apimName}-log'
    // Non-required parameters
    location: location
  }
}

//app insights resource
module appInsights 'br/public:avm/res/insights/component:0.4.0' = {
  name: 'appInsightsDeployment'
  params: {
    // Required parameters
    name: '${apimName}-appi'
    workspaceResourceId: law.outputs.resourceId
    // Non-required parameters
    location: location
  }
}

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
        name: privateSubnetName
        addressPrefix: privateSubnetAddressPrefix
        // Associate NSG required for Internal APIM deployment
        networkSecurityGroupResourceId: apimSubnetNsg.id
      }
      {
        name: privateSubnetName2
        addressPrefix: privateSubnet2AddressPrefix
        // Associate explicit NSG for Application Gateway subnet so policy-created NSG doesn't block inbound listener ports
        networkSecurityGroupResourceId: appGatewaySubnetNsg.id
      }
      {
        name: privateSubnetName3
        addressPrefix: privateSubnet3AddressPrefix
      }
    ]
  }
}

// Helper vars to avoid deep property access in module params (stabilizes Bicep compilation)
var apimSubnetId = virtualNetwork.outputs.subnetResourceIds[0]
var foundryPrivateEndpointSubnetId = virtualNetwork.outputs.subnetResourceIds[2]
// Use second subnet for Application Gateway (must be dedicated)
var appGatewaySubnetId = virtualNetwork.outputs.subnetResourceIds[1]

module service 'br/public:avm/res/api-management/service:0.1.7' = {
  name: 'apimServiceDeployment'
  params: {
    // Required parameters
    name: apimName
    publisherEmail: adminEmail
    publisherName: orgName
    // Non-required parameters
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
    subnetResourceId: apimSubnetId
    location: location
    managedIdentities: {
      systemAssigned: true
    }
    virtualNetworkType: 'Internal'
  }
  dependsOn: [
  ]
}

// Create a logger only if we have an App Insights ID and instrumentation key.
module apimAppInsightsLogger 'br/public:avm/res/api-management/service/logger:0.1.0' = {
  name: 'apimAppInsightsLoggerDeployment'
  params: {
    apiManagementServiceName: service.outputs.name
    name: 'appinsights-logger'
    description: 'APIM Logger for Application Insights'
    isBuffered: false
    type: 'applicationInsights'
    targetResourceId: appInsights.outputs.resourceId
    credentials: {instrumentationKey: appInsights.outputs.instrumentationKey}
  }
  dependsOn: [
  ]
}

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
  ]
}]

module foundryModule './modules/foundry.bicep' = {
  name: 'foundryModule'
  params: {
    aiServiceConfig: aiServiceConfig
    modelsConfig: modelsConfig
    apimPrincipalId: service.outputs.systemAssignedMIPrincipalId
    foundryProjectName: foundryProjectName
    privateEndpointSubnetResourceId: foundryPrivateEndpointSubnetId
    privateDnsZoneIds: foundryDnsZoneIds
    lawId: law.outputs.resourceId
    appInsightsInstrumentationKey: appInsights.outputs.instrumentationKey
    appInsightsId: appInsights.outputs.resourceId
  }
}

// Network Security Group for the apim subnet
resource apimSubnetNsg 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {
  name: '${vnetName}-${privateSubnetName}-nsg-${location}'
  location: location
  properties: {
    securityRules: [] // rules defined as separate child resources below
  }
}

// Network Security Group for the Application Gateway subnet (allow inbound HTTP now; extend later for HTTPS)
resource appGatewaySubnetNsg 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {
  name: '${vnetName}-${privateSubnetName2}-nsg-${location}'
  location: location
  properties: {
    // Define required rules inline to avoid child resource conflicts with policy-managed NSG
    securityRules: [
      // Allow required ephemeral port range from GatewayManager service tag (additional control plane sources)
      {
        name: 'Inbound-AllowGateway'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 2704
          direction: 'Inbound'
        }
      }
      // Listener port 80 traffic
      {
        name: 'Inbound-Internet-HTTP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 2705
          direction: 'Inbound'
        }
      }
    ]
  }
}

// (GatewayManager ephemeral rule already injected by policy as AllowGatewayManager @ ~2702)

// (Optional future) Allow HTTPS can be added similarly if/when listener on 443 introduced
// resource appGwRuleInboundHttps 'Microsoft.Network/networkSecurityGroups/securityRules@2024-07-01' = {
//   parent: appGatewaySubnetNsg
//   name: 'Inbound-Internet-HTTPS'
//   properties: {
//     protocol: 'Tcp'
//     sourcePortRange: '*'
//     destinationPortRange: '443'
//     sourceAddressPrefix: '*'
//     destinationAddressPrefix: 'VirtualNetwork'
//     access: 'Allow'
//     priority: 110
//     direction: 'Inbound'
//   }
//   dependsOn: [ virtualNetwork ]
// }

// Inbound rules now conditional on resolved IP
resource subnet3RuleInboundVNet 'Microsoft.Network/networkSecurityGroups/securityRules@2024-07-01' = {
  parent: apimSubnetNsg
  name: 'Inbound-APIM-to-VNET'
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRanges: [
      '3443'
    ]
    sourceAddressPrefix: 'ApiManagement'
    destinationAddressPrefix: 'VirtualNetwork'
    access: 'Allow'
    priority: 100
    direction: 'Inbound'
  }
  dependsOn: [
    virtualNetwork
  ]
}

resource subnet3RuleInboundAlb 'Microsoft.Network/networkSecurityGroups/securityRules@2024-07-01' = {
  parent: apimSubnetNsg
  name: 'Inbound-ALB-to-VNET'
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '6390'
    sourceAddressPrefix: 'AzureLoadBalancer'
    destinationAddressPrefix: 'VirtualNetwork'
    access: 'Allow'
    priority: 110
    direction: 'Inbound'
  }
  dependsOn: [
    virtualNetwork
  ]
}

// Outbound storage rule does not depend on VIP
resource subnet3RuleOutboundStorage 'Microsoft.Network/networkSecurityGroups/securityRules@2024-07-01' = {
  parent: apimSubnetNsg
  name: 'Outbound-VNet-to-Storage'
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '443'
    sourceAddressPrefix: 'VirtualNetwork'
    destinationAddressPrefix: 'Storage'
    access: 'Allow'
    priority: 130
    direction: 'Outbound'
  }
  dependsOn: [
    virtualNetwork
  ]
}

// Correct SQL port is 1433 (was 1443)
resource subnet3RuleOutBoundSql 'Microsoft.Network/networkSecurityGroups/securityRules@2024-07-01' = {
  parent: apimSubnetNsg
  name: 'Outbound-VNet-to-SQL'
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRanges: [
      '1433'
    ]
    sourceAddressPrefix: 'VirtualNetwork'
    destinationAddressPrefix: 'Sql'
    access: 'Allow'
    priority: 100
    direction: 'Outbound'
  }
  dependsOn: [
    virtualNetwork
  ]
}

resource subnet3RuleOutboundAkv 'Microsoft.Network/networkSecurityGroups/securityRules@2024-07-01' =  {
  parent: apimSubnetNsg
  name: 'Outbound-VNet-to-AKV'
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '443'
    sourceAddressPrefix: 'VirtualNetwork'
    destinationAddressPrefix: 'AzureKeyVault'
    access: 'Allow'
    priority: 110
    direction: 'Outbound'
  }
  dependsOn: [
    virtualNetwork
  ]
}

resource subnet3RuleOutboundAzMon 'Microsoft.Network/networkSecurityGroups/securityRules@2024-07-01' = {
  parent: apimSubnetNsg
  name: 'Outbound-VNet-to-AzureMonitor'
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRanges: ['1886', '443']
    sourceAddressPrefix: 'VirtualNetwork'
    destinationAddressPrefix: 'AzureMonitor'
    access: 'Allow'
    priority: 140
    direction: 'Outbound'
  }
  dependsOn: [
    virtualNetwork
  ]
}

// =============================
// Public IP for Application Gateway
// =============================
module publicIpAddress 'br/public:avm/res/network/public-ip-address:0.9.1' = {
  name: 'publicIpAddressDeployment'
  params: {
    // Required parameters
    name: publicIpName
    // Non-required parameters
    dnsSettings: {
      domainNameLabel: '${apimName}-agw-dns'
    }
    location: location
    skuName: 'Standard'
    skuTier: 'Regional'
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'

  }
}

var effectivePublicIpId = publicIpAddress.outputs.resourceId

// =============================
// Application Gateway collection variables (so we can reference names later)
// =============================
var appGwFrontendIpConfigs = [
  {
    name: 'public'
    properties: {
      publicIPAddress: {
        id: effectivePublicIpId
      }
    }
  }
]

var appGwFrontendPorts = [
  {
    name: 'port80'
    properties: {
      port: 80
    }
  }
]

var appGwBackendAddressPools = [
  {
    name: 'backendpool'
    properties: {
      backendAddresses: [
        {
          fqdn: appGatewayBackendHostname
        }
      ]
    }
  }
]

var appGwBackendHttpSettings = [
  {
    name: 'apim-backend'
    properties: {
      port: 443
      protocol: 'Https'
      probe: {
        id: '${resourceId('Microsoft.Network/applicationGateways', applicationGatewayName)}/probes/apim-probe'
      }
      cookieBasedAffinity: 'Disabled'
      hostName: appGatewayBackendHostname
      pickHostNameFromBackendAddress: false
      requestTimeout: 20
    }
  }
]

var appGwListenerName = 'http-listener'
var appGwFrontendIpName = appGwFrontendIpConfigs[0].name
var appGwFrontendPortName = appGwFrontendPorts[0].name
var appGwBackendPoolName = appGwBackendAddressPools[0].name
var appGwBackendSettingName = appGwBackendHttpSettings[0].name

// =============================
// Application Gateway (AVM Module)
// =============================
module applicationGateway 'br/public:avm/res/network/application-gateway:0.7.2' = {
  name: 'applicationGatewayDeployment'
  params: {
    name: applicationGatewayName
    availabilityZones: appGatewayZones
    location: location
    sku: appGatewaySkuName
    enableHttp2: appGatewayEnableHttp2
    autoscaleMinCapacity: appGatewayMinCapacity
    autoscaleMaxCapacity: appGatewayMaxCapacity
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: appGatewaySubnetId
          }
        }
      }
    ]
    frontendIPConfigurations: appGwFrontendIpConfigs
    frontendPorts: appGwFrontendPorts
    backendAddressPools: appGwBackendAddressPools
    backendHttpSettingsCollection: appGwBackendHttpSettings
    httpListeners: [
      {
        name: appGwListenerName
        properties: {
          frontendIPConfiguration: {
            id: '${resourceId('Microsoft.Network/applicationGateways', applicationGatewayName)}/frontendIPConfigurations/${appGwFrontendIpName}'
          }
          frontendPort: {
            id: '${resourceId('Microsoft.Network/applicationGateways', applicationGatewayName)}/frontendPorts/${appGwFrontendPortName}'
          }
          protocol: 'Http'
          hostNames: []
          requireServerNameIndication: false
        }
      }
    ]
     probes: [
      {
        name: 'apim-probe'
        properties: {
          protocol: 'Https'
          host: appGatewayBackendHostname
          path: '/status-0123456789abcdef'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: false
          match: {
            statusCodes: [ '200-399' ]
          }
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'apim-rule'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: '${resourceId('Microsoft.Network/applicationGateways', applicationGatewayName)}/httpListeners/${appGwListenerName}'
          }
          backendAddressPool: {
            id: '${resourceId('Microsoft.Network/applicationGateways', applicationGatewayName)}/backendAddressPools/${appGwBackendPoolName}'
          }
          backendHttpSettings: {
            id: '${resourceId('Microsoft.Network/applicationGateways', applicationGatewayName)}/backendHttpSettingsCollection/${appGwBackendSettingName}'
          }
        }
      }
    ]
  }
  dependsOn: [
    service
    ] 
}

// =============================
// Outputs (augment with Application Gateway details)
// =============================
output applicationGatewayId string = applicationGateway.outputs.resourceId
output applicationGatewayFrontendPublicIpId string = effectivePublicIpId
