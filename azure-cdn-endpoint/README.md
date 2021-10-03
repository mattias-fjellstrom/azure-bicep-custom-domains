# Add a custom domain to an Azure CDN Endpoint

[![Build azure-cdn-endpoint](https://github.com/mattias-fjellstrom/azure-bicep-custom-domains/actions/workflows/azure-cdn-endpoint.yml/badge.svg)](https://github.com/mattias-fjellstrom/azure-bicep-custom-domains/actions/workflows/azure-cdn-endpoint.yml)

This example demonstrates how to add a custom domain name for an Azure CDN Endpoint during infrastructure setup using Azure Bicep. Note that this example sets up a storage account as the origin for the CDN, and enables static website hosting for the storage account.

## Prerequisites

- A DNS zone hosted in a separate resource group in your Azure subscription. If your DNS zone is in a different subscription than the one you deploy the example to you will need to modify the example accordingly.
- Install the Azure CLI ([instructions](https://docs.microsoft.com/cli/azure/install-azure-cli))
- Install the Azure Bicep CLI (install using the Azure CLI command `az bicep install`)
- Set your default Azure subscription (`az account set --subscription <subscription name or ID>`)

## Instructions

Set values for the required parameters.

```bash
location=northeurope
dnsZoneResourceGroupName=my-dns-resource-group
dnsZoneName=example.com
cnameRecord=fabulousdonkey
```

Deploy the example using the Azure CLI.

```bash
az deployment sub create \
  --name my-cdn-deployment \
  --template-file main.bicep \
  --location $location \
  --parameters dnsZoneResourceGroupName=$dnsZoneResourceGroupName \
      dnsZoneName=$dnsZoneName \
      cnameRecord=$cnameRecord
```

The `main.bicep` template is deployed to the subscription scope. A new resource group is created for a storage account, a CDN profile, and a CDN endpoint. The deployment is split in three modules. The first module creates CNAME record in the DNS Zone. The second module creates a storage account and enables static website hosting using a deploymentScript resource. The third module sets up the CDN Profile and CDN Endpoint, as well as enabling HTTPS for the CDN custom domain using a user-assigned managed identity and a deploymentScript resource.

## Clean-up

Delete the resource group containing the storage account and the CDN using the Azure CLI.

```bash
rg=$(az group list --query '[?tags.app == `azure-bicep-custom-domains-cdn`] | [0].name' -o tsv)
az group delete -n $rg -y --no-wait
```

Delete the CNAME record from the DNS zone using the Azure CLI.

```bash
az network dns record-set cname delete \
  -g $dnsZoneResourceGroupName \
  -z $dnsZoneName \
  -n $cnameRecord \
  -y
```
