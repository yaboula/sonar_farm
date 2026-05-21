local function t(key, ...)
    return locale(key, ...)
end

local function log_line(target_src, line)
    if target_src == 0 then
        print(line)
    else
        TriggerClientEvent('chat:addMessage', target_src, {
            color = Config.Farm.Chat.BrandColor,
            args = { t('ui.brand_name'), line },
        })
    end
end

local function get_db()
    return Sonar and Sonar.Farm and Sonar.Farm.DB or nil
end

local function get_plot_service()
    return Sonar and Sonar.Farm and Sonar.Farm.PlotService or nil
end

local function get_lifecycle()
    return Sonar and Sonar.Farm and Sonar.Farm.CropLifecycle or nil
end

local function fetch_crop(db, plot_id)
    return db.row([[
        SELECT `plot_id`, `stage`, `next_stage_ts`
        FROM `sonar_farm_crops`
        WHERE `plot_id` = ?
        LIMIT 1
    ]], { plot_id })
end

local function set_next_stage_ts(db, plot_service, plot_id, next_stage_ts)
    db.execute('UPDATE `sonar_farm_crops` SET `next_stage_ts` = ? WHERE `plot_id` = ?', { next_stage_ts, plot_id })
    return plot_service.UpdatePlotState(plot_id, {
        next_stage_ts = next_stage_ts,
    }, 'debug_fastforward')
end

local function run_fastforward(caller_src, plot_id, hours)
    if not Config or not Config.Farm or Config.Farm.Debug ~= true then
        log_line(caller_src, t('debug.fastforward.disabled'))
        return
    end

    if type(plot_id) ~= 'string' or plot_id == '' or type(hours) ~= 'number' or hours <= 0 then
        log_line(caller_src, t('debug.fastforward.usage'))
        return
    end

    local db = get_db()
    local plot_service = get_plot_service()
    local lifecycle = get_lifecycle()
    if not db or not plot_service or not lifecycle or type(lifecycle.AdvanceStage) ~= 'function' then
        log_line(caller_src, t('debug.fastforward.unavailable'))
        return
    end

    local crop = fetch_crop(db, plot_id)
    if not crop then
        log_line(caller_src, t('debug.fastforward.no_crop', plot_id))
        return
    end

    local remaining_seconds = math.floor(hours * 3600)
    local now_ts

    while crop and remaining_seconds > 0 and (tonumber(crop.stage) or 0) < 4 do
        now_ts = os.time()
        local current_next_stage_ts = tonumber(crop.next_stage_ts) or now_ts
        local seconds_to_next_stage = current_next_stage_ts - now_ts
        if seconds_to_next_stage < 0 then
            seconds_to_next_stage = 0
        end

        if remaining_seconds >= seconds_to_next_stage then
            local ok, err = set_next_stage_ts(db, plot_service, plot_id, now_ts)
            if not ok then
                log_line(caller_src, tostring(err))
                return
            end

            ok, err = lifecycle.AdvanceStage(plot_id)
            if not ok then
                log_line(caller_src, tostring(err))
                return
            end

            remaining_seconds = remaining_seconds - seconds_to_next_stage
            crop = fetch_crop(db, plot_id)
        else
            local next_stage_ts = current_next_stage_ts - remaining_seconds
            local ok, err = set_next_stage_ts(db, plot_service, plot_id, next_stage_ts)
            if not ok then
                log_line(caller_src, tostring(err))
                return
            end
            remaining_seconds = 0
        end
    end

    log_line(caller_src, t('debug.fastforward.done', plot_id, hours))
end

RegisterCommand('sonarfarm:debug:fastforward', function(source, args)
    local caller_src = tonumber(source) or 0

    if caller_src > 0 and not IsPlayerAceAllowed(caller_src, 'sonar.farm.admin') then
        log_line(caller_src, t('debug.fastforward.ace_required'))
        return
    end

    local plot_id = args[1]
    local hours = tonumber(args[2])
    run_fastforward(caller_src, plot_id, hours)
end, false)
