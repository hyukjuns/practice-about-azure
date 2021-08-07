# PowerShell Syntax Guide
### Powershell version 확인
```
$PSVersionTable.PSVersion
```
### Azure Powershell version 확인
```
 Get-InstalledModule -Name Az -AllVersions | Select-Object -Property Name, Version
 ```
### 가용한 이미지 검색
1. Image Publishser 검색
```
$locName="<Azure location, such as West US>"
Get-AzVMImagePublisher -Location $locName | Select PublisherName
```
2. 선택한 Publicsher의 Offer 검색
```
$pubName="<publisher>"
Get-AzVMImageOffer -Location $locName -PublisherName $pubName | Select Offer
```
3. 선택한 Offer의 SKU(제품) 검색
```
$offerName="<offer>"
Get-AzVMImageSku -Location $locName -PublisherName $pubName -Offer $offerName | Select Skus
```
4. 선택한 SKU를 입력하여 이미지 버전을 가져옴
```
$skuName="<SKU>"
Get-AzVMImage -Location $locName -PublisherName $pubName -Offer $offerName -Sku $skuName | Select Version
```
### PowerShell tips
- 개행문자 `
- "" => '""'
- VM 사이즈 확인
    ```
    Get-AzVMSize -Location WestUS
    ```
## 기본 개념
- 기본적으로 오브젝트를 얻어서 변수에 저장후, 다른 리소스 만들때 의존성으로 참조, '|' 파이프라인 사용해서 오브젝트 전달, 리소스의 참조가능($publicip.Name)
- 생성 순서
    1. 해당 리소스의 config, 내부 설정 우선 생성, 변수처리
        1. 해당 리소스의 config 생성
        2. 해당 리소스 만들때 config 사용
    2. 해당 리소스 생성
    3. 리소스 내용 업데이트
        1. Get resource
        2. Update or Set Commponent resource
        3. Set Target resource with Commponent resource
- 기본 접두사
    - New
    - Get
    - Set
    - Add
    - Update
    - Remove

## Command
### Connect Account
- Connect-AzAccount [-Environment AzureChinaCloud]
### Create Resource Group
New-AzResourceGroup [-Name] <String> [-Location] <String>
### Find Command
- Get-Command -Verb Get -Noun AzVM* -Module Az.Compute

## Virtual Network
### Add-AzVirtualNetworkSubnetConfig
Adds a subnet configuration to a virtual network. => 새로운 subnet을 기존에 있는 vnet에 추가
### Set-AzVirtualNetworkSubnetConfig
- Updates a subnet configuration for a virtual network. => 기존에 있는 서브넷 정보 업데이트
- 이후 Set-AzVirtualNetwork 필요, Subnet을 Add로 추가하고 Vnet에서 Set을 해줘야 해당 Vnet에 추가한 Subnet이 반영이 됨
### Get-AzVirtualNetworkSubnetConfig
Gets a subnet in a virtual network. => 기존에 있는 서브넷 정보 획득하여 구성에 사용

## Virtual Machine
1. Create NIC
2. Create Availability Set
3. Set up VM Config(New-AzVMConfig, Set-AzVMOperatingSystem, Add-AzVMNetworkInterface, Set-AzVMSourceImage)
4. Craete VM(New-AzVM)

## FileShare Usage
- Window에서 Azure 파일 공유 사용
- Azure 파일 공유 탑재(UNC 경로를 통해 액세스)
- Azure Portal에서 스크립트 확인
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