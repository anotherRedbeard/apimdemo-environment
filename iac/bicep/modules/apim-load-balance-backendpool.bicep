@description('Provide the name of the apim instance.')
param apimName string = 'Basic'

@description('Array of backend pools that need to be created')
param backends array

resource bepool 'Microsoft.ApiManagement/service/backends@2023-09-01-preview' = [for backend in backends: {
    name: toLower('${apimName}/${backend.poolName}')
    properties: {
      description: 'Load balancer for ${backend.poolTypeName} backends'
      type: 'Pool'
      pool: {
        services: [for service in backend.services: {
            id: service.id
            //if priority is passed in then set it; otherwise don't set it
            ...(service.priority != null ? {
                priority: service.priority
            } : {})
            //if weight is passed in then set it; otherwise don't set it
            ...(service.weight != null ? {
                weight: service.weight
            } : {})
          }
        ]
      }
    }
  }
]
