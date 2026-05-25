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
    local now_value = tonumber(now_ts) or get_now_ts()
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
    local now_ts = get_now_ts()
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

    local tick_ts = tonumber(now_ts) or get_now_ts()
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

function ClimateService.ForceWeatherChange(weather_type)
    if not state then
        return false, 'climate_not_initialized'
    end

    local season_def = get_season_definition(state.current_season)
    if not season_def or not season_def.weather_probabilities or season_def.weather_probabilities[weather_type] == nil then
        return false, 'invalid_weather_for_season'
    end

    local now_ts = get_now_ts()
    local changed = change_weather(weather_type, now_ts)
    if changed then
        next_plot_effect_at = now_ts
    end

    return true, nil
end

Sonar.Farm.ClimateService = ClimateService