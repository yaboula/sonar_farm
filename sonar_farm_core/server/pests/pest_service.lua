Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}

local PestService = {}

local function log_info(message)
    print(('[sonar_farm_core][pests] %s'):format(message))
end

local function get_db()
    if not Sonar.Farm.DB then
        error('Sonar.Farm.DB is unavailable', 2)
    end

    return Sonar.Farm.DB
end

local function get_pest_factor()
    local quality = Sonar.Farm.Quality or {}
    local factors = quality.Factors or {}
    local pest_factor = factors.Pest
    if type(pest_factor) ~= 'table' then
        error('Sonar.Farm.Quality.Factors.Pest is unavailable', 2)
    end

    return pest_factor
end

local function get_crops_config()
    local crops = Config and Config.Farm and Config.Farm.Crops or nil
    if type(crops) ~= 'table' then
        return nil
    end

    return crops
end

local function get_crop_pest_config(crop_type)
    local crops = get_crops_config()
    local crop = crops and crops[crop_type] or nil
    local pests = crop and crop.pests or nil
    if type(pests) ~= 'table' then
        return nil
    end

    return pests
end

local function get_random_pest(susceptible_to)
    if type(susceptible_to) ~= 'table' or #susceptible_to == 0 then
        return nil
    end

    return susceptible_to[math.random(1, #susceptible_to)]
end

local function safe_trigger(event_name, payload)
    if type(TriggerEvent) == 'function' then
        TriggerEvent(event_name, payload)
    end
end

function PestService.Boot()
    local crops = get_crops_config()
    if not crops then
        log_info('pest service boot skipped: crops config unavailable')
        return false
    end

    local susceptible_crop_count = 0
    for _, crop in pairs(crops) do
        local pests = crop and crop.pests or nil
        if type(pests) == 'table' and type(pests.susceptible_to) == 'table' and #pests.susceptible_to > 0 then
            susceptible_crop_count = susceptible_crop_count + 1
        end
    end

    log_info(('ready: %d pest-susceptible crops configured'):format(susceptible_crop_count))
    return true
end

function PestService.TickCrops(active_crops)
    local pest_factor = get_pest_factor()
    local crop_rows = type(active_crops) == 'table' and active_crops or {}

    for index = 1, #crop_rows do
        local crop = crop_rows[index]
        local crop_type = crop and crop.crop_type or nil
        local plot_id = crop and crop.plot_id or nil
        local stage = tonumber(crop and crop.stage) or 0
        local pest_config = crop_type and get_crop_pest_config(crop_type) or nil

        if pest_config and type(plot_id) == 'string' and plot_id ~= '' then
            local min_stage = tonumber(pest_config.min_stage) or 1
            local max_stage = tonumber(pest_config.max_stage) or 3
            local probability = tonumber(pest_config.spawn_probability_per_tick) or 0
            if stage >= min_stage and stage <= max_stage and probability > 0 then
                local status = pest_factor.GetStatus(plot_id)
                if not status and math.random() < probability then
                    local pest_type = get_random_pest(pest_config.susceptible_to)
                    if pest_type then
                        pest_factor.Appear(plot_id, pest_type)
                    end
                end
            end
        end
    end

    local detected_rows = get_db().rows([[
        SELECT
            q.`plot_id`,
            q.`pest_detected_ts`,
            c.`crop_type`
        FROM `sonar_farm_quality_tracking` q
        INNER JOIN `sonar_farm_crops` c
            ON c.`plot_id` = q.`plot_id`
        WHERE q.`pest_detected_ts` IS NOT NULL
          AND q.`pest_severity` = 'detected'
        ORDER BY q.`plot_id` ASC
    ]], {}) or {}

    local now_ts = os.time()
    for index = 1, #detected_rows do
        local row = detected_rows[index]
        local pest_config = get_crop_pest_config(row.crop_type)
        local detected_ts = tonumber(row.pest_detected_ts)
        local severity_hours = pest_config and tonumber(pest_config.severity_hours) or 24
        if pest_config and detected_ts and severity_hours >= 0 then
            local hours_untreated = (now_ts - detected_ts) / 3600
            if hours_untreated >= severity_hours then
                get_db().execute([[UPDATE `sonar_farm_quality_tracking` SET `pest_severity` = 'severe' WHERE `plot_id` = ? AND `pest_severity` = 'detected']], { row.plot_id })
                local pest_type = nil
                if type(pest_factor.GetActivePestType) == 'function' then
                    pest_type = pest_factor.GetActivePestType(row.plot_id)
                end
                safe_trigger('sonar:farm:pest:severe', {
                    plot_id = row.plot_id,
                    pest_type = pest_type,
                    hours_untreated = hours_untreated,
                })
            end
        end
    end

    return true
end

function PestService.GetActivePests()
    return get_db().rows([[
        SELECT
            `plot_id`,
            `pest_detected_ts`,
            `pest_severity`
        FROM `sonar_farm_quality_tracking`
        WHERE `pest_severity` != 'none'
        ORDER BY `plot_id` ASC
    ]], {}) or {}
end

Sonar.Farm.PestService = PestService