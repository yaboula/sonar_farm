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
$climatePath = Join-Path $root 'sonar_farm_core\server\climate\climate_service.lua'

Replace-Exact $climatePath @'
local function get_plot_effect_interval_seconds()
    return get_effective_seconds(get_climate_config().PlotEffectIntervalSeconds or 1800)
end

local function copy_state(source)
'@ @'
local function get_plot_effect_interval_seconds()
    return get_effective_seconds(get_climate_config().PlotEffectIntervalSeconds or 1800)
end

local function get_now_ts()
    if type(ClimateService.__test_now) == 'function' then
        local test_now = tonumber(ClimateService.__test_now())
        if test_now then
            return test_now
        end
    end

    return os.time()
end

local function copy_state(source)
'@

Replace-Exact $climatePath @'
    local season_started_at = tonumber(type(row) == 'table' and row.season_started_at or nil) or os.time()
    local weather_started_at = tonumber(type(row) == 'table' and row.weather_started_at or nil) or season_started_at

    if not get_season_definition(current_season) then
        current_season = get_default_season()
    end

    local season_definition = get_season_definition(current_season) or {}
    if not has_positive_probabilities(season_definition.weather_probabilities) then
        current_weather = get_default_weather()
    elseif type(season_definition.weather_probabilities[current_weather]) ~= 'number' then
        current_weather = get_default_weather()
    end
'@ @'
    local season_started_at = tonumber(type(row) == 'table' and row.season_started_at or nil) or get_now_ts()
    local weather_started_at = tonumber(type(row) == 'table' and row.weather_started_at or nil) or season_started_at

    if not get_season_definition(current_season) then
        current_season = get_default_season()
    end

    local season_definition = get_season_definition(current_season) or {}
    local probabilities = season_definition.weather_probabilities or {}
    if not has_positive_probabilities(probabilities) or probabilities[current_weather] == nil then
        current_weather = get_default_weather()
    end
'@

Replace-Exact $climatePath @'
local function initialize_timers(now_ts)
    local now_value = tonumber(now_ts) or os.time()
    next_weather_evaluation_at = math.max(state.weather_started_at + get_weather_evaluation_seconds(), now_value)
    next_plot_effect_at = math.max(state.weather_started_at + get_plot_effect_interval_seconds(), now_value)
end
'@ @'
local function initialize_timers(now_ts)
    local now_value = tonumber(now_ts) or get_now_ts()
    next_weather_evaluation_at = math.max(state.weather_started_at + get_weather_evaluation_seconds(), now_value)
    next_plot_effect_at = math.max(state.weather_started_at + get_plot_effect_interval_seconds(), now_value)
end
'@

Replace-Exact $climatePath @'
local function emit_change(event_name, payload)
    if type(TriggerEvent) == 'function' then
        TriggerEvent(event_name, payload)
    end
    if type(TriggerClientEvent) == 'function' then
        TriggerClientEvent(event_name, -1, payload)
    end
end
'@ @'
local function emit_change(event_name, payload)
    if type(ClimateService.__test_emit) == 'function' then
        ClimateService.__test_emit(event_name, payload)
    end
    if type(TriggerEvent) == 'function' then
        TriggerEvent(event_name, payload)
    end
    if type(TriggerClientEvent) == 'function' then
        TriggerClientEvent(event_name, -1, payload)
    end
end
'@

Replace-Exact $climatePath "    local now_ts = os.time()" "    local now_ts = get_now_ts()"
Replace-Exact $climatePath "    local tick_ts = tonumber(now_ts) or os.time()" "    local tick_ts = tonumber(now_ts) or get_now_ts()"

$specPath = Join-Path $root 'sonar_farm_core\tests\server\climate_service_spec.lua'
Set-File $specPath @'
Config = {
    Farm = {
        Greenhouse = {
            PlotTypes = {
                greenhouse = true,
            },
            WeatherNeutralScore = 70,
        },
        Quality = {
            NeutralDefaults = {
                irrigation = 70,
                pest_impact = 100,
                weather_match = 70,
                seed_quality = 70,
                fertilization = 70,
            },
        },
        Climate = {
            DefaultSeason = 'spring',
            DefaultWeather = 'clear',
            SeasonOrder = { 'spring', 'summer', 'autumn', 'winter' },
            WeatherEvaluationSeconds = 10,
            PlotEffectIntervalSeconds = 10,
            WeatherFactor = {
                SeasonWeight = 0.6,
                WeatherWeight = 0.4,
                OptimalSeasonScore = 100,
                ShoulderSeasonScore = 70,
                OffSeasonScore = 35,
            },
            WeatherEffects = {
                clear = { irrigation_delta = 0, irrigation_floor = 0, irrigation_ceiling = 100 },
                light_rain = { irrigation_delta = 8, irrigation_floor = 0, irrigation_ceiling = 95 },
                torrential_rain = { irrigation_delta = -12, irrigation_floor = 40, irrigation_ceiling = 100 },
                drought = { irrigation_delta = -10, irrigation_floor = 25, irrigation_ceiling = 100 },
                hail = { irrigation_delta = -15, irrigation_floor = 20, irrigation_ceiling = 100 },
                frost = { irrigation_delta = -6, irrigation_floor = 30, irrigation_ceiling = 100 },
            },
            Seasons = {
                spring = {
                    duration_seconds = 20,
                    weather_probabilities = {
                        clear = 0.0,
                        light_rain = 1.0,
                        torrential_rain = 0.0,
                        drought = 0.0,
                        hail = 0.0,
                        frost = 0.0,
                    },
                },
                summer = {
                    duration_seconds = 20,
                    weather_probabilities = {
                        clear = 0.0,
                        light_rain = 0.0,
                        torrential_rain = 0.0,
                        drought = 0.0,
                        hail = 1.0,
                        frost = 0.0,
                    },
                },
                autumn = {
                    duration_seconds = 20,
                    weather_probabilities = {
                        clear = 1.0,
                        light_rain = 0.0,
                        torrential_rain = 0.0,
                        drought = 0.0,
                        hail = 0.0,
                        frost = 0.0,
                    },
                },
                winter = {
                    duration_seconds = 20,
                    weather_probabilities = {
                        clear = 1.0,
                        light_rain = 0.0,
                        torrential_rain = 0.0,
                        drought = 0.0,
                        hail = 0.0,
                        frost = 0.0,
                    },
                },
            },
        },
        Crops = {
            wheat = {
                optimal_seasons = { 'spring' },
                preferred_weather = {
                    clear = 80,
                    light_rain = 100,
                    torrential_rain = 55,
                    drought = 35,
                    hail = 20,
                    frost = 40,
                },
            },
            tomato = {
                optimal_seasons = { 'summer' },
                preferred_weather = {
                    clear = 95,
                    light_rain = 80,
                    torrential_rain = 35,
                    drought = 30,
                    hail = 15,
                    frost = 10,
                },
            },
        },
    },
}

Sonar = { Farm = { Quality = { Factors = {} } } }

local now_ts = 1000
local climate_state_row = nil
local quality_rows = {
    outdoor_plot = {
        irrigation = 70,
        weather_match = 70,
        calculated_at = now_ts,
    },
    greenhouse_plot = {
        irrigation = 70,
        weather_match = 70,
        calculated_at = now_ts,
    },
}
local crop_rows = {
    outdoor_plot = {
        plot_id = 'outdoor_plot',
        crop_type = 'wheat',
    },
    greenhouse_plot = {
        plot_id = 'greenhouse_plot',
        crop_type = 'tomato',
    },
}
local plots = {
    outdoor_plot = {
        plot_id = 'outdoor_plot',
        plot_type = 'extensive',
    },
    greenhouse_plot = {
        plot_id = 'greenhouse_plot',
        plot_type = 'greenhouse',
    },
}
local captured_events = {}

Sonar.Farm.PlotService = {
    GetPlot = function(plot_id)
        return plots[plot_id]
    end,
}

Sonar.Farm.DB = {
    row = function(query, params)
        if query:find('FROM `sonar_farm_climate_state`', 1, true) then
            return climate_state_row
        end

        local plot_id = params[1]
        if query:find('FROM `sonar_farm_crops`', 1, true) then
            return crop_rows[plot_id]
        end
        if query:find('SELECT `weather_match` FROM `sonar_farm_quality_tracking`', 1, true) then
            return quality_rows[plot_id]
        end

        return nil
    end,
    execute = function(query, params)
        if query:find('INSERT INTO `sonar_farm_climate_state`', 1, true) then
            climate_state_row = {
                current_season = params[1],
                current_weather = params[2],
                season_started_at = params[3],
                weather_started_at = params[4],
            }
            return true
        end

        if query:find('INSERT INTO `sonar_farm_quality_tracking`', 1, true) then
            quality_rows[params[1]] = {
                irrigation = params[2],
                weather_match = params[3],
                calculated_at = params[4],
            }
            return true
        end

        return true
    end,
}

dofile('sonar_farm_core/server/quality/factors/weather.lua')
dofile('sonar_farm_core/server/climate/climate_service.lua')

local WeatherFactor = Sonar.Farm.Quality.Factors.Weather
local ClimateService = Sonar.Farm.ClimateService
ClimateService.__test_now = function()
    return now_ts
end
ClimateService.__test_emit = function(event_name, payload)
    captured_events[#captured_events + 1] = {
        name = event_name,
        payload = payload,
    }
end

local boot_ok = ClimateService.Boot()
assert(boot_ok == true, 'climate boot must succeed')
assert(climate_state_row ~= nil, 'climate boot must persist initial state')
assert(climate_state_row.current_season == 'spring', 'default season must be spring')
assert(climate_state_row.current_weather == 'clear', 'default weather must be clear before first roll')

local active_crops = {
    {
        plot_id = 'outdoor_plot',
        crop_type = 'wheat',
        plot_type = 'extensive',
        irrigation = 70,
        weather_match = 70,
    },
    {
        plot_id = 'greenhouse_plot',
        crop_type = 'tomato',
        plot_type = 'greenhouse',
        irrigation = 70,
        weather_match = 70,
    },
}

now_ts = 1010
local first_tick = ClimateService.Tick(active_crops, now_ts)
assert(first_tick.current_weather == 'light_rain', 'spring weather must roll to light_rain on evaluation')
assert(quality_rows.outdoor_plot.irrigation == 78, ('light_rain must increase outdoor irrigation to 78, got %s'):format(tostring(quality_rows.outdoor_plot.irrigation)))
assert(quality_rows.outdoor_plot.weather_match == 100, ('wheat in spring light_rain must score 100, got %s'):format(tostring(quality_rows.outdoor_plot.weather_match)))
assert(quality_rows.greenhouse_plot.irrigation == 70, 'greenhouse irrigation must remain unchanged')
assert(WeatherFactor:get('greenhouse_plot') == 70, 'greenhouse weather factor must stay neutral')

now_ts = 1025
active_crops[1].irrigation = quality_rows.outdoor_plot.irrigation
active_crops[1].weather_match = quality_rows.outdoor_plot.weather_match
active_crops[2].irrigation = quality_rows.greenhouse_plot.irrigation
active_crops[2].weather_match = quality_rows.greenhouse_plot.weather_match

local second_tick = ClimateService.Tick(active_crops, now_ts)
assert(second_tick.current_season == 'summer', 'season must advance to summer after duration elapses')
assert(second_tick.current_weather == 'hail', 'summer weather must roll to hail')
assert(quality_rows.outdoor_plot.irrigation == 63, ('hail must reduce outdoor irrigation to 63, got %s'):format(tostring(quality_rows.outdoor_plot.irrigation)))
assert(quality_rows.outdoor_plot.weather_match == 50, ('wheat in summer hail must score 50, got %s'):format(tostring(quality_rows.outdoor_plot.weather_match)))
assert(WeatherFactor:get('outdoor_plot') == 50, 'outdoor weather factor must reflect current climate context')

local season_changed = false
local weather_changed = 0
for index = 1, #captured_events do
    local event_name = captured_events[index].name
    if event_name == 'sonar:farm:climate:season_changed' then
        season_changed = true
    elseif event_name == 'sonar:farm:climate:weather_changed' then
        weather_changed = weather_changed + 1
    end
end

assert(season_changed == true, 'season_changed event must be emitted')
assert(weather_changed >= 2, 'weather_changed event must be emitted for both light_rain and hail')

ClimateService.__test_now = nil
ClimateService.__test_emit = nil

print('climate_service_spec.lua: OK (boot + weather roll + season advance + greenhouse neutrality)')
'@

Write-Host 'S16 lint fixes applied.'
