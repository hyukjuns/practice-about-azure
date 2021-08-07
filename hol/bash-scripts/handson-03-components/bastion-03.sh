#!/bin/bash

# create subnet
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