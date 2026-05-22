RegisterCommand('sonarfarm:debug:pest', function(source, args)
    local caller_src = tonumber(source) or 0
    if caller_src > 0 and not IsPlayerAceAllowed(caller_src, 'sonar.farm.admin') then
        print('[sonar_farm_core][debug:pest] ACE sonar.farm.admin is required')
        return
    end

    local plot_id = args[1]
    local pest_type = args[2]
    if type(plot_id) ~= 'string' or plot_id == '' or type(pest_type) ~= 'string' or pest_type == '' then
        print('[sonar_farm_core][debug:pest] Usage: /sonarfarm:debug:pest <plot_id> <pest_type>')
        return
    end

    local pest_factor = Sonar and Sonar.Farm and Sonar.Farm.Quality and Sonar.Farm.Quality.Factors and Sonar.Farm.Quality.Factors.Pest or nil
    if not pest_factor or type(pest_factor.Appear) ~= 'function' then
        print('[sonar_farm_core][debug:pest] PestFactor not available')
        return
    end

    local ok, err = pest_factor.Appear(plot_id, pest_type)
    if ok then
        print(('[sonar_farm_core][debug:pest] Spawned %s at %s'):format(pest_type, plot_id))
    else
        print(('[sonar_farm_core][debug:pest] Failed: %s'):format(tostring(err)))
    end
end, false)
