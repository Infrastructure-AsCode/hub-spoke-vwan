targetScope = 'subscription'

var varNumberOfInstances = 4
var varLocation = 'norwayeast'

import {varVariables} from '.global/variables.bicep'

module modResourceGroup 'br/public:avm/res/resources/resource-group:0.4.0' = [for i in range(0, varNumberOfInstances): {
  name: 'deploy-resource-group-${i}'
  params: {
    name: 'rg-vwan-labs-${varLocation}-${i}'
    location: varLocation
    enableTelemetry: false
  }
}]

module modWorkspace 'br/public:avm/res/operational-insights/workspace:0.9.1' = [for i in range(0, varNumberOfInstances): {
  name: 'deploy-la-workspace'
  scope: resourceGroup('rg-vwan-labs-${varLocation}-${i}')
  dependsOn: [
    modResourceGroup[i]
  ]
  params: {
    name: 'law-${varLocation}-${i}'
    location: varLocation
    enableTelemetry: false
  }
}]

module modOnPremNorwayEast 'modules/onPrem.bicep' = [for i in range(0, varNumberOfInstances): {
  name: 'deploy-onprem-norwayeast-${i}'
  dependsOn: [
    modResourceGroup[i]
  ]
  scope: resourceGroup('rg-vwan-labs-${varLocation}-${i}')
  params: {
    parInstanceId: i
    parLocation: 'norwayeast'
    parAddressRange: varVariables.OnPremNorwayEastAddressRange
    parWorkspaceResourceId: modWorkspace[i].outputs.resourceId
    parAsn: varVariables.OnPremASNNorwayEast
  }
}]

module modVirtualWan 'br/public:avm/res/network/virtual-wan:0.3.0' = [for i in range(0, varNumberOfInstances): {
  name: 'deploy-vwan-${i}'
  dependsOn: [
    modResourceGroup[i]
  ]
  scope: resourceGroup('rg-vwan-labs-${varLocation}-${i}')  
  params: {
    location: varLocation
    name: 'vwan-${varLocation}-${i}'
    allowBranchToBranchTraffic: true
    allowVnetToVnetTraffic: true
    disableVpnEncryption: true
    type: 'Standard'
    enableTelemetry: false
  }
}]

module modConnectivityHubNorwayEast 'modules/connectivityHub.bicep' = [for i in range(0, varNumberOfInstances): {
  name: 'deploy-connectivity-hub-norwayeast-${i}'
  scope: resourceGroup('rg-vwan-labs-${varLocation}-${i}')  
  dependsOn: [
    modResourceGroup[i]
  ]
  params: {
    parInstanceId: i
    parLocation: 'norwayeast'
    parVirtualWanResourceId: modVirtualWan[i].outputs.resourceId
    parHubAddressPrefix: varVariables.HubAddressPrefixNorwayEast
    parVpnClientAddressPoolAddressPrefixes: varVariables.VpnClientAddressPoolAddressPrefixesNorwayEast
    parWorkspaceResourceId: modWorkspace[i].outputs.resourceId
    parOnPremWorkloadAddressRange: modOnPremNorwayEast[i].outputs.outOnPremWorkloadAddressRange
    parOnpremGwPublicIpAddress: modOnPremNorwayEast[i].outputs.outOnpremGwPublicIpAddress
    parOnpremGwName: modOnPremNorwayEast[i].outputs.outVirtualNetworkGatewayName
  }    
}]

module modS2SNorwayEast 'modules/s2s.bicep' = [for i in range(0, varNumberOfInstances): {
  name: 'deploy-s2s-norwayeast-${i}'
  scope: resourceGroup('rg-vwan-labs-${varLocation}-${i}')  
  params: {
    parInstanceId: i
    parLocation: 'norwayeast'
    parWorkload1AddressRange: varVariables.WorkloadNorwayEastAddressRange
    parHubVpnGatewayName: modConnectivityHubNorwayEast[i].outputs.outHubVpnGatewayName
    parVirtualNetworkGatewayId: modOnPremNorwayEast[i].outputs.outVirtualNetworkGatewayId
  }
}]

module modWorkloadNorwayEast 'modules/workload.bicep' = [for i in range(0, varNumberOfInstances): {
  name: 'deploy-workload-norwayeast-${i}'
  scope: resourceGroup('rg-vwan-labs-${varLocation}-${i}')  
  params: {
    parInstanceId: i
    parLocation: 'norwayeast'
    parAddressRange: varVariables.WorkloadNorwayEastAddressRange
    parWorkspaceResourceId: modWorkspace[i].outputs.resourceId
    parVirtualWanHubResourceId: modConnectivityHubNorwayEast[i].outputs.outHubResourceId
  }
}]

module modDiagnosticNorwayEast 'modules/diagnostic.bicep' = [for i in range(0, varNumberOfInstances): {
  name: 'deploy-diagnostic-norwayeast-${i}'
  scope: resourceGroup('rg-vwan-labs-${varLocation}-${i}')  
  params: {
    parWorkspaceResourceId: modWorkspace[i].outputs.resourceId
    parHubP2SGatewayName: modConnectivityHubNorwayEast[i].outputs.outHubP2SGatewayName
    parHubVpnGatewayName: modConnectivityHubNorwayEast[i].outputs.outHubVpnGatewayName
  }
}]

module modOnPremSwedenCentral 'modules/onPrem.bicep' = [for i in range(0, varNumberOfInstances): {
  name: 'deploy-onprem-swedencentral-${i}'
  dependsOn: [
    modResourceGroup[i]
  ]
  scope: resourceGroup('rg-vwan-labs-${varLocation}-${i}')  
  params: {
    parInstanceId: i
    parLocation: 'swedencentral'
    parAddressRange: varVariables.OnPremSwedenCentralAddressRange
    parWorkspaceResourceId: modWorkspace[i].outputs.resourceId
    parAsn: varVariables.OnPremASNSwedenCentral
  }
}]

module modConnectivityHubSwedenCentral 'modules/connectivityHub.bicep' = [for i in range(0, varNumberOfInstances): {
  name: 'deploy-connectivity-hub-swedencentral-${i}'
  scope: resourceGroup('rg-vwan-labs-${varLocation}-${i}')  
  dependsOn: [
    modResourceGroup[i]
  ]
  params: {
    parInstanceId: i
    parLocation: 'swedencentral'
    parVirtualWanResourceId: modVirtualWan[i].outputs.resourceId
    parHubAddressPrefix: varVariables.HubAddressPrefixSwedenCentral
    parVpnClientAddressPoolAddressPrefixes: varVariables.VpnClientAddressPoolAddressPrefixesSwedenCentral
    parWorkspaceResourceId: modWorkspace[i].outputs.resourceId
    parOnPremWorkloadAddressRange: modOnPremSwedenCentral[i].outputs.outOnPremWorkloadAddressRange
    parOnpremGwPublicIpAddress: modOnPremSwedenCentral[i].outputs.outOnpremGwPublicIpAddress
    parOnpremGwName: modOnPremSwedenCentral[i].outputs.outVirtualNetworkGatewayName
  }    
}]

module modWorkloadSwedenCentral 'modules/workload.bicep' = [for i in range(0, varNumberOfInstances): {
  name: 'deploy-workload-swedencentral-${i}'
  scope: resourceGroup('rg-vwan-labs-${varLocation}-${i}')  
  params: {
    parInstanceId: i
    parLocation: 'swedencentral'
    parAddressRange: varVariables.WorkloadSwedenCentralAddressRange
    parWorkspaceResourceId: modWorkspace[i].outputs.resourceId
    parVirtualWanHubResourceId: modConnectivityHubSwedenCentral[i].outputs.outHubResourceId
  }
}]

// module modS2SSwedenCentral 'modules/s2s.bicep' = {
//   name: 'deploy-s2s-swedencentral-${parInstanceId}'
//   scope: resourceGroup(varResourceGroupName)
//   params: {
//     parInstanceId: parInstanceId
//     parLocation: 'swedencentral'
//     parWorkload1AddressRange: varVariables.WorkloadSwedenCentralAddressRange
//     parHubVpnGatewayName: modConnectivityHubSwedenCentral.outputs.outHubVpnGatewayName
//     parVirtualNetworkGatewayId: modOnPremSwedenCentral.outputs.outVirtualNetworkGatewayId
//   }
// }

module modDiagnosticSwedenCentral 'modules/diagnostic.bicep' = [for i in range(0, varNumberOfInstances): {
  name: 'deploy-diagnostic-swedencentral-${i}'
  scope: resourceGroup('rg-vwan-labs-${varLocation}-${i}')  
  params: {
    parWorkspaceResourceId: modWorkspace[i].outputs.resourceId
    parHubP2SGatewayName: modConnectivityHubSwedenCentral[i].outputs.outHubP2SGatewayName
    parHubVpnGatewayName: modConnectivityHubSwedenCentral[i].outputs.outHubVpnGatewayName
  }
}]
