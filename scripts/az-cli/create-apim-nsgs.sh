#!/bin/bash

# Variables for resource group, location, and NSG names
RESOURCE_GROUP="resourceGroupName"
LOCATION="location"
NSG_NAME="nsgName"
VNET_NAME="vnetName"
SUBNET_NAME="subnetName"

# Input parameter for NSG type (internal or external)
TYPE=$1

if [[ $TYPE != "internal" && $TYPE != "external" ]]; then
  echo "Please specify the type as 'internal' or 'external'."
fi

# Create NSG based on the type
if [ "$TYPE" == "external" ]; then
  echo "Creating NSG and rules for External setup..."
  az network nsg create --resource-group $RESOURCE_GROUP --name $NSG_NAME --location $LOCATION

  # Define rules for External NSG
  az network nsg rule create --resource-group $RESOURCE_GROUP --nsg-name $NSG_NAME --name "AllowFromInternetToVNet" \
    --priority 100 --access Allow --direction Inbound --protocol Tcp --source-address-prefix 'Internet' \
    --source-port-range '*' --destination-address-prefix 'VirtualNetwork' --destination-port-ranges 80 443

  az network nsg rule create --resource-group $RESOURCE_GROUP --nsg-name $NSG_NAME --name "AllowFromTrafficManagerToVNet" \
    --priority 110 --access Allow --direction Inbound --protocol Tcp --source-address-prefix 'AzureTrafficManager' \
    --source-port-range '*' --destination-address-prefix 'VirtualNetwork' --destination-port-ranges 443

fi

  # Define outbound rules common to both NSGs
  COMMON_RULES=(
    "AllowFromAPIMToVNet 3443 ApiManagement VirtualNetwork Inbound 120"
    "AllowFromALBToVNet 6390 AzureLoadBalancer VirtualNetwork Inbound 130"
    "AllowFromVNetToStorage 443 VirtualNetwork Storage Outbound 120"
    "AllowFromVNetToSQL 1443 VirtualNetwork Sql Outbound 130"
    "AllowFromVNetToKeyVault 443 VirtualNetwork AzureKeyVault Outbound 140"
    "AllowFromVNetToAzureMonitor [1886,443] VirtualNetwork AzureMonitor Outbound 150"
  )

  for RULE in "${COMMON_RULES[@]}"; do
    IFS=' ' read -r NAME PORT SOURCE DESTINATION DIRECTION PRIORITY <<< "$RULE"
    COMMAND="az network nsg rule create --resource-group $RESOURCE_GROUP --nsg-name $NSG_NAME --name \"$NAME\" --priority $PRIORITY --access Allow --direction $DIRECTION --protocol Tcp --source-address-prefix $SOURCE --source-port-range '*' --destination-address-prefix $DESTINATION --destination-port-ranges $PORT"
    echo "Creating rule: $COMMAND"
    eval $COMMAND
  done

echo "Network Security Group and rules created successfully for $TYPE setup."

# Associate NSG with the subnet
echo "Associating NSG with the subnet..."
az network vnet subnet update --resource-group $RESOURCE_GROUP --vnet-name $VNET_NAME --name $SUBNET_NAME --network-security-group $NSG_NAME
