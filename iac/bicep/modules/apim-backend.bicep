@description('Provide the name of the apim instance.')
param apimName string = 'Basic'

@description('Provide the name of backend.')
param backendName string = 'my-backend'
@description('Provide the url of the backend.')
param backendUrl string = ''
@description('Provide the description of the backend.')
param backendDescription string = 'short description'


resource backenddeployment 'Microsoft.ApiManagement/service/backends@2023-09-01-preview' = {
  name: toLower('${apimName}/${backendName}')
  properties: {
    url: backendUrl
    protocol: 'http'
    description: backendDescription
  }
}

@description('Output the backend id property for later use')
output backendId string = backenddeployment.id
