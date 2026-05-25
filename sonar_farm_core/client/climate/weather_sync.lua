local current_climate = {
    season = nil,
    weather = nil,
}

local latest_apply_token = 0
local persist_thread_started = false

local function get_climate_config()
    return Config and Config.Farm and Config.Farm.Climate or {}
end

local function is_sync_enabled()
    return get_climate_config().EnableWeatherSync == true
end

local function get_transition_seconds()
    local seconds = tonumber(get_climate_config().WeatherTransitionSeconds) or 20
    if seconds < 0 then
        return 0
    end

    return seconds
end

local function get_persist_refresh_seconds()
    local seconds = tonumber(get_climate_config().WeatherPersistRefreshSeconds) or 60
    if seconds <= 0 then
        return 60
    end

    return seconds
end

local function get_native_weather_name(weather_name)
    local weather_map = get_climate_config().NativeWeatherMap
    local mapped = type(weather_map) == 'table' and weather_map[weather_name] or nil
    if type(mapped) == 'string' and mapped ~= '' then
        return mapped
    end

    local fallback = type(weather_map) == 'table' and weather_map.clear or nil
    if type(fallback) == 'string' and fallback ~= '' then
        return fallback
    end

    return 'CLEAR'
end

local function copy_current_climate()
    return {
        season = current_climate.season,
        weather = current_climate.weather,
    }
end

local function update_climate_state(season, weather)
    if type(season) == 'string' and season ~= '' then
        current_climate.season = season
    end

    if type(weather) == 'string' and weather ~= '' then
        current_climate.weather = weather
    end
end

local function apply_weather(weather_name)
    if not is_sync_enabled() then
        return
    end

    if type(weather_name) ~= 'string' or weather_name == '' then
        return
    end

    local native_weather = get_native_weather_name(weather_name)
    local transition_seconds = get_transition_seconds()

    if transition_seconds <= 0 then
        ClearOverrideWeather()
        SetWeatherTypePersist(native_weather)
        return
    end

    latest_apply_token = latest_apply_token + 1
    local apply_token = latest_apply_token

    ClearOverrideWeather()
    SetWeatherTypeOverTime(native_weather, transition_seconds + 0.0)

    CreateThread(function()
        Wait(math.floor(transition_seconds * 1000))
        if apply_token ~= latest_apply_token then
            return
        end

        ClearOverrideWeather()
        SetWeatherTypePersist(native_weather)
    end)
end

local function sync_from_server()
    if not lib or not lib.callback or type(lib.callback.await) ~= 'function' then
        return false
    end

    local ok, state = pcall(function()
        return lib.callback.await('sonar:farm:climate:get_state', false)
    end)

    if not ok or type(state) ~= 'table' then
        return false
    end

    update_climate_state(state.current_season, state.current_weather)
    apply_weather(current_climate.weather)
    return true
end

local function ensure_persist_thread()
    if persist_thread_started or not is_sync_enabled() then
        return
    end

    persist_thread_started = true

    CreateThread(function()
        while true do
            Wait(math.floor(get_persist_refresh_seconds() * 1000))

            if is_sync_enabled() and type(current_climate.weather) == 'string' and current_climate.weather ~= '' then
                SetWeatherTypePersist(get_native_weather_name(current_climate.weather))
            end
        end
    end)
end

RegisterNetEvent('sonar:farm:climate:weather_changed', function(payload)
    if type(payload) ~= 'table' then
        return
    end

    update_climate_state(payload.season, payload.current_weather)
    apply_weather(payload.current_weather)
end)

RegisterNetEvent('sonar:farm:climate:season_changed', function(payload)
    if type(payload) ~= 'table' then
        return
    end

    update_climate_state(payload.current_season, nil)
end)

AddEventHandler('playerSpawned', function()
    CreateThread(function()
        Wait(1000)
        sync_from_server()
    end)
end)

AddEventHandler('onClientResourceStart', function(resource_name)
    if resource_name ~= GetCurrentResourceName() then
        return
    end

    ensure_persist_thread()
    sync_from_server()
end)

AddEventHandler('onResourceStop', function(resource_name)
    if resource_name ~= GetCurrentResourceName() then
        return
    end

    if is_sync_enabled() then
        ClearOverrideWeather()
    end
end)

exports('GetCurrentClimate', function()
    return copy_current_climate()
end)