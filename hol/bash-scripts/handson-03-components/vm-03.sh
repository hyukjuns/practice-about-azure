#!/bin/sh

# 01. Create Availability Set and Virtual machine
az vm availability-set create --name avset02 -g handson \
--platform-fault-domain-count 2 \
--platform-update-domain-count 5

az vm create -g handson \
--name vm01 \
--vnet-name vnet01 \
--subnet subnet01 \
--availability-set avset01 \
--nsg none --public-ip-address "" --image Win2019Datacenter \
--size Standard_D1_v2 \
--storage-sku Standard_LRS \
--admin-username USERNAME \
--admin-password PASSWORD

az vm create -g handson \
--name vm02 \
--vnet-name vnet01 \
--subnet subnet01 \
--availability-set avset01 \
--nsg none --public-ip-address "" --image Win2019Datacenter \
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
--nsg none --public-ip-address "" --image Win2019Datacenter \
--size Standard_D1_v2 \
--storage-sku Standard_LRS \
--admin-username USERNAME \
--admin-password PASSWORD

az vm create -g handson \
--name vm04 \
--vnet-name vnet01 \
--subnet subnet02 \
--availability-set avset02 \
--nsg none --public-ip-address "" --image Win2019Datacenter \
--size Standard_D1_v2 \
--storage-sku Standard_LRS \
--admin-username USERNAME \
--admin-password PASSWORD