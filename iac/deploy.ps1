$stopwatch = [System.Diagnostics.Stopwatch]::new()
$stopwatch.Start()

$location = 'norwayeast'

Write-Host "Deploying workshop lab infra into $location..."
$deploymentName = 'iac-labs-vwan-{0}' -f (-join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
az deployment sub create -l $location --template-file main.bicep --parameters parameters/main.bicepparam -n $deploymentName

$stopwatch.Stop()

Write-Host "Deployment time: " $stopwatch.Elapsed 
