@description('Name of the target API Management service.')
param apimServiceName string

@description('Workspace definitions (name, description, publicNetworkAccess).')
param workspaces array

resource apimService 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apimServiceName
}

resource workspaceResources 'Microsoft.ApiManagement/service/workspaces@2024-05-01' = [for ws in workspaces: {
  parent: apimService
  name: '${ws.name}'
  properties: {
    description: ws.description
    displayName: ws.name
  }
}]

resource workspaceProducts 'Microsoft.ApiManagement/service/workspaces/products@2024-06-01-preview' = [for (ws, i) in workspaces: {
  parent: workspaceResources[i]
  name: '${ws.name}StarterProduct'
  properties: {
    displayName: '${ws.name} Starter Product'
    description: '${ws.name} simple product'
    subscriptionRequired: true
    approvalRequired: false
    state: 'published'
  }
  dependsOn: [
    workspaceResources
  ]
}]

@description('Full workspace resource names (apimServiceName/workspaceName).')
output workspaceNames array = [for (ws, i) in workspaces: workspaceResources[i].name]

@description('Workspace resource IDs.')
output workspaceIds array = [for (ws, i) in workspaces: workspaceResources[i].id]

@description('Workspace product resource names (apimServiceName/workspaceName/productName).')
output workspaceProductNames array = [for (ws, i) in workspaces: workspaceProducts[i].name]

@description('Workspace product resource IDs.')
output workspaceProductIds array = [for (ws, i) in workspaces: workspaceProducts[i].id]

@description('Map objects: { workspaceName, productName }.')
output workspaceProductMap array = [for (ws, i) in workspaces: {
  workspaceName: ws.name
  productName: '${ws.name}StarterProduct'
}]
