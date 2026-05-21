-- ============================================================
-- Farm Sonar — Debug command to plant wheat without ox_target.
-- Temporary workaround for smoke test B1.
-- Plant(plot_id, player_cid, crop_type)
-- ============================================================

RegisterCommand('sonarfarm:debug:plant', function(source, args)
    local plot_id = args[1]
    if not plot_id or plot_id == '' then
        print('[sonar_farm_core][debug:plant] Usage: /sonarfarm:debug:plant <plot_id>')
        return
    end

    local lifecycle = Sonar and Sonar.Farm and Sonar.Farm.CropLifecycle
    if not lifecycle then
        print('[sonar_farm_core][debug:plant] CropLifecycle not available')
        return
    end

    local player_cid = 'debug_admin'
    local ok, err = lifecycle.Plant(plot_id, player_cid, 'wheat')
    if ok then
        print(('[sonar_farm_core][debug:plant] Planted wheat at %s'):format(plot_id))
    else
        print(('[sonar_farm_core][debug:plant] Failed: %s'):format(tostring(err)))
    end
end, true)
