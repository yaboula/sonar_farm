-- Farm Sonar — Debug command to reset a plot to fallow state.
-- Usage: /sonarfarm:debug:reset <plot_id>
-- This deletes the active crop, quality tracking, and resets plot state to fallow.

local Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}

local function log_info(msg)
    print(('[sonar_farm_core][debug:reset] %s'):format(msg))
end

local function log_error(msg)
    print(('[sonar_farm_core][debug:reset][ERROR] %s'):format(msg))
end

RegisterCommand('sonarfarm:debug:reset', function(source, args)
    -- Allow execution from both server console and in-game

    local plot_id = args[1]
    if not plot_id or plot_id == '' then
        log_error('Usage: /sonarfarm:debug:reset <plot_id>')
        log_error('Example: /sonarfarm:debug:reset mlo_field_extensive_02')
        return
    end

    log_info(('Resetting plot "%s" to fallow state...'):format(plot_id))

    local db = Sonar.Farm.DB
    if not db then
        log_error('Database not available')
        return
    end

    -- Delete active crop
    local delete_crop_ok, delete_crop_err = pcall(function()
        return db.execute('DELETE FROM `sonar_farm_crops` WHERE `plot_id` = ?', { plot_id })
    end)

    if not delete_crop_ok then
        log_error(('Failed to delete crop: %s'):format(tostring(delete_crop_err)))
        return
    end

    log_info(('Deleted crop for plot "%s"'):format(plot_id))

    -- Delete quality tracking
    local delete_quality_ok, delete_quality_err = pcall(function()
        return db.execute('DELETE FROM `sonar_farm_quality_tracking` WHERE `plot_id` = ?', { plot_id })
    end)

    if not delete_quality_ok then
        log_error(('Failed to delete quality tracking: %s'):format(tostring(delete_quality_err)))
        return
    end

    log_info(('Deleted quality tracking for plot "%s"'):format(plot_id))

    -- Reset plot state to fallow
    local reset_plot_ok, reset_plot_err = pcall(function()
        return db.execute('UPDATE `sonar_farm_plots` SET `state` = ?, `last_updated_ts` = ? WHERE `plot_id` = ?', { 'fallow', os.time(), plot_id })
    end)

    if not reset_plot_ok then
        log_error(('Failed to reset plot state: %s'):format(tostring(reset_plot_err)))
        return
    end

    log_info(('Plot "%s" successfully reset to fallow state'):format(plot_id))
    log_info('You can now plant a new crop on this plot.')
end, true)
