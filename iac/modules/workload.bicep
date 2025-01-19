targetScope = 'resourceGroup'

param parInstanceId int
param parLocation string
param parAddressRange string
param parWorkspaceResourceId string
param parVirtualWanHubResourceId string

var varVNetName = 'vnet-workload-${parLocation}-${parInstanceId}'

module modVNet 'br/public:avm/res/network/virtual-network:0.5.2' = {
  name: 'deploy-workload-vnet-${parLocation}-${parInstanceId}'
  params: {
    addressPrefixes: [
      parAddressRange
    ]
    name: varVNetName
    diagnosticSettings: [
      {
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
        name: 'diagnostic'
        workspaceResourceId: parWorkspaceResourceId
      }
    ]
    location: parLocation
    subnets: [
      {
        addressPrefix: parAddressRange
        name: 'subnet-workload'
      }
    ]
    enableTelemetry: false
  }
}

var varVwanHubName = split(parVirtualWanHubResourceId, '/')[8]
var varVnetPeeringVwanName = '${varVwanHubName}/${varVNetName}'

resource resVnetPeeringVwan 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2023-02-01' = if (parLocation == 'norwayeast') {
  name: varVnetPeeringVwanName
  properties: {
    remoteVirtualNetwork: {
      id: modVNet.outputs.resourceId
    }
    enableInternetSecurity: false
  }
}

module modVirtualMachine 'br/public:avm/res/compute/virtual-machine:0.11.0' = {
  name: 'deploy-workload-vm-${parLocation}-${parInstanceId}'
  params: {
    adminUsername: 'iac-user'
    adminPassword: 'fooBar123!'
    imageReference: {
      offer: '0001-com-ubuntu-server-jammy'
      publisher: 'Canonical'
      sku: '22_04-lts-gen2'
      version: 'latest'
    }
    name: 'vm-wl-${parLocation}'
    nicConfigurations: [
      {
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: modVNet.outputs.subnetResourceIds[0]
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
