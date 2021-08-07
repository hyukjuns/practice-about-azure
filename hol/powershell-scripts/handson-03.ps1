$resourceGroup = "hjrg"
$location = "eastus"
$vnetName = "hjvnet01"
$vnetPrefix = "10.0.0.0/8"
$subnetPrefix = "10.1.0.0/16"
$subnetPrefix02 = "10.2.0.0/16"
$subnetPrefixBastion = "10.100.0.0/24"
$subnetName = "hjsubnet01"
$subnetName02 = "hjsubnet02"
$subnetNameBastion = "AzureBastionSubnet"
# Create Vnet
$virtualNetwork = New-AzVirtualNetwork `
  -ResourceGroupName $resourceGroup `
  -Location EastUS `
  -Name $vnetName `
  -AddressPrefix $vnetPrefix
# Create subnet
$subnetConfig = Add-AzVirtualNetworkSubnetConfig `
  -Name $subnetName `
  -AddressPrefix $subnetPrefix `
  -VirtualNetwork $virtualNetwork
$subnetConfig02 = Add-AzVirtualNetworkSubnetConfig `
  -Name $subnetName02 `
  -AddressPrefix $subnetPrefix02 `
  -VirtualNetwork $virtualNetwork
$subnetConfigBastion = Add-AzVirtualNetworkSubnetConfig `
  -Name $subnetNameBastion `
  -AddressPrefix $subnetPrefixBastion `
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
Set-AzVirtualNetworkSubnetConfig -Name $subnetName02 -VirtualNetwork $vnet -AddressPrefix $subnetPrefix02 `
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
$avsetName02 = "hjavset02"
$avset02 = New-AzAvailabilitySet `
   -Location $location `
   -Name $avsetName02 `
   -ResourceGroupName $resourceGroup `
   -Sku aligned `
   -PlatformFaultDomainCount 2 `
   -PlatformUpdateDomainCount 2


# Create Virtual Machine
$vm_local_admin_user = "USERNAME"
$vm_local_admin_user_password = ConvertTo-SecureString  -AsPlainText -Force
$computerName = "hjvm01"
$computerName02 = "hjvm02"
$vmName = "hjvm01"
$vmName02 = "hjvm02"
$vmSize = "Standard_DS1_v2"
$vnet = Get-AzVirtualNetwork -name $vnetName -ResourceGroupName $resourceGroup

$NICName = "hjvm01nic"
$NICName02 = "hjvm02nic"
$NIC = New-AzNetworkInterface -Name $NICName -ResourceGroupName $resourceGroup -Location $location -SubnetId $vnet.Subnets[0].Id
$NIC02 = New-AzNetworkInterface -Name $NICName02 -ResourceGroupName $resourceGroup -Location $location -SubnetId $vnet.Subnets[1].Id

# Identical Credential between vm01,vm02
$credential = New-Object System.Management.Automation.PSCredential ($vm_local_admin_user, $vm_local_admin_user_password);

# Create vm01
$VirtualMachine = New-AzVMConfig -VMName $vmName -VMSize $vmSize -AvailabilitySetId $avset.Id
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $computerName -Credential $credential -ProvisionVMAgent -EnableAutoUpdate
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2012-R2-Datacenter' -Version latest

New-AzVM -ResourceGroupName $resourceGroup -Location $location -VM $VirtualMachine -Verbose

#Create vm02
$VirtualMachine02 = New-AzVMConfig -VMName $vmName02 -VMSize $vmSize -AvailabilitySetId $avset02.Id
$VirtualMachine02 = Set-AzVMOperatingSystem -VM $VirtualMachine02 -Windows -ComputerName $computerName02 -Credential $credential -ProvisionVMAgent -EnableAutoUpdate
$VirtualMachine02 = Add-AzVMNetworkInterface -VM $VirtualMachine02 -Id $NIC02.Id
$VirtualMachine02 = Set-AzVMSourceImage -VM $VirtualMachine02 -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2012-R2-Datacenter' -Version latest

New-AzVM -ResourceGroupName $resourceGroup -Location $location -VM $VirtualMachine02 -Verbose

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
$lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $resourceGroup
$lb | Add-AzLoadBalancerInboundNatRuleConfig -Name "vm01NatRule" -FrontendIPConfiguration $lb.FrontendIpConfigurations[0] -Protocol "Tcp" -FrontendPort 5000 -BackendPort 3389
$lb | Set-AzLoadBalancer

$vm01NicInfo = get-aznetworkinterface -resourcegroup $resourceGroup
$vm01NicName = $vm01NicInfo[0].Name
$vm01ipconfigname = $vm01NicInfo[0].IpConfigurations.Name

$nic = Get-AzNetworkInterface -Name $vm01NicName -ResourceGroupName $resourceGroup
$bepool = $lb | Get-AzLoadBalancerBackendAddressPoolConfig
$NatRule = $lb | Get-AzLoadBalancerInboundNatRuleConfig

$lb = Get-AzLoadBalancer -Name "MyLoadBalancer" -ResourceGroupName $resourceGroup
Set-AzNetworkInterfaceIpConfig -Name $vm01ipconfigname -NetworkInterface $nic `
-LoadBalancerBackendAddressPool  $bepool `
-LoadBalancerInboundNatRule $NatRule

Set-AzNetworkInterface -NetworkInterface $nic

# Create Internal LoadBalancer
## Variables for the commands ##
$fe = 'hjinternal'
## Command to create frontend configuration. The variable $vnet is from the previous commands. ##
$feip = New-AzLoadBalancerFrontendIpConfig -Name $fe -SubnetId $vnet.subnets[1].Id

## Variable for the command ##
$be = 'hjInternalBackEndPool'
$bepool = New-AzLoadBalancerBackendAddressPoolConfig -Name $be

## Variables for the command ##
$hp = 'hjInternalHealthProbe'
$pro = 'http'
$port = '80'
$int = '360'
$cnt = '5'

$probe = New-AzLoadBalancerProbeConfig -Name $hp -Protocol $pro -Port $port -RequestPath / -IntervalInSeconds $int -ProbeCount $cnt

## Variables for the command ##
$lbr = 'hjInternalHTTPRule'
$pro = 'tcp'
$port = '80'
$idl = '15'

## $feip and $bePool are the variables from previous steps. ##

$rule = New-AzLoadBalancerRuleConfig -Name $lbr -Protocol $pro -Probe $probe -FrontendPort $port -BackendPort $port -FrontendIpConfiguration $feip -BackendAddressPool $bePool -DisableOutboundSNAT -IdleTimeoutInMinutes $idl -EnableTcpReset

## Variables for the command ##
$lbn = 'hjIntLoadBalancer'
$sku = 'Standard'

## $feip, $bepool, $probe, $rule are variables with configuration information from previous steps. ##
$lb = New-AzLoadBalancer -ResourceGroupName $resourceGroup -Name $lbn -SKU $sku -Location $location -FrontendIpConfiguration $feip -BackendAddressPool $bepool -Probe $probe -LoadBalancingRule $rule

$lb = Get-AzLoadBalancer -Name $lbn -ResourceGroupName $resourceGroup
$vm02NicInfo = get-aznetworkinterface -resourcegroup $resourceGroup
$vm02NicName = $vm02NicInfo[1].Name
$vm02ipconfigname = $vm02NicInfo[1].IpConfigurations.Name
$nic = Get-AzNetworkInterface -Name $vm02NicName -ResourceGroupName $resourceGroup
$bepool = $lb | Get-AzLoadBalancerBackendAddressPoolConfig

$lb = Get-AzLoadBalancer -Name "hjIntLoadBalancer" -ResourceGroupName $resourceGroup
Set-AzNetworkInterfaceIpConfig -Name $vm02ipconfigname -NetworkInterface $nic `
-LoadBalancerBackendAddressPool  $bepool 

Set-AzNetworkInterface -NetworkInterface $nic

# Create Bastion Host
## Variables for the command ##
$ipn = 'myPublicIPBastion'
$all = 'static'
$sku = 'standard'

$publicip = New-AzPublicIpAddress -ResourceGroupName $resourceGroup -Location $location -Name $ipn -AllocationMethod $all -Sku $sku

## Variables for the commands ##
$nmn = 'myBastion'
## Command to create bastion host. $vnet and $publicip are from the previous steps ##
New-AzBastion -ResourceGroupName $resourceGroup -Name $nmn -PublicIpAddress $publicip -VirtualNetwork $vnet

# FileShare
## Storage Account
$storageAccountName = "hjstorageacct$(Get-Random)"

$storageAcct = New-AzStorageAccount `
    -ResourceGroupName $resourceGroup `
    -Name $storageAccountName `
    -Location $location `
    -Kind StorageV2 `
    -SkuName Standard_ZRS `
    -EnableLargeFileShare

## Create FileShare
$shareName = "hjshare"

New-AzRmStorageShare `
-StorageAccount $storageAcct `
-Name $shareName `
-QuotaGiB 1024 | Out-Null

# Window에서 Azure 파일 공유 사용
## Azure 파일 공유 탑재(UNC 경로를 통해 액세스)
## Azure Portal에서 스크립트 확인

## FileShare Usage
### Create Directory
New-AzStorageDirectory `
   -Context $storageAcct.Context `
   -ShareName $shareName `
   -Path "myDirectory"
### Upload File
#### this expression will put the current date and time into a new file on your scratch drive
cd "~/CloudDrive/"
Get-Date | Out-File -FilePath "SampleUpload.txt" -Force

#### this expression will upload that newly created file to your Azure file share
Set-AzStorageFileContent `
   -Context $storageAcct.Context `
   -ShareName $shareName `
   -Source "SampleUpload.txt" `
   -Path "myDirectory\SampleUpload.txt"
##### 업로드 확인
Get-AzStorageFile `
    -Context $storageAcct.Context `
    -ShareName $shareName `
    -Path "myDirectory\"
### Download File
#### Delete an existing file by the same name as SampleDownload.txt, if it exists because you've run this example before.
Remove-Item `
    -Path "SampleDownload.txt" `
    -Force `
    -ErrorAction SilentlyContinue

Get-AzStorageFileContent `
    -Context $storageAcct.Context `
    -ShareName $shareName `
    -Path "myDirectory\SampleUpload.txt" `
    -Destination "SampleDownload.txt"

#### 다운로드 확인
Get-ChildItem | Where-Object { $_.Name -eq "SampleDownload.txt" }

### Copy File
$otherShareName = "myshare2"

New-AzRmStorageShare `
    -StorageAccount $storageAcct `
    -Name $otherShareName `
    -EnabledProtocol SMB `
    -QuotaGiB 1024 | Out-Null
  
New-AzStorageDirectory `
   -Context $storageAcct.Context `
   -ShareName $otherShareName `
   -Path "myDirectory2"

Start-AzStorageFileCopy `
    -Context $storageAcct.Context `
    -SrcShareName $shareName `
    -SrcFilePath "myDirectory\SampleUpload.txt" `
    -DestShareName $otherShareName `
    -DestFilePath "myDirectory2\SampleCopy.txt" `
    -DestContext $storageAcct.Context
#### 파일 복사 확인
Get-AzStorageFile `
    -Context $storageAcct.Context `
    -ShareName $otherShareName `
    -Path "myDirectory2"