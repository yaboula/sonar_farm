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