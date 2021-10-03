@description('The custom domain to be added to a Function App (e.g. xyz.example.com)')
param customDomain string

@description('Name of an existing App Service plan')
param appServicePlanName string

@description('Name of an existing Function App')
param functionAppName string

@description('Random string used to give resources unique names')
param randomString string

// reference existing app service plan
resource appServicePlan 'Microsoft.Web/serverfarms@2021-01-15' existing = {
  name: appServicePlanName
}

// reference existing function app
resource functionApp 'Microsoft.Web/sites@2021-01-15' existing = {
  name: functionAppName

  resource hostNameBinding 'hostNameBindings' = {
    name: customDomain
    properties: {
      siteName: functionApp.name
    }
  }
}

resource certificate 'Microsoft.Web/certificates@2021-01-15' = {
  name: '${customDomain}-${functionAppName}'
  location: resourceGroup().location
  properties: {
    serverFarmId: appServicePlan.id
    hostNames: [
      customDomain
    ]
    canonicalName: customDomain
  }
}

resource sslIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'ssl-identity-${randomString}'
  location: resourceGroup().location
  dependsOn: [
    certificate
  ]
}

var websiteContributor = 'de139f84-1756-47ae-9be6-808fbbe84772'
resource websiteContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: '${guid(resourceGroup().id, 'website')}'
  scope: resourceGroup()
  properties: {
    principalType: 'ServicePrincipal'
    principalId: sslIdentity.properties.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', websiteContributor)
  }
}

param utcValue string = utcNow()
resource addSslBinding 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'addSslBinding'
  location: resourceGroup().location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${sslIdentity.id}': {}
    }
  }
  properties: {
    forceUpdateTag: utcValue
    azCliVersion: '2.26.1'
    timeout: 'PT30M'
    retentionInterval: 'PT1H'
    arguments: '${resourceGroup().name} ${certificate.properties.thumbprint} ${functionApp.name}'
    scriptContent: loadTextContent('../scripts/addSslBinding.sh')
  }
}
