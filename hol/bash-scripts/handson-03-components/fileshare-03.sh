#!/bin/bash

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

# vm03, vm04 에서  file share 사용하기 위해선 vm03,vm04에 직접 접속하여 powershell에서 file share 연결 후 사용
# file share dashboard에서 연결 커맨드 확인 가능
# storageaccount -> fileshare -> hjfileshare -> connect