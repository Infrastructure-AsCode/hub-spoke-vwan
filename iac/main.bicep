targetScope = 'subscription'

param parInstanceId int = 1
param parLocation string = 'norwayeast'

var varLAWName = 'law-${parLocation}-${parInstanceId}'
var varVWanName = 'vwan-${parLocation}-${parInstanceId}'

import {varVariables} from '.global/variables.bicep'
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
    name: varLAWName
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
    parAsn: varVariables.OnPremASNNorwayEast
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
    name: varVWanName
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

module modDiagnosticNorwayEast 'modules/diagnostic.bicep' = {
  name: 'deploy-diagnostic-norwayeast-${parInstanceId}'
  scope: resourceGroup(varResourceGroupName)
  params: {
    parWorkspaceResourceId: modWorkspace.outputs.resourceId
    parHubP2SGatewayName: modConnectivityHubNorwayEast.outputs.outHubP2SGatewayName
    parHubVpnGatewayName: modConnectivityHubNorwayEast.outputs.outHubVpnGatewayName
  }
}

module modOnPremSwedenCentral 'modules/onPrem.bicep' = {
  name: 'deploy-onprem-swedencentral-${parInstanceId}'
  dependsOn: [
    modResourceGroup
  ]
  scope: resourceGroup(varResourceGroupName)
  params: {
    parInstanceId: parInstanceId
    parLocation: 'swedencentral'
    parAddressRange: varVariables.OnPremSwedenCentralAddressRange
    parWorkspaceResourceId: modWorkspace.outputs.resourceId
    parAsn: varVariables.OnPremASNSwedenCentral
  }
}

module modConnectivityHubSwedenCentral 'modules/connectivityHub.bicep' = {
  name: 'deploy-connectivity-hub-swedencentral-${parInstanceId}'
  scope: resourceGroup(varResourceGroupName)
  dependsOn: [
    modResourceGroup
  ]
  params: {
    parInstanceId: parInstanceId    
    parLocation: 'swedencentral'
    parVirtualWanResourceId: modVirtualWan.outputs.resourceId
    parHubAddressPrefix: varVariables.HubAddressPrefixSwedenCentral
    parVpnClientAddressPoolAddressPrefixes: varVariables.VpnClientAddressPoolAddressPrefixesSwedenCentral
    parWorkspaceResourceId: modWorkspace.outputs.resourceId
    parOnPremWorkloadAddressRange: modOnPremSwedenCentral.outputs.outOnPremWorkloadAddressRange
    parOnpremGwPublicIpAddress: modOnPremSwedenCentral.outputs.outOnpremGwPublicIpAddress
    parOnpremGwName: modOnPremSwedenCentral.outputs.outVirtualNetworkGatewayName
  }    
}

module modWorkloadSwedenCentral 'modules/workload.bicep' = {
  name: 'deploy-workload-swedencentral-${parInstanceId}'
  scope: resourceGroup(varResourceGroupName)
  params: {
    parInstanceId: parInstanceId
    parLocation: 'swedencentral'
    parAddressRange: varVariables.WorkloadSwedenCentralAddressRange
    parWorkspaceResourceId: modWorkspace.outputs.resourceId
    parVirtualWanHubResourceId: modConnectivityHubSwedenCentral.outputs.outHubResourceId
  }
}

module modS2SSwedenCentral 'modules/s2s.bicep' = {
  name: 'deploy-s2s-swedencentral-${parInstanceId}'
  scope: resourceGroup(varResourceGroupName)
  params: {
    parInstanceId: parInstanceId
    parLocation: 'swedencentral'
    parWorkload1AddressRange: varVariables.WorkloadSwedenCentralAddressRange
    parHubVpnGatewayName: modConnectivityHubSwedenCentral.outputs.outHubVpnGatewayName
    parVirtualNetworkGatewayId: modOnPremSwedenCentral.outputs.outVirtualNetworkGatewayId
  }
}

module modDiagnosticSwedenCentral 'modules/diagnostic.bicep' = {
  name: 'deploy-diagnostic-swedencentral-${parInstanceId}'
  scope: resourceGroup(varResourceGroupName)
  params: {
    parWorkspaceResourceId: modWorkspace.outputs.resourceId
    parHubP2SGatewayName: modConnectivityHubSwedenCentral.outputs.outHubP2SGatewayName
    parHubVpnGatewayName: modConnectivityHubSwedenCentral.outputs.outHubVpnGatewayName
  }
}
