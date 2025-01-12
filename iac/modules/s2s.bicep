targetScope = 'resourceGroup'

param parInstanceId int
param parLocation string
param parWorkload1AddressRange string
param parHubVpnGatewayName string
param parVirtualNetworkGatewayId string

resource resHubGw 'Microsoft.Network/vpnGateways@2024-05-01' existing = {
  name: parHubVpnGatewayName
}

var enableTelemetry = false

module modLocalNetworkGateway 'br/public:avm/res/network/local-network-gateway:0.3.0' = {
  name: 'deploy-local-network-gateway-${parLocation}-${parInstanceId}'
  params: {
    localAddressPrefixes: [
      parWorkload1AddressRange
    ]
    localGatewayPublicIpAddress: resHubGw.properties.ipConfigurations[0].publicIpAddress
    name: 'lgw-onprem-${parLocation}-${parInstanceId}'
    location: parLocation    
    enableTelemetry: enableTelemetry
  }
}

module modConnection 'br/public:avm/res/network/connection:0.1.3' = {
  name: 'deploy-gw-connection-${parLocation}-${parInstanceId}'
  params: {
    name: 'onprem-${parLocation}-to-hub'
    location: parLocation
    virtualNetworkGateway1: {
      id: parVirtualNetworkGatewayId
    }
    localNetworkGateway2: {
      id: modLocalNetworkGateway.outputs.resourceId
    }
    connectionType: 'IPsec'
    connectionProtocol: 'IKEv2'
    vpnSharedKey: 'foobar'
    enableBgp: false
    usePolicyBasedTrafficSelectors: false
    useLocalAzureIpAddress: false
    customIPSecPolicy: {
      saLifeTimeSeconds: 27000
      saDataSizeKilobytes: 0
      ipsecEncryption: 'AES256'
      ipsecIntegrity: 'SHA256'
      ikeEncryption: 'AES256'
      ikeIntegrity: 'SHA384'
      dhGroup: 'DHGroup24'
      pfsGroup: 'PFS24'
    }
    enableTelemetry: false
  }
}
