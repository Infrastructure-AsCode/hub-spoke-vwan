param parWorkspaceResourceId string
param parHubP2SGatewayName string
param parHubVpnGatewayName string


resource resHubGw 'Microsoft.Network/vpnGateways@2024-05-01' existing = {
  name: parHubVpnGatewayName
}

resource resHubGWDiagnostic 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diagnostic'
  scope: resHubGw
  properties: {
    workspaceId: parWorkspaceResourceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    logs: [
      {
        categoryGroup: 'AllLogs'
        enabled: true
      }
    ]
  }
}

resource regP2SGv 'Microsoft.Network/p2svpnGateways@2024-05-01' existing = {
  name: parHubP2SGatewayName
}

resource resP2SGwDiagnostic 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diagnostic'
  scope: regP2SGv 
  properties: {    
    workspaceId: parWorkspaceResourceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    logs: [
      {
        categoryGroup: 'AllLogs'
        enabled: true
      }
    ]
  }
}
