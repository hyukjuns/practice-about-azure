#!/bin/sh

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