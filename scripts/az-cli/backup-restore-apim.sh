#!/bin/bash

# Check if the required arguments are provided
if [ "$#" -lt 7 ]; then
    echo "Usage: $0 <operation> <api_management_name> <api_management_resource_group> <storage_account_name> <storage_resource_group> <container_name> <backup_name>"
    echo "operation: backup or restore"
    return 1
fi

# Assign arguments to variables
OPERATION=$1
API_MANAGEMENT_NAME=$2
API_MANAGEMENT_RESOURCE_GROUP=$3
STORAGE_ACCOUNT_NAME=$4
STORAGE_RESOURCE_GROUP=$5
CONTAINER_NAME=$6
BACKUP_NAME=$7

# Get the storage account key
# This requires the az CLI to be logged in and the storage account needs to have 'Allow storage account key access' enabled
# AZ CLI does not have ability to use managed identity so to use that I would recommend using the powershell commands
echo "Getting storage account key..."
STORAGE_KEY=$(az storage account keys list --resource-group $STORAGE_RESOURCE_GROUP --account-name $STORAGE_ACCOUNT_NAME --query [0].value --output tsv)

if [ -z "$STORAGE_KEY" ]; then
    echo "Failed to retrieve storage account key."
    return 1
fi

# Perform the backup or restore operation
if [ "$OPERATION" == "backup" ]; then
    echo "Performing backup..."
    az apim backup --resource-group $API_MANAGEMENT_RESOURCE_GROUP --name $API_MANAGEMENT_NAME --storage-account-name $STORAGE_ACCOUNT_NAME --storage-account-key $STORAGE_KEY --storage-account-container $CONTAINER_NAME --backup-name $BACKUP_NAME
elif [ "$OPERATION" == "restore" ]; then
    echo "Performing restore..."
    az apim restore --resource-group $API_MANAGEMENT_RESOURCE_GROUP --name $API_MANAGEMENT_NAME --storage-account-name $STORAGE_ACCOUNT_NAME --storage-account-key $STORAGE_KEY --storage-account-container $CONTAINER_NAME --backup-name $BACKUP_NAME
else
    echo "Invalid operation. Use 'backup' or 'restore'."
    return 1
fi

echo "Operation $OPERATION completed successfully."