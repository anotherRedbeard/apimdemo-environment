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
param privateSubnetName2 string = 'privateSubnetName2'

@description('The name of the private subnet.')
param privateSubnetName3 string = 'privateSubnetName3'

@description('The address prefix for the virtual network.')
param vnetAddressPrefix string

@description('The address prefix for the public subnet.')
param publicSubnetAddressPrefix string

@description('The address prefix for the private subnet.')
param privateSubnet2AddressPrefix string

@description('The address prefix for the private subnet.')
param privateSubnet3AddressPrefix string

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
        name: privateSubnetName2
        addressPrefix: privateSubnet2AddressPrefix
        delegation: 'Microsoft.Web/hostingEnvironments'
      }
      {
        name: privateSubnetName3
        addressPrefix: privateSubnet3AddressPrefix
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
  dependsOn: [
    virtualNetwork
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
    virtualNetwork
  ]
}]// Existing NSGs
resource subnet3Nsg 'Microsoft.Network/networkSecurityGroups@2024-07-01' existing = {
  name: '${vnetName}-${privateSubnetName3}-nsg-${location}'
}

// Inbound rules now conditional on resolved IP
resource subnet3RuleInboundVNet 'Microsoft.Network/networkSecurityGroups/securityRules@2024-07-01' = {
  parent: subnet3Nsg
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
  parent: subnet3Nsg
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
  parent: subnet3Nsg
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

resource subnet3RuleOutBoundSql 'Microsoft.Network/networkSecurityGroups/securityRules@2024-07-01' = {
  parent: subnet3Nsg
  name: 'Outbound-VNet-to-SQL'
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRanges: [
      '1443'
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
  parent: subnet3Nsg
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
  parent: subnet3Nsg
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
