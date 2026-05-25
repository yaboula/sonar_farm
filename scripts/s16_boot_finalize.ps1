$ErrorActionPreference = 'Stop'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Set-File([string]$path, [string]$content) {
    [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
}

function Replace-Exact([string]$path, [string]$old, [string]$new) {
    $content = [System.IO.File]::ReadAllText($path)
    if (-not $content.Contains($old)) {
        throw "Pattern not found in $path"
    }
    $content = $content.Replace($old, $new)
    Set-File $path $content
}

$root = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $root 'sonar_farm_core\config.lua'
$mainPath = Join-Path $root 'sonar_farm_core\server\main.lua'

Replace-Exact $configPath "Config.Farm.Scheduler = { TickSeconds = 30 }`r`n" "Config.Farm.TimeMultiplier = Config.Farm.TimeMultiplier or 1.0`r`nConfig.Farm.Scheduler = { TickSeconds = 30 }`r`n"

Replace-Exact $mainPath "    run_quality_boot()`r`n    run_offline_reconcile_boot()`r`n    run_lifecycle_boot()`r`n" "    run_quality_boot()`r`n    run_offline_reconcile_boot()`r`n    if Sonar.Farm.ClimateService and type(Sonar.Farm.ClimateService.Boot) == 'function' then`r`n        local climate_ok, climate_result = pcall(Sonar.Farm.ClimateService.Boot)`r`n        if not climate_ok or climate_result ~= true then`r`n            log_error(('[climate] boot failed: %s'):format(tostring(climate_result)))`r`n        end`r`n    else`r`n        log_error('[climate] boot unavailable. Check fxmanifest.lua server_scripts order.')`r`n    end`r`n    run_lifecycle_boot()`r`n"

Write-Host 'S16 boot wiring finalized.'
