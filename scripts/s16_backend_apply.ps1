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

$fxmanifest = Join-Path $root 'sonar_farm_core\fxmanifest.lua'
Replace-Exact $fxmanifest "    'config/irrigation.lua',`r`n    'config/items.lua'," "    'config/irrigation.lua',`r`n    'config/climate.lua',`r`n    'config/items.lua',"
Replace-Exact $fxmanifest "    'server/npcs/init.lua',`r`n    -- Quality domain: factors first → calculator → boot." "    'server/npcs/init.lua',`r`n    'server/climate/climate_service.lua',`r`n    -- Quality domain: factors first → calculator → boot."
Replace-Exact $fxmanifest "sonar_farm_migration 'database/migrations/011_pest_severity.sql'`r`n" "sonar_farm_migration 'database/migrations/011_pest_severity.sql'`r`nsonar_farm_migration 'database/migrations/012_climate.sql'`r`n"

$schedulerPath = Join-Path $root 'sonar_farm_core\server\lifecycle\scheduler.lua'
Set-File $schedulerPath @'
Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}
Sonar.Farm.Lifecycle = Sonar.Farm.Lifecycle or {}

local Scheduler = {}
local running = false

local function get_tick_seconds()
    local scheduler_config = Config and Config.Farm and Config.Farm.Scheduler or {}
    local tick_seconds = tonumber(scheduler_config.TickSeconds) or 30
    if tick_seconds < 1 then
        return 1
    end
    return math.floor(tick_seconds)
end

local function get_db()
    return Sonar and Sonar.Farm and Sonar.Farm.DB or nil
end

local function get_lifecycle()
    return Sonar and Sonar.Farm and Sonar.Farm.CropLifecycle or nil
end

local function get_pest_service()
    return Sonar and Sonar.Farm and Sonar.Farm.PestService or nil
end

local function get_climate_service()
    return Sonar and Sonar.Farm and Sonar.Farm.ClimateService or nil
end

local function run_tick()
    local db = get_db()
    local lifecycle = get_lifecycle()
    local pest_service = get_pest_service()
    local climate_service = get_climate_service()
    if not db or not lifecycle or type(lifecycle.AdvanceStage) ~= 'function' then
        return
    end

    local now_ts = os.time()
    local due_rows = db.rows([[
        SELECT `plot_id`
        FROM `sonar_farm_crops`
        WHERE `next_stage_ts` <= ? AND `stage` < 4
        ORDER BY `next_stage_ts` ASC
    ]], { now_ts }) or {}

    for index = 1, #due_rows do
        local ok, result = pcall(lifecycle.AdvanceStage, due_rows[index].plot_id)
        if not ok then
            print(('[sonar_farm_core][lifecycle][scheduler][ERROR] %s'):format(tostring(result)))
        end
    end

    local active_crops = db.rows([[
        SELECT
            c.`plot_id`,
            c.`crop_type`,
            c.`stage`,
            p.`plot_type`,
            q.`irrigation`,
            q.`weather_match`
        FROM `sonar_farm_crops` c
        INNER JOIN `sonar_farm_plots` p
            ON p.`plot_id` = c.`plot_id`
        LEFT JOIN `sonar_farm_quality_tracking` q
            ON q.`plot_id` = c.`plot_id`
        WHERE c.`stage` < 4
        ORDER BY c.`next_stage_ts` ASC
    ]], {}) or {}

    if climate_service and type(climate_service.Tick) == 'function' then
        local ok, result = pcall(climate_service.Tick, active_crops, now_ts)
        if not ok then
            print(('[sonar_farm_core][lifecycle][scheduler][ERROR] %s'):format(tostring(result)))
        end
    end

    if pest_service and type(pest_service.TickCrops) == 'function' then
        local ok, result = pcall(pest_service.TickCrops, active_crops)
        if not ok then
            print(('[sonar_farm_core][lifecycle][scheduler][ERROR] %s'):format(tostring(result)))
        end
    end
end

function Scheduler.Start()
    if running then
        return false
    end

    running = true
    CreateThread(function()
        while running do
            Wait(get_tick_seconds() * 1000)
            run_tick()
        end
    end)

    return true
end

function Scheduler.Stop()
    running = false
    return true
end

function Scheduler.IsRunning()
    return running
end

Sonar.Farm.Lifecycle.Scheduler = Scheduler
'@

$weatherPath = Join-Path $root 'sonar_farm_core\server\quality\factors\weather.lua'
Set-File $weatherPath @'
Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}
Sonar.Farm.Quality = Sonar.Farm.Quality or {}
Sonar.Farm.Quality.Factors = Sonar.Farm.Quality.Factors or {}

local WeatherFactor = {}
local FACTOR_NAME = 'weather_match'
local DEFAULT_SCORE = 70

local function configured_default()
    local quality_config = Config and Config.Farm and Config.Farm.Quality or nil
    local defaults = quality_config and quality_config.NeutralDefaults or nil
    return defaults and defaults.weather_match or DEFAULT_SCORE
end

local function clamp_score(value)
    local score = tonumber(value) or configured_default()
    if score < 0 then
        return 0
    end
    if score > 100 then
        return 100
    end
    return math.floor(score + 0.5)
end

local function get_db()
    return Sonar and Sonar.Farm and Sonar.Farm.DB or nil
end

local function get_plot_service()
    return Sonar and Sonar.Farm and Sonar.Farm.PlotService or nil
end

local function get_climate_service()
    return Sonar and Sonar.Farm and Sonar.Farm.ClimateService or nil
end

local function get_greenhouse_config()
    return Config and Config.Farm and Config.Farm.Greenhouse or {}
end

local function get_climate_config()
    return Config and Config.Farm and Config.Farm.Climate or {}
end

local function get_crop_config(crop_type)
    local crops = Config and Config.Farm and Config.Farm.Crops or {}
    local crop = crops and crops[crop_type] or nil
    if type(crop) ~= 'table' then
        return nil
    end

    return crop
end

local function greenhouse_plot_type(plot_type)
    local plot_types = get_greenhouse_config().PlotTypes or {}
    return plot_types[plot_type] == true
end

local function is_greenhouse_plot(plot_id)
    local plot_service = get_plot_service()
    if not plot_service or type(plot_service.GetPlot) ~= 'function' then
        return false
    end

    local plot = plot_service.GetPlot(plot_id)
    if type(plot) ~= 'table' then
        return false
    end

    return greenhouse_plot_type(plot.plot_type)
end

local function greenhouse_score_override(plot_id)
    if not is_greenhouse_plot(plot_id) then
        return nil
    end

    local configured_score = tonumber(get_greenhouse_config().WeatherNeutralScore)
    return clamp_score(configured_score)
end

local function greenhouse_score_override_for_type(plot_type)
    if not greenhouse_plot_type(plot_type) then
        return nil
    end

    local configured_score = tonumber(get_greenhouse_config().WeatherNeutralScore)
    return clamp_score(configured_score)
end

local function safe_trigger(event_name, payload)
    if type(TriggerEvent) == 'function' then
        TriggerEvent(event_name, payload)
    end
end

local function get_season_order()
    local season_order = get_climate_config().SeasonOrder
    if type(season_order) == 'table' and #season_order > 0 then
        return season_order
    end

    return { 'spring', 'summer', 'autumn', 'winter' }
end

local function season_index(season_name)
    local order = get_season_order()
    for index = 1, #order do
        if order[index] == season_name then
            return index
        end
    end

    return nil
end

local function table_contains(list, value)
    if type(list) ~= 'table' then
        return false
    end

    for index = 1, #list do
        if list[index] == value then
            return true
        end
    end

    return false
end

local function season_is_adjacent(current_season, optimal_seasons)
    local order = get_season_order()
    local order_count = #order
    local current_index = season_index(current_season)
    if not current_index or type(optimal_seasons) ~= 'table' then
        return false
    end

    for index = 1, #optimal_seasons do
        local optimal_index = season_index(optimal_seasons[index])
        if optimal_index then
            local distance = math.abs(current_index - optimal_index)
            if distance == 1 or distance == (order_count - 1) then
                return true
            end
        end
    end

    return false
end

local function calculate_season_score(crop_config, current_season)
    local weather_factor_config = get_climate_config().WeatherFactor or {}
    local optimal_score = tonumber(weather_factor_config.OptimalSeasonScore) or 100
    local shoulder_score = tonumber(weather_factor_config.ShoulderSeasonScore) or 70
    local off_season_score = tonumber(weather_factor_config.OffSeasonScore) or 35
    local optimal_seasons = crop_config and crop_config.optimal_seasons or nil

    if type(current_season) ~= 'string' or current_season == '' or type(optimal_seasons) ~= 'table' or #optimal_seasons == 0 then
        return configured_default()
    end

    if table_contains(optimal_seasons, current_season) then
        return clamp_score(optimal_score)
    end

    if season_is_adjacent(current_season, optimal_seasons) then
        return clamp_score(shoulder_score)
    end

    return clamp_score(off_season_score)
end

local function calculate_weather_score(crop_config, current_weather)
    local preferences = crop_config and (crop_config.preferred_weather or crop_config.weather_preferences) or nil
    if type(current_weather) ~= 'string' or current_weather == '' or type(preferences) ~= 'table' then
        return configured_default()
    end

    local configured = preferences[current_weather]
    if configured == nil then
        return configured_default()
    end

    return clamp_score(configured)
end

local function calculate_weighted_score(season_score, weather_score)
    local weather_factor_config = get_climate_config().WeatherFactor or {}
    local season_weight = tonumber(weather_factor_config.SeasonWeight) or 0.6
    local weather_weight = tonumber(weather_factor_config.WeatherWeight) or 0.4
    local denominator = season_weight + weather_weight
    if denominator <= 0 then
        return configured_default()
    end

    return clamp_score(((season_score * season_weight) + (weather_score * weather_weight)) / denominator)
end

local function fetch_active_crop(plot_id)
    local db = get_db()
    if not db then
        return nil
    end

    return db.row('SELECT `crop_type` FROM `sonar_farm_crops` WHERE `plot_id` = ? LIMIT 1', { plot_id })
end

function WeatherFactor.CalculateForContext(crop_type, plot_type, current_season, current_weather)
    local greenhouse_override = greenhouse_score_override_for_type(plot_type)
    if greenhouse_override ~= nil then
        return greenhouse_override
    end

    local crop_config = get_crop_config(crop_type)
    if not crop_config then
        return configured_default()
    end

    local season_score = calculate_season_score(crop_config, current_season)
    local weather_score = calculate_weather_score(crop_config, current_weather)
    return calculate_weighted_score(season_score, weather_score)
end

function WeatherFactor:track(plot_id, event, data)
    local db = get_db()
    if not db then
        return false, 'Sonar.Farm.DB is unavailable'
    end

    local score = greenhouse_score_override(plot_id) or clamp_score(data and (data.weather_match or data.score))
    db.execute([[
        INSERT INTO `sonar_farm_quality_tracking` (`plot_id`, `weather_match`, `calculated_at`)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE
            `weather_match` = VALUES(`weather_match`),
            `calculated_at` = VALUES(`calculated_at`)
    ]], { plot_id, score, os.time() })

    safe_trigger('sonar:farm:quality:tracked', {
        plot_id = plot_id,
        factor = FACTOR_NAME,
        event = event,
        score = score,
        tracked_at = os.time(),
    })

    return true, score
end

function WeatherFactor:get(plot_id)
    local greenhouse_override = greenhouse_score_override(plot_id)
    if greenhouse_override ~= nil then
        return greenhouse_override
    end

    local climate_service = get_climate_service()
    local climate_state = climate_service and type(climate_service.GetState) == 'function' and climate_service.GetState() or nil
    local active_crop = fetch_active_crop(plot_id)
    if climate_state and active_crop and type(active_crop.crop_type) == 'string' then
        local plot_service = get_plot_service()
        local plot = plot_service and type(plot_service.GetPlot) == 'function' and plot_service.GetPlot(plot_id) or nil
        local plot_type = plot and plot.plot_type or nil
        return WeatherFactor.CalculateForContext(active_crop.crop_type, plot_type, climate_state.current_season, climate_state.current_weather)
    end

    local db = get_db()
    if not db then
        return configured_default()
    end

    local row = db.row('SELECT `weather_match` FROM `sonar_farm_quality_tracking` WHERE `plot_id` = ? LIMIT 1', { plot_id })
    if not row then
        return configured_default()
    end

    return clamp_score(row.weather_match)
end

Sonar.Farm.Quality.Factors.Weather = WeatherFactor
'@

$climatePath = Join-Path $root 'sonar_farm_core\server\climate\climate_service.lua'
Set-File $climatePath @'
Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}

local ClimateService = {}
local state = nil
local next_weather_evaluation_at = nil
local next_plot_effect_at = nil

local function get_db()
    if not Sonar.Farm.DB then
        error('Sonar.Farm.DB is unavailable', 2)
    end

    return Sonar.Farm.DB
end

local function get_climate_config()
    return Config and Config.Farm and Config.Farm.Climate or {}
end

local function get_quality_defaults()
    local quality = Config and Config.Farm and Config.Farm.Quality or {}
    return quality.NeutralDefaults or {}
end

local function get_weather_factor()
    local quality = Sonar.Farm.Quality or {}
    local factors = quality.Factors or {}
    return factors.Weather
end

local function get_time_multiplier()
    local multiplier = tonumber(Config and Config.Farm and Config.Farm.TimeMultiplier) or 1.0
    if multiplier <= 0 then
        return 1.0
    end

    return multiplier
end

local function get_season_order()
    local season_order = get_climate_config().SeasonOrder
    if type(season_order) == 'table' and #season_order > 0 then
        return season_order
    end

    return { 'spring', 'summer', 'autumn', 'winter' }
end

local function get_default_season()
    local climate = get_climate_config()
    local configured = climate.DefaultSeason
    if type(configured) == 'string' and configured ~= '' then
        return configured
    end

    return get_season_order()[1]
end

local function get_default_weather()
    local climate = get_climate_config()
    local configured = climate.DefaultWeather
    if type(configured) == 'string' and configured ~= '' then
        return configured
    end

    return 'clear'
end

local function get_season_definition(season_name)
    local seasons = get_climate_config().Seasons or {}
    return seasons[season_name]
end

local function has_positive_probabilities(probabilities)
    if type(probabilities) ~= 'table' then
        return false
    end

    for _, value in pairs(probabilities) do
        if (tonumber(value) or 0) > 0 then
            return true
        end
    end

    return false
end

local function get_effective_seconds(base_seconds)
    local seconds = tonumber(base_seconds) or 0
    if seconds <= 0 then
        return 1
    end

    return math.max(1, math.floor((seconds * get_time_multiplier()) + 0.5))
end

local function get_season_duration_seconds(season_name)
    local season = get_season_definition(season_name) or {}
    return get_effective_seconds(season.duration_seconds or 86400)
end

local function get_weather_evaluation_seconds()
    return get_effective_seconds(get_climate_config().WeatherEvaluationSeconds or 1800)
end

local function get_plot_effect_interval_seconds()
    return get_effective_seconds(get_climate_config().PlotEffectIntervalSeconds or 1800)
end

local function copy_state(source)
    return {
        current_season = source.current_season,
        current_weather = source.current_weather,
        season_started_at = tonumber(source.season_started_at) or 0,
        weather_started_at = tonumber(source.weather_started_at) or 0,
    }
end

local function normalize_state(row)
    local current_season = type(row) == 'table' and tostring(row.current_season or '') or ''
    local current_weather = type(row) == 'table' and tostring(row.current_weather or '') or ''
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

    return {
        current_season = current_season,
        current_weather = current_weather,
        season_started_at = season_started_at,
        weather_started_at = weather_started_at,
    }
end

local function persist_state()
    if not state then
        return false
    end

    get_db().execute([[
        INSERT INTO `sonar_farm_climate_state` (
            `id`,
            `current_season`,
            `current_weather`,
            `season_started_at`,
            `weather_started_at`
        ) VALUES (1, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            `current_season` = VALUES(`current_season`),
            `current_weather` = VALUES(`current_weather`),
            `season_started_at` = VALUES(`season_started_at`),
            `weather_started_at` = VALUES(`weather_started_at`)
    ]], {
        state.current_season,
        state.current_weather,
        state.season_started_at,
        state.weather_started_at,
    })

    return true
end

local function initialize_timers(now_ts)
    local now_value = tonumber(now_ts) or os.time()
    next_weather_evaluation_at = math.max(state.weather_started_at + get_weather_evaluation_seconds(), now_value)
    next_plot_effect_at = math.max(state.weather_started_at + get_plot_effect_interval_seconds(), now_value)
end

local function season_index(season_name)
    local order = get_season_order()
    for index = 1, #order do
        if order[index] == season_name then
            return index
        end
    end

    return 1
end

local function get_next_season(season_name)
    local order = get_season_order()
    if #order == 0 then
        return get_default_season()
    end

    local current_index = season_index(season_name)
    local next_index = current_index + 1
    if next_index > #order then
        next_index = 1
    end

    return order[next_index]
end

local function roll_weighted_weather(season_name)
    local probabilities = (get_season_definition(season_name) or {}).weather_probabilities or {}
    local total = 0
    for _, value in pairs(probabilities) do
        local numeric_value = tonumber(value) or 0
        if numeric_value > 0 then
            total = total + numeric_value
        end
    end

    if total <= 0 then
        return get_default_weather()
    end

    local roll = math.random() * total
    local cumulative = 0
    for weather_name, value in pairs(probabilities) do
        local numeric_value = tonumber(value) or 0
        if numeric_value > 0 then
            cumulative = cumulative + numeric_value
            if roll <= cumulative then
                return weather_name
            end
        end
    end

    return get_default_weather()
end

local function greenhouse_plot_type(plot_type)
    local greenhouse = Config and Config.Farm and Config.Farm.Greenhouse or {}
    local plot_types = greenhouse.PlotTypes or {}
    return plot_types[plot_type] == true
end

local function default_irrigation_score()
    return tonumber(get_quality_defaults().irrigation) or 70
end

local function clamp_score(value)
    local numeric = tonumber(value) or 0
    if numeric < 0 then
        return 0
    end
    if numeric > 100 then
        return 100
    end
    return math.floor(numeric + 0.5)
end

local function apply_irrigation_effect(current_irrigation, weather_name)
    local effect = (get_climate_config().WeatherEffects or {})[weather_name] or {}
    local irrigation_delta = tonumber(effect.irrigation_delta) or 0
    local irrigation_floor = tonumber(effect.irrigation_floor)
    local irrigation_ceiling = tonumber(effect.irrigation_ceiling)
    local score = tonumber(current_irrigation) or default_irrigation_score()
    local updated = score + irrigation_delta

    if irrigation_floor ~= nil and updated < irrigation_floor then
        updated = irrigation_floor
    end
    if irrigation_ceiling ~= nil and updated > irrigation_ceiling then
        updated = irrigation_ceiling
    end

    return clamp_score(updated)
end

local function update_crop_quality(plot_id, irrigation_score, weather_match_score, calculated_at)
    get_db().execute([[
        INSERT INTO `sonar_farm_quality_tracking` (
            `plot_id`,
            `irrigation`,
            `weather_match`,
            `calculated_at`
        ) VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            `irrigation` = VALUES(`irrigation`),
            `weather_match` = VALUES(`weather_match`),
            `calculated_at` = VALUES(`calculated_at`)
    ]], {
        plot_id,
        clamp_score(irrigation_score),
        clamp_score(weather_match_score),
        calculated_at,
    })
end

local function apply_weather_to_crops(active_crops, now_ts, apply_irrigation)
    local weather_factor = get_weather_factor()
    if type(weather_factor) ~= 'table' or type(weather_factor.CalculateForContext) ~= 'function' then
        error('Sonar.Farm.Quality.Factors.Weather.CalculateForContext is unavailable', 2)
    end

    local rows = type(active_crops) == 'table' and active_crops or {}
    for index = 1, #rows do
        local row = rows[index]
        local plot_id = row and row.plot_id or nil
        local crop_type = row and row.crop_type or nil
        local plot_type = row and row.plot_type or nil
        if type(plot_id) == 'string' and plot_id ~= '' and type(crop_type) == 'string' and crop_type ~= '' then
            local current_irrigation = tonumber(row.irrigation) or default_irrigation_score()
            local irrigation_score = current_irrigation
            if apply_irrigation and not greenhouse_plot_type(plot_type) then
                irrigation_score = apply_irrigation_effect(current_irrigation, state.current_weather)
            end

            local weather_match = weather_factor.CalculateForContext(crop_type, plot_type, state.current_season, state.current_weather)
            if irrigation_score ~= current_irrigation or weather_match ~= tonumber(row.weather_match) then
                update_crop_quality(plot_id, irrigation_score, weather_match, now_ts)
            end
        end
    end
end

local function emit_change(event_name, payload)
    if type(TriggerEvent) == 'function' then
        TriggerEvent(event_name, payload)
    end
    if type(TriggerClientEvent) == 'function' then
        TriggerClientEvent(event_name, -1, payload)
    end
end

local function change_weather(new_weather, now_ts)
    local previous_weather = state.current_weather
    if new_weather == previous_weather then
        next_weather_evaluation_at = now_ts + get_weather_evaluation_seconds()
        return false
    end

    state.current_weather = new_weather
    state.weather_started_at = now_ts
    next_weather_evaluation_at = now_ts + get_weather_evaluation_seconds()
    next_plot_effect_at = now_ts
    persist_state()
    emit_change('sonar:farm:climate:weather_changed', {
        previous_weather = previous_weather,
        current_weather = state.current_weather,
        season = state.current_season,
        weather_started_at = state.weather_started_at,
        changed_at = now_ts,
    })

    return true
end

local function advance_seasons(now_ts)
    local changed = false
    local previous_season = state.current_season

    while now_ts >= (state.season_started_at + get_season_duration_seconds(state.current_season)) do
        local previous_duration = get_season_duration_seconds(state.current_season)
        state.season_started_at = state.season_started_at + previous_duration
        state.current_season = get_next_season(state.current_season)
        changed = true
    end

    if not changed then
        return false
    end

    persist_state()
    emit_change('sonar:farm:climate:season_changed', {
        previous_season = previous_season,
        current_season = state.current_season,
        season_started_at = state.season_started_at,
        changed_at = now_ts,
    })

    return true
end

function ClimateService.Boot()
    local now_ts = os.time()
    local row = get_db().row([[
        SELECT
            `current_season`,
            `current_weather`,
            `season_started_at`,
            `weather_started_at`
        FROM `sonar_farm_climate_state`
        WHERE `id` = 1
        LIMIT 1
    ]], {})

    if row then
        state = normalize_state(row)
    else
        state = normalize_state({
            current_season = get_default_season(),
            current_weather = get_default_weather(),
            season_started_at = now_ts,
            weather_started_at = now_ts,
        })
        persist_state()
    end

    initialize_timers(now_ts)
    return true
end

function ClimateService.GetState()
    if not state then
        return nil
    end

    return copy_state(state)
end

function ClimateService.GetCurrentSeason()
    return state and state.current_season or nil
end

function ClimateService.GetCurrentWeather()
    return state and state.current_weather or nil
end

function ClimateService.SelectWeatherForSeason(season_name)
    return roll_weighted_weather(season_name)
end

function ClimateService.Tick(active_crops, now_ts)
    if not state then
        ClimateService.Boot()
    end

    local tick_ts = tonumber(now_ts) or os.time()
    local season_changed = advance_seasons(tick_ts)
    local weather_changed = false

    if season_changed then
        local season_weather = roll_weighted_weather(state.current_season)
        weather_changed = change_weather(season_weather, tick_ts) or weather_changed
    elseif tick_ts >= (next_weather_evaluation_at or 0) then
        local rolled_weather = roll_weighted_weather(state.current_season)
        weather_changed = change_weather(rolled_weather, tick_ts) or weather_changed
        if not weather_changed then
            next_weather_evaluation_at = tick_ts + get_weather_evaluation_seconds()
        end
    end

    local irrigation_due = tick_ts >= (next_plot_effect_at or 0)
    if season_changed or weather_changed or irrigation_due then
        apply_weather_to_crops(active_crops, tick_ts, weather_changed or irrigation_due)
        if weather_changed or irrigation_due then
            next_plot_effect_at = tick_ts + get_plot_effect_interval_seconds()
        end
    end

    return copy_state(state)
end

Sonar.Farm.ClimateService = ClimateService
'@

$cropFiles = @{
    'sonar_farm_core\config\crops\wheat.lua' = @'
Config = Config or {}
Config.Farm = Config.Farm or {}
Config.Farm.Crops = Config.Farm.Crops or {}

local verified_props = Config.Farm.VerifiedProps and Config.Farm.VerifiedProps.wheat or {}
local verified_stages = verified_props.stages or {}

Config.Farm.Crops.wheat = {
    display_name_key = 'crops.wheat.name',
    plot_types_allowed = { 'extensive' },
    stages = {
        [0] = { duration_seconds = 21600, prop_name = verified_stages[0] and verified_stages[0].prop_name or 'prop_veg_grass_01_a', prop_scale = verified_stages[0] and verified_stages[0].prop_scale or 1.0, prop_z_offset = verified_stages[0] and verified_stages[0].prop_z_offset or 0.0, state = 'planted' },
        [1] = { duration_seconds = 21600, prop_name = verified_stages[1] and verified_stages[1].prop_name or 'prop_veg_grass_01_b', prop_scale = verified_stages[1] and verified_stages[1].prop_scale or 1.0, prop_z_offset = verified_stages[1] and verified_stages[1].prop_z_offset or 0.0, state = 'germinating' },
        [2] = { duration_seconds = 21600, prop_name = verified_stages[2] and verified_stages[2].prop_name or 'prop_veg_grass_01_c', prop_scale = verified_stages[2] and verified_stages[2].prop_scale or 1.0, prop_z_offset = verified_stages[2] and verified_stages[2].prop_z_offset or 0.0, state = 'growing' },
        [3] = { duration_seconds = 21600, prop_name = verified_stages[3] and verified_stages[3].prop_name or 'prop_veg_crop_06', prop_scale = verified_stages[3] and verified_stages[3].prop_scale or 1.0, prop_z_offset = verified_stages[3] and verified_stages[3].prop_z_offset or 0.0, state = 'maturing' },
        [4] = { duration_seconds = 0, prop_name = verified_stages[4] and verified_stages[4].prop_name or 'prop_veg_crop_06', prop_scale = verified_stages[4] and verified_stages[4].prop_scale or 1.0, prop_z_offset = verified_stages[4] and verified_stages[4].prop_z_offset or 0.0, state = 'harvest_ready' },
    },
    seed_weight_g = 500,
    harvest_window_seconds = 21600,
    harvest_yield_g = 2500,
    fallow_cooldown_seconds = 3600,
    freshness_decay_rate_per_h = 2,
    seed_quality_default = 70,
    optimal_seasons = { 'autumn', 'winter' },
    preferred_weather = {
        clear = 80,
        light_rain = 95,
        torrential_rain = 55,
        drought = 40,
        hail = 20,
        frost = 70,
    },
    npk_optimal = { n = 60, p = 40, k = 50 },
    fertilization = {
        optimal_items = { 'sonar_fertilizer_npk', 'sonar_fertilizer_n' },
        ceiling = 90,
        wrong_penalty = -5,
        overfertilize_floor = 40,
        max_applications_per_stage = 1,
        score_gain_correct = 15,
    },
    pests = {
        susceptible_to = { 'blight', 'aphid' },
        spawn_probability_per_tick = 0.05,
        min_stage = 1,
        max_stage = 3,
        severity_hours = 24,
        treat_score_restore = 30,
        severe_treat_ceiling = 60,
    },
}
'@
    'sonar_farm_core\config\crops\corn.lua' = @'
Config = Config or {}
Config.Farm = Config.Farm or {}
Config.Farm.Crops = Config.Farm.Crops or {}

local verified_props = Config.Farm.VerifiedProps and Config.Farm.VerifiedProps.corn or {}
local verified_stages = verified_props.stages or {}

Config.Farm.Crops.corn = {
    display_name_key = 'crops.corn.name',
    plot_types_allowed = { 'extensive' },
    stages = {
        [0] = { duration_seconds = 31500, prop_name = verified_stages[0] and verified_stages[0].prop_name or 'prop_veg_corn_01', prop_scale = verified_stages[0] and verified_stages[0].prop_scale or 0.7, prop_z_offset = verified_stages[0] and verified_stages[0].prop_z_offset or 0.0, state = 'planted' },
        [1] = { duration_seconds = 31500, prop_name = verified_stages[1] and verified_stages[1].prop_name or 'prop_veg_corn_01', prop_scale = verified_stages[1] and verified_stages[1].prop_scale or 0.95, prop_z_offset = verified_stages[1] and verified_stages[1].prop_z_offset or 0.0, state = 'germinating' },
        [2] = { duration_seconds = 31500, prop_name = verified_stages[2] and verified_stages[2].prop_name or 'prop_veg_corn_01', prop_scale = verified_stages[2] and verified_stages[2].prop_scale or 1.15, prop_z_offset = verified_stages[2] and verified_stages[2].prop_z_offset or 0.0, state = 'growing' },
        [3] = { duration_seconds = 31500, prop_name = verified_stages[3] and verified_stages[3].prop_name or 'prop_veg_corn_01', prop_scale = verified_stages[3] and verified_stages[3].prop_scale or 1.3, prop_z_offset = verified_stages[3] and verified_stages[3].prop_z_offset or 0.0, state = 'maturing' },
        [4] = { duration_seconds = 0, prop_name = verified_stages[4] and verified_stages[4].prop_name or 'prop_veg_corn_01', prop_scale = verified_stages[4] and verified_stages[4].prop_scale or 1.35, prop_z_offset = verified_stages[4] and verified_stages[4].prop_z_offset or 0.0, state = 'harvest_ready' },
    },
    seed_weight_g = 650,
    harvest_window_seconds = 25200,
    harvest_yield_g = 3500,
    fallow_cooldown_seconds = 3600,
    freshness_decay_rate_per_h = 2,
    seed_quality_default = 70,
    optimal_seasons = { 'spring', 'summer' },
    preferred_weather = {
        clear = 95,
        light_rain = 85,
        torrential_rain = 50,
        drought = 25,
        hail = 15,
        frost = 10,
    },
    npk_optimal = { n = 70, p = 35, k = 55 },
    fertilization = {
        optimal_items = { 'sonar_fertilizer_npk', 'sonar_fertilizer_k' },
        ceiling = 90,
        wrong_penalty = -5,
        overfertilize_floor = 40,
        max_applications_per_stage = 1,
        score_gain_correct = 15,
    },
    pests = {
        susceptible_to = { 'aphid', 'blight' },
        spawn_probability_per_tick = 0.05,
        min_stage = 1,
        max_stage = 3,
        severity_hours = 24,
        treat_score_restore = 30,
        severe_treat_ceiling = 60,
    },
}
'@
    'sonar_farm_core\config\crops\barley.lua' = @'
Config = Config or {}
Config.Farm = Config.Farm or {}
Config.Farm.Crops = Config.Farm.Crops or {}

local verified_props = Config.Farm.VerifiedProps and Config.Farm.VerifiedProps.barley or {}
local verified_stages = verified_props.stages or {}

Config.Farm.Crops.barley = {
    display_name_key = 'crops.barley.name',
    plot_types_allowed = { 'extensive' },
    stages = {
        [0] = { duration_seconds = 25200, prop_name = verified_stages[0] and verified_stages[0].prop_name or 'prop_plant_cane_01a', prop_scale = verified_stages[0] and verified_stages[0].prop_scale or 0.8, prop_z_offset = verified_stages[0] and verified_stages[0].prop_z_offset or 0.0, state = 'planted' },
        [1] = { duration_seconds = 25200, prop_name = verified_stages[1] and verified_stages[1].prop_name or 'prop_plant_cane_01a', prop_scale = verified_stages[1] and verified_stages[1].prop_scale or 1.0, prop_z_offset = verified_stages[1] and verified_stages[1].prop_z_offset or 0.0, state = 'germinating' },
        [2] = { duration_seconds = 25200, prop_name = verified_stages[2] and verified_stages[2].prop_name or 'prop_plant_cane_01b', prop_scale = verified_stages[2] and verified_stages[2].prop_scale or 1.05, prop_z_offset = verified_stages[2] and verified_stages[2].prop_z_offset or 0.0, state = 'growing' },
        [3] = { duration_seconds = 25200, prop_name = verified_stages[3] and verified_stages[3].prop_name or 'prop_plant_cane_01b', prop_scale = verified_stages[3] and verified_stages[3].prop_scale or 1.15, prop_z_offset = verified_stages[3] and verified_stages[3].prop_z_offset or 0.0, state = 'maturing' },
        [4] = { duration_seconds = 0, prop_name = verified_stages[4] and verified_stages[4].prop_name or 'prop_plant_cane_01b', prop_scale = verified_stages[4] and verified_stages[4].prop_scale or 1.2, prop_z_offset = verified_stages[4] and verified_stages[4].prop_z_offset or 0.0, state = 'harvest_ready' },
    },
    seed_weight_g = 500,
    harvest_window_seconds = 21600,
    harvest_yield_g = 2400,
    fallow_cooldown_seconds = 3600,
    freshness_decay_rate_per_h = 2,
    seed_quality_default = 70,
    optimal_seasons = { 'autumn', 'winter' },
    preferred_weather = {
        clear = 78,
        light_rain = 90,
        torrential_rain = 60,
        drought = 45,
        hail = 20,
        frost = 65,
    },
    npk_optimal = { n = 55, p = 35, k = 45 },
    fertilization = {
        optimal_items = { 'sonar_fertilizer_npk', 'sonar_fertilizer_n' },
        ceiling = 90,
        wrong_penalty = -5,
        overfertilize_floor = 40,
        max_applications_per_stage = 1,
        score_gain_correct = 15,
    },
    pests = {
        susceptible_to = { 'blight' },
        spawn_probability_per_tick = 0.05,
        min_stage = 1,
        max_stage = 3,
        severity_hours = 24,
        treat_score_restore = 30,
        severe_treat_ceiling = 60,
    },
}
'@
    'sonar_farm_core\config\crops\tomato.lua' = @'
Config = Config or {}
Config.Farm = Config.Farm or {}
Config.Farm.Crops = Config.Farm.Crops or {}

local verified_props = Config.Farm.VerifiedProps and Config.Farm.VerifiedProps.tomato or {}
local verified_stages = verified_props.stages or {}

Config.Farm.Crops.tomato = {
    display_name_key = 'crops.tomato.name',
    plot_types_allowed = { 'horticultural', 'greenhouse' },
    stages = {
        [0] = { duration_seconds = 18000, prop_name = verified_stages[0] and verified_stages[0].prop_name or 'prop_bush_med_01', prop_scale = verified_stages[0] and verified_stages[0].prop_scale or 0.35, prop_z_offset = verified_stages[0] and verified_stages[0].prop_z_offset or -0.1, state = 'planted' },
        [1] = { duration_seconds = 18000, prop_name = verified_stages[1] and verified_stages[1].prop_name or 'prop_bush_med_01', prop_scale = verified_stages[1] and verified_stages[1].prop_scale or 0.45, prop_z_offset = verified_stages[1] and verified_stages[1].prop_z_offset or -0.08, state = 'germinating' },
        [2] = { duration_seconds = 18000, prop_name = verified_stages[2] and verified_stages[2].prop_name or 'prop_bush_med_01', prop_scale = verified_stages[2] and verified_stages[2].prop_scale or 0.6, prop_z_offset = verified_stages[2] and verified_stages[2].prop_z_offset or -0.05, state = 'growing' },
        [3] = { duration_seconds = 18000, prop_name = verified_stages[3] and verified_stages[3].prop_name or 'prop_plant_flower_02', prop_scale = verified_stages[3] and verified_stages[3].prop_scale or 0.85, prop_z_offset = verified_stages[3] and verified_stages[3].prop_z_offset or 0.0, state = 'maturing' },
        [4] = { duration_seconds = 0, prop_name = verified_stages[4] and verified_stages[4].prop_name or 'prop_plant_flower_02', prop_scale = verified_stages[4] and verified_stages[4].prop_scale or 0.95, prop_z_offset = verified_stages[4] and verified_stages[4].prop_z_offset or 0.0, state = 'harvest_ready' },
    },
    seed_weight_g = 120,
    harvest_window_seconds = 18000,
    harvest_yield_g = 1800,
    fallow_cooldown_seconds = 2700,
    freshness_decay_rate_per_h = 4,
    seed_quality_default = 72,
    optimal_seasons = { 'spring', 'summer' },
    preferred_weather = {
        clear = 95,
        light_rain = 80,
        torrential_rain = 35,
        drought = 30,
        hail = 15,
        frost = 10,
    },
    npk_optimal = { n = 70, p = 50, k = 60 },
    fertilization = {
        optimal_items = { 'sonar_fertilizer_npk', 'sonar_fertilizer_k' },
        ceiling = 92,
        wrong_penalty = -4,
        overfertilize_floor = 45,
        max_applications_per_stage = 1,
        score_gain_correct = 16,
    },
    pests = {
        susceptible_to = { 'aphid', 'blight' },
        spawn_probability_per_tick = 0.06,
        min_stage = 1,
        max_stage = 3,
        severity_hours = 24,
        treat_score_restore = 32,
        severe_treat_ceiling = 62,
    },
}
'@
    'sonar_farm_core\config\crops\pepper.lua' = @'
Config = Config or {}
Config.Farm = Config.Farm or {}
Config.Farm.Crops = Config.Farm.Crops or {}

local verified_props = Config.Farm.VerifiedProps and Config.Farm.VerifiedProps.pepper or {}
local verified_stages = verified_props.stages or {}

Config.Farm.Crops.pepper = {
    display_name_key = 'crops.pepper.name',
    plot_types_allowed = { 'horticultural', 'greenhouse' },
    stages = {
        [0] = { duration_seconds = 19800, prop_name = verified_stages[0] and verified_stages[0].prop_name or 'prop_bush_med_01', prop_scale = verified_stages[0] and verified_stages[0].prop_scale or 0.32, prop_z_offset = verified_stages[0] and verified_stages[0].prop_z_offset or -0.1, state = 'planted' },
        [1] = { duration_seconds = 19800, prop_name = verified_stages[1] and verified_stages[1].prop_name or 'prop_bush_med_01', prop_scale = verified_stages[1] and verified_stages[1].prop_scale or 0.42, prop_z_offset = verified_stages[1] and verified_stages[1].prop_z_offset or -0.08, state = 'germinating' },
        [2] = { duration_seconds = 19800, prop_name = verified_stages[2] and verified_stages[2].prop_name or 'prop_plant_flower_01', prop_scale = verified_stages[2] and verified_stages[2].prop_scale or 0.65, prop_z_offset = verified_stages[2] and verified_stages[2].prop_z_offset or -0.02, state = 'growing' },
        [3] = { duration_seconds = 19800, prop_name = verified_stages[3] and verified_stages[3].prop_name or 'prop_plant_flower_03', prop_scale = verified_stages[3] and verified_stages[3].prop_scale or 0.8, prop_z_offset = verified_stages[3] and verified_stages[3].prop_z_offset or 0.0, state = 'maturing' },
        [4] = { duration_seconds = 0, prop_name = verified_stages[4] and verified_stages[4].prop_name or 'prop_plant_flower_03', prop_scale = verified_stages[4] and verified_stages[4].prop_scale or 0.9, prop_z_offset = verified_stages[4] and verified_stages[4].prop_z_offset or 0.0, state = 'harvest_ready' },
    },
    seed_weight_g = 110,
    harvest_window_seconds = 19800,
    harvest_yield_g = 1600,
    fallow_cooldown_seconds = 2700,
    freshness_decay_rate_per_h = 4,
    seed_quality_default = 72,
    optimal_seasons = { 'spring', 'summer' },
    preferred_weather = {
        clear = 92,
        light_rain = 78,
        torrential_rain = 35,
        drought = 28,
        hail = 15,
        frost = 10,
    },
    npk_optimal = { n = 65, p = 45, k = 70 },
    fertilization = {
        optimal_items = { 'sonar_fertilizer_k', 'sonar_fertilizer_npk' },
        ceiling = 92,
        wrong_penalty = -4,
        overfertilize_floor = 45,
        max_applications_per_stage = 1,
        score_gain_correct = 16,
    },
    pests = {
        susceptible_to = { 'aphid', 'blight' },
        spawn_probability_per_tick = 0.06,
        min_stage = 1,
        max_stage = 3,
        severity_hours = 24,
        treat_score_restore = 32,
        severe_treat_ceiling = 62,
    },
}
'@
    'sonar_farm_core\config\crops\lettuce.lua' = @'
Config = Config or {}
Config.Farm = Config.Farm or {}
Config.Farm.Crops = Config.Farm.Crops or {}

local verified_props = Config.Farm.VerifiedProps and Config.Farm.VerifiedProps.lettuce or {}
local verified_stages = verified_props.stages or {}

Config.Farm.Crops.lettuce = {
    display_name_key = 'crops.lettuce.name',
    plot_types_allowed = { 'horticultural', 'greenhouse' },
    stages = {
        [0] = { duration_seconds = 14400, prop_name = verified_stages[0] and verified_stages[0].prop_name or 'prop_plant_clover_01', prop_scale = verified_stages[0] and verified_stages[0].prop_scale or 0.55, prop_z_offset = verified_stages[0] and verified_stages[0].prop_z_offset or -0.08, state = 'planted' },
        [1] = { duration_seconds = 14400, prop_name = verified_stages[1] and verified_stages[1].prop_name or 'prop_plant_clover_01', prop_scale = verified_stages[1] and verified_stages[1].prop_scale or 0.75, prop_z_offset = verified_stages[1] and verified_stages[1].prop_z_offset or -0.06, state = 'germinating' },
        [2] = { duration_seconds = 14400, prop_name = verified_stages[2] and verified_stages[2].prop_name or 'prop_plant_clover_02', prop_scale = verified_stages[2] and verified_stages[2].prop_scale or 0.9, prop_z_offset = verified_stages[2] and verified_stages[2].prop_z_offset or -0.05, state = 'growing' },
        [3] = { duration_seconds = 14400, prop_name = verified_stages[3] and verified_stages[3].prop_name or 'prop_plant_clover_02', prop_scale = verified_stages[3] and verified_stages[3].prop_scale or 1.05, prop_z_offset = verified_stages[3] and verified_stages[3].prop_z_offset or -0.05, state = 'maturing' },
        [4] = { duration_seconds = 0, prop_name = verified_stages[4] and verified_stages[4].prop_name or 'prop_plant_clover_02', prop_scale = verified_stages[4] and verified_stages[4].prop_scale or 1.1, prop_z_offset = verified_stages[4] and verified_stages[4].prop_z_offset or -0.05, state = 'harvest_ready' },
    },
    seed_weight_g = 90,
    harvest_window_seconds = 14400,
    harvest_yield_g = 900,
    fallow_cooldown_seconds = 1800,
    freshness_decay_rate_per_h = 5,
    seed_quality_default = 74,
    optimal_seasons = { 'autumn', 'winter' },
    preferred_weather = {
        clear = 75,
        light_rain = 95,
        torrential_rain = 65,
        drought = 30,
        hail = 25,
        frost = 70,
    },
    npk_optimal = { n = 55, p = 60, k = 40 },
    fertilization = {
        optimal_items = { 'sonar_fertilizer_p', 'sonar_fertilizer_n' },
        ceiling = 90,
        wrong_penalty = -4,
        overfertilize_floor = 50,
        max_applications_per_stage = 1,
        score_gain_correct = 14,
    },
    pests = {
        susceptible_to = { 'aphid' },
        spawn_probability_per_tick = 0.05,
        min_stage = 1,
        max_stage = 3,
        severity_hours = 24,
        treat_score_restore = 30,
        severe_treat_ceiling = 60,
    },
}
'@
    'sonar_farm_core\config\crops\onion.lua' = @'
Config = Config or {}
Config.Farm = Config.Farm or {}
Config.Farm.Crops = Config.Farm.Crops or {}

local verified_props = Config.Farm.VerifiedProps and Config.Farm.VerifiedProps.onion or {}
local verified_stages = verified_props.stages or {}

Config.Farm.Crops.onion = {
    display_name_key = 'crops.onion.name',
    plot_types_allowed = { 'horticultural', 'greenhouse' },
    stages = {
        [0] = { duration_seconds = 16200, prop_name = verified_stages[0] and verified_stages[0].prop_name or 'prop_plant_01a', prop_scale = verified_stages[0] and verified_stages[0].prop_scale or 0.55, prop_z_offset = verified_stages[0] and verified_stages[0].prop_z_offset or -0.4, state = 'planted' },
        [1] = { duration_seconds = 16200, prop_name = verified_stages[1] and verified_stages[1].prop_name or 'prop_plant_01a', prop_scale = verified_stages[1] and verified_stages[1].prop_scale or 0.75, prop_z_offset = verified_stages[1] and verified_stages[1].prop_z_offset or -0.35, state = 'germinating' },
        [2] = { duration_seconds = 16200, prop_name = verified_stages[2] and verified_stages[2].prop_name or 'prop_plant_01b', prop_scale = verified_stages[2] and verified_stages[2].prop_scale or 0.9, prop_z_offset = verified_stages[2] and verified_stages[2].prop_z_offset or -0.28, state = 'growing' },
        [3] = { duration_seconds = 16200, prop_name = verified_stages[3] and verified_stages[3].prop_name or 'prop_plant_01b', prop_scale = verified_stages[3] and verified_stages[3].prop_scale or 1.0, prop_z_offset = verified_stages[3] and verified_stages[3].prop_z_offset or -0.22, state = 'maturing' },
        [4] = { duration_seconds = 0, prop_name = verified_stages[4] and verified_stages[4].prop_name or 'prop_plant_01b', prop_scale = verified_stages[4] and verified_stages[4].prop_scale or 1.05, prop_z_offset = verified_stages[4] and verified_stages[4].prop_z_offset or -0.2, state = 'harvest_ready' },
    },
    seed_weight_g = 130,
    harvest_window_seconds = 18000,
    harvest_yield_g = 1400,
    fallow_cooldown_seconds = 2400,
    freshness_decay_rate_per_h = 2,
    seed_quality_default = 71,
    optimal_seasons = { 'spring', 'autumn' },
    preferred_weather = {
        clear = 82,
        light_rain = 88,
        torrential_rain = 60,
        drought = 40,
        hail = 20,
        frost = 55,
    },
    npk_optimal = { n = 45, p = 55, k = 65 },
    fertilization = {
        optimal_items = { 'sonar_fertilizer_p', 'sonar_fertilizer_k' },
        ceiling = 91,
        wrong_penalty = -4,
        overfertilize_floor = 48,
        max_applications_per_stage = 1,
        score_gain_correct = 15,
    },
    pests = {
        susceptible_to = { 'blight' },
        spawn_probability_per_tick = 0.04,
        min_stage = 1,
        max_stage = 3,
        severity_hours = 24,
        treat_score_restore = 30,
        severe_treat_ceiling = 60,
    },
}
'@
    'sonar_farm_core\config\crops\potato.lua' = @'
Config = Config or {}
Config.Farm = Config.Farm or {}
Config.Farm.Crops = Config.Farm.Crops or {}

local verified_props = Config.Farm.VerifiedProps and Config.Farm.VerifiedProps.potato or {}
local verified_stages = verified_props.stages or {}

Config.Farm.Crops.potato = {
    display_name_key = 'crops.potato.name',
    plot_types_allowed = { 'horticultural', 'greenhouse' },
    stages = {
        [0] = { duration_seconds = 18900, prop_name = verified_stages[0] and verified_stages[0].prop_name or 'h4_prop_weed_01_plant', prop_scale = verified_stages[0] and verified_stages[0].prop_scale or 0.5, prop_z_offset = verified_stages[0] and verified_stages[0].prop_z_offset or -0.45, state = 'planted' },
        [1] = { duration_seconds = 18900, prop_name = verified_stages[1] and verified_stages[1].prop_name or 'h4_prop_weed_01_plant', prop_scale = verified_stages[1] and verified_stages[1].prop_scale or 0.68, prop_z_offset = verified_stages[1] and verified_stages[1].prop_z_offset or -0.4, state = 'germinating' },
        [2] = { duration_seconds = 18900, prop_name = verified_stages[2] and verified_stages[2].prop_name or 'h4_prop_weed_01_plant', prop_scale = verified_stages[2] and verified_stages[2].prop_scale or 0.82, prop_z_offset = verified_stages[2] and verified_stages[2].prop_z_offset or -0.35, state = 'growing' },
        [3] = { duration_seconds = 18900, prop_name = verified_stages[3] and verified_stages[3].prop_name or 'h4_prop_weed_01_plant', prop_scale = verified_stages[3] and verified_stages[3].prop_scale or 0.95, prop_z_offset = verified_stages[3] and verified_stages[3].prop_z_offset or -0.32, state = 'maturing' },
        [4] = { duration_seconds = 0, prop_name = verified_stages[4] and verified_stages[4].prop_name or 'h4_prop_weed_01_plant', prop_scale = verified_stages[4] and verified_stages[4].prop_scale or 1.0, prop_z_offset = verified_stages[4] and verified_stages[4].prop_z_offset or -0.3, state = 'harvest_ready' },
    },
    seed_weight_g = 220,
    harvest_window_seconds = 21600,
    harvest_yield_g = 2200,
    fallow_cooldown_seconds = 3000,
    freshness_decay_rate_per_h = 1,
    seed_quality_default = 70,
    optimal_seasons = { 'spring', 'autumn' },
    preferred_weather = {
        clear = 80,
        light_rain = 90,
        torrential_rain = 65,
        drought = 38,
        hail = 22,
        frost = 50,
    },
    npk_optimal = { n = 60, p = 50, k = 75 },
    fertilization = {
        optimal_items = { 'sonar_fertilizer_k', 'sonar_fertilizer_npk' },
        ceiling = 92,
        wrong_penalty = -5,
        overfertilize_floor = 46,
        max_applications_per_stage = 1,
        score_gain_correct = 16,
    },
    pests = {
        susceptible_to = { 'blight', 'aphid' },
        spawn_probability_per_tick = 0.05,
        min_stage = 1,
        max_stage = 3,
        severity_hours = 24,
        treat_score_restore = 32,
        severe_treat_ceiling = 62,
    },
}
'@
}

foreach ($relativePath in $cropFiles.Keys) {
    $target = Join-Path $root $relativePath
    Set-File $target $cropFiles[$relativePath]
}

Write-Host 'S16 climate backend edits applied.'
