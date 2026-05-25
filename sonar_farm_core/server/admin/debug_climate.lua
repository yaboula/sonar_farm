-- Debug command to force weather change for testing
-- Usage: /sonarfarm:debug:climate_weather <weather_type>

Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}

local function log_info(message)
    print(('[sonar_farm_core][debug] %s'):format(message))
end

local VALID_WEATHER = {
    'clear',
    'light_rain',
    'torrential_rain',
    'drought',
    'hail',
    'frost',
}

RegisterCommand('sonarfarm:debug:climate_weather', function(source, args, _rawCommand)
    if source ~= 0 then
        -- Only allow from server console or admin
        return
    end

    local weather_type = args[1]
    if not weather_type or weather_type == '' then
        log_info('Usage: sonarfarm:debug:climate_weather <weather_type>')
        log_info('Valid weather types: ' .. table.concat(VALID_WEATHER, ', '))
        return
    end

    -- Validate weather type
    local is_valid = false
    for _, valid in ipairs(VALID_WEATHER) do
        if valid == weather_type then
            is_valid = true
            break
        end
    end

    if not is_valid then
        log_info(('Invalid weather type: %s'):format(weather_type))
        log_info('Valid weather types: ' .. table.concat(VALID_WEATHER, ', '))
        return
    end

    if not Sonar.Farm.ClimateService then
        log_info('ClimateService not available')
        return
    end

    -- Force weather change
    local success, err = Sonar.Farm.ClimateService.ForceWeatherChange(weather_type)
    if not success then
        log_info(('Error forcing weather change: %s'):format(err or 'unknown'))
        return
    end

    log_info(('Forced weather change to: %s'):format(weather_type))
end, true)
