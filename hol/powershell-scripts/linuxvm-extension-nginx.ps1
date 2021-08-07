# Linux vm Ubuntu18.04
# Extension waagent Verison 2.2.41

# var for common values
$rg_name = 'hjrg'
$location = 'koreacentral'
$vmName = 'hjlinuxvm00'

# username and password
$securePassword = ConvertTo-SecureString 'PASSWORD' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("USERNAME", $securePassword)

# Create a resource group
New-AzResourceGroup -Name $rg_name -Location $location

# Create a subnet configuration
## SubnetConfig
$subnetConfig = New-AzVirtualNetworkSubnetConfig -Name hjSubnet -AddressPrefix 192.168.1.0/24

## Create a virtual network
$vnet = New-AzVirtualNetwork -ResourceGroupName $rg_name -Location $location `
-Name hjVnet -AddressPrefix 192.168.0.0/16 -Subnet $subnetConfig

# Create a public IP address and  specify a DNS name
$pip = New-AzPublicIpAddress -ResourceGroupName $rg_name -Location $location `
-Name "hjpublicdns$(Get-Random)" -AllocationMethod Static -IdleTimeoutInMinutes 4

# Create an nsg rule for ssh, port 22
$nsgRuleSSH = New-AzNetworkSecurityRuleConfig -Name allowSSH `
-Priority 110 `
-Direction Inbound `
-Protocol Tcp `
-SourceAddressPrefix * `
-SourcePortRange * `
-DestinationAddressPrefix * `
-DestinationPortRange 22 `
-Access Allow
# Create an nsg rule for http, port 80
$nsgRuleHTTP = New-AzNetworkSecurityRuleConfig -Name allowHTTP `
-Priority 120 `
-Direction Inbound `
-Protocol Tcp `
-SourceAddressPrefix * `
-SourcePortRange * `
-DestinationAddressPrefix * `
-DestinationPortRange 80 `
-Access Allow
# Create a nsg
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $rg_name -Location $location `
-Name hjnsg00 -SecurityRules $nsgRuleSSH,$nsgRuleHTTP

# Create a NIC and Associate with public ip address and dns
$nic = New-AzNetworkInterface -ResourceGroupName $rg_name -Location $location `
-Name hjnic -SubnetID $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id

# Create a VM Configuration
# Get available vm size >> get-azvmsize -location koreacentral
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize Standard_DS1_v2 | `
Set-AzVMOperatingSystem -Linux -ComputerName $VmName -Credential $cred | `
Set-AzVMSourceImage -PublisherName Canonical -Offer UbuntuServer -Skus 18.04-LTS -Version latest | `
Add-AzVMNetworkInterface -Id $nic.Id

# Create a VM
New-AzVM -ResourceGroupName $rg_name -Location $location -VM $vmConfig

# Install NGINX
$PublicSettings = '{"commandToExecute":"apt -y update && apt -y install nginx"}'

Set-AzVMExtension -ExtensionName "NGINX" -ResourceGroupName $rg_name -VMName $vmName `
  -Publisher "Microsoft.Azure.Extensions" -ExtensionType "CustomScript" -TypeHandlerVersion 2.0 `
  -SettingString $PublicSettings -Location $location