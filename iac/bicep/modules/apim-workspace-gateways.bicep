@description('API Management service name.')
param apimServiceName string

@description('Azure region for the gateway resources.')
param location string

@description('Array of gateway definitions: { name, workspaceName, virtualNetworkType ("Internal"|"External"), capacity, [skuName], [subnetId if Internal] }')
param gateways array

// Deploy all gateways
resource gatewayResources 'Microsoft.ApiManagement/gateways@2024-06-01-preview' = [for gw in gateways: {
  name: gw.name
  location: location
  sku: {
    name: gw.skuName 
    capacity: gw.capacity
  }
  properties: {
    backend: toLower(gw.virtualNetworkType) != 'none' ? {
      subnet: {
        id: gw.subnetId
      }
    } : null
    frontend: {}
    virtualNetworkType: gw.virtualNetworkType
  }
}]

resource workspaceGatewayConfigConnection 'Microsoft.ApiManagement/gateways/configConnections@2024-06-01-preview' = [for (gw, i) in gateways: { 
  parent: gatewayResources[i]
  name: 'gw-${gw.name}-config'
  properties: {
    sourceId: '${resourceId('Microsoft.ApiManagement/service', apimServiceName)}/workspaces/${gw.workspaceName}'
  }
}]

// Outputs
@description('Gateway resource IDs.')
output gatewayIds array = [for i in range(0, length(gateways)): gatewayResources[i].id]

@description('Gateway resource names.')
output gatewayNames array = [for i in range(0, length(gateways)): gatewayResources[i].name]

// NEW: resolve internal gateway private VIP (blank if not present in param list)
var gatewayNames = [for g in gateways: g.name]
var internalGatewayIndex = indexOf(gatewayNames, 'internal-gateway')
var internalGatewayPrivateVip = internalGatewayIndex >= 0
  ? reference(gatewayResources[internalGatewayIndex].id, '2024-06-01-preview', 'full').properties.frontend.inboundIpAddresses.private[0]
  : ''

@description('Private inbound IP of internal-gateway (empty string if not found).')
output internalGatewayPrivateVip string = internalGatewayPrivateVip
