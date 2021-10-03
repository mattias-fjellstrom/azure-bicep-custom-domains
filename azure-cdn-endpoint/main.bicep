targetScope =  'subscription'

@description('The name of the resource group where the existing DNS Zone is deployed')
param dnsZoneResourceGroupName string

@description('The name of the DNS zone (e.g. example.com)')
param dnsZoneName string

@description('CNAME record for the custom domain (e.g. xyz.<dns zone>)')
param cnameRecord string

@description('A timestamp to add to each resource group deployment to tell them apart')
param deploymentTimestamp string = utcNow()

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-cdn-${uniqueString(subscription().id, deployment().name)}'
  location: deployment().location
  tags: {
    'app': 'azure-bicep-custom-domains-cdn'
  }
}

// reference existing resource group where the DNS Zone is deployed
resource dnsResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: dnsZoneResourceGroupName
}

var randomString = uniqueString(rg.id)
var cdnEndpoint = 'cdne-${randomString}.azureedge.net'

module dnsModule 'modules/dns.bicep' = {
  scope: dnsResourceGroup
  name: '${deploymentTimestamp}-dns-module'
  params: {
    dnsZoneName: dnsZoneName
    cdnEndpoint: cdnEndpoint
    cnameRecord: cnameRecord
  }
}

module storageModule 'modules/storage.bicep' = {
  scope: rg
  name: '${deploymentTimestamp}-storage-module'
  params: {
    randomString: randomString
  }
}

module cdnModule 'modules/cdn.bicep' = {
  scope: rg
  name: '${deploymentTimestamp}-cdn-module'
  params: {
    randomString: randomString
    cnameRecord: cnameRecord
    dnsZoneName: dnsZoneName
    origin: storageModule.outputs.origin
    cdnEndpoint: cdnEndpoint
  }
  dependsOn: [
    storageModule
    dnsModule
  ]
}
