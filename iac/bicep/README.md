# Bicep

This directory contains scripts that are used for various tasks in this project.

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

### Folder structure

We have this folder broken down into the modules folder and then the main bicep files. Below is a description of each of the main files and what modules they use

#### create-aoai-load-balancing.bicep

This file will create 2 circuit breaker gateways and 2 backend pools based on region using the `apim-circuit-breaker-backends.bicep` and `apim-load-balance-backendpool.bicep` modules.  Follow the steps to deploy above to deploy this to your subscription.

