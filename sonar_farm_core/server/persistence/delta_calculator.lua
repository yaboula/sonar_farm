Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}
Sonar.Farm.Persistence = Sonar.Farm.Persistence or {}

local DeltaCalculator = {}
local STAGE_HARVEST_READY = 4

local function is_non_empty_string(value)
    return type(value) == 'string' and value ~= ''
end

local function normalize_unix_ts(value)
    local ts = tonumber(value)
    if not ts or ts < 0 then
        return nil
    end

    return math.floor(ts)
end

local function clamp_score(value)
    local score = tonumber(value) or 0
    if score < 0 then
        return 0
    end
    if score > 100 then
        return 100
    end
    return math.floor(score + 0.5)
end

local function get_persistence_config()
    return Config and Config.Farm and Config.Farm.Persistence or {}
end

local function get_quality_defaults()
    local quality_config = Config and Config.Farm and Config.Farm.Quality or {}
    return quality_config.NeutralDefaults or {}
end

local function get_crop_config(crop_type)
    local crops = Config and Config.Farm and Config.Farm.Crops or nil
    return crops and crops[crop_type] or nil
end

local function get_stage_config(crop_config, stage)
    return crop_config and crop_config.stages and crop_config.stages[stage] or nil
end

local function compute_stage_progression(crop, crop_config, now_ts)
    local stage = tonumber(crop.stage) or 0
    local scheduled_ts = normalize_unix_ts(crop.next_stage_ts)
    local advances = 0

    if stage >= STAGE_HARVEST_READY or not scheduled_ts or scheduled_ts <= 0 then
        local stage_config = get_stage_config(crop_config, stage)
        local state = stage_config and stage_config.state or (stage >= STAGE_HARVEST_READY and 'harvest_ready' or nil)
        return stage, scheduled_ts, advances, state, nil
    end

    while stage < STAGE_HARVEST_READY and scheduled_ts <= now_ts do
        stage = stage + 1
        advances = advances + 1

        if stage < STAGE_HARVEST_READY then
            local stage_config = get_stage_config(crop_config, stage)
            if not stage_config then
                return nil, nil, nil, nil, ('crop_type "%s" is missing stage %d config'):format(tostring(crop.crop_type), stage)
            end

            scheduled_ts = scheduled_ts + (tonumber(stage_config.duration_seconds) or 0)
        end
    end

    local current_stage_config = get_stage_config(crop_config, stage)
    local state = current_stage_config and current_stage_config.state or (stage >= STAGE_HARVEST_READY and 'harvest_ready' or nil)

    return stage, scheduled_ts, advances, state, nil
end

local function compute_factor_penalty(current_score, default_score, penalty_per_hour, starts_at_ts, last_updated_ts, effective_end_ts, max_factor_penalty)
    if not starts_at_ts or starts_at_ts > effective_end_ts then
        return current_score, 0
    end

    local penalty_from_ts = starts_at_ts
    if penalty_from_ts < last_updated_ts then
        penalty_from_ts = last_updated_ts
    end

    local elapsed_seconds = effective_end_ts - penalty_from_ts
    if elapsed_seconds <= 0 then
        return current_score, 0
    end

    local elapsed_hours = math.ceil(elapsed_seconds / 3600)
    local total_penalty = math.max(0, elapsed_hours * math.max(0, tonumber(penalty_per_hour) or 0))
    if total_penalty <= 0 then
        return current_score, 0
    end

    local floor_score = clamp_score((tonumber(default_score) or 0) - math.max(0, tonumber(max_factor_penalty) or 0))
    local next_score = clamp_score(current_score - total_penalty)
    if next_score < floor_score then
        next_score = floor_score
    end

    return next_score, math.max(0, current_score - next_score)
end

function DeltaCalculator.Calculate(input)
    if type(input) ~= 'table' then
        return nil, 'input must be a table'
    end

    local plot = input.plot
    local crop = input.crop
    local quality = input.quality or {}
    local now_ts = normalize_unix_ts(input.now_ts) or os.time()

    if type(plot) ~= 'table' then
        return nil, 'input.plot must be a table'
    end

    if type(crop) ~= 'table' then
        return nil, 'input.crop must be a table'
    end

    if not is_non_empty_string(plot.plot_id) then
        return nil, 'plot.plot_id must be a non-empty string'
    end

    if not is_non_empty_string(crop.crop_type) then
        return nil, 'crop.crop_type must be a non-empty string'
    end

    local last_updated_ts = normalize_unix_ts(plot.last_updated_ts)
    if not last_updated_ts then
        return nil, 'plot.last_updated_ts must be a non-negative integer'
    end

    if now_ts <= last_updated_ts then
        return {
            plot = { changed = false },
            crop = { changed = false },
            quality = { changed = false },
            offline = {
                seconds = 0,
                capped = false,
                effective_end_ts = now_ts,
            },
        }, nil
    end

    local crop_config = get_crop_config(crop.crop_type)
    if not crop_config then
        return nil, ('crop_type "%s" is not configured'):format(crop.crop_type)
    end

    local stage, next_stage_ts, stage_advances, next_state, stage_err = compute_stage_progression(crop, crop_config, now_ts)
    if not stage then
        return nil, stage_err
    end

    local persistence_config = get_persistence_config()
    local cap_hours = math.max(0, tonumber(persistence_config.OfflineCapHours) or 6)
    local cap_seconds = math.floor(cap_hours * 3600)
    local offline_seconds = now_ts - last_updated_ts
    local effective_end_ts = now_ts
    local offline_capped = false

    if cap_seconds > 0 and offline_seconds > cap_seconds then
        effective_end_ts = last_updated_ts + cap_seconds
        offline_capped = true
    end

    local defaults = get_quality_defaults()
    local max_factor_penalty = math.max(0, tonumber(persistence_config.MaxFactorPenalty) or 30)
    local irrigation_default = clamp_score(defaults.irrigation or 70)
    local pest_default = clamp_score(defaults.pest_impact or 100)
    local irrigation_current = clamp_score(quality.irrigation or irrigation_default)
    local pest_current = clamp_score(quality.pest_impact or pest_default)

    local irrigation_next, irrigation_delta = compute_factor_penalty(
        irrigation_current,
        irrigation_default,
        persistence_config.IrrigationPenaltyPerHour,
        normalize_unix_ts(quality.next_irrigation_due_ts),
        last_updated_ts,
        effective_end_ts,
        max_factor_penalty
    )

    local pest_next, pest_delta = compute_factor_penalty(
        pest_current,
        pest_default,
        persistence_config.PestPenaltyPerHour,
        normalize_unix_ts(quality.pest_detected_ts),
        last_updated_ts,
        effective_end_ts,
        max_factor_penalty
    )

    local crop_changed = stage ~= (tonumber(crop.stage) or 0) or next_stage_ts ~= normalize_unix_ts(crop.next_stage_ts)
    local plot_changed = (type(next_state) == 'string' and next_state ~= '' and next_state ~= tostring(plot.state or ''))
        or next_stage_ts ~= normalize_unix_ts(plot.next_stage_ts)
    local quality_changed = irrigation_next ~= irrigation_current or pest_next ~= pest_current

    local capped_factors = {}
    if irrigation_delta > 0 and offline_capped then
        capped_factors[#capped_factors + 1] = 'irrigation'
    end
    if pest_delta > 0 and offline_capped then
        capped_factors[#capped_factors + 1] = 'pest_impact'
    end

    return {
        plot = {
            changed = plot_changed,
            state = next_state or tostring(plot.state or ''),
            next_stage_ts = next_stage_ts,
            previous_state = tostring(plot.state or ''),
        },
        crop = {
            changed = crop_changed,
            stage = stage,
            previous_stage = tonumber(crop.stage) or 0,
            next_stage_ts = next_stage_ts,
            stage_advances = stage_advances,
        },
        quality = {
            changed = quality_changed,
            irrigation = irrigation_next,
            irrigation_previous = irrigation_current,
            irrigation_delta = irrigation_delta,
            pest_impact = pest_next,
            pest_previous = pest_current,
            pest_delta = pest_delta,
            calculated_at = now_ts,
        },
        offline = {
            seconds = offline_seconds,
            capped = offline_capped,
            effective_end_ts = effective_end_ts,
            capped_factors = capped_factors,
        },
    }, nil
end

Sonar.Farm.Persistence.DeltaCalculator = DeltaCalculator
