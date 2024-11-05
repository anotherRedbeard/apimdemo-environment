# apimdemo-environment

This is the repo that holds everything I need to setup a new apimdemo environment.  I keep this around in case I need to stand my demo back up in short order.

## Prerequisites

- First and foremost, you will need an Azure API Management instance up and running.
  - If you don't have one, you can take a look at my bicep files to deploy the infrastructure that we use to setup this demo environment.
  - [Bicep Samples](https://github.com/anotherRedbeard/apimdemo-environment/tree/main/iac/bicep) - The APIMDemo bicep should contain all that you need to get the infrastructure setup. Any manual steps that need to be executed will be listed in the [Bicep Readme](https://github.com/anotherRedbeard/apimdemo-environment/tree/main/iac/bicep)

- You will need to create a new client_id and secret on an existing or new service principal.
  - Here is the command to create the new service principal

    ```# Bash script
      az ad sp create-for-rbac --name myServicePrincipalName1 --role reader --scopes /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myRG1
    ```

- Create environments for each of the apim instances under *{repository} -> Settings -> Environments* with the below secrets:

    | Secret Name | Description | Usage |
    | ------------- | ----------- | ------------- |
    |ALLOWED_IP_ADDRESS|This is used in an example policy to limit to a specific IP address|APIOps|
    |APIM_TESTING_SUBSCRIPTION_KEY|Subscription key that postman will use to send the test requests to APIM and confirm the endpoints|Postman Testing Automation|
    |API_TESTING_BACKEND_CLIENT_ID|Client id of the backend app registration for token request|Postman Testing Automation|
    |API_TESTING_FRONTEND_CLIENT_ID|Client id of the frontend app registration for token request|Postman Testing Automation|
    |API_TESTING_FRONTEND_CLIENT_SECRET|Client Secret from the frontend app registration so we can perform a client credential flow to test the apis|Postman Testing Automation|
    |APPINSIGHTS_LOGGER_KEY|Instrumentation key from the app insights resource so we can connect it to the APIM resource.|APIOps|
    |AZURE_CLIENT_ID|The client id of the service principal|APIOps|
    |AZURE_CLIENT_SECRET|The client secret of the service principal|APIOps|
    |AZURE_OPENAI_KEY|The AOAI key, are not using this any longer since we are authenticating via Managed Identity|GenAI Gateway AOAI|
    |AZURE_SUBSCRIPTION_ID|The subscription id of the apim resource |APIOps|
    |AZURE_TENANT_ID|The tenant id of the service principal|APIOps|
    |B2C_AUDIENCE|B2C Audience for B2C auth validation|APIOps|
    |B2C_ISSUER_GUID|B2C Issuer for B2C auth validation|APIOps|
    |ENTRAID_BACKEND_AUDIENCE|EntraId Audience for EntraId auth validation|APIOps|
    |ENTRAID_TENANT|EntraId Tenant Id for EntraId auth validation|APIOps|
    |ENTRAID_TENANT_GROUP_ALLCOMPANY_ID|EntraId group id for `All Company` EntraId group for syncing|APIOps|
    |FRONT_DOOR_ID|Azure Front Door Id that is used to ensure traffic is coming to APIM from FrontDoor in APIM Policy|APIOps|
    |POSTMAN_API_KEY|Postman api key for automation|Postman Testing Automation|

    | Variable Name | Description | Usage |
    | ------------- | ----------- | ---|
    |APIM_SERVICE_NAME |The name of the APIM instance to migrate from |APIOps|
    |APIM_RG_NAME|The name of the resource group the APIM instance is in|APIOps|
    |APIOPS_VERSION|This is the version of APIOps that I am using|APIOps|
    |LOG_LEVEL|Sets the log level as to what kind of logging will be displayed in the logs.|APIOps|

    *Note:* The names of the environments can be dev, stage etc. If using different names, update the run-extractor.yaml and run-publisher-with-env.yaml for the environment names. This would also be a good time to setup [deployment protection rules](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment#deployment-protection-rules) if you wish in the environment settings of GitHub.

- Grant permissions for the actions to create a PR. Set *Read and write permissions* and "Allow GitHub Actions to create and approve pull requests" under *{repository} -> Settings -> Actions -> General -> Workflow permissions*.

## Tech I'm using

- [APIOps](https://azure.github.io/apiops/)
- [Postman Collections](https://www.postman.com/collection/)
- Powershell and CLI [Scripts](https://github.com/anotherRedbeard/apimdemo-environment/tree/main/scripts) to create infra
- [APIM GenAI Gateway](https://techcommunity.microsoft.com/t5/azure-integration-services-blog/introducing-genai-gateway-capabilities-in-azure-api-management/ba-p/4146525)
- [bicep](https://github.com/anotherRedbeard/apimdemo-environment/tree/main/iac/bicep) to implement the GenAI features as well as general infrastructure to support everything else.

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

### Scripts

I have created a few scripts to help me test things out. There is currently no specific README for them, but each script has inline comments to describe what is happening. In the future I will move these into the bicep section and create a main file to deploy these specific setups.
