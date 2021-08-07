$resourceGroup = "hjrg"
$vnetPrefix = "10.0.0.0/8"
$subnetPrefix = "10.1.0.0/16"
$location = "eastus"
$vnetName = "hjvnet01"
$subnetName = "hjsubnet01"

# Create Vnet
echo "Create Vnet"
$virtualNetwork = New-AzVirtualNetwork `
  -ResourceGroupName $resourceGroup `
  -Location EastUS `
  -Name $vnetName `
  -AddressPrefix $vnetPrefix

# Create subnet
echo "Create Subnet"
  $subnetConfig = Add-AzVirtualNetworkSubnetConfig `
  -Name $subnetName `
  -AddressPrefix $subnetPrefix `
  -VirtualNetwork $virtualNetwork

# Connect Vnet and Subnet
$virtualNetwork | Set-AzVirtualNetwork

# Create NSG & Adding nsg rules
$nsgName = "hjnsg01"
New-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $resourceGroup  -Location  $location

Get-AzNetworkSecurityGroup -Name  $nsgName -ResourceGroupName $resourceGroup | 
Add-AzNetworkSecurityRuleConfig -Name RDP -Description "Allow RDP" `
-Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
-SourceAddressPrefix * -SourcePortRange * `
-DestinationAddressPrefix * -DestinationPortRange 3389 | 
Set-AzNetworkSecurityGroup

Get-AzNetworkSecurityGroup -Name  $nsgName -ResourceGroupName $resourceGroup | 
Add-AzNetworkSecurityRuleConfig -Name HTTP -Description "Allow HTTP" `
-Access Allow -Protocol Tcp -Direction Inbound -Priority 110 `
-SourceAddressPrefix * -SourcePortRange * `
-DestinationAddressPrefix * -DestinationPortRange 80 | 
Set-AzNetworkSecurityGroup

Get-AzNetworkSecurityGroup -Name  $nsgName -ResourceGroupName $resourceGroup | 
Add-AzNetworkSecurityRuleConfig -Name ICMP -Description "Allow ICMP" `
-Access Allow -Protocol Tcp -Direction Inbound -Priority 120 `
-SourceAddressPrefix * -SourcePortRange * `
-DestinationAddressPrefix * -DestinationPortRange * | 
Set-AzNetworkSecurityGroup

# Associate nsg to subnet
$vnet = Get-AzVirtualNetwork -name $vnetName -ResourceGroupName $resourceGroup
$nsg = Get-AzNetworkSecurityGroup -name $nsgName -ResourceGroupName $resourceGroup
Set-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet -AddressPrefix $subnetPrefix `
-NetworkSecurityGroup $nsg
$vnet | Set-AzVirtualNetwork

# Create Availability Set
$avsetName = "hjavset"
$avset = New-AzAvailabilitySet `
   -Location $location `
   -Name $avsetName `
   -ResourceGroupName $resourceGroup `
   -Sku aligned `
   -PlatformFaultDomainCount 2 `
   -PlatformUpdateDomainCount 2

# Create Virtual Machine
$vm_local_admin_user = "USERNAME"
$vm_local_admin_user_password = ConvertTo-SecureString  -AsPlainText -Force
$computerName = "hjvm01"
$vmName = "hjvm01"
$vmSize = "Standard_DS1_v2"
$vnet = Get-AzVirtualNetwork -name $vnetName -ResourceGroupName $resourceGroup

$NICName = "hjvm01nic"
$NIC = New-AzNetworkInterface -Name $NICName -ResourceGroupName $resourceGroup -Location $location -SubnetId $vnet.Subnets[0].Id

$credential = New-Object System.Management.Automation.PSCredential ($vm_local_admin_user, $vm_local_admin_user_password);

$VirtualMachine = New-AzVMConfig -VMName $vmName -VMSize $vmSize -AvailabilitySetId $avset.Id
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $computerName -Credential $credential -ProvisionVMAgent -EnableAutoUpdate
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2012-R2-Datacenter' -Version latest

New-AzVM -ResourceGroupName $resourceGroup -Location $location -VM $VirtualMachine -Verbose

# Create Public LoadBalancer
$publicip = @{
    Name = 'hjpip'
    ResourceGroupName = $resourceGroup
    Location = $location
    Sku = 'Standard'
    AllocationMethod = 'static'
}
New-AzPublicIpAddress @publicip

## Place public IP created in previous steps into variable. ##
$publicIp = Get-AzPublicIpAddress -Name $publicip.Name -ResourceGroupName $resourceGroup

## Create load balancer frontend configuration and place in variable. ##
$feip = New-AzLoadBalancerFrontendIpConfig -Name 'myFrontEnd' -PublicIpAddress $publicIp

## Create backend address pool configuration and place in variable. ##
$bepool = New-AzLoadBalancerBackendAddressPoolConfig -Name 'myBackEndPool'

## Create the health probe and place in variable. ##
$probe = @{
    Name = 'myHealthProbe'
    Protocol = 'http'
    Port = '80'
    IntervalInSeconds = '360'
    ProbeCount = '5'
    RequestPath = '/'
}
$healthprobe = New-AzLoadBalancerProbeConfig @probe

## Create the load balancer rule and place in variable. ##
$lbrule = @{
    Name = 'myHTTPRule'
    Protocol = 'tcp'
    FrontendPort = '80'
    BackendPort = '80'
    IdleTimeoutInMinutes = '15'
    FrontendIpConfiguration = $feip
    BackendAddressPool = $bePool
}
$rule = New-AzLoadBalancerRuleConfig @lbrule -EnableTcpReset -DisableOutboundSNAT

## Create the load balancer resource. ##
$lbName = "myLoadBalancer"
$loadbalancer = @{
    ResourceGroupName = $resourceGroup
    Name = $lbName
    Location = 'eastus'
    Sku = 'Standard'
    FrontendIpConfiguration = $feip
    BackendAddressPool = $bePool
    LoadBalancingRule = $rule
    Probe = $healthprobe
}
New-AzLoadBalancer @loadbalancer

# Add VM to loadbalancer backend pool and Create InboundNatRule(Attach VM)
# Create Inbound NAT Rule
$lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $resourceGroup
$lb | Add-AzLoadBalancerInboundNatRuleConfig -Name "vm01NatRule" -FrontendIPConfiguration $lb.FrontendIpConfigurations[0] -Protocol "Tcp" -FrontendPort 5000 -BackendPort 3389
$lb | Set-AzLoadBalancer

# Get nic info 
$vm01NicInfo = get-aznetworkinterface -resourcegroup $resourceGroup
$vm01NicName = $vm01NicInfo.Name
$nic = Get-AzNetworkInterface -Name $vm01NicName -ResourceGroupName $resourceGroup

# Get Backend pool info, InboundNatRule info
$bepool = $lb | Get-AzLoadBalancerBackendAddressPoolConfig
$NatRule = $lb | Get-AzLoadBalancerInboundNatRuleConfig

# Associate nic to bepool, inboundNatRule
$lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $resourceGroup
Set-AzNetworkInterfaceIpConfig -Name ipconfig1 -NetworkInterface $nic `
-LoadBalancerBackendAddressPool  $bepool `
-LoadBalancerInboundNatRule $NatRule

Set-AzNetworkInterface -NetworkInterface $nic