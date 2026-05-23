Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}

local CropLifecycle = {}
local STAGE_HARVEST_READY = 4

local function is_string_non_empty(value)
    return type(value) == 'string' and value ~= ''
end

local function get_db()
    if not Sonar.Farm.DB then
        error('Sonar.Farm.DB is unavailable', 3)
    end

    return Sonar.Farm.DB
end

local function get_plot_service()
    if not Sonar.Farm.PlotService then
        error('Sonar.Farm.PlotService is unavailable', 3)
    end

    return Sonar.Farm.PlotService
end

local function get_crop_config(crop_type)
    local crops = Config and Config.Farm and Config.Farm.Crops or nil
    return crops and crops[crop_type] or nil
end

local function get_stage_config(crop_config, stage)
    return crop_config and crop_config.stages and crop_config.stages[stage] or nil
end

local function get_quality()
    return Sonar and Sonar.Farm and Sonar.Farm.Quality or nil
end

local function get_physical_item()
    return Sonar and Sonar.Farm and Sonar.Farm.PhysicalItem or nil
end

local function get_greenhouse_config()
    return Config and Config.Farm and Config.Farm.Greenhouse or {}
end

local function is_greenhouse_plot_type(plot_type)
    local greenhouse_config = get_greenhouse_config()
    local plot_types = greenhouse_config.PlotTypes or {}
    return plot_types[plot_type] == true
end

local function get_greenhouse_weather_score()
    local greenhouse_config = get_greenhouse_config()
    local configured_score = tonumber(greenhouse_config.WeatherNeutralScore)
    if configured_score then
        if configured_score < 0 then
            return 0
        end
        if configured_score > 100 then
            return 100
        end
        return math.floor(configured_score + 0.5)
    end

    local quality_config = Config and Config.Farm and Config.Farm.Quality or {}
    local defaults = quality_config.NeutralDefaults or {}
    return math.floor((tonumber(defaults.weather_match) or 70) + 0.5)
end

local function build_plot_policy(plot)
    local greenhouse_config = get_greenhouse_config()
    local maintenance = greenhouse_config.Maintenance or {}
    local greenhouse = type(plot) == 'table' and is_greenhouse_plot_type(plot.plot_type)

    return {
        plot_type = plot and plot.plot_type or nil,
        greenhouse = greenhouse == true,
        weather_override = greenhouse and get_greenhouse_weather_score() or nil,
        maintenance_cost = greenhouse and math.max(tonumber(maintenance.CostPerCycle) or 0, 0) or 0,
        maintenance_account = greenhouse and tostring(maintenance.Account or 'bank') or nil,
        maintenance_reason = greenhouse and tostring(maintenance.Reason or 'greenhouse_maintenance') or nil,
    }
end

local function safe_trigger(event_name, payload)
    if type(TriggerEvent) == 'function' then
        TriggerEvent(event_name, payload)
    end
end

local function crop_allows_plot_type(crop_config, plot_type)
    local allowed = crop_config.plot_types_allowed or {}
    for index = 1, #allowed do
        if allowed[index] == plot_type then
            return true
        end
    end
    return false
end

local function full_cycle_seconds(crop_config)
    local total = 0
    for stage = 0, STAGE_HARVEST_READY - 1 do
        local stage_config = get_stage_config(crop_config, stage)
        total = total + (stage_config and stage_config.duration_seconds or 0)
    end
    return total
end

local function normalize_crop(row)
    if not row then
        return nil
    end

    return {
        id = tonumber(row.id),
        plot_id = row.plot_id,
        crop_type = row.crop_type,
        player_cid = row.player_cid,
        stage = tonumber(row.stage) or 0,
        planted_ts = tonumber(row.planted_ts) or 0,
        next_stage_ts = tonumber(row.next_stage_ts) or 0,
        harvest_deadline_ts = tonumber(row.harvest_deadline_ts) or 0,
    }
end

local function fetch_active_crop(plot_id)
    return normalize_crop(get_db().row([[
        SELECT
            `id`,
            `plot_id`,
            `crop_type`,
            `player_cid`,
            `stage`,
            `planted_ts`,
            `next_stage_ts`,
            `harvest_deadline_ts`
        FROM `sonar_farm_crops`
        WHERE `plot_id` = ?
        LIMIT 1
    ]], { plot_id }))
end

local function quality_tracking_defaults(plot, crop_config)
    local quality_config = Config and Config.Farm and Config.Farm.Quality or {}
    local defaults = quality_config.NeutralDefaults or {}
    local plot_policy = build_plot_policy(plot)
    return {
        soil_score = plot.soil_score or 50,
        irrigation = defaults.irrigation or 70,
        pest_impact = defaults.pest_impact or 100,
        weather_match = plot_policy.weather_override or defaults.weather_match or 70,
        seed_quality = crop_config.seed_quality_default or defaults.seed_quality or 70,
        fertilization = defaults.fertilization or 70,
        harvest_timing = 100,
    }
end

local function revive_cooldown_if_ready(plot, now_ts)
    if plot.state ~= 'cooldown' then
        return plot
    end

    if plot.next_stage_ts and plot.next_stage_ts > now_ts then
        return plot
    end

    local ok, updated_or_error = get_plot_service().UpdatePlotState(plot.plot_id, {
        state = 'fallow',
        next_stage_ts = now_ts,
    }, 'crop_cooldown_complete')

    if ok then
        return updated_or_error
    end

    return plot
end

function CropLifecycle.GetActiveCrop(plot_id)
    if not is_string_non_empty(plot_id) then
        return nil
    end

    return fetch_active_crop(plot_id)
end

function CropLifecycle.GetPlantPolicy(plot_id, crop_type)
    if not is_string_non_empty(plot_id) then
        return nil, 'plot_id must be a non-empty string'
    end

    if not is_string_non_empty(crop_type) then
        return nil, 'crop_type must be a non-empty string'
    end

    local crop_config = get_crop_config(crop_type)
    if not crop_config then
        return nil, ('crop_type "%s" is not configured'):format(crop_type)
    end

    local plot = get_plot_service().GetPlot(plot_id)
    if not plot then
        return nil, ('plot "%s" not found'):format(plot_id)
    end

    if not crop_allows_plot_type(crop_config, plot.plot_type) then
        return nil, ('crop_type "%s" cannot be planted on plot_type "%s"'):format(crop_type, plot.plot_type)
    end

    return build_plot_policy(plot), nil
end

function CropLifecycle.Plant(plot_id, player_cid, crop_type)
    if not is_string_non_empty(plot_id) then
        return false, 'plot_id must be a non-empty string'
    end

    if not is_string_non_empty(player_cid) then
        return false, 'player_cid must be a non-empty string'
    end

    if not is_string_non_empty(crop_type) then
        return false, 'crop_type must be a non-empty string'
    end

    local crop_config = get_crop_config(crop_type)
    if not crop_config then
        return false, ('crop_type "%s" is not configured'):format(crop_type)
    end

    local plot_service = get_plot_service()
    local plot = plot_service.GetPlot(plot_id)
    if not plot then
        return false, ('plot "%s" not found'):format(plot_id)
    end

    local now_ts = os.time()
    plot = revive_cooldown_if_ready(plot, now_ts)

    if plot.state ~= 'fallow' then
        return false, ('plot "%s" is not fallow'):format(plot_id)
    end

    if not crop_allows_plot_type(crop_config, plot.plot_type) then
        return false, ('crop_type "%s" cannot be planted on plot_type "%s"'):format(crop_type, plot.plot_type)
    end

    if fetch_active_crop(plot_id) then
        return false, ('plot "%s" already has an active crop'):format(plot_id)
    end

    local stage_config = get_stage_config(crop_config, 0)
    if not stage_config then
        return false, ('crop_type "%s" is missing stage 0 config'):format(crop_type)
    end

    local planted_ts = now_ts
    local next_stage_ts = planted_ts + stage_config.duration_seconds
    local harvest_deadline_ts = planted_ts + full_cycle_seconds(crop_config) + (crop_config.harvest_window_seconds or 0)
    local defaults = quality_tracking_defaults(plot, crop_config)

    local ok, updated_or_error = plot_service.UpdatePlotState(plot_id, {
        state = stage_config.state,
        planted_ts = planted_ts,
        next_stage_ts = next_stage_ts,
    }, 'crop_planted')

    if not ok then
        return false, updated_or_error
    end

    local db_ok, db_error = pcall(function()
        get_db().transaction({
            {
                query = [[
                    INSERT INTO `sonar_farm_crops` (
                        `plot_id`,
                        `crop_type`,
                        `player_cid`,
                        `stage`,
                        `planted_ts`,
                        `next_stage_ts`,
                        `harvest_deadline_ts`
                    ) VALUES (?, ?, ?, 0, ?, ?, ?)
                ]],
                values = { plot_id, crop_type, player_cid, planted_ts, next_stage_ts, harvest_deadline_ts },
            },
            {
                query = [[
                    INSERT INTO `sonar_farm_quality_tracking` (
                        `plot_id`,
                        `soil_score`,
                        `irrigation`,
                        `pest_impact`,
                        `weather_match`,
                        `seed_quality`,
                        `fertilization`,
                        `harvest_timing`,
                        `calculated_at`
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                ]],
                values = {
                    plot_id,
                    defaults.soil_score,
                    defaults.irrigation,
                    defaults.pest_impact,
                    defaults.weather_match,
                    defaults.seed_quality,
                    defaults.fertilization,
                    defaults.harvest_timing,
                    now_ts,
                },
            },
        })
    end)

    if not db_ok then
        plot_service.UpdatePlotState(plot_id, {
            state = 'fallow',
            planted_ts = planted_ts,
            next_stage_ts = planted_ts,
        }, 'crop_plant_rollback')
        return false, tostring(db_error)
    end

    local crop = fetch_active_crop(plot_id)
    safe_trigger('sonar:farm:plot:planted', {
        plot_id = plot_id,
        crop_type = crop_type,
        player_cid = player_cid,
        stage = 0,
        planted_ts = planted_ts,
        next_stage_ts = next_stage_ts,
    })

    return true, crop
end

function CropLifecycle.AdvanceStage(plot_id)
    if not is_string_non_empty(plot_id) then
        return false, 'plot_id must be a non-empty string'
    end

    local crop = fetch_active_crop(plot_id)
    if not crop then
        return false, ('plot "%s" has no active crop'):format(plot_id)
    end

    if crop.stage >= STAGE_HARVEST_READY then
        return true, crop
    end

    local crop_config = get_crop_config(crop.crop_type)
    if not crop_config then
        return false, ('crop_type "%s" is not configured'):format(crop.crop_type)
    end

    local next_stage = crop.stage + 1
    local next_stage_config = get_stage_config(crop_config, next_stage)
    if not next_stage_config then
        return false, ('crop_type "%s" is missing stage %d config'):format(crop.crop_type, next_stage)
    end

    local now_ts = os.time()
    local next_stage_ts = crop.next_stage_ts
    if next_stage < STAGE_HARVEST_READY then
        next_stage_ts = now_ts + (next_stage_config.duration_seconds or 0)
    end

    get_db().execute([[
        UPDATE `sonar_farm_crops`
        SET
            `stage` = ?,
            `next_stage_ts` = ?
        WHERE `plot_id` = ?
    ]], { next_stage, next_stage_ts, plot_id })

    local ok, updated_or_error = get_plot_service().UpdatePlotState(plot_id, {
        state = next_stage_config.state,
        next_stage_ts = next_stage_ts,
    }, 'crop_stage_advanced')

    if not ok then
        return false, updated_or_error
    end

    local updated = fetch_active_crop(plot_id)
    safe_trigger('sonar:farm:plot:stage_advanced', {
        plot_id = plot_id,
        crop_type = crop.crop_type,
        previous_stage = crop.stage,
        next_stage = next_stage,
        next_stage_ts = next_stage_ts,
    })

    return true, updated
end

function CropLifecycle.Harvest(plot_id, player_cid)
    if not is_string_non_empty(plot_id) then
        return false, 'plot_id must be a non-empty string'
    end

    if not is_string_non_empty(player_cid) then
        return false, 'player_cid must be a non-empty string'
    end

    local crop = fetch_active_crop(plot_id)
    if not crop then
        return false, ('plot "%s" has no active crop'):format(plot_id)
    end

    if crop.stage < STAGE_HARVEST_READY then
        return false, ('plot "%s" is not harvest-ready'):format(plot_id)
    end

    local crop_config = get_crop_config(crop.crop_type)
    if not crop_config then
        return false, ('crop_type "%s" is not configured'):format(crop.crop_type)
    end

    local harvested_ts = os.time()
    local harvest_timing_factor = get_quality() and get_quality().Factors and get_quality().Factors.HarvestTiming or nil
    local harvest_timing_score = 100
    if harvest_timing_factor and type(harvest_timing_factor.calculate) == 'function' then
        harvest_timing_score = harvest_timing_factor:calculate(crop.harvest_deadline_ts, harvested_ts)
        harvest_timing_factor:track(plot_id, 'harvest', { score = harvest_timing_score })
    end

    local quality = get_quality()
    if not quality or type(quality.Calculate) ~= 'function' then
        return false, 'Sonar.Farm.Quality.Calculate is unavailable'
    end

    local quality_result = quality.Calculate(plot_id, harvest_timing_score)
    local physical_item = get_physical_item()
    if not physical_item or type(physical_item.CreateBatch) ~= 'function' then
        return false, 'Sonar.Farm.PhysicalItem.CreateBatch is unavailable'
    end

    local batch_params = {
        plot_id = plot_id,
        crop_id = crop.id,
        player_cid = player_cid,
        crop_type = crop.crop_type,
        quality = quality_result.grade,
        quality_score = quality_result.score,
        weight_g = crop_config.harvest_yield_g,
        freshness = 100,
        lineage_chain = {},
        harvested_ts = harvested_ts,
        persist = false,
        emit_events = false,
    }

    local batch_id, metadata_or_error = physical_item.CreateBatch(batch_params)

    if not batch_id then
        return false, metadata_or_error
    end

    get_db().transaction({
        physical_item.BuildBatchInsertQuery(batch_params, batch_id, harvested_ts),
        {
            query = 'DELETE FROM `sonar_farm_quality_tracking` WHERE `plot_id` = ?',
            values = { plot_id },
        },
        {
            query = 'DELETE FROM `sonar_farm_crops` WHERE `plot_id` = ?',
            values = { plot_id },
        },
    })

    local cooldown_until = harvested_ts + (crop_config.fallow_cooldown_seconds or 0)
    local ok, updated_or_error = get_plot_service().UpdatePlotState(plot_id, {
        state = 'cooldown',
        next_stage_ts = cooldown_until,
    }, 'crop_harvested')

    if not ok then
        return false, updated_or_error
    end

    physical_item.EmitCreated(batch_params, batch_id, harvested_ts)

    safe_trigger('sonar:farm:plot:harvested', {
        plot_id = plot_id,
        crop_type = crop.crop_type,
        player_cid = player_cid,
        batch_id = batch_id,
        quality = quality_result.grade,
        weight_g = crop_config.harvest_yield_g,
    })

    return true, {
        batch_id = batch_id,
        metadata = metadata_or_error,
        quality = quality_result,
    }
end

function CropLifecycle.Boot()
    if not Sonar.Farm.DB then
        print('[sonar_farm_core][lifecycle][ERROR] DB unavailable')
        return false
    end

    if not Sonar.Farm.PlotService then
        print('[sonar_farm_core][lifecycle][ERROR] PlotService unavailable')
        return false
    end

    if Sonar.Farm.Lifecycle and Sonar.Farm.Lifecycle.Scheduler and type(Sonar.Farm.Lifecycle.Scheduler.Start) == 'function' then
        Sonar.Farm.Lifecycle.Scheduler.Start()
    end

    print('[sonar_farm_core][lifecycle] ready')
    return true
end

Sonar.Farm.CropLifecycle = CropLifecycle
