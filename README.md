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
    |AZURE_CLIENT_ID|The client id of the service principal|
    |AZURE_CLIENT_SECRET|The client secret of the service principal|
    |AZURE_SUBSCRIPTION_ID|The subscription id of the apim resource |
    |AZURE_TENANT_ID|The tenant id of the service principal|

    | Variable Name | Description |
    | ------------- | ----------- |
    |APIM_SERVICE_NAME |The name of the APIM instance to migrate from |
    |APIM_RG_NAME|The name of the resource group the APIM instance is in|
    |APIOPS_VERSION|This is the version of APIOps that I am using|
    |LOG_LEVEL|Sets the log level as to what kind of logging will be displayed in the logs.|

    *Note:* The names of the environments can be dev, stage etc. If using different names, update the run-extractor.yaml and run-publisher-with-env.yaml for the environment names. This would also be a good time to setup [deployment protection rules](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment#deployment-protection-rules) if you wish in the environment settings of GitHub.

- Grant permissions for the actions to create a PR. Set *Read and write permissions* and "Allow GitHub Actions to create and approve pull requests" under *{repository} -> Settings -> Actions -> General -> Workflow permissions*.

## Tech I'm using

- [APIOps](https://azure.github.io/apiops/)
- [Postman Collections](https://www.postman.com/collection/)
- Powershell and CLI [Scripts](https://github.com/anotherRedbeard/apimdemo-environment/tree/main/scripts) to create infra
- [APIM GenAI Gateway](https://techcommunity.microsoft.com/t5/azure-integration-services-blog/introducing-genai-gateway-capabilities-in-azure-api-management/ba-p/4146525)
- [bicep](https://github.com/anotherRedbeard/apimdemo-environment/tree/main/iac/bicep) to implement some of the GenAI features

### APIOps Steps

For full documentation steps of how to setup and run APIOps, it would be best to check the [Official Documentation](https://azure.github.io/apiops/apiops/3-apimTools/), but since I've already done all of that here are the steps I use to deploy.

#### Portal First Deployment

  1. Run the extractor.yaml
    a. This will create a PR for you to approve, once you approve the PR the publisher.yaml pipeline will execute which will deploy your code to all the environments

#### Code First Deployment

  1. Create a PR for the changes that you've made.
  2. Approve the PR
    a. Once you approve the PR the publisher.yaml pipeline will execute which will deploy your code to all the environments

### Automated Testing with Postman Collection

For the test automation using Postman Collections this repo is taking advantage of the [Postman CLI](https://learning.postman.com/docs/postman-cli/postman-cli-overview/). Previously we were using Newman, but now have switched over to use the CLI as it supports interaction with the Postman UI.

This is what we followed to [integration Postman with GitHub Actions](https://learning.postman.com/docs/integrations/available-integrations/ci-integrations/github-actions/#configuring-the-postman-cli-for-github-actions).  We already had a folder named `postman-collections` so we did need to configure that differently in the setup. This integration also creates a `.postman` folder in your repo that has config files that get auto-generated so you don't have to change anything there.

Finally we are not using the `postman api lint` command since we don't have a need for it, but also we don't want to keep up with the api definition in code for our purposes.

### APIM GenAI Gateway

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
