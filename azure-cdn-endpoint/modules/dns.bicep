@description('CDN endpoint (e.g. xyz.azureedge.net)')
param cdnEndpoint string

@description('The name of the DNS zone (e.g. example.com)')
param dnsZoneName string

@description('CNAME record for the custom domain (e.g. xyz.<dns zone>)')
param cnameRecord string

resource dnsZone 'Microsoft.Network/dnsZones@2018-05-01' existing = {
  name: dnsZoneName

  resource frontend 'CNAME' = {
    name: cnameRecord
    properties: {
      TTL: 3600
      CNAMERecord: {
        cname: cdnEndpoint
      }
    }
  }
}
