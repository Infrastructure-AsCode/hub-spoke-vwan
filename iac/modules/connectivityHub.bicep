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
param parEnableTelemetry bool = false
param parVpnClientAddressPoolAddressPrefixes array
param parWorkspaceResourceId string
param parOnPremWorkloadAddressRange string
param parOnpremGwPublicIpAddress string
param parOnpremGwName string


import {varVariables} from '../.global/variables.bicep'

resource resVhub 'Microsoft.Network/virtualHubs@2023-04-01' = {
  name: parHubName
  location: parLocation
  dependsOn: [
    modFirewallPolicy
  ]
  properties: {
    addressPrefix: parHubAddressPrefix
    sku: 'Standard'
    virtualWan: {
      id: parVirtualWanResourceId
    }
  }
}

resource resVhubRoutingIntent 'Microsoft.Network/virtualHubs/routingIntent@2023-04-01' = if(parLocation == 'norwayeast') {
  parent: resVhub
  name: '${parHubName}-Routing-Intent'
  dependsOn: [
  ]
  properties: {
    routingPolicies: [
      {
        name: 'PublicTraffic'
        destinations: [
          'Internet'
        ]
        nextHop: modAzureFirewall.outputs.resourceId
      }
      {
        name: 'PrivateTraffic'
        destinations: [
          'PrivateTraffic'
        ]
        nextHop: modAzureFirewall.outputs.resourceId
      }      
    ]
  }
}

module modFirewallPolicy 'br/public:avm/res/network/firewall-policy:0.2.0' = {
  name: 'deploy-firewall-policy-${parLocation}-${parInstanceId}'
  params: {
    name: parFirewallPolicyName
    location: parLocation
    tier: 'Standard'    
    enableTelemetry: parEnableTelemetry    
    ruleCollectionGroups: (parLocation == 'norwayeast') ? [
      {
        name: 'norwayeast'
        priority: 5000
        ruleCollections: [
          {
            action: {
              type: 'Allow'
            }
            name: 'NetworkRules'
            priority: 5555
            ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
            rules: [
              {
                name: 'allow-workload-to-onprem'
                ruleType: 'NetworkRule'
                sourceAddresses: [
                  varVariables.WorkloadNorwayEastAddressRange
                ]
                destinationAddresses: [
                  varVariables.OnPremNorwayEastAddressRange
                ]
                destinationPorts: [
                  '22'
                ]
                ipProtocols: [
                  'TCP'
                  'ICMP'
                ]
              }
              {
                name: 'allow-from-vpn-client-to-star'
                ruleType: 'NetworkRule'
                sourceAddresses: union(
                  varVariables.VpnClientAddressPoolAddressPrefixesNorwayEast,
                  varVariables.VpnClientAddressPoolAddressPrefixesSwedenCentral
                )
                destinationAddresses: [
                  varVariables.OnPremNorwayEastAddressRange
                  varVariables.OnPremSwedenCentralAddressRange
                  varVariables.WorkloadNorwayEastAddressRange
                  varVariables.WorkloadSwedenCentralAddressRange
                ]
                destinationPorts: [
                  '22'
                ]
                ipProtocols: [
                  'TCP'
                  'ICMP'
                ]
              }
            ]
          }
        ]
      }
    ] : []
  }
}

module modAzureFirewall 'br/public:avm/res/network/azure-firewall:0.5.2' = {
  name: 'deploy-azure-firewall-${parLocation}-${parInstanceId}'
  params: {
    name: parAzureFirewallName
    firewallPolicyId: modFirewallPolicy.outputs.resourceId
    virtualHubId: resVhub.id
    hubIPAddresses: {
      publicIPs: {
        count: 1
      }
    }
    location: parLocation
    azureSkuTier: 'Standard'
    enableTelemetry: parEnableTelemetry
    diagnosticSettings: [
      {
        name: 'diagnostic'
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
    aadAudience: varVariables.AADAudience
    aadIssuer: varVariables.AADIssuer
    aadTenant: varVariables.AADTenant
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
    virtualHubResourceId: resVhub.id
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
    name: varHubVpnGatewayName
    virtualHubResourceId: resVhub.id
    location: parLocation    
    enableTelemetry: parEnableTelemetry    
    vpnConnections: (parLocation == 'norwayeast') ? [
      {
        name: 'hub-to-onprem-${parLocation}'
        connectionBandwidth: 100
        enableBgp: true
        enableInternetSecurity: true
        enableRateLimiting: false
        remoteVpnSiteResourceId: modSiteOnPrem.outputs.resourceId
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
    ] : null
  }
}

resource resOnPremGW 'Microsoft.Network/virtualNetworkGateways@2024-05-01' existing = {
  name: parOnpremGwName
}

module modSiteOnPrem 'br/public:avm/res/network/vpn-site:0.3.0' = if (parLocation == 'norwayeast') {
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

output outHubP2SGatewayName string = modP2SVpnGateway.outputs.name
output outHubVpnGatewayName string = modHubVpnGateway.outputs.name
output outHubResourceId string = resVhub.id
