-- Farm Sonar — Debug command to check plot status.
-- Usage: /sonarfarm:debug:status <plot_id>
-- Shows current state, crop info, stage, and quality tracking.

local Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}

local function log_info(msg)
    print(('[sonar_farm_core][debug:status] %s'):format(msg))
end

local function log_error(msg)
    print(('[sonar_farm_core][debug:status][ERROR] %s'):format(msg))
end

RegisterCommand('sonarfarm:debug:status', function(source, args)
    if source ~= 0 then
        log_error('This command can only be run from server console')
        return
    end

    local plot_id = args[1]
    if not plot_id or plot_id == '' then
        log_error('Usage: /sonarfarm:debug:status <plot_id>')
        log_error('Example: /sonarfarm:debug:status mlo_field_extensive_02')
        return
    end

    log_info(('Checking status for plot "%s"...'):format(plot_id))

    local db = Sonar.Farm.DB
    if not db then
        log_error('Database not available')
        return
    end

    -- Get plot info
    local plot_ok, plot_row = pcall(function()
        return db.row('SELECT * FROM `sonar_farm_plots` WHERE `plot_id` = ? LIMIT 1', { plot_id })
    end)

    if not plot_ok or not plot_row then
        log_error(('Failed to get plot info: %s'):format(tostring(plot_row)))
        return
    end

    log_info('--- PLOT INFO ---')
    log_info(('plot_id: %s'):format(plot_row.plot_id))
    log_info(('state: %s'):format(plot_row.state))
    log_info(('soil_score: %s'):format(plot_row.soil_score))
    log_info(('last_updated_ts: %s'):format(plot_row.last_updated_ts))

    -- Get crop info
    local crop_ok, crop_row = pcall(function()
        return db.row('SELECT * FROM `sonar_farm_crops` WHERE `plot_id` = ? LIMIT 1', { plot_id })
    end)

    if crop_ok and crop_row then
        log_info('--- CROP INFO ---')
        log_info(('crop_type: %s'):format(crop_row.crop_type))
        log_info(('stage: %s'):format(crop_row.stage))
        log_info(('next_stage_ts: %s'):format(crop_row.next_stage_ts))
        log_info(('harvest_deadline_ts: %s'):format(crop_row.harvest_deadline_ts))
        log_info(('planted_ts: %s'):format(crop_row.planted_ts))
    else
        log_info('--- CROP INFO ---')
        log_info('No active crop found')
    end

    -- Get quality tracking
    local quality_ok, quality_row = pcall(function()
        return db.row('SELECT * FROM `sonar_farm_quality_tracking` WHERE `plot_id` = ? LIMIT 1', { plot_id })
    end)

    if quality_ok and quality_row then
        log_info('--- QUALITY TRACKING ---')
        log_info(('irrigation: %s'):format(quality_row.irrigation))
        log_info(('pest_impact: %s'):format(quality_row.pest_impact))
        log_info(('harvest_timing: %s'):format(quality_row.harvest_timing))
        log_info(('calculated_at: %s'):format(quality_row.calculated_at))
    else
        log_info('--- QUALITY TRACKING ---')
        log_info('No quality tracking found')
    end

    log_info('--- END STATUS ---')
end, true)
