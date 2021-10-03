# Add a custom domain to an Azure Function App

[![Build azure-function-apps](https://github.com/mattias-fjellstrom/azure-bicep-custom-domains/actions/workflows/azure-function-apps.yml/badge.svg)](https://github.com/mattias-fjellstrom/azure-bicep-custom-domains/actions/workflows/azure-function-apps.yml)

This example demonstrates how to add a custom domain name for a Function App during infrastructure setup using Azure Bicep. Note that this example sets up an empty Function App configured for Node.js on Windows. Modify the Function App resource to fit your needs.

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
  --name my-funcapp-deployment \
  --template-file main.bicep \
  --location $location \
  --parameters dnsZoneResourceGroupName=$dnsZoneResourceGroupName \
      dnsZoneName=$dnsZoneName \
      cnameRecord=$cnameRecord
```

The `main.bicep` template is deployed to the subscription scope. A new resource group is created for the Function App and all of its related resources. The deployment is split in three modules. The first module creates the Function App and all of its related resources. The second module adds the required CNAME and TXT records to the DNS Zone to prepare for the custom domain. The third module adds the custom domain and certificate resources to the Function App, it also adds the SSL binding between the custom domain and the certificate. This last operation is a data plane operation, so it is handled by a deploymentScript resource.

## Clean-up

Delete the resource group containing the Function App and all related resources using the Azure CLI.

```bash
rg=$(az group list --query '[?tags.app == `azure-bicep-custom-domains-functionapp`] | [0].name' -o tsv)
az group delete -n $rg -y --no-wait
```

Delete the TXT and CNAME records from the DNS zone using the Azure CLI.

```bash
az network dns record-set cname delete \
  -g $dnsZoneResourceGroupName \
  -z $dnsZoneName \
  -n $cnameRecord \
  -y

az network dns record-set txt delete \
  -g $dnsZoneResourceGroupName \
  -z $dnsZoneName \
  -n asuid.$cnameRecord \
  -y
```
