targetScope='resourceGroup'

param prefix string = 'cptd'
param location string = 'eastus'
var hubName1 = '${prefix}hub1'

resource vnethub1 'Microsoft.Network/virtualNetworks@2015-06-15' existing = {
  name: hubName1
}

resource pubipvgw 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
  name: '${prefix}vgw'
  location: location
  sku: {
    name:'Standard'
  }
  properties: {
    publicIPAllocationMethod:'Static'
  }
}

resource vgw 'Microsoft.Network/virtualNetworkGateways@2021-05-01' = {
  name: '${prefix}vgw'
  location: location
  properties: {
    sku: {
      name:'VpnGw1'
      tier:'VpnGw1'
    }
    gatewayType:'Vpn'
    vpnType:'RouteBased'
    enableBgp: true
    activeActive: false
    vpnClientConfiguration: {
      vpnClientAddressPool:{
        addressPrefixes:[
          '172.16.25.0/24'
        ]
      }
      vpnClientProtocols:[
        'SSTP'
        'IkeV2'
      ]
      vpnClientRootCertificates: [
        {
          name: '${prefix}win'
          properties: {
            publicCertData: 'MIIC4TCCAcmgAwIBAgIQEZ1/NZ4RUKBL5KFiE5EwtTANBgkqhkiG9w0BAQsFADAT MREwDwYDVQQDDAhjcHRkdm5ldDAeFw0yMjAxMjgxOTM3NDdaFw0yMzAxMjgxOTU3 NDdaMBMxETAPBgNVBAMMCGNwdGR2bmV0MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A MIIBCgKCAQEAtiCgS4WSe9/eKROUMCkGuoQmVgGWNYHdkOeOrGybBKCxtJEsx/zi 4cuBSHSUZvqtaC17B0HuYfDNqTH5oxxGXKZpSuCeilCDIUAoQ5DDR0fVzinPJuDB H0oh8ZaAMa6CvtmjNM22Hhhgn3RM0LH7+TsxUa4oVX8nisrlQjoU/9q75lL1rDBQ g7Obj0XdZ3/BzRfLEN1wS+jV9IMBiit8mOUluwRElxHfUQIKtxSMtsAy4N3wiMOf 4TGUsqj/23ZbZJ6ONm8+LuM6vlurGemXHSawyEFtXvk7/O2evt5RCEePovwe53lV fx/s7mTGvZqVSW2bZD0Zn8umY9JaNqdqDQIDAQABozEwLzAOBgNVHQ8BAf8EBAMC AgQwHQYDVR0OBBYEFMrBHEauinQEZ6AT3liH9utbc2+iMA0GCSqGSIb3DQEBCwUA A4IBAQB8NFA5UwaJ2RIYcjkk2zxpNgBczLUrCMOoBGid66xszn9/CLebK2GNayuY BBz9GH6Aa4YUgfNDHcUI4BUkTAMwqrEL9CcE1zuxUksR4Hfe36VikZk1m5L2eEN0 DlpSZPGwDGXLi1/o+Q4+8Lj7JtdoDLEePjsH6VEXXAUb8NNzd91hYG2je8jObMkE bzMaKQHj5340XAA1tev0XHr8XyZb0iXHQKQ0NDgikN2GvBAv/tmO77qhgul9By7u ZPDTiozJ4ND6IQ41SiMP/3Xa0f8XlWzNTa8pZFqa5UJTtiPQ5tQvZ3x3UCXTjy1R f66nAh60AWZAAHmJ3ZdX/nRRvZZk'
          }
        }
      ]
      bgpSettings: {
        asn: 65515
        bgpPeeringAddress: '10.0.3.254'
        peerWeight: 0
        bgpPeeringAddresses: [
          {
            ipconfigurationId: '${virtualNetworkGateways_cptdvnet_name_resource.id}/ipConfigurations/default'
            customBgpIpAddresses: []
          }
        ]
      }
    }
  }
}
