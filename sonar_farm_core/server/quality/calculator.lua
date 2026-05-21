Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}
Sonar.Farm.Quality = Sonar.Farm.Quality or {}

local Quality = Sonar.Farm.Quality

local FACTOR_KEYS = {
    { output = 'soil_score', weight = 'soil', factor = 'Soil' },
    { output = 'irrigation', weight = 'irrigation', factor = 'Irrigation' },
    { output = 'pest_impact', weight = 'pest_impact', factor = 'Pest' },
    { output = 'weather_match', weight = 'weather_match', factor = 'Weather' },
    { output = 'seed_quality', weight = 'seed_quality', factor = 'Seed' },
    { output = 'fertilization', weight = 'fertilization', factor = 'Fertilization' },
    { output = 'harvest_timing', weight = 'harvest_timing', factor = 'HarvestTiming' },
}

local function get_quality_config()
    return Config and Config.Farm and Config.Farm.Quality or {}
end

local function get_weights()
    local quality_config = get_quality_config()
    return quality_config.weights or quality_config.Weights or {}
end

local function clamp_score(value)
    local score = tonumber(value) or 0
    if score < 0 then
        return 0
    end
    if score > 100 then
        return 100
    end
    return score
end

local function grade_for_score(score)
    local grades = get_quality_config().Grades or { S = 95, A = 80, B = 60, C = 40 }
    if score >= grades.S then
        return 'S'
    end
    if score >= grades.A then
        return 'A'
    end
    if score >= grades.B then
        return 'B'
    end
    if score >= grades.C then
        return 'C'
    end
    return 'D'
end

local function read_factor(plot_id, factor_name)
    local factors = Quality.Factors or {}
    local factor = factors[factor_name]
    if not factor or type(factor.get) ~= 'function' then
        return 0
    end

    return clamp_score(factor:get(plot_id))
end

function Quality.Calculate(plot_id, harvest_timing_score)
    local weights = get_weights()
    local factors = {}
    local numerator = 0
    local denominator = 0

    for _, factor_spec in ipairs(FACTOR_KEYS) do
        local factor_value
        if factor_spec.output == 'harvest_timing' and harvest_timing_score ~= nil then
            factor_value = clamp_score(harvest_timing_score)
        else
            factor_value = read_factor(plot_id, factor_spec.factor)
        end

        local weight = tonumber(weights[factor_spec.weight]) or 1.0
        factors[factor_spec.output] = factor_value
        numerator = numerator + (factor_value * weight)
        denominator = denominator + weight
    end

    local score = 0
    if denominator > 0 then
        score = math.floor((numerator / denominator) + 0.5)
    end

    return {
        score = score,
        grade = grade_for_score(score),
        factors = factors,
    }
end
