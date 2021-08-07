#!/bin/sh

# Create Virtual Network, Subnet Network Security Group and  NSG rules 
az network vnet create --name vnet01 --resource-group handson --location eastus --address-prefix 10.0.0.0/8 --subnet-name subnet01 --subnet-prefix 10.1.0.0/16
az network nsg create -g handson --name nsg01 --location eastus
az network nsg rule create -g handson --nsg-name nsg01 --name RDP --protocol tcp --direction inbound --priority 100 --source-address-prefix '*' --source-port-range '*' --destination-address-prefix '*' --destination-port-range 3389 --access allow
az network nsg rule create -g handson --nsg-name nsg01 --name HTTP --protocol tcp --direction inbound --priority 110 --source-address-prefix '*' --source-port-range '*' --destination-address-prefix '*' --destination-port-range 80 --access allow
az network nsg rule create -g handson --nsg-name nsg01 --name ICMP --protocol icmp --direction inbound --priority 120 --source-address-prefix '*' --source-port-range '*' --destination-address-prefix '*' --destination-port-range '*' --access allow

# Attach NSG to  Subnet
az network vnet subnet update --vnet-name vnet01 --name subnet01 -g handson --nsg nsg01

# Create Availability Set and Virtual machine
az vm availability-set create --name avset01 -g handson \
--platform-fault-domain-count 2 \
--platform-update-domain-count 5 

az vm create -g handson \
--name vm01 \
--vnet-name vnet01 \
--subnet subnet01 \
--availability-set avset01 \
--nsg "" --public-ip-address "" --image Win2019Datacenter \
--size Standard_D1_v2 \
--admin-username azureuser \
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
--admin-username azureuser \
--storage-sku Standard_LRS \
--admin-username USERNAME \
--admin-password PASSWORD

# Create Load balancer
# create public ip
az network public-ip create \
    -g handson \
    -n mylbpip \
    --sku Standard
# create public load balancer
az network lb create \
    -g handson \
    -n extlb \
    --sku Standard \
    --public-ip-address mylbpip \
    --backend-pool-name mybepool

# lb backend address pool, health probe, load balance rule
az network lb address-pool create -g handson --lb-name extlb --vnet vnet01 -n mybepool
az network lb probe create -g handson --lb-name extlb --name mylbhp --port 80 --protocol tcp 
az network lb rule create -g handson --backend-port 80 --frontend-port 80 --lb-name extlb \
--name mylbrule --protocol tcp --backend-pool-name mybepool --probe-name mylbhp

# add vm to lb backend pool
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

# inbound nat rule
# 1. create inbound nat rule
# 2. add nic ip-config to inbound-nat-rule
az network lb inbound-nat-rule create -g handson --backend-port 3389 --frontend-port 5000 --lb-name extlb \
--name vm01natrule --protocol tcp 
az network nic ip-config inbound-nat-rule add --inbound-nat-rule vm01natrule --ip-config-name ipconfigvm01 \
--nic-name vm01VMNic -g handson --lb-name extlb

az network lb inbound-nat-rule create -g handson --backend-port 3389 --frontend-port 5001 --lb-name extlb \
--name vm02natrule --protocol tcp 
az network nic ip-config inbound-nat-rule add --inbound-nat-rule vm02natrule --ip-config-name ipconfigvm02 \
--nic-name vm02VMNic -g handson --lb-name extlb

