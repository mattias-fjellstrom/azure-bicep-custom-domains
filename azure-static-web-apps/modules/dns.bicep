@description('Hostname of the Static Web App')
param targetHostname string

@description('The name of the DNS zone (e.g. example.com)')
param dnsZoneName string

@description('CNAME record for the custom domain (e.g. XXX.<dns zone>)')
param cnameRecord string

// Add a CNAME record to an existing DNS Zone
resource dnsZone 'Microsoft.Network/dnsZones@2018-05-01' existing = {
  name: dnsZoneName

  resource cname 'CNAME' = {
    name: cnameRecord
    properties: {
      TTL: 3600
      CNAMERecord: {
        cname: targetHostname
      }
    }
  }
}
