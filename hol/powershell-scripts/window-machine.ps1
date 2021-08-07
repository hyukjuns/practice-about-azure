# Login to Azure
# Connect-AzAccount

# Create Resource Group
New-AzResourceGroup -Name RESOUCE_GROUP_NAME -Location LOCATION

# VM에 대한 관리자 자격 증명(username, password)
$cred = Get-Credential -Mesage "Enter a username and password for the virtual machine."

# Create Window VirtualMachine
# vnet, subnet이 vm이름으로 생성됨
$vmParams = @{
    ResourceGroupName = 'TutorialResources'
    Name = 'TutorialVM1'
    Location = 'eastus'
    ImageName = 'Win2016Datacenter'
    PublicIpAddressName = 'tutorialPublicIp'
    Credential = $cred
    OpenPorts = 3389
  }
$newVM1 = New-AzVM @vmParams
# 생성된 vm결과 확인
$newVM1

# Query
# VM 이름과 관리자 정보
$newVM1.OSProfile | Select-Object ComputerName,AdminUserName

# 네트워크 구성 정보
$newVM1 | Get-AzNetworkInterface |
  Select-Object -ExpandProperty IpConfigurations |
    Select-Object Name,PrivateIpAddress

# 공용 IP 정보
$publicIp = Get-AzPublicIpAddress -Name tutorialPublicIp -ResourceGroupName TutorialResources
$publicIp | Select-Object Name,IpAddress,@{label='FQDN';expression={$_.DnsSettings.Fqdn}}

# 로컬에서 원격 데스크톱을 통해 VM연결
mstsc.exe /v PUBLIC_IP_ADDRESS

# 기존 서브넷에 새 VM 만들기
$vm2Params = @{
    ResourceGroupName = 'TutorialResources'
    Name = 'TutorialVM2'
    ImageName = 'Win2016Datacenter'
    VirtualNetworkName = 'TutorialVM1'
    SubnetName = 'TutorialVM1'
    PublicIpAddressName = 'tutorialPublicIp2'
    Credential = $cred
    OpenPorts = 3389
  }
$newVM2 = New-AzVM @vm2Params
$newVM2

# 새 VM에 원격 연결
mstsc.exe /v $newVM2.FullyQualifiedDomainName

# 리소스 삭제
$job = Remove-AzResourceGroup -Name TutorialResources -Force -AsJob
$job

# 삭제 웨이팅
Wait-Job -Id $job.Id