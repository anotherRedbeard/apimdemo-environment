// =========== main.bicep ===========
@description('The name of the APIM resource.')
param apimName string = ''

@description('Provide the name of your SCUS AOAI name.')
param scusAOAIName string = ''
@description('Provide a name for your APIM backend for SCUS.')
param scusApimBackendName string = ''
@description('Provide the name of your EUS AOAI name.')
param eusAOAIName string = ''
@description('Provide a name for your APIM backend for EUS.')
param eusApimBackendName string = ''
@description('Provide the name of your WEU AOAI name.')
param weuAOAIName string = ''
@description('Provide a name for your APIM backend for WEU.')
param weuApimBackendName string = ''

// =================================

// Create Circuit Breaker backends
module circuitBreakerBackends './modules/apim-circuit-breaker-backends.bicep' = {
  name: 'CircuitBreakerBackendsDeployment'
  params: {
    apimName: apimName
    scusAOAIName: scusAOAIName
    scusApimBackendName: scusApimBackendName
    eusAOAIName: eusAOAIName
    eusApimBackendName: eusApimBackendName
    weuAOAIName: weuAOAIName
    weuApimBackendName: weuApimBackendName
  }
}

var backendPools = [
  {
    poolName: 'adaembedding-backendpool'
    poolTypeName: 'Pool'
    services: [
      {
        id: circuitBreakerBackends.outputs.eusBackendId
        priority: null
        weight: null 
      }
      {
        id: circuitBreakerBackends.outputs.scusBackendId
        priority: null
        weight: null 
      }
      {
        id: circuitBreakerBackends.outputs.weuBackendId
        priority: null 
        weight: null
      }
    ]
  }
  {
    poolName: 'gpt35-backendpool'
    poolTypeName: 'Pool'
    services: [
      {
        id: circuitBreakerBackends.outputs.eusBackendId
        priority: null
        weight: null 
      }
      {
        id: circuitBreakerBackends.outputs.scusBackendId 
        priority: null
        weight: null 
      }
    ]
  }
  {
    poolName: 'gpt4o-backendpool'
    poolTypeName: 'Pool'
    services: [
      {
        id: circuitBreakerBackends.outputs.eusBackendId
        priority: null
        weight: null 
      }
      {
        id: circuitBreakerBackends.outputs.scusBackendId
        priority: null
        weight: null 
      }
    ]
  }
]

// Create Load Balancing Pools
module loadBalancingPools './modules/apim-load-balance-backendpool.bicep' = {
  name: 'LoadBalancingPoolsDeployment'
  params: {
    apimName: apimName
    backends: backendPools
  }
}
