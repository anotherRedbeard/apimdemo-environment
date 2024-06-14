@description('Provide the name of the apim instance.')
param apimName string = 'Basic'

@description('Provide the name of scus backend.')
param scusApimBackendName string = 'scus-aoai-backend'
@description('Provide the name of scus AOAI instance.')
param scusAOAIName string = ''

@description('Provide the name of eus backend.')
param eusApimBackendName string = 'eus-aoai-backend'
@description('Provide the name of eus AOAI instance.')
param eusAOAIName string = ''

@description('Provide the name of weu backend.')
param weuApimBackendName string = 'wus-aoai-backend'
@description('Provide the name of wus AOAI instance.')
param weuAOAIName string = ''

resource backendbrdscus 'Microsoft.ApiManagement/service/backends@2023-09-01-preview' = {
  name: toLower('${apimName}/${scusApimBackendName}')
  properties: {
    url: 'https://${scusAOAIName}.openai.azure.com/openai/'
    protocol: 'http'
    circuitBreaker: {
      rules: [
        {
          failureCondition: {
            count: 1
            errorReasons: [
              'Non 200-300 status codes'
            ]
            interval: 'PT1M' 
            statusCodeRanges: [
              {
                min: 400
                max: 599
              }
            ]
          }
          name: 'myBreakerRule'
          tripDuration: 'PT1M'  
          acceptRetryAfter: true
        }
      ]
    }
   }
 }

 resource backendbrdeus 'Microsoft.ApiManagement/service/backends@2023-09-01-preview' = {
  name: toLower('${apimName}/${eusApimBackendName}')
  properties: {
    url: 'https://${eusAOAIName}.openai.azure.com/openai/'
    protocol: 'http'
    circuitBreaker: {
      rules: [
        {
          failureCondition: {
            count: 1
            errorReasons: [
              'Non 200-300 status codes'
            ]
            interval: 'PT1M' 
            statusCodeRanges: [
              {
                min: 400
                max: 599
              }
            ]
          }
          name: 'myBreakerRule'
          tripDuration: 'PT1M'  
          acceptRetryAfter: true
        }
      ]
    }
   }
 }

 resource backendbrdweu 'Microsoft.ApiManagement/service/backends@2023-09-01-preview' = {
  name: toLower('${apimName}/${weuApimBackendName}')
  properties: {
    url: 'https://${weuAOAIName}.openai.azure.com/openai/'
    protocol: 'http'
    circuitBreaker: {
      rules: [
        {
          failureCondition: {
            count: 1
            errorReasons: [
              'Non 200-300 status codes'
            ]
            interval: 'PT1M' 
            statusCodeRanges: [
              {
                min: 400
                max: 599
              }
            ]
          }
          name: 'myBreakerRule'
          tripDuration: 'PT1M'  
          acceptRetryAfter: true
        }
      ]
    }
   }
 }

@description('Output the backend id property for later use')
output scusBackendId string = backendbrdscus.id
output eusBackendId string = backendbrdeus.id
output weuBackendId string = backendbrdweu.id
