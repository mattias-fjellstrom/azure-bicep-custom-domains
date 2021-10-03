@description('The name of the resource group where the existing DNS Zone is deployed')
param dnsZoneResourceGroupName string

@description('The name of the DNS zone (e.g. example.com)')
param dnsZoneName string

@description('CNAME record for the custom domain (e.g. xyz.<dns zone>)')
param cnameRecord string

@description('A timestamp to add to each resource group deployment to tell them apart')
param deploymentTimestamp string = utcNow()

targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-funcapp-${uniqueString(subscription().id, deployment().name)}'
  location: deployment().location
  tags: {
    'app': 'azure-bicep-custom-domains-functionapp'
  }
}

// random string used to give resources unique names
var randomString = uniqueString(rg.id)

// reference to existing resource group where DNS Zone is deployed
resource dnsZoneResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: dnsZoneResourceGroupName
}

module functionAppModule './modules/functionApp.bicep' = {
  name: '${deploymentTimestamp}-function-app-module'
  scope: rg
  params: {
    randomString: randomString
  }
}

module dnsModule 'modules/dns.bicep' = {
  scope: dnsZoneResourceGroup
  name: '${deploymentTimestamp}-dns-module'
  params: {
    dnsZoneName: dnsZoneName
    functionAppHostname: functionAppModule.outputs.hostname
    customDomainVerificationId: functionAppModule.outputs.customDomainVerificationId
    cnameRecord: cnameRecord
  }
}

module customDomainModule 'modules/customDomain.bicep' = {
  scope: rg
  name: '${deploymentTimestamp}-custom-domain-module'
  params: {
    randomString: randomString
    appServicePlanName: functionAppModule.outputs.appServicePlanName
    functionAppName: functionAppModule.outputs.functionAppName
    customDomain: '${cnameRecord}.${dnsZoneName}'
  }
  dependsOn: [
    dnsModule
  ]
}
