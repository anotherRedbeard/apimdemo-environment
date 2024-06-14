// =========== main.bicep ===========
@description('Provide the name of the apim instance.')
param apimName string = 'Basic'

@description('Provide the name of backend.')
param backendName string = 'my-backend'
@description('Provide the url of the backend.')
param backendUrl string = ''
@description('Provide the description of the backend.')
param backendDescription string = 'short description'

// =================================

// Create backend
module createBackend './modules/apim-backend.bicep' = {
  name: 'CircuitBreakerBackendsDeployment'
  params: {
    apimName: apimName
    backendName: backendName
    backendUrl: backendUrl
    backendDescription: backendDescription
  }
}
