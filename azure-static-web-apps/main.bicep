targetScope = 'subscription'

@description('A limited number of regions are supported for Static Web Apps')
@allowed([
  'centralus'
  'eastus2'
  'eastasia'
  'westeurope'
  'westus2'
])
param location string

@description('The name of the resource group where the existing DNS Zone is deployed')
param dnsZoneResourceGroupName string

@description('The name of the DNS zone (e.g. example.com)')
param dnsZoneName string

@description('CNAME record for the custom domain (e.g. XXX.<dns zone>)')
param cnameRecord string

@description('A timestamp to add to each resource group deployment to tell them apart')
param deploymentTimestamp string = utcNow()

resource swaResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-swa-${uniqueString(subscription().id, deployment().name)}'
  location: location
  tags: {
    'app': 'azure-bicep-custom-domains-swa'
  }
}

module swaModule 'modules/swa.bicep' = {
  name: '${deploymentTimestamp}-swa-module'
  scope: swaResourceGroup
}

// reference existing resource group where the DNS Zone is deployed
resource dnsResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: dnsZoneResourceGroupName
}

module dnsModule 'modules/dns.bicep' = {
  name: '${deploymentTimestamp}-dns-module'
  scope: dnsResourceGroup
  params: {
    cnameRecord: cnameRecord
    dnsZoneName: dnsZoneName
    targetHostname: swaModule.outputs.hostname
  }
}

module swaCustomDomainModule 'modules/swaCustomDomain.bicep' = {
  name: '${deploymentTimestamp}-custom-domain-module'
  scope: swaResourceGroup
  params: {
    staticWebAppName: swaModule.outputs.name
    customDomainName: '${cnameRecord}.${dnsZoneName}'
  }
  dependsOn: [
    dnsModule
  ]
}
