# Scripts Directory

This directory contains scripts that are used for various tasks in this project.

## Directory Structure

The `scripts` directory has the following structure:

### az-cli

This directory contains scripts written for the Azure Command-Line Interface (CLI). These scripts are used to interact with Azure services.

#### apim-vnet-internal-az-premium.sh

This will create a virtual network with 2 subnets. Then it will create the apim resource. Once that is complete it will use the ARM api to update the virtual network

### powershell

This directory contains PowerShell scripts. PowerShell is a cross-platform task automation solution made up of a command-line shell, a scripting language, and a configuration management framework. These scripts are used for various tasks such as setting up the environment, running tests, and deploying the application.

#### apim-vnet-internal-az-wo-pip.ps1

This will use existing vNet to create an Azure API resource with availability zones enabled, vNet integration in Internal mode.

Currently this requires a Public IP, so this script will fail, but that requirement should go away soon.

#### apim-vnet-internal-az-pip.ps1

This will use existing vNet to create an Azure API resource with availability zones enabled, vNet integration in Internal mode and it will create a new public IP and use it in the APIM creation.

## Usage

Right now these directories hold example files, but i'm working to make them more usable