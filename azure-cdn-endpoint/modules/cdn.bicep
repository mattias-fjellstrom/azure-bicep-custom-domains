@description('CDN origin for the storage account web endpoint')
param origin string

@description('CDN endpoint (e.g. xyz.azureedge.net)')
param cdnEndpoint string

@description('The name of the DNS zone (e.g. example.com)')
param dnsZoneName string

@description('CNAME record for the custom domain (e.g. xyz.<dns zone>)')
param cnameRecord string

@description('Random string used to make resource names unique')
param randomString string

resource cdn 'Microsoft.Cdn/profiles@2020-09-01' = {
  name: 'cdnp-${randomString}'
  location: resourceGroup().location
  sku: {
    name: 'Standard_Microsoft'
  }

  resource endpoint 'endpoints' = {
    name: split(cdnEndpoint, '.')[0]
    location: resourceGroup().location
    properties: {
      originHostHeader: origin
      isHttpAllowed: false
      origins: [
        {
          name: 'storageAccountOrigin'
          properties: {
            hostName: origin
          }
        }
      ]
    }

    resource customDomain 'customDomains' = {
      name: replace('${cnameRecord}.${dnsZoneName}', '.', '-')
      properties: {
        hostName: '${cnameRecord}.${dnsZoneName}'
      }
    }
  }
}

resource dnsIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'dns-identity-${randomString}'
  location: resourceGroup().location
}

var roleDefinitions = [
  '426e0c7f-0c7e-4658-b36f-ff54d6c29b45' // CDN Endpoint Contributor
  'ec156ff8-a8d1-4d15-830c-5b80698ca432' // CDN Profile Contributor
]

resource roleAssignments 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = [for roleDefinitionId in roleDefinitions: {
  name: guid(resourceGroup().id, roleDefinitionId)
  scope: resourceGroup()
  properties: {
    principalType: 'ServicePrincipal'
    principalId: dnsIdentity.properties.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
  }
}]

param utcValue string = utcNow()
resource enableHttpsForCustomDomain 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'enableHttpsForCustomDomain'
  location: resourceGroup().location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${dnsIdentity.id}': {}
    }
  }
  properties: {
    forceUpdateTag: utcValue
    azCliVersion: '2.26.1'
    timeout: 'PT5M'
    retentionInterval: 'PT1H'
    scriptContent: 'az cdn custom-domain enable-https -g ${resourceGroup().name} -n ${cdn::endpoint::customDomain.name} --profile-name ${cdn.name} --endpoint-name ${cdn::endpoint.name}'
  }
}
