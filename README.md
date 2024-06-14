# apimdemo-environment
This is the repo that holds everything I need to setup a new apimdemo environment.  I keep this around in case I need to stand my demo back up in short order.

## Prerequisites

- You will need to create a new client_id and secret on an existing or new service principal.
  - Here is the command to create the new service principal
    ```# Bash script
      az ad sp create-for-rbac --name myServicePrincipalName1 --role reader --scopes /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myRG1
    ```
- Create environments for each of the apim instances under *{repository} -> Settings -> Environments* with the below secrets:

    | Secret Name | Description |
    | ------------- | ----------- |
    |APIM_INSTANCE_NAME |The name of the APIM instance to migrate from |
    |RESOURCE_GROUP_NAME|The name of the resource group the APIM instance is in|
    |AZURE_CLIENT_ID|The client id of the service principal|
    |AZURE_CLIENT_SECRET|The client secret of the service principal|
    |AZURE_SUBSCRIPTION_ID|The subscription id of the apim resource |
    |AZURE_TENANT_ID|The tenant id of the service principal|

    *Note:* The names of the environments can be dev, stage etc. If using different names, update the run-extractor.yaml and run-publisher-with-env.yaml for the environment names. This would also be a good time to setup [deployment protection rules](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment#deployment-protection-rules) if you wish in the environment settings of GitHub.

- Grant permissions for the actions to create a PR. Set *Read and write permissions* and "Allow GitHub Actions to create and approve pull requests" under *{repository} -> Settings -> Actions -> General -> Workflow permissions*.

## Tech I'm using

- [APIOps](https://azure.github.io/apiops/)
- [Postman Collections](https://www.postman.com/collection/)
- Powershell and CLI [Scripts](https://github.com/anotherRedbeard/apimdemo-environment/tree/main/scripts) to create infra
- [APIM GenAI Gateway](https://techcommunity.microsoft.com/t5/azure-integration-services-blog/introducing-genai-gateway-capabilities-in-azure-api-management/ba-p/4146525)
- [bicep](https://github.com/anotherRedbeard/apimdemo-environment/tree/main/iac/bicep) to implement some of the GenAI features

## Automated Testing with Postman Collection

todo:  add details of automated testing with postman collections

## APIM GenAI Gateway

This repo shows how to use each of the new GenAI gateway features listed below:

  1. **Token Limit Policy**
    - Using this policy you can set limits, expressed in tokens-per-minute(TPM).
    - [Policy Documentation](https://aka.ms/apim/openai/token-limit-policy)
    - [My Implementation Example](https://github.com/anotherRedbeard/apimdemo-environment/blob/a89ce525e2db887f3cc0514183c00a053d039176/apimartifacts/apis/azureopenai/policy.xml#L13)
  2. **Emit Token Metric Policy**
    - Captures prompt, completions, and total token usage metrics and sends them to an Application Insights namespace of your choice. There are a few pre-requisites that you need to ensure you enable to make this work.
    - [Policy Documentation](https://aka.ms/apim/openai/token-metric-policy)
    - [My Implementation Example](https://github.com/anotherRedbeard/apimdemo-environment/blob/main/apimartifacts/apis/azureopenai/policy.xml#21)
  3. **Load Balancer and Circuit Breaker**
    - Allows you to support round-robin, weighted, and priority-based load balancing as well as setting up gateways to use circuit breaker pattern.
    - [Documentation](https://learn.microsoft.com/en-us/azure/api-management/backends?tabs=bicep)
    - [My implementation Example](https://github.com/anotherRedbeard/apimdemo-environment/tree/main/iac/bicep) is create in the bicep section of this repo.
  4. **Semantic Caching Policy**
    - Allows you to leverage any external cache compatible with RediSearch. You will need create an Azure OpenAI embedding backend so this policy can take advantage of that.
    - [Policy Documentation](https://aka.ms/apim/openai/semantic-caching)
    - My Implementation Example--Coming Soon--
