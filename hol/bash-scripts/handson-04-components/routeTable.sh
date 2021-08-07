#!/bin/bash

# Create Route Table
az network route-table create --name hjroutetable00 \
--resource-group handson \
--location eastus

# Create Route
az network route-table route create --address-prefix 192.168.0.0/16 \
--name hjroute00 \
--next-hop-type VirtualAppliance \
--resource-group handson \
--route-table-name hjroutetable00 \
--next-hop-ip-address 192.168.1.4

# Associate Route table to subnet
az network vnet subnet update -g handson --vnet-name vnet01 -n subnet01 --route-table hjroutetable00