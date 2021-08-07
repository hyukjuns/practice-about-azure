#!/bin/sh

# Create rg
az group create --name hjrg -l eastus

# Create network
az network vnet create -n vnet00 -g hjrg --address-prefixes 10.0.0.0/8 --subnet-name websubnet --subnet-prefixes 10.1.0.0/16
az network vnet subnet create -g hjrg --address-prefixes 10.2.0.0/16 --name wassubnet --vnet-name vnet00
az network vnet subnet create -g hjrg --address-prefixes 10.3.0.0/16 --name dbsubnet --vnet-name vnet00

az network nsg create -n webnsg -g hjrg -l eastus
az network nsg create -n wasnsg -g hjrg -l eastus
az network nsg create -n dbnsg -g hjrg -l eastus

az network nsg rule create -n "Allow 80" -g hjrg --nsg-name webnsg --access Allow  --direction Inbound --priority 100 --source-address-prefixes  "*" --source-port-range "*" --destination-address-prefixes "*" --destination-port-ranges 80
az network nsg rule create -n "Allow 8080" -g hjrg --nsg-name webnsg --access Allow --direction Inbound --priority 120 --source-address-prefixes "*" --source-port-range "*" --destination-address-prefixes "*" --destination-port-range 8080
az network nsg rule create -n "Allow ssh" -g hjrg --nsg-name webnsg --access Allow  --direction Inbound --priority 110 --source-address-prefixes  "*" --source-port-range "*" --destination-address-prefixes "*" --destination-port-ranges 22

az network nsg rule create -n "Allow ssh" -g hjrg --nsg-name wasnsg --access Allow  --direction Inbound --priority 110 --source-address-prefixes  "*" --source-port-range "*" --destination-address-prefixes "*" --destination-port-ranges 22
az network nsg rule create -n "Allow 8080" -g hjrg --nsg-name wasnsg --access Allow --direction Inbound --priority 120 --source-address-prefixes "*" --source-port-range "*" --destination-address-prefixes "*" --destination-port-range 8080
az network nsg rule create -n "Allow 8009" -g hjrg --nsg-name wasnsg --access Allow --direction Inbound --priority 130 --source-address-prefixes "*" --source-port-range "*" --destination-address-prefixes "*" --destination-port-range 8009
az network nsg rule create -n "Allow 8443" -g hjrg --nsg-name wasnsg --access Allow --direction Inbound --priority 140 --source-address-prefixes "*" --source-port-range "*" --destination-address-prefixes "*" --destination-port-range 8443


az network nsg rule create -n "Allow ssh" -g hjrg --nsg-name wasnsg --access Allow  --direction Inbound --priority 110 --source-address-prefixes  "*" --source-port-range "*" --destination-address-prefixes "*" --destination-port-ranges 22
az network nsg rule create -n "Allow 3306" -g hjrg --nsg-name wasnsg --access Allow --direction Inbound --priority 130 --source-address-prefixes "*" --source-port-range "*" --destination-address-prefixes "*" --destination-port-range 8009

az network vnet subnet update -g hjrg -n websubnet --vnet-name vnet00 --nsg webnsg
az network vnet subnet update -g hjrg -n wassubnet --vnet-name vnet00 --nsg wasnsg
az network vnet subnet update -g hjrg -n dbsubnet --vnet-name vnet00 --nsg dbnsg


# # Create Web Server(Front End)
az vm create -g hjrg -n web00 --image CentOS --admin-username azureuser --generate-ssh-keys --nsg "" --size Standard_D1_v2 --vnet-name vnet00 --subnet websubnet --public-ip-address webserverpip
az vm create -g hjrg -n web01 --image CentOS --admin-username azureuser --generate-ssh-keys --nsg "" --size Standard_D1_v2 --vnet-name vnet00 --subnet websubnet --public-ip-address webserverpip2


# Create WAS Server(Back End)
az vm create -g hjrg -n was00 --image CentOS --admin-username azureuser --generate-ssh-keys --nsg "" --size Standard_D1_v2 --vnet-name vnet00 --subnet wassubnet --public-ip-address wasserverpip

# Create DB Server()
az vm create -g hjrg -n db00 --image CentOS --admin-username azureuser --generate-ssh-keys --nsg "" --size Standard_D1_v2 --vnet-name vnet00 --subnet dbsubnet --public-ip-address dbserverpip
az vm create -g hjrg -n db01 --image CentOS --admin-username azureuser --generate-ssh-keys --nsg "" --size Standard_D1_v2 --vnet-name vnet00 --subnet dbsubnet --public-ip-address dbserverpip01