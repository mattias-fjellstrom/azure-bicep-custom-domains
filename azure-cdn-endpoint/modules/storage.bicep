@description('Random string used to make resource names unique')
param randomString string

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: 'stweb${randomString}'
  location: resourceGroup().location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

param utcValue string = utcNow()
resource enableStaticWebsite 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'enableStaticWebsite'
  location: resourceGroup().location
  kind: 'AzureCLI'
  properties: {
    forceUpdateTag: utcValue
    azCliVersion: '2.26.1'
    timeout: 'PT5M'
    retentionInterval: 'PT1H'
    environmentVariables: [
      {
        name: 'AZURE_STORAGE_ACCOUNT'
        value: storageAccount.name
      }
      {
        name: 'AZURE_STORAGE_KEY'
        secureValue: storageAccount.listKeys().keys[0].value
      }
    ]
    arguments: 'index.html'
    scriptContent: 'az storage blob service-properties update --static-website --index-document $1 --404-document $1'
  }
}

output origin string = replace(replace(storageAccount.properties.primaryEndpoints.web, 'https://', ''), '/', '')
