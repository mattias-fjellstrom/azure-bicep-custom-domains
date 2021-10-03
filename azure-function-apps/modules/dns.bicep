@description('The name of the DNS zone (e.g. example.com)')
param dnsZoneName string

@description('CNAME record for the custom domain (e.g. xyz.<dns zone>)')
param cnameRecord string

@description('Hostname for the Function App')
param functionAppHostname string

@description('Custom domain verification ID from the Function App')
param customDomainVerificationId string

resource dnsZone 'Microsoft.Network/dnsZones@2018-05-01' existing = {
  name: dnsZoneName

  resource txt 'TXT' = {
    name: 'asuid.${cnameRecord}'
    properties: {
      TTL: 3600
      TXTRecords: [
        {
          value: [
            customDomainVerificationId
          ]
        }
      ]
    }
  }

  resource cname 'CNAME' = {
    name: cnameRecord
    properties: {
      TTL: 3600
      CNAMERecord: {
        cname: functionAppHostname
      }
    }
  }
}
