resource swa 'Microsoft.Web/staticSites@2021-01-15' = {
  name: 'swa-${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  sku: {
    tier: 'Free'
    name: 'Free'
  }
  properties: {}
}

output name string = swa.name
output hostname string = swa.properties.defaultHostname
