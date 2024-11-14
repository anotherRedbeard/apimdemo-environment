# Scripts Directory

This directory contains scripts that are used for various tasks in this project. If you notice in the `.gitignore` I am ignoring anything in this folder with a .dev in the name so you can save you specific settings in a copy of each of these files. That way you can come back to your code and test as you like.

## Directory Structure

The `scripts` directory has the following structure:

### az-cli

This directory contains scripts written for the Azure Command-Line Interface (CLI). These scripts are used to interact with Azure services.

#### apim-vnet-internal-az-premium.sh

This will create a virtual network with 2 subnets. Then it will create the apim resource. Once that is complete it will use the ARM api to update the virtual network

#### create-apim-nsgs.sh

This will create all the documented nsg that you need and it will do that based on the parameter you give it (either Internal or External). It's based on the rules from [this document](https://learn.microsoft.com/en-us/azure/api-management/api-management-using-with-vnet?tabs=stv2#configure-nsg-rules).

#### create-apim-automate-devportal-classic-skus.sh

Prerequisites:

- jq library for JSON parsing.

    ```bash
    brew install jq
    ```

- playwright library so you can execute the browser call

    ```bash
    npx playwright install
    ```

This will create an APIM resource and then proceed to automate the provisioning of the developer portal for the Classic SKUs. For the v2 SKUs you just need to set the `developerPortalStatus` property to 'Enabled' and that will provision the portal for you.  This is a bit involved as you need to call a few APIs to get the SSO token with the Developer Portal url. It then uses Playwright (any headless browser will do here) to call that URL just as an Admin would for the provisioning of the portal the first time. Then it runs the REST api to create a new revision which publishes the portal and then it's ready for use.

### powershell

This directory contains PowerShell scripts. PowerShell is a cross-platform task automation solution made up of a command-line shell, a scripting language, and a configuration management framework. These scripts are used for various tasks such as setting up the environment, running tests, and deploying the application.

#### apim-vnet-internal-az-wo-pip.ps1

This will use existing vNet to create an Azure API resource with availability zones enabled, vNet integration in Internal mode.

Currently this requires a Public IP, so this script will fail, but that requirement should go away soon.

#### apim-vnet-internal-az-pip.ps1

This will use existing vNet to create an Azure API resource with availability zones enabled, vNet integration in Internal mode and it will create a new public IP and use it in the APIM creation.

## Usage

Right now these directories hold example files, but i'm working to make them more usable with pipelines and such.
