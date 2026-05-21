Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}
Sonar.Farm.Quality = Sonar.Farm.Quality or {}
Sonar.Farm.Quality.Factors = Sonar.Farm.Quality.Factors or {}

local HarvestTimingFactor = {}
local FACTOR_NAME = 'harvest_timing'
local DEFAULT_SCORE = 100

local function configured_decay()
    local quality_config = Config and Config.Farm and Config.Farm.Quality or nil
    return quality_config and quality_config.HarvestTimingDecayPerHour or 5
end

local function clamp_score(value)
    local score = tonumber(value) or DEFAULT_SCORE
    if score < 0 then
        return 0
    end
    if score > 100 then
        return 100
    end
    return math.floor(score + 0.5)
end

local function get_db()
    return Sonar and Sonar.Farm and Sonar.Farm.DB or nil
end

function HarvestTimingFactor:calculate(harvest_deadline_ts, harvested_ts)
    local deadline = tonumber(harvest_deadline_ts) or 0
    local harvested_at = tonumber(harvested_ts) or os.time()
    if deadline <= 0 or harvested_at <= deadline then
        return DEFAULT_SCORE
    end

    local late_hours = (harvested_at - deadline) / 3600
    return clamp_score(DEFAULT_SCORE - (late_hours * configured_decay()))
end

function HarvestTimingFactor:track(plot_id, event, data)
    local db = get_db()
    if not db then
        return false, 'Sonar.Farm.DB is unavailable'
    end

    local score = clamp_score(data and (data.harvest_timing or data.score))
    db.execute([[
        INSERT INTO `sonar_farm_quality_tracking` (`plot_id`, `harvest_timing`, `calculated_at`)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE
            `harvest_timing` = VALUES(`harvest_timing`),
            `calculated_at` = VALUES(`calculated_at`)
    ]], { plot_id, score, os.time() })

    TriggerEvent('sonar:farm:quality:tracked', {
        plot_id = plot_id,
        factor = FACTOR_NAME,
        event = event,
        score = score,
        tracked_at = os.time(),
    })

    return true, score
end

function HarvestTimingFactor:get(plot_id)
    local db = get_db()
    if not db then
        return DEFAULT_SCORE
    end

    local row = db.row('SELECT `harvest_timing` FROM `sonar_farm_quality_tracking` WHERE `plot_id` = ? LIMIT 1', { plot_id })
    if not row then
        return DEFAULT_SCORE
    end

    return clamp_score(row.harvest_timing)
end

Sonar.Farm.Quality.Factors.HarvestTiming = HarvestTimingFactor
