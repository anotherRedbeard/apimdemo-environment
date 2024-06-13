@description('Provide the name of the apim instance.')
param apimName string = 'Basic'

@description('Provide the id of the scus backend.')
param scusBackendId string = ''
@description('Provide the id of the eus backend.')
param eusBackendId string = ''

resource mydavincibepool 'Microsoft.ApiManagement/service/backends@2023-09-01-preview' = {
  name: toLower('${apimName}/mydavinci3-backendpool')
  properties: {
    description: 'Load balancer for davinci backends'
    type: 'Pool'
    pool: {
      services: [
        {
          id: scusBackendId
          priority: 1
          weight: 3
        }
        {
          id: eusBackendId
          priority: 1
          weight: 1
        }
      ]
    }
  }
}
