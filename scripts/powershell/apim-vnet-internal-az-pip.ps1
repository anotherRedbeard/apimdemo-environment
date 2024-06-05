# Define variables for resource group and subscription
param (
    [string]$subscriptionId = "<your subscription ID>",
    [string]$resourceGroupName = "myRG",
    [string]$apimName = "myTestAPIMInstance020",
    [string]$subnetName = "MyAPIMPremTest",
    [string]$vnetName = "myApimVNetTest",
    [string]$location = "South Central US",
    [string]$org = "Contoso",
    [string]$adminEmail = "<your admin email>",
    [string]$vpnType = "Internal",
    [string]$publicIpName = "myAPIMPTestIP",
    [string]$publicIpDomainName = "brdtest"
)

#get debug output
$DebugPreference = "Continue"

# Create a public IP address
$publicIp = New-AzPublicIpAddress -Name $publicIpName -ResourceGroupName $resourceGroupName -Location $location -AllocationMethod Static -DomainNameLabel $publicIpDomainName

# Define the resource ID for the VNet and subnet
$vnetResourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Network/virtualNetworks/$vnetName"
$subnetResourceId = "$vnetResourceId/subnets/$subnetName"

# Create a PsApiManagementVirtualNetwork object
$virtualNetwork = New-Object -TypeName Microsoft.Azure.Commands.ApiManagement.Models.PsApiManagementVirtualNetwork
$virtualNetwork.SubnetResourceId = $subnetResourceId

# Create the API Management instance with VNet integration and internal mode
New-AzApiManagement -ResourceGroupName $resourceGroupName -Name $apimName -Location $location -Organization $org -AdminEmail $adminEmail -Sku Premium -Capacity 3 -Zone @("1","2","3") -VirtualNetwork $virtualNetwork -VpnType $vpnType -PublicIpAddressId $publicIp.Id
