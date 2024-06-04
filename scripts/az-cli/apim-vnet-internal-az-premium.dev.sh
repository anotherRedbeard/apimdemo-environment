# Variables
resourceGroupName="myRG"
vnetName="myApimVNetTest"
subnetName="MyAPIMPremTest"
location="South Central US"
apiManagementName="myTestAPIMInstance020"
organizationName="Contoso"
adminEmail="<your admin email>"
sku="Premium"
capacity=3
zones=("1" "2" "3")
virtualNetworkType="Internal"

# Create Resource Group if it doesn't exist
az group create --name $resourceGroupName --location "$location"

# Create VNet and Subnet
az network vnet create --resource-group $resourceGroupName --name $vnetName --address-prefix "10.21.0.0/16" --location "$location"
az network vnet subnet create --resource-group $resourceGroupName --vnet-name $vnetName --name 'default' --address-prefix "10.21.0.0/24"
az network vnet subnet create --resource-group $resourceGroupName --vnet-name $vnetName --name $subnetName --address-prefix "10.21.1.0/27"


# Create the API Management instance with VNet integration and internal mode
az apim create --resource-group $resourceGroupName \
    --name $apiManagementName \
    --location "$location" \
    --publisher-email $adminEmail \
    --publisher-name $organizationName \
    --sku-name $sku \
    --sku-capacity $capacity \
    --zones ${zones[@]}

# Get apim id
apiManagementName=$(az apim list --resource-group $resourceGroupName --query "[0].id" --output tsv)

# Get the subnet ID
subnetId=$(az network vnet subnet show --resource-group $resourceGroupName --vnet-name $vnetName --name $subnetName --query id --output tsv)

# Update the API Management instance to use the VNet in internal mode
az resource update --ids $apiManagementName \
    --set properties.virtualNetworkConfiguration.subnetResourceId=$subnetId \
    --set properties.virtualNetworkType=$virtualNetworkType