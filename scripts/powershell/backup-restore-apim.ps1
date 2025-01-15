# Define variables for resource group and subscription
param (
    [string]$operation,
    [string]$subscriptionId,
    [string]$apimName,
    [string]$apimResourceGroup,
    [string]$storageAccountName,
    [string]$storageAccountResourceGroup,
    [string]$container,
    [string]$backupName
)

# Prompt for input if not provided
if (-not $operation) {
    $operation = Read-Host "Enter the operation (backup or restore)"
}
if (-not $subscriptionId) {
    $subscriptionId = Read-Host "Enter the subscription ID"
}
if (-not $apimName) {
    $apimName = Read-Host "Enter the API Management instance name"
}
if (-not $apimResourceGroup) {
    $apimResourceGroup = Read-Host "Enter the API Management resource group name"
}
if (-not $storageAccountName) {
    $storageAccountName = Read-Host "Enter the storage account name"
}
if (-not $storageAccountResourceGroup) {
    $storageAccountResourceGroup = Read-Host "Enter the storage account resource group name"
}
if (-not $container) {
    $container = Read-Host "Enter the container name"
}
if (-not $backupName) {
    $backupName = Read-Host "Enter the backup name"
}

# get debug output
$DebugPreference = "Continue"

# Set the subscription context
Set-AzContext -SubscriptionId $subscriptionId

# Debugging information
Write-Output "Operation: $operation"
Write-Output "API Management Name: $apimName"
Write-Output "API Management Resource Group: $apimResourceGroup"
Write-Output "Storage Account Name: $storageAccountName"
Write-Output "Storage Account Resource Group: $storageAccountResourceGroup"
Write-Output "Container: $container"
Write-Output "Backup Name: $backupName"

# Create a storage context
$storageContext = New-AzStorageContext -StorageAccountName $storageAccountName

# Perform the backup or restore operation
if ($operation -eq "backup") {
    Write-Output "Backing up API Management instance..."
    Backup-AzApiManagement -ResourceGroupName $apimResourceGroup -Name $apimName -StorageContext $storageContext -TargetContainerName $container -TargetBlobName $backupName -AccessType "SystemAssignedManagedIdentity"
}
elseif ($operation -eq "restore") {
    Write-Output "Restoring API Management instance..."
    Restore-AzApiManagement -ResourceGroupName $apimResourceGroup -Name $apimName -StorageContext $storageContext -SourceContainerName $container -SourceBlobName $backupName -AccessType "SystemAssignedManagedIdentity"
}
else {
    Write-Output "Invalid operation. Please specify 'backup' or 'restore'."
}