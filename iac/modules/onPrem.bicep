targetScope = 'resourceGroup'

param parInstanceId int
param parLocation string
param parAddressRange string
param parWorkspaceResourceId string
param parAsn int

var varWorkloadAddressRange = cidrSubnet(parAddressRange, 25, 1)
module modVNetOnPrem 'br/public:avm/res/network/virtual-network:0.5.2' = {
  name: 'deploy-onprem-vnet-${parLocation}-${parInstanceId}'
  params: {
    // Required parameters
    addressPrefixes: [
      parAddressRange
    ]
    name: 'vnet-onprem-${parLocation}-${parInstanceId}'
    diagnosticSettings: [
      {
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
        name: 'diag'
        workspaceResourceId: parWorkspaceResourceId
      }
    ]
    location: parLocation
    subnets: [
      {
        addressPrefix: cidrSubnet(parAddressRange, 27, 0)
        name: 'GatewaySubnet'
      }
      {
        addressPrefix: varWorkloadAddressRange
        name: 'subnet-workload-1'
      }
    ]
    enableTelemetry: false
  }
}

module modGwPublicIpAddress 'br/public:avm/res/network/public-ip-address:0.7.1' = {
  name: 'deploy-onprem-gw-public-ip-${parLocation}-${parInstanceId}'
  params: {
    name: 'pip-onprem-gw-${parLocation}-${parInstanceId}'
    location: parLocation
    skuName: 'Standard'
    zones: [1, 2, 3]
    enableTelemetry: false
  }
}

var varVPNGatewayName = 'vpn-onprem-${parLocation}-${parInstanceId}'
module modVirtualNetworkGateway 'br/public:avm/res/network/virtual-network-gateway:0.5.0' = {
  name: 'deploy-virtual-network-gateway-${parLocation}-${parInstanceId}'
  params: {
    clusterSettings: {
      clusterMode: 'activePassiveBgp'
      asn: parAsn
    }
    gatewayType: 'Vpn'       
    name: varVPNGatewayName   
    vNetResourceId: modVNetOnPrem.outputs.resourceId
    allowRemoteVnetTraffic: true
    disableIPSecReplayProtection: true
    enableBgpRouteTranslationForNat: true
    enablePrivateIpAddress: false
    existingFirstPipResourceId: modGwPublicIpAddress.outputs.resourceId
    location: parLocation
    skuName: 'VpnGw2AZ'
    vpnGatewayGeneration: 'Generation2'
    vpnType: 'RouteBased'
    enableTelemetry: false    
    diagnosticSettings: [
      {
        name: 'diag'
        workspaceResourceId: parWorkspaceResourceId
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

module modVirtualMachine 'br/public:avm/res/compute/virtual-machine:0.11.0' = {
  name: 'deploy-onprem-vm-${parLocation}-${parInstanceId}'
  params: {
    adminUsername: 'iac-user'
    adminPassword: 'fooBar123!'
    imageReference: {
      offer: '0001-com-ubuntu-server-jammy'
      publisher: 'Canonical'
      sku: '22_04-lts-gen2'
      version: 'latest'
    }
    name: 'vm-dc-${parLocation}'
    nicConfigurations: [
      {
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: modVNetOnPrem.outputs.subnetResourceIds[1]
          }
        ]
        nicSuffix: '-nic-01'
      }
    ]
    osDisk: {
      caching: 'ReadWrite'
      diskSizeGB: 128
      managedDisk: {
        storageAccountType: 'StandardSSD_LRS'
      }
    }
    osType: 'Linux'
    vmSize: 'Standard_DS1_v2'
    zone: 0
    location: parLocation
    enableTelemetry: false
  }
}

output outOnpremGwPublicIpAddress string = modGwPublicIpAddress.outputs.ipAddress
output outOnPremWorkloadAddressRange string = varWorkloadAddressRange
output outVirtualNetworkGatewayId string = modVirtualNetworkGateway.outputs.resourceId
output outVirtualNetworkGatewayName string = modVirtualNetworkGateway.outputs.name

