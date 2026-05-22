-- Farm Sonar — Debug command to simulate offline time for persistence testing.
-- Usage: /sonarfarm:debug:offline <plot_id> <hours>
-- Simulates the plot being offline for X hours by updating timestamps.

local Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}

local function log_info(msg)
    print(('[sonar_farm_core][debug:offline] %s'):format(msg))
end

local function log_error(msg)
    print(('[sonar_farm_core][debug:offline][ERROR] %s'):format(msg))
end

RegisterCommand('sonarfarm:debug:offline', function(source, args)
    local plot_id = args[1]
    local hours = tonumber(args[2])

    if not plot_id or plot_id == '' then
        log_error('Usage: /sonarfarm:debug:offline <plot_id> <hours>')
        log_error('Example: /sonarfarm:debug:offline mlo_field_extensive_01 8')
        return
    end

    if not hours or hours <= 0 then
        log_error('Hours must be a positive number')
        return
    end

    log_info(('Simulating %d hours offline for plot "%s"...'):format(hours, plot_id))

    local db = Sonar.Farm.DB
    if not db then
        log_error('Database not available')
        return
    end

    local now_ts = os.time()
    local offline_seconds = hours * 3600
    local past_ts = now_ts - offline_seconds

    -- Update plot last_updated_ts
    local update_plot_ok, update_plot_err = pcall(function()
        return db.execute('UPDATE `sonar_farm_plots` SET `last_updated_ts` = ? WHERE `plot_id` = ?', { past_ts, plot_id })
    end)

    if not update_plot_ok then
        log_error(('Failed to update plot timestamp: %s'):format(tostring(update_plot_err)))
        return
    end

    log_info(('Updated plot last_updated_ts to %d (%d hours ago)'):format(past_ts, hours))

    -- Update crop timestamps to simulate offline growth
    local update_crop_ok, update_crop_err = pcall(function()
        return db.execute([[
            UPDATE `sonar_farm_crops` 
            SET 
                `planted_ts` = ?,
                `next_stage_ts` = ?,
                `harvest_deadline_ts` = ?
            WHERE `plot_id` = ?
        ]], { past_ts, past_ts + 21600, past_ts + 86400, plot_id })
    end)

    if not update_crop_ok then
        log_error(('Failed to update crop timestamps: %s'):format(tostring(update_crop_err)))
        return
    end

    log_info(('Updated crop timestamps to simulate offline growth'))

    -- Update quality tracking to simulate active risks during offline
    local update_quality_ok, update_quality_err = pcall(function()
        return db.execute([[
            UPDATE `sonar_farm_quality_tracking` 
            SET 
                `next_irrigation_due_ts` = ?,
                `pest_detected_ts` = ?,
                `calculated_at` = ?
            WHERE `plot_id` = ?
        ]], { past_ts + 100, past_ts + 100, past_ts, plot_id })
    end)

    if not update_quality_ok then
        log_error(('Failed to update quality tracking: %s'):format(tostring(update_quality_err)))
        return
    end

    log_info(('Updated quality tracking to simulate active risks during offline'))
    log_info(('Plot "%s" is now ready for offline persistence test'):format(plot_id))
    log_info(('Run /sonarfarm:persistence:dryrun to preview changes, then restart sonar_farm_core'))
end, true)
