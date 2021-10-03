#!/bin/bash

resourceGroup=$1
thumbprint=$2
name=$3

# make sure a certificate exists before binding it
certificates=$(az functionapp config ssl list -g $resourceGroup --query '[] | length(@)')
while [ $certificates -lt 1 ]
do
    echo "Found $certificates certificates, sleeping 5 seconds ..."
    sleep 5
    certificates=$(az functionapp config ssl list -g $resourceGroup --query '[] | length(@)')
done

# bind certificate
az functionapp config ssl bind \
    --certificate-thumbprint $thumbprint \
    --ssl-type SNI \
    -g $resourceGroup \
    -n $name