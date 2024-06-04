# Define variables for resource group and subscription
$subscriptionId = "<Subscription ID>"
$resourceGroupName = "myRG"
$apimName = "myTestAPIMInstance020"
$subnetName = "MyAPIMPremTest"
$vnetName = "myApimVNetTest"
$location = "South Central US"
$org = "Contoso"
$adminEmail = "<your admin email>"
$vpnType = "Internal"

# Define the resource ID for the VNet and subnet
$vnetResourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Network/virtualNetworks/$vnetName"
$subnetResourceId = "$vnetResourceId/subnets/$subnetName"

# Create a PsApiManagementVirtualNetwork object
$virtualNetwork = New-Object -TypeName Microsoft.Azure.Commands.ApiManagement.Models.PsApiManagementVirtualNetwork
$virtualNetwork.SubnetResourceId = $subnetResourceId

# Create the API Management instance with VNet integration and internal mode
New-AzApiManagement -ResourceGroupName $resourceGroupName -Name $apimName -Location $location -Organization $org -AdminEmail $adminEmail -Sku Premium -Capacity 3 -Zone @("1","2","3") -VirtualNetwork $virtualNetwork -VpnType $vpnType
