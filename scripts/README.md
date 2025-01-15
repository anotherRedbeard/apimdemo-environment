# Scripts Directory

This directory contains scripts that are used for various tasks in this project. If you notice in the `.gitignore` I am ignoring anything in this folder with a .dev in the name so you can save you specific settings in a copy of each of these files. That way you can come back to your code and test as you like.

## Directory Structure

The `scripts` directory has the following structure:

### az-cli

This directory contains scripts written for the Azure Command-Line Interface (CLI). These scripts are used to interact with Azure services.

#### ./apim-vnet-internal-az-premium.sh

This will create a virtual network with 2 subnets. Then it will create the apim resource. Once that is complete it will use the ARM api to update the virtual network

#### ./create-apim-nsgs.sh

This will create all the documented nsg that you need and it will do that based on the parameter you give it (either Internal or External). It's based on the rules from [this document](https://learn.microsoft.com/en-us/azure/api-management/api-management-using-with-vnet?tabs=stv2#configure-nsg-rules).

#### ./create-apim-automate-devportal-classic-skus.sh

This will create an APIM resource and then proceed to automate the provisioning of the developer portal for the Classic SKUs. For the v2 SKUs you just need to set the `developerPortalStatus` property to 'Enabled' and that will provision the portal for you.  This is a bit involved as you need to call a few APIs to get the SSO token with the Developer Portal url. It then uses Playwright (any headless browser will do here) to call that URL just as an Admin would for the provisioning of the portal the first time. Then it runs the REST api to create a new revision which publishes the portal and then it's ready for use.

- **Prerequisites:**

  - jq library for JSON parsing.

    ```bash
    brew install jq
    ```

  - playwright library so you can execute the browser call

    ```bash
    npx playwright install
    ```

#### ./backup-restore-apim.sh

This is an example of how you can backup and restore an APIM instance using the `az cli`.  This process is documented [here](https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-disaster-recovery-backup-restore?tabs=cli).  The basics of this process is that the backup command saves a file into a storage account and the restore command uses that backup file to populate an APIM instance from the backup.  Currently the `az cli` only supports using a SAS token and the current recommendation is to use the PowerShell commands to do this using Managed Identities, but this is an example of how it can work using SAS tokens with the storage account.  

- **Prerequisites:**

  - AZ CLI
    - You must also already be logged in using `az login` with an account that has Contributor or higher on the APIM instance before running the script
  - API Management Service Instance(s)
    - You will need at least one APIM service instance, if you want to backup one and restore into another instance then you will need both of those instances created already
    - Check out my bicep template to [create a base instance](https://github.com/anotherRedbeard/apimdemo-environment/tree/main/iac/bicep#create-base-apim-instance) if you need help getting an instance created
  - Azure Storage Account
    - Create a container to hold the backup file

There are 7 parameters needed to run this script and they must be passed in the following order:

1. **Operation Name**: backup or restore
2. **API Management Service Name**:  Name of the API Management you are testing with
3. **API Management Resource Group Name**: Name of the resource group where you APIM instance resides
4. **Storage Account Name**: Name of the storage account where you will be storing the backup file
5. **Storage Account Resource Group Name**: Name of the resource group where you storage account resides
6. **Container Name**: This is the of the container where you backup file will be stored
7. **Backup File Name**: Name of the backup file

#### ./trace-apim-example.sh

This is an example of how you can trace a call in APIM by using these [instructions](https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-api-inspector#enable-tracing-for-an-api).
The general steps are as follows:

> 1. Obtain a token credential for tracing.
> 2. Add the token value in an `Apim-Debug-Authorization` request header to the API Management gateway.
> 3. Obtain a trace ID in the `Apim-Trace-Id` response header.
> 4. Retrieve the trace corresponding to the trace ID.

- **Prerequisites:**

  - AZ CLI
    - You must also already be logged in using `az login` with an account that has Contributor or higher on the APIM instance before running the script

There are 6 parameters needed to run this script and they must be passed in the following order:

1. **Subscription ID**: This is your subscription ID
2. **Resource Group Name**: Name of the resource group where you APIM instance resides
3. **API Mananagement Service Name**:  Name of the API Management you are testing with
4. **API Name**: Name of the api you are testing
5. **URL Encoded URI**: This is the URL encoded URL that you are attempting to test in APIM
6. **API Management Subscription Key**: Subscription key to use with the APIM call you are making

The script outputs the response from the API call as well as the trace log assuming everything goes well. I wrote this to help folks out attempting to trace API calls until more tooling becomes available.

### powershell

This directory contains PowerShell scripts. PowerShell is a cross-platform task automation solution made up of a command-line shell, a scripting language, and a configuration management framework. These scripts are used for various tasks such as setting up the environment, running tests, and deploying the application.

#### apim-vnet-internal-az-wo-pip.ps1

This will use existing vNet to create an Azure API resource with availability zones enabled, vNet integration in Internal mode.

Currently this requires a Public IP, so this script will fail, but that requirement should go away soon.

#### apim-vnet-internal-az-pip.ps1

This will use existing vNet to create an Azure API resource with availability zones enabled, vNet integration in Internal mode and it will create a new public IP and use it in the APIM creation.

#### backup-resotre-apim.ps1

This is an example of how you can backup and restore an APIM instance using the `powershell`.  This process is documented [here](https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-disaster-recovery-backup-restore?tabs=powershell).  The basics of this process is that the backup command saves a file into a storage account and the restore command uses that backup file to populate an APIM instance from the backup.  This example is using a system assigned managed identity so you will need to grant `Storage Blob Data Contributor` role to the managed identity on the storage account.

- **Prerequisites:**

  - Install [Azure PowerShell](https://learn.microsoft.com/en-us/powershell/azure/install-azure-powershell?view=azps-13.1.0)
    - You must also already be logged in using `az login` with an account that has Contributor or higher on the APIM instance before running the script
  - API Management Service Instance(s)
    - You will need at least one APIM service instance, if you want to backup one and restore into another instance then you will need both of those instances created already
    - Check out my bicep template to [create a base instance](https://github.com/anotherRedbeard/apimdemo-environment/tree/main/iac/bicep#create-base-apim-instance) if you need help getting an instance created
  - Azure Storage Account
    - Create a container to hold the backup file

There are 8 parameters needed to run this script:

1. **operation**: backup or restore
2. **subscriptionId**: This is your subscription ID for the API Management and Storage account
3. **apimName**:  Name of the API Management you are testing with
4. **apimResourceGroup**: Name of the resource group where you APIM instance resides
5. **storageAccountName**: Name of the storage account where you will be storing the backup file
6. **storageAccountResourceGroup**: Name of the resource group where you storage account resides
7. **container**: This is the of the container where you backup file will be stored
8. **backupName**: Name of the backup file

## Usage

Right now these directories hold example files, but i'm working to make them more usable with pipelines and such.
