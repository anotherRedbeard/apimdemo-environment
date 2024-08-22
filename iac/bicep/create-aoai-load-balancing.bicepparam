using './create-aoai-load-balancing.bicep'

param apimName = '<your-apim-name>'
param scusAOAIName = '<scus-aoai-name>'
param scusApimBackendName = 'scus-aoai-backend'
param eusAOAIName = '<eus-aoai-name>'
param eusApimBackendName = 'eus-aoai-backend'
param weuAOAIName = '<weu-aoai-name>'
param weuApimBackendName = 'weu-aoai-backend'

