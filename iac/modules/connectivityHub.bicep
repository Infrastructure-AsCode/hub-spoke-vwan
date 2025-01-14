targetScope = 'resourceGroup'

param parInstanceId int
param parLocation string
param parVirtualWanResourceId string
param parHubName string = 'hub-${parLocation}-${parInstanceId}'
param parP2SVpnName string = 'p2sVpnGw-${parLocation}-${parInstanceId}'
param parVpnServerConfigurationName string = 'p2s-vpn-config-${parLocation}-${parInstanceId}'
param parAzureFirewallName string = 'afw-${parLocation}-${parInstanceId}'
param parFirewallPolicyName string = 'afwp-${parLocation}-${parInstanceId}'
param parHubAddressPrefix string
param parAADAudience string
param parAADIssuer string
param parAADTenant string
param parEnableTelemetry bool = false
param parVpnClientAddressPoolAddressPrefixes array
param parWorkspaceResourceId string
param parOnPremWorkloadAddressRange string
param parOnpremGwPublicIpAddress string
param parOnpremGwName string


module modVirtualHub 'br/public:avm/res/network/virtual-hub:0.2.2' = {
  name: 'deploy-virtual-hub-${parLocation}-${parInstanceId}'
  params: {
    location: parLocation
    name: parHubName
    addressPrefix: parHubAddressPrefix
    hubRouteTables: []
    virtualWanId: parVirtualWanResourceId
    enableTelemetry: parEnableTelemetry  
  }  
}

module modFirewallPolicy 'br/public:avm/res/network/firewall-policy:0.2.0' = {
  name: 'deploy-firewall-policy-${parLocation}-${parInstanceId}'
  params: {
    name: parFirewallPolicyName
    location: parLocation
    enableTelemetry: parEnableTelemetry
  }
}

module modAzureFirewall 'br/public:avm/res/network/azure-firewall:0.5.2' = {
  name: 'deploy-azure-firewall-${parLocation}-${parInstanceId}'
  params: {
    name: parAzureFirewallName
    firewallPolicyId: modFirewallPolicy.outputs.resourceId
    hubIPAddresses: {
      publicIPs: {
        count: 1
      }
    }
    location: parLocation
    virtualHubId: modVirtualHub.outputs.resourceId
    azureSkuTier: 'Standard'
    enableTelemetry: parEnableTelemetry
    diagnosticSettings: [
      {
        name: 'diag'
        workspaceResourceId: parWorkspaceResourceId
        logAnalyticsDestinationType: 'Dedicated'
        logCategoriesAndGroups: [
          {
            categoryGroup: 'allLogs'
            enabled: true
          }
        ]
        metricCategories: [
          {
            category: 'AllMetrics'
            enabled: true
          }
        ]
      }
    ]
  }
}

module modVpnServerConfiguration 'br/public:avm/res/network/vpn-server-configuration:0.1.0' = {
  name: 'deploy-p2s-vpn-config-${parLocation}-${parInstanceId}'
  params: {
    name: parVpnServerConfigurationName
    aadAudience: parAADAudience
    aadIssuer: parAADIssuer
    aadTenant: parAADTenant
    location: parLocation
    vpnAuthenticationTypes: [
      'AAD'
    ]
    vpnProtocols: [
      'OpenVPN'
    ]
    enableTelemetry: parEnableTelemetry
  }
}

module modP2SVpnGateway 'br/public:avm/res/network/p2s-vpn-gateway:0.1.0' = {
  name: 'deploy-p2s-vpn-gateway-${parLocation}-${parInstanceId}'
  params: {
    name: parP2SVpnName
    location: parLocation
    virtualHubResourceId: modVirtualHub.outputs.resourceId
    associatedRouteTableName: 'defaultRouteTable'
    p2SConnectionConfigurationsName: parVpnServerConfigurationName
    vpnClientAddressPoolAddressPrefixes: parVpnClientAddressPoolAddressPrefixes
    vpnServerConfigurationResourceId: modVpnServerConfiguration.outputs.resourceId
    enableTelemetry: parEnableTelemetry
  }
}

var varHubVpnGatewayName = 'vpnGw-${parLocation}-${parInstanceId}'
module modHubVpnGateway 'br/public:avm/res/network/vpn-gateway:0.1.4' = {
  name: 'deploy-hub-vpn-gateway-${parLocation}-${parInstanceId}'
  params: {
    // Required parameters
    name: varHubVpnGatewayName
    virtualHubResourceId: modVirtualHub.outputs.resourceId
    location: parLocation    
    enableTelemetry: parEnableTelemetry    
    vpnConnections: [
      {
        name: 'hub-to-onprem-${parLocation}'
        connectionBandwidth: 100
        enableBgp: true
        enableInternetSecurity: true
        enableRateLimiting: false
        remoteVpnSiteResourceId: modSiteOnPremNorwayEast.outputs.resourceId
        routingWeight: 0
        useLocalAzureIpAddress: false
        usePolicyBasedTrafficSelectors: false
        vpnConnectionProtocolType: 'IKEv2'    
        sharedKey: 'foobar'
        ipsecPolicies: [
          {
            dhGroup: 'DHGroup24'
            ikeEncryption: 'AES256'
            ikeIntegrity: 'SHA384'
            ipsecEncryption: 'AES256'
            ipsecIntegrity: 'SHA256'
            pfsGroup: 'PFS24'
            saLifeTimeSeconds: 28800
          }]
      }          
    ]
  }
}

resource resOnPremGW 'Microsoft.Network/virtualNetworkGateways@2024-05-01' existing = {
  name: parOnpremGwName
}

module modSiteOnPremNorwayEast 'br/public:avm/res/network/vpn-site:0.3.0' = {
  name: 'deploy-vpn-site-onprem-${parLocation}-${parInstanceId}'
  params: {
    name: 'onprem-${parLocation}'
    virtualWanId: parVirtualWanResourceId
    location: parLocation
    addressPrefixes: [
      parOnPremWorkloadAddressRange
    ]                    
    ipAddress: parOnpremGwPublicIpAddress
    enableTelemetry: parEnableTelemetry
    bgpProperties: {
      asn: resOnPremGW.properties.bgpSettings.asn
      bgpPeeringAddress: resOnPremGW.properties.bgpSettings.bgpPeeringAddress
    }
  }  
}

output outHubVpnGatewayName string = modHubVpnGateway.outputs.name
output outHubResourceId string = modVirtualHub.outputs.resourceId
