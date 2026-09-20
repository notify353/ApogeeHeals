[CmdletBinding()]
param([string]$ForeverExportPath = $env:APOGEE_FOREVER_EXPORT)
$ErrorActionPreference = 'Stop'
Push-Location (Split-Path -Parent $PSScriptRoot)
$previousExport = $env:APOGEE_FOREVER_EXPORT
try {
    $env:APOGEE_FOREVER_EXPORT = $ForeverExportPath
    $version = (& lua -v 2>&1 | Out-String)
    if ($version -notmatch 'Lua 5\.1\.') { throw 'Lua 5.1 required.' }
    $toc = Get-Content ApogeeHeals.toc
    if ($toc -notcontains '## Interface: 16001') { throw 'Wrong interface.' }
    if ($toc -notcontains '## SavedVariablesPerCharacter: ApogeeHealsDB') { throw 'Wrong storage contract.' }
    if ($toc -match '^## (SavedVariables:|Dependencies:|RequiredDeps:|OptionalDeps:)') { throw 'Unexpected dependency or storage.' }
    foreach ($line in $toc) {
        if ($line -match '^[^#].*\.lua$' -and -not (Test-Path -LiteralPath $line)) { throw "Missing TOC file: $line" }
    }
    foreach ($file in Get-ChildItem -Recurse -File -Filter *.lua) {
        & luac -p $file.FullName
        if ($LASTEXITCODE -ne 0) { throw "Parse failed: $($file.Name)" }
    }
    foreach ($file in Get-ChildItem tests -Filter '*_spec.lua' | Sort-Object Name) {
        & lua $file.FullName
        if ($LASTEXITCODE -ne 0) { throw "Test failed: $($file.Name)" }
    }
    & git diff --check
    if ($LASTEXITCODE -ne 0) { throw 'Whitespace check failed.' }
    & git diff --cached --check
    if ($LASTEXITCODE -ne 0) { throw 'Staged whitespace check failed.' }
    foreach ($file in Get-ChildItem -Recurse -File | Where-Object Extension -in '.lua','.md','.ps1','.toc') {
        if (Select-String -LiteralPath $file.FullName -Pattern '[\t ]+$' -Quiet) { throw "Trailing whitespace: $($file.Name)" }
    }
    Write-Host 'All Apogee Heals local checks passed.'
} finally { $env:APOGEE_FOREVER_EXPORT = $previousExport; Pop-Location }
