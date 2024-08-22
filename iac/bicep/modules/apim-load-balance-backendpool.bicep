@description('Provide the name of the apim instance.')
param apimName string = 'Basic'

/*
@description('Provide the id of the scus backend.')
param scusBackendId string = ''
@description('Provide the id of the eus backend.')
param eusBackendId string = ''
@description('Provide the id of the wus backend.')
param weuBackendId string = ''
*/
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

/*
resource adaembeddingbepool 'Microsoft.ApiManagement/service/backends@2023-09-01-preview' = {
  name: toLower('${apimName}/adaembedding-backendpool')
  properties: {
    description: 'Load balancer for ada backends'
    type: 'Pool'
    pool: {
      services: [
        {
          id: scusBackendId
          //priority: 1
          //weight: 3
        }
        {
          id: eusBackendId
          //priority: 1
          //weight: 1
        }
        {
          id: weuBackendId
          //priority: 1
          //weight: 1
        }
      ]
    }
  }
}

resource gpt35bepool 'Microsoft.ApiManagement/service/backends@2023-09-01-preview' = {
  name: toLower('${apimName}/gpt35-backendpool')
  properties: {
    description: 'Load balancer for gpt35 backends'
    type: 'Pool'
    pool: {
      services: [
        {
          id: scusBackendId
          //priority: 1
          //weight: 3
        }
        {
          id: eusBackendId
          //priority: 1
          //weight: 1
        }
      ]
    }
  }
}
*/
