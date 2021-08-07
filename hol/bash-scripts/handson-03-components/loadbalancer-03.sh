#!/bin/bash

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


## lb backend address pool, health probe, load balance rule
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