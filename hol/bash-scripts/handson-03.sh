#!/bin/sh

# Network
# Create Virtual Network, Subnet Network
az network vnet create --name vnet01 --resource-group handson --location eastus --address-prefix 10.0.0.0/8 --subnet-name subnet01 --subnet-prefix 10.1.0.0/16

# Create NSG and Adding NSG rules(RDP, HTTP, ICMP)
az network nsg create -g handson --name hjnsg --location eastus
az network nsg rule create -g handson --nsg-name hjnsg --name RDP --protocol tcp --direction inbound --priority 100 --source-address-prefix '*' --source-port-range '*' --destination-address-prefix '*' --destination-port-range 3389 --access allow
az network nsg rule create -g handson --nsg-name hjnsg --name HTTP --protocol tcp --direction inbound --priority 110 --source-address-prefix '*' --source-port-range '*' --destination-address-prefix '*' --destination-port-range 80 --access allow
az network nsg rule create -g handson --nsg-name hjnsg --name ICMP --protocol icmp --direction inbound --priority 120 --source-address-prefix '*' --source-port-range '*' --destination-address-prefix '*' --destination-port-range '*' --access allow

# Attach NSG to  Subnet
az network vnet subnet update --vnet-name vnet01 --name subnet01 -g handson --nsg hjnsg

# Create subnet02 and attach NSG to subnet02
az network vnet subnet create --address-prefixes 10.2.0.0/16 --name subnet02 -g handson --vnet-name vnet01 --network-security-group hjnsg

# Virtual Machines
# 01. Create Availability Set and Virtual machine
az vm availability-set create --name avset02 -g handson \
--platform-fault-domain-count 2 \
--platform-update-domain-count 5

az vm create -g handson \
--name vm01 \
--vnet-name vnet01 \
--subnet subnet01 \
--availability-set avset01 \
--nsg "" --public-ip-address "" --image Win2019Datacenter \
--size Standard_D1_v2 \
--storage-sku Standard_LRS \
--admin-username USERNAME \
--admin-password PASSWORD

az vm create -g handson \
--name vm02 \
--vnet-name vnet01 \
--subnet subnet01 \
--availability-set avset01 \
--nsg "" --public-ip-address "" --image Win2019Datacenter \
--size Standard_D1_v2 \
--storage-sku Standard_LRS \
--admin-username USERNAME \
--admin-password PASSWORD

# 02. Create Availability Set and Virtual machine
az vm availability-set create --name avset02 -g handson \
--platform-fault-domain-count 2 \
--platform-update-domain-count 5

az vm create -g handson \
--name vm03 \
--vnet-name vnet01 \
--subnet subnet02 \
--availability-set avset02 \
--nsg "" --public-ip-address "" --image Win2019Datacenter \
--size Standard_D1_v2 \
--storage-sku Standard_LRS \
--admin-username USERNAME \
--admin-password PASSWORD

az vm create -g handson \
--name vm04 \
--vnet-name vnet01 \
--subnet subnet02 \
--availability-set avset02 \
--nsg "" --public-ip-address "" --image Win2019Datacenter \
--size Standard_D1_v2 \
--storage-sku Standard_LRS \
--admin-username USERNAME \
--admin-password PASSWORD

# Bastion

# Create bastion subnet
# *name: AzureBastionSubnet
az network vnet subnet create --address-prefixes 10.100.0.0/24 \
-g handson \
-n AzureBastionSubnet \
--vnet-name vnet01

# Create bastion public ip
az network public-ip create -g handson \
--name hjbastionpip --sku Standard \
--location eastus

# Create bastion host
az network bastion create -l eastus \
-n hjbastion \
--public-ip-address hjbastionpip \
-g handson \
--vnet-name vnet01

# Load balancer

# Public facing Load balancer
# Create lb's public ip
az network public-ip create \
    -g handson \
    -n mylbpip \
    --sku Standard

# Create public load balancer
az network lb create \
    -g handson \
    -n extlb \
    --sku Standard \
    --public-ip-address mylbpip \
    --backend-pool-name mybepool

# Create backend pool, health probe, load balance rule
az network lb address-pool create -g handson --lb-name extlb --vnet vnet01 -n mybepool
az network lb probe create -g handson --lb-name extlb --name mylbhp --port 80 --protocol tcp 
az network lb rule create -g handson --backend-port 80 --frontend-port 80 --lb-name extlb \
--name mylbrule --protocol tcp --backend-pool-name mybepool --probe-name mylbhp

# Add vm to lb backend pool
# nic를 backend pool에 등록해야함
# --ip-config-name: nic ip configuration name
# --nic name: nic name
# ip config name 과 nic name 확인방법
# az network nic list
# az network nic ip-config list --nic-name --resource-group                             \
az network nic ip-config address-pool add \
--address-pool mybepool \
--ip-config-name ipconfigvm01 \
--nic-name vm01VMNic \
-g handson \
--lb-name extlb

az network nic ip-config address-pool add \
--address-pool mybepool \
--ip-config-name ipconfigvm02 \
--nic-name vm02VMNic \
-g handson \
--lb-name extlb

# Internal Load balancer
# Create internal load balancer
# *Specify vnet and subnet
az network lb create \
    -g handson \
    -n intlb \
    --sku Standard \
    --public-ip-address "" \
    --backend-pool-name myintbepool \
    --vnet-name vnet01 \
    --subnet subnet02


# lb backend address pool, health probe, load balance rule
az network lb address-pool create -g handson --lb-name intlb --vnet vnet01 -n myintbepool
az network lb probe create -g handson --lb-name intlb --name myintlbhp --port 80 --protocol tcp 
az network lb rule create -g handson --backend-port 80 --frontend-port 80 --lb-name intlb \
--name myintlbrule --protocol tcp --backend-pool-name myintbepool --probe-name myintlbhp

# Add vm to lb backend pool
# --ip-config-name: nic ip configuration name
# --nic name: nic name
# ip config name 과 nic name 확인방법
# az network nic list
# az network nic ip-config list --nic-name --resource-group                             \
az network nic ip-config address-pool add \
--address-pool myintbepool \
--ip-config-name ipconfigvm03 \
--nic-name vm03VMNic \
-g handson \
--lb-name intlb

az network nic ip-config address-pool add \
--address-pool myintbepool \
--ip-config-name ipconfigvm04 \
--nic-name vm04VMNic \
-g handson \
--lb-name intlb

# File share
# vm03, vm04 에서  file share 사용하기 위해선 vm03,vm04에 직접 접속하여 powershell에서 file share 연결 후 사용
# file share dashboard에서 연결 커맨드 확인 가능
# storageaccount -> fileshare -> hjfileshare -> connect

# Create storage account
az storage account create \
    --resource-group handson \
    --name hj00storageaccount \
    --location eastus \
    --kind StorageV2 \
    --sku Standard_LRS \
    --enable-large-file-share \
    --output none

# export storage account key
export resourceGroupName=handson
export storageAccountName=hj00storageaccount
export storageAccountKey=$(az storage account keys list -g handson --account-name hj00storageaccount --query "[0].value" | tr -d '"')

# Create File Share
shareName="hjshare"

az storage share create \
    --account-name $storageAccountName \
    --account-key $storageAccountKey \
    --name $shareName \
    --quota 1024

# Create directory in file share
az storage directory create \
   --account-name $storageAccountName \
   --account-key $storageAccountKey \
   --share-name $shareName \
   --name "hjdirectory"

# Upload test file to directory
date > test.txt

az storage file upload \
    --account-name $storageAccountName \
    --account-key $storageAccountKey \
    --share-name $shareName \
    --source "test.txt" \
    --path "hjdirectory/test.txt"