targetScope = 'subscription'

param parInstanceId int
param parAADAudience string
param parAADIssuer string
param parAADTenant string
param parLocation string
param parLAWName string = 'law-${parLocation}-${parInstanceId}'
param parVWanName string = 'vwan-${parLocation}-${parInstanceId}'

var varVariables = loadJsonContent('.global/variables.json')
var varResourceGroupName = 'rg-vwan-labs-${parLocation}-${parInstanceId}'

module modResourceGroup 'br/public:avm/res/resources/resource-group:0.4.0' = {
  name: 'deploy-resource-group'
  params: {
    name: varResourceGroupName
    location: parLocation
    enableTelemetry: false
  }
}

module modWorkspace 'br/public:avm/res/operational-insights/workspace:0.9.1' = {
  name: 'deploy-la-workspace'
  scope: resourceGroup(varResourceGroupName)
  dependsOn: [
    modResourceGroup
  ]
  params: {
    name: parLAWName
    location: parLocation
    enableTelemetry: false
  }
}

module modOnPremNorwayEast 'modules/onPrem.bicep' = {
  name: 'deploy-onprem-norwayeast-${parInstanceId}'
  dependsOn: [
    modResourceGroup
  ]
  scope: resourceGroup(varResourceGroupName)
  params: {
    parInstanceId: parInstanceId
    parLocation: 'norwayeast'
    parAddressRange: varVariables.OnPremNorwayEastAddressRange
    parWorkspaceResourceId: modWorkspace.outputs.resourceId
  }
}

module modVirtualWan 'br/public:avm/res/network/virtual-wan:0.3.0' = {
  name: 'deploy-vwan'
  dependsOn: [
    modResourceGroup
  ]
  scope: resourceGroup(varResourceGroupName)  
  params: {
    location: parLocation
    name: parVWanName
    allowBranchToBranchTraffic: true
    allowVnetToVnetTraffic: true
    disableVpnEncryption: true
    type: 'Standard'
    enableTelemetry: false
  }
}

module modConnectivityHubNorwayEast 'modules/connectivityHub.bicep' = {
  name: 'deploy-connectivity-hub-norwayeast-${parInstanceId}'
  scope: resourceGroup(varResourceGroupName)
  dependsOn: [
    modResourceGroup
  ]
  params: {
    parInstanceId: parInstanceId    
    parLocation: 'norwayeast'
    parVirtualWanResourceId: modVirtualWan.outputs.resourceId
    parAADAudience: parAADAudience
    parAADIssuer: parAADIssuer
    parAADTenant: parAADTenant
    parHubAddressPrefix: varVariables.HubAddressPrefixNorwayEast
    parVpnClientAddressPoolAddressPrefixes: varVariables.VpnClientAddressPoolAddressPrefixesNorwayEast
    parWorkspaceResourceId: modWorkspace.outputs.resourceId
    parOnPremWorkloadAddressRange: modOnPremNorwayEast.outputs.outOnPremWorkloadAddressRange
    parOnpremGwPublicIpAddress: modOnPremNorwayEast.outputs.outOnpremGwPublicIpAddress
    parOnpremGwName: modOnPremNorwayEast.outputs.outVirtualNetworkGatewayName
  }    
}

module modS2SNorwayEast 'modules/s2s.bicep' = {
  name: 'deploy-s2s-norwayeast-${parInstanceId}'
  scope: resourceGroup(varResourceGroupName)
  params: {
    parInstanceId: parInstanceId
    parLocation: 'norwayeast'
    parWorkload1AddressRange: varVariables.WorkloadNorwayEastAddressRange
    parHubVpnGatewayName: modConnectivityHubNorwayEast.outputs.outHubVpnGatewayName
    parVirtualNetworkGatewayId: modOnPremNorwayEast.outputs.outVirtualNetworkGatewayId
  }
}

module modWorkloadNorwayEast 'modules/workload.bicep' = {
  name: 'deploy-workload-norwayeast-${parInstanceId}'
  scope: resourceGroup(varResourceGroupName)
  params: {
    parInstanceId: parInstanceId
    parLocation: 'norwayeast'
    parAddressRange: varVariables.WorkloadNorwayEastAddressRange
    parWorkspaceResourceId: modWorkspace.outputs.resourceId
    parVirtualWanHubResourceId: modConnectivityHubNorwayEast.outputs.outHubResourceId
  }
}

// module modOnPremSwedenCentral 'modules/onPrem.bicep' = {
//   name: 'deploy-onprem-swedencentral-${parInstanceId}'
//   dependsOn: [
//     modResourceGroup
//   ]
//   scope: resourceGroup(varResourceGroupName)
//   params: {
//     parInstanceId: parInstanceId
//     parLocation: 'swedencentral'
//     parAddressRange: varVariables.OnPremSwedenCentralAddressRange
//     parWorkspaceResourceId: modWorkspace.outputs.resourceId
//   }
// }

// module modConnectivityHubSwedenCentral 'modules/connectivityHub.bicep' = {
//   name: 'deploy-connectivity-hub-swedencentral-${parInstanceId}'
//   scope: resourceGroup(varResourceGroupName)
//   dependsOn: [
//     modResourceGroup
//   ]
//   params: {
//     parInstanceId: parInstanceId    
//     parLocation: 'swedencentral'
//     parVirtualWanResourceId: modVirtualWan.outputs.resourceId
//     parAADAudience: parAADAudience
//     parAADIssuer: parAADIssuer
//     parAADTenant: parAADTenant
//     parHubAddressPrefix: varVariables.HubAddressPrefixSwedenCentral
//     parVpnClientAddressPoolAddressPrefixes: varVariables.VpnClientAddressPoolAddressPrefixesSwedenCentral
//     parWorkspaceResourceId: modWorkspace.outputs.resourceId
//     parOnPremWorkloadAddressRange: modOnPremSwedenCentral.outputs.outOnPremWorkloadAddressRange
//     parOnpremGwPublicIpAddress: modOnPremSwedenCentral.outputs.outOnpremGwPublicIpAddress
//   }    
// }

// module modWorkloadSwedenCentral 'modules/workload.bicep' = {
//   name: 'deploy-workload-swedencentral-${parInstanceId}'
//   scope: resourceGroup(varResourceGroupName)
//   params: {
//     parInstanceId: parInstanceId
//     parLocation: 'swedencentral'
//     parAddressRange: varVariables.WorkloadSwedenCentralAddressRange
//     parWorkspaceResourceId: modWorkspace.outputs.resourceId
//     parVirtualWanHubResourceId: modConnectivityHubSwedenCentral.outputs.outHubResourceId
//   }
// }
