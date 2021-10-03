@description('Random string used to give resources unique names')
param randomString string

resource appServicePlan 'Microsoft.Web/serverfarms@2021-01-15' = {
  name: 'plan-${randomString}'
  location: resourceGroup().location
  kind: 'functionapp'
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
    size: 'Y1'
    family: 'Y'
    capacity: 0
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: 'stfunc${randomString}'
  location: resourceGroup().location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-${randomString}'
  location: resourceGroup().location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

var endpointSuffix = environment().suffixes.storage

resource functionApp 'Microsoft.Web/sites@2021-01-15' = {
  name: 'func-${randomString}'
  location: resourceGroup().location
  kind: 'functionapp'
  properties: {
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.properties.ConnectionString
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${listKeys(storage.name, storage.apiVersion).keys[0].value};EndpointSuffix=${endpointSuffix}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${listKeys(storage.name, storage.apiVersion).keys[0].value};EndpointSuffix=${endpointSuffix}'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~14'
        }
        // WEBSITE_CONTENTSHARE is created automatically
        // WEBSITE_RUN_FROM_PACKAGE will be set during app deployment from VS Code
      ]
    }
    serverFarmId: appServicePlan.id
  }
}

output appServicePlanName string = appServicePlan.name
output functionAppName string = functionApp.name
output hostname string = functionApp.properties.defaultHostName
output customDomainVerificationId string = functionApp.properties.customDomainVerificationId
