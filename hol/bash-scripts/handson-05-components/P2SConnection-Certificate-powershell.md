# Certificate Usage
## Root Certificate
### Requirements
1. Install Azure PowerShell
```
if ($PSVersionTable.PSEdition -eq 'Desktop' -and (Get-Module -Name AzureRM -ListAvailable)) {
    Write-Warning -Message ('Az module not installed. Having both the AzureRM and ' +
      'Az modules installed at the same time is not supported.')
} else {
    Install-Module -Name Az -AllowClobber -Scope CurrentUser
}
```
[Go to Docs](https://docs.microsoft.com/ko-kr/powershell/azure/install-az-ps?view=azps-5.2.0#code-try-1)

### Login Using Azure Powershell
1. Powershell을 로컬로 실행 하는 경우 로그인
```
Connect-AzAccount
```
2. 구독 목록 확인
```
Get-AzSubscription
```
3. 구독 선택
```
Select-AzSubscription -SubscriptionName "Name of subscription"
```

### Setting Variables
```
$VNetName  = "vnet01"
$FESubName = "FrontEnd"
$GWSubName = "GatewaySubnet"
$VNetPrefix = "10.0.0.0/8"
$FESubPrefix = "10.1.0.0/16"
$GWSubPrefix = "10.100.100.0/24"
$VPNClientAddressPool = "172.16.201.0/24"
$RG = "handson"
$Location = "EastUS"
$GWName = "hjvnetGW"
$GWIPName = "hjvnetGWPip"
$GWIPconfName = "vnetGatewayConfig0"
```
### Adding VPN Client Address Pool
```
$Gateway = Get-AzVirtualNetworkGateway -ResourceGroupName $RG -Name $GWName
Set-AzVirtualNetworkGateway -VirtualNetworkGateway $Gateway -VpnClientAddressPool $VPNClientAddressPool
```

### Create Certificate
1. 자체 서명된 루트인증서 만들기
```
$cert = New-SelfSignedCertificate -Type Custom -KeySpec Signature `
-Subject "CN=P2SRootCert" -KeyExportPolicy Exportable `
-HashAlgorithm sha256 -KeyLength 2048 `
-CertStoreLocation "Cert:\CurrentUser\My" -KeyUsageProperty Sign -KeyUsage CertSign
```
2. 루트인증서를 사용해 클라이언트 인증서 만들기
```
New-SelfSignedCertificate -Type Custom -DnsName P2SChildCert -KeySpec Signature `
-Subject "CN=P2SChildCert" -KeyExportPolicy Exportable `
-HashAlgorithm sha256 -KeyLength 2048 `
-CertStoreLocation "Cert:\CurrentUser\My" `
-Signer $cert -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")
```
3. 루트 인증서 공개키(.cer) 내보내기
- 쉘에 certmgr 입력하여 프로그램 사용
- 내보낸 인증서의 공개키(.cer) 파일은 Azure에 업로드 예정
4. 클라이언트 인증서(.pfx) 내보내기
- certmgr 프로그램 사용하여 진행
- 내보낸 클라이언트 인증서는 VPN의 클라이언트 PC에 옮긴 뒤 배포하여 설치해야 함
5. Azure에 루트 인증서 공개 키 정보 업로드
    1. 인증서 이름에 대한 변수 선언(내보낸 .cer 파일이름 지정)
    ```
    $P2SRootCertName = "P2SRootCert.cer"
    ```
    2. 파일 경로를 고유한 값으로 바꾼 후 cmdlet 실행
    ```
    $filePathForCert = "PATH\FILENAME.cer"
    $cert = new-object System.Security.Cryptography.X509Certificates.X509Certificate2($filePathForCert)
    $CertBase64 = [system.convert]::ToBase64String($cert.RawData)
    ```
    3. 공개키 정보를 Azure에 업로드
    ```
    Add-AzVpnClientRootCertificate -VpnClientRootCertificateName $P2SRootCertName -VirtualNetworkGatewayname "VNet1GW" -ResourceGroupName "TestRG1" -PublicCertData $CertBase64
    ```
6. 내보낸 클라이언트 인증서 설치
- 내보낸 클라이언트 인증서(.pfx) 설치
7. VPN 클라이언트 구성
- 구성파일 생성
```
$profile=New-AzVpnClientConfiguration -ResourceGroupName $RG -Name $GWName -AuthenticationMethod "EapTls"

$profile.VPNProfileSASUrl
```
- 위 명령으로 떨어진 URL을 브라우저에 입력 하면 구성 프로그램이 다운로드 받아짐
    - 사용자 PC의 운영환경에 맞는 프로그램 선택
8. 네트워크 설정에서 VPN 연결 성립
[Go to Docs](https://docs.microsoft.com/ko-kr/azure/vpn-gateway/vpn-gateway-certificates-point-to-site)
