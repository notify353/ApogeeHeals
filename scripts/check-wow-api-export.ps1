[CmdletBinding()]
param([string]$WowRoot = 'C:/Program Files (x86)/World of Warcraft')
$ErrorActionPreference = 'Stop'
$metadata = Get-Content (Join-Path $PSScriptRoot '../docs/wow-api-export.json') -Raw | ConvertFrom-Json
$lines = Get-Content -LiteralPath (Join-Path $WowRoot '.build.info')
$columns = $lines[0].Split('|')
$productIndex = -1
$versionIndex = -1
for ($i = 0; $i -lt $columns.Count; $i++) {
    if ($columns[$i] -like 'Product!*') { $productIndex = $i }
    if ($columns[$i] -like 'Version!*') { $versionIndex = $i }
}
if ($productIndex -lt 0 -or $versionIndex -lt 0) { throw 'Invalid build metadata.' }
$versions = @(foreach ($line in $lines | Select-Object -Skip 1) {
    $values = $line.Split('|')
    if ($values.Count -gt [Math]::Max($productIndex, $versionIndex) -and $values[$productIndex] -eq 'wow_classic_beta') {
        $values[$versionIndex]
    }
}) | Sort-Object -Unique
if (@($versions).Count -ne 1 -or $versions -ne $metadata.clientVersion) { throw 'Installed Forever build differs from reviewed export. Refresh and review before implementation.' }
$client = Join-Path $WowRoot '_classic_beta_'
$exe = Get-Item -LiteralPath (Join-Path $client 'WowB.exe')
$export = Join-Path $client 'BlizzardInterfaceCode/Interface/AddOns'
foreach ($relative in $metadata.requiredFiles) {
    $file = Get-Item -LiteralPath (Join-Path $export $relative)
    if ($file.LastWriteTimeUtc -lt $exe.LastWriteTimeUtc) { throw "Stale export: $relative" }
}
$toc = Get-Content (Join-Path $PSScriptRoot '../ApogeeHeals.toc')
if ($toc -notcontains "## Interface: $($metadata.interface)") { throw 'TOC differs from verified interface.' }
Write-Host "Forever export checked: $($metadata.clientVersion), interface $($metadata.interface)."
