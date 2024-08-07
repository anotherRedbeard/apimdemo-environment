# Bicep

This directory contains bicep templates that are used for various tasks in this project. If you want to use your own parameter files, this repo is setup to copy the `*.bicepparam` files and create your own with the `dev.bicepparam` extension. They will be ignored from check-in. I'm using [Azure Verifed Modules](https://azure.github.io/Azure-Verified-Modules/indexes/bicep/bicep-resource-modules/) where they exist to create these bicep files.

1. **APIM smart load balancing with circuit breaker**

    Prerequisites:
    - You will need to create 3 Azure OpenAPI endpoints in 3 different regions with 2 deployments (make sure you have the same model version in each region or it will fail). Here is what I have setup:
        | Region | Deployments (version) |
        | ------------- | ----------- |
        |South Central US | gpt-35-turbo (0301), text-embedding-ada-002(2) |
        |East US| gpt-35-turbo (0301), text-embedding-ada-002(2) |
        |West Europe|text-embedding-ada-002 (2)|

    `create-aoai-load-balancing.bicep` is the main template for this. Here we are creating 3 backends (these are OpenAI endpoints) in 3 different Azure regions and load balancing across each of them based on the deployment name. That is 2 backend pools, one for each deployment. This setup is using Round Robin, but there are ways to use weighted and priority in the backend pools. You can find more info in the [load balancing options](https://learn.microsoft.com/en-us/azure/api-management/backends?tabs=bicep#load-balancing-options) doc.

2. **APIM create a backend**

    `create-apim-backend.bicep` is the main template to create a new backend in APIM.

3. **Create base APIM instance**

    `create-base-apim.bicep` is the main template to create a base developer instance of API Management. I will be adding to this any dependency that I need to recreate my dev environment.

    What's Included:

    - Developer sku of API management
    - Application Insights *(coming soon)*
    - Identities for the developer portal *(coming soon)*
    - OAuth2.0 servers to handle authentication *(coming soon)*
    - Diagnostic Loggers *(coming soon)*

## Deploying with Bicep

Bicep is an Infrastructure as Code (IaC) language developed by Microsoft for deploying Azure resources in a declarative manner. It simplifies the deployment process and enhances readability and maintainability of your infrastructure code. Here is the [official Bicep documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)

### Prerequisites

Before you begin, ensure you have the following installed:

- Azure CLI: Bicep is integrated directly into the Azure CLI and provides first-class support for deploying Bicep files.
- Bicep CLI: While not strictly necessary due to Azure CLI integration, the Bicep CLI can be useful for compiling, decompiling, and validating Bicep files.

### Steps to Deploy

1. **Login to Azure**

    Start by logging into Azure with the Azure CLI:

    ```bash
    az login
    ```

2. **Set your subscription**

    Make sure you're working with the correct Azure subscription:

    ```bash
    az account set --subscription "<Your-Subscription-ID>"
    ```

3. **Compile Bicep file (Optional)

    If you have Bicep CLI installed, you can manually compile your Bicep file to an ARM template. This step is optional because Azure CLI compiles Bicep files automatically on deployment.

    ```bash
    bicep build <your-file>.bicep
    ```

4. **Deploy the Bicep file**

    Use the Azure CLI to deploy your Bicep file. Replace `<your-resource-group>` with your Azure Resource Group name, and `<your-deployment-name>` with a name for your deployment.  **Note**: since we are using bicep parameter files and they are tied to one bicep file we don't need the --template-file switch.  See [Bicep file with parameters file](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/parameter-files?tabs=Bicep#deploy-bicep-file-with-parameters-file) for more info.

    ```bash
    az deployment group create --resource-group <your-resource-group> --name <your-deployment-name> --parameters <your-file>.bicepparam
    ```
