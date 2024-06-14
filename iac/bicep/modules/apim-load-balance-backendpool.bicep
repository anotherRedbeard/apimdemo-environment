@description('Provide the name of the apim instance.')
param apimName string = 'Basic'

@description('Provide the id of the scus backend.')
param scusBackendId string = ''
@description('Provide the id of the eus backend.')
param eusBackendId string = ''
@description('Provide the id of the wus backend.')
param weuBackendId string = ''

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
