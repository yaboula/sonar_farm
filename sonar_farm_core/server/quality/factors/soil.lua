Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}
Sonar.Farm.Quality = Sonar.Farm.Quality or {}
Sonar.Farm.Quality.Factors = Sonar.Farm.Quality.Factors or {}

local SoilFactor = {}
local FACTOR_NAME = 'soil_score'
local DEFAULT_SCORE = 50

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

function SoilFactor:track(plot_id, event, data)
    local db = get_db()
    if not db then
        return false, 'Sonar.Farm.DB is unavailable'
    end

    local score = clamp_score(data and (data.soil_score or data.score))
    db.execute([[
        INSERT INTO `sonar_farm_quality_tracking` (`plot_id`, `soil_score`, `calculated_at`)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE
            `soil_score` = VALUES(`soil_score`),
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

function SoilFactor:get(plot_id)
    local db = get_db()
    if not db then
        return DEFAULT_SCORE
    end

    local row = db.row('SELECT `soil_score` FROM `sonar_farm_quality_tracking` WHERE `plot_id` = ? LIMIT 1', { plot_id })
    if not row then
        return DEFAULT_SCORE
    end

    return clamp_score(row.soil_score)
end

Sonar.Farm.Quality.Factors.Soil = SoilFactor
