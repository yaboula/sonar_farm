Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}
Sonar.Farm.Quality = Sonar.Farm.Quality or {}

local Quality = Sonar.Farm.Quality

function Quality.Boot()
    local required_factors = {
        'Soil',
        'Irrigation',
        'Pest',
        'Weather',
        'Seed',
        'Fertilization',
        'HarvestTiming',
    }

    Quality.Factors = Quality.Factors or {}

    for _, factor_name in ipairs(required_factors) do
        local factor = Quality.Factors[factor_name]
        if type(factor) ~= 'table' or type(factor.get) ~= 'function' or type(factor.track) ~= 'function' then
            print(('[sonar_farm_core][quality][ERROR] factor %s is unavailable'):format(factor_name))
            return false
        end
    end

    if type(Quality.Calculate) ~= 'function' then
        print('[sonar_farm_core][quality][ERROR] calculator is unavailable')
        return false
    end

    print('[sonar_farm_core][quality] ready')
    return true
end
