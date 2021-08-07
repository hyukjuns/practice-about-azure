#!/bin/bash
# Create Virtual Network, Subnet Network Security Group and  NSG rules 
az network vnet create --name vnet01 --resource-group handson --location eastus --address-prefix 10.0.0.0/8 --subnet-name subnet01 --subnet-prefix 10.1.0.0/16
az network nsg create -g handson --name nsg01 --location eastus
az network nsg rule create -g handson --nsg-name nsg01 --name RDP --protocol tcp --direction inbound --priority 100 --source-address-prefix '*' --source-port-range '*' --destination-address-prefix '*' --destination-port-range 3389 --access allow
az network nsg rule create -g handson --nsg-name nsg01 --name HTTP --protocol tcp --direction inbound --priority 110 --source-address-prefix '*' --source-port-range '*' --destination-address-prefix '*' --destination-port-range 80 --access allow
az network nsg rule create -g handson --nsg-name nsg01 --name ICMP --protocol icmp --direction inbound --priority 120 --source-address-prefix '*' --source-port-range '*' --destination-address-prefix '*' --destination-port-range '*' --access allow

# Attach NSG to  Subnet
az network vnet subnet update --vnet-name vnet01 --name subnet01 -g handson --nsg nsg01