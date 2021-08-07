# **Hands-On 1 의 구성에서 VM대신 VMSS 사용** 
# Create VMSS with External Loadbalancer
# version 1. Create a VMSS using the **`DefaultParameterSet`**
# [Docs](https://docs.microsoft.com/ko-kr/powershell/module/az.compute/new-azvmss?view=azps-5.2.0)
# Common
$LOC = "EastUS";
$RGName = "hjrg";

# SRP
$STOName = "sto" + $RGName;
$STOType = "Standard_GRS";
New-AzStorageAccount -ResourceGroupName $RGName -Name $STOName -Location $LOC -Type $STOType;
$STOAccount = Get-AzStorageAccount -ResourceGroupName $RGName -Name $STOName; 

# NRP
$VNet = Get-AzVirtualNetwork -Name "hjvnet01" -ResourceGroupName $RGName;
$SubNetId = $VNet.Subnets[0].Id;

$PubIP = New-AzPublicIpAddress -Force -Name ("pip" + $RGName) -ResourceGroupName $RGName -Location $LOC -AllocationMethod Dynamic -DomainNameLabel ("pip" + $RGName);
$PubIP = Get-AzPublicIpAddress -Name ("pip"  + $RGName) -ResourceGroupName $RGName;

# Create LoadBalancer
$FrontendName = "fe" + $RGName
$BackendAddressPoolName = "bepool" + $RGName
$ProbeName = "vmssprobe" + $RGName
$InboundNatPoolName  = "innatpool" + $RGName
$LBRuleName = "lbrule" + $RGName
$LBName = "vmsslb" + $RGName

$Frontend = New-AzLoadBalancerFrontendIpConfig -Name $FrontendName -PublicIpAddress $PubIP
$BackendAddressPool = New-AzLoadBalancerBackendAddressPoolConfig -Name $BackendAddressPoolName
$Probe = New-AzLoadBalancerProbeConfig -Name $ProbeName -RequestPath healthcheck.aspx -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
$InboundNatPool = New-AzLoadBalancerInboundNatPoolConfig -Name $InboundNatPoolName  -FrontendIPConfigurationId $Frontend.Id -Protocol Tcp -FrontendPortRangeStart 3360 -FrontendPortRangeEnd 3370 -BackendPort 3389;
$LBRule = New-AzLoadBalancerRuleConfig -Name $LBRuleName `
-FrontendIPConfiguration $Frontend -BackendAddressPool $BackendAddressPool `
-Probe $Probe -Protocol Tcp -FrontendPort 80 -BackendPort 80 `
-IdleTimeoutInMinutes 15 -EnableFloatingIP -LoadDistribution SourceIP;
$ActualLb = New-AzLoadBalancer -Name $LBName -ResourceGroupName $RGName -Location $LOC `
    -FrontendIpConfiguration $Frontend -BackendAddressPool $BackendAddressPool `
    -Probe $Probe -LoadBalancingRule $LBRule -InboundNatPool $InboundNatPool;
$ExpectedLb = Get-AzLoadBalancer -Name $LBName -ResourceGroupName $RGName


$InboundNatPool = Set-AzLoadBalancerInboundNatPoolConfig -Loadbalancer $ExpectedLb -Name $InboundNatPoolName  -FrontendIPConfigurationId $Frontend.Id -Protocol Tcp -FrontendPortRangeStart 3360 -FrontendPortRangeEnd 3370 -BackendPort 3389;

$ExpectedLb | Set-AzLoadBalancer

$VMSSName = "vmss" + $RGName;

$AdminUsername = "ADMINNAME";
$AdminPassword = "PASSWORD";

$PublisherName = "MicrosoftWindowsServer" 
$Offer         = "WindowsServer" 
$Sku           = "2012-R2-Datacenter" 
$Version       = "latest"
        
$VHDContainer = "https://" + $STOName + ".blob.core.windows.net/" + $VMSSName;

$ExtName = "CSETest";
$Publisher = "Microsoft.Compute";
$ExtType = "BGInfo";
$ExtVer = "2.1";

#IP Config for the NIC
$IPCfg = New-AzVmssIPConfig -Name "Test" `
-LoadBalancerInboundNatPoolsId $ExpectedLb.InboundNatPools[0].Id `
-LoadBalancerBackendAddressPoolsId $ExpectedLb.BackendAddressPools[0].Id `
-SubnetId $SubNetId;
            
#VMSS Config
$VMSS = New-AzVmssConfig -Location $LOC -SkuCapacity 2 -SkuName "Standard_E4-2ds_v4" -UpgradePolicyMode "Automatic" `
    | Add-AzVmssNetworkInterfaceConfiguration -Name "Test" -Primary $True -IPConfiguration $IPCfg `
    | Add-AzVmssNetworkInterfaceConfiguration -Name "Test2"  -IPConfiguration $IPCfg `
    | Set-AzVmssOSProfile -ComputerNamePrefix "Test"  -AdminUsername $AdminUsername -AdminPassword $AdminPassword `
    | Set-AzVmssStorageProfile -Name "Test"  -OsDiskCreateOption 'FromImage' -OsDiskCaching "None" `
    -ImageReferenceOffer $Offer -ImageReferenceSku $Sku -ImageReferenceVersion $Version `
    -ImageReferencePublisher $PublisherName -VhdContainer $VHDContainer `
    | Add-AzVmssExtension -Name $ExtName -Publisher $Publisher -Type $ExtType -TypeHandlerVersion $ExtVer -AutoUpgradeMinorVersion $True

#Create the VMSS
New-AzVmss -ResourceGroupName $RGName -Name $VMSSName -VirtualMachineScaleSet $VMSS;

# version 2. Simple
# image: Windows Server 2016 Datacenter
New-AzVmss `
  -ResourceGroupName "hjrg" `
  -Location "EastUS" `
  -VMScaleSetName "hjvset" `
  -VirtualNetworkName "hjvnet01" `
  -SubnetName "hjsubnet01" `
  -PublicIpAddressName "hjPublicIPAddress" `
  -LoadBalancerName "hjLoadBalancer"

# vsersion 3. Specify vmss spec
[link](https://docs.microsoft.com/ko-kr/powershell/module/az.compute/new-azvmssconfig?view=azps-5.2.0)