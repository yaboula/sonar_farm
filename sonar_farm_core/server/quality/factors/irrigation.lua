Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}
Sonar.Farm.Quality = Sonar.Farm.Quality or {}
Sonar.Farm.Quality.Factors = Sonar.Farm.Quality.Factors or {}

local IrrigationFactor = {}
local FACTOR_NAME = 'irrigation'
local DEFAULT_SCORE = 70

local function configured_default()
    local quality_config = Config and Config.Farm and Config.Farm.Quality or nil
    local defaults = quality_config and quality_config.NeutralDefaults or nil
    return defaults and defaults.irrigation or DEFAULT_SCORE
end

local function clamp_score(value)
    local score = tonumber(value) or configured_default()
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

function IrrigationFactor:track(plot_id, event, data)
    local db = get_db()
    if not db then
        return false, 'Sonar.Farm.DB is unavailable'
    end

    local score = clamp_score(data and (data.irrigation or data.score))
    db.execute([[
        INSERT INTO `sonar_farm_quality_tracking` (`plot_id`, `irrigation`, `calculated_at`)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE
            `irrigation` = VALUES(`irrigation`),
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

function IrrigationFactor:get(plot_id)
    local db = get_db()
    if not db then
        return configured_default()
    end

    local row = db.row('SELECT `irrigation` FROM `sonar_farm_quality_tracking` WHERE `plot_id` = ? LIMIT 1', { plot_id })
    if not row then
        return configured_default()
    end

    return clamp_score(row.irrigation)
end

Sonar.Farm.Quality.Factors.Irrigation = IrrigationFactor
