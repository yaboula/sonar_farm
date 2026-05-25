$ErrorActionPreference = 'Stop'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Set-File([string]$path, [string]$content) {
    [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
}

$root = Split-Path -Parent $PSScriptRoot
$fxmanifest = Join-Path $root 'sonar_farm_core\fxmanifest.lua'
$fxContent = [System.IO.File]::ReadAllText($fxmanifest)

if (-not $fxContent.Contains("'server/climate/climate_service.lua'")) {
    $needle = "    'server/npcs/init.lua',`r`n"
    if (-not $fxContent.Contains($needle)) {
        throw 'Could not find server/npcs/init.lua line in fxmanifest.lua'
    }
    $fxContent = $fxContent.Replace($needle, "    'server/npcs/init.lua',`r`n    'server/climate/climate_service.lua',`r`n")
}

if (-not $fxContent.Contains("012_climate.sql")) {
    $needle = "sonar_farm_migration 'database/migrations/011_pest_severity.sql'`r`n"
    if (-not $fxContent.Contains($needle)) {
        throw 'Could not find 011_pest_severity migration line in fxmanifest.lua'
    }
    $fxContent = $fxContent.Replace($needle, "sonar_farm_migration 'database/migrations/011_pest_severity.sql'`r`nsonar_farm_migration 'database/migrations/012_climate.sql'`r`n")
}

Set-File $fxmanifest $fxContent

$sourceScript = Join-Path $PSScriptRoot 's16_backend_apply.ps1'
$fullScript = [System.IO.File]::ReadAllText($sourceScript)
$marker = "$schedulerPath = Join-Path $root 'sonar_farm_core\server\lifecycle\scheduler.lua'"
$startIndex = $fullScript.IndexOf($marker)
if ($startIndex -lt 0) {
    throw 'Could not locate scheduler marker in s16_backend_apply.ps1'
}

$tailScript = $fullScript.Substring($startIndex)
Invoke-Expression $tailScript

Write-Host 'S16 climate backend v2 edits applied.'
