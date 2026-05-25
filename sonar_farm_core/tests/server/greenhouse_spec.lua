Config = {
    Farm = {
        Greenhouse = {
            PlotTypes = {
                greenhouse = true,
            },
            WeatherNeutralScore = 70,
            Maintenance = {
                CostPerCycle = 25.0,
                Account = 'bank',
                Reason = 'greenhouse_maintenance',
            },
        },
        Quality = {
            NeutralDefaults = {
                irrigation = 70,
                pest_impact = 100,
                weather_match = 70,
                seed_quality = 70,
                fertilization = 70,
            },
        },
        Crops = {
            tomato = {
                plot_types_allowed = { 'horticultural', 'greenhouse' },
                stages = {
                    [0] = { duration_seconds = 0, state = 'planted' },
                    [1] = { duration_seconds = 0, state = 'germinating' },
                    [2] = { duration_seconds = 0, state = 'growing' },
                    [3] = { duration_seconds = 0, state = 'maturing' },
                    [4] = { duration_seconds = 0, state = 'harvest_ready' },
                },
                harvest_window_seconds = 10,
                harvest_yield_g = 1800,
                fallow_cooldown_seconds = 1800,
                seed_quality_default = 72,
            },
        },
    },
}

Sonar = { Farm = {} }

local plots = {
    mlo_greenhouse_01 = {
        plot_id = 'mlo_greenhouse_01',
        plot_type = 'greenhouse',
        state = 'fallow',
        soil_score = 75,
    },
    mlo_field_extensive_01 = {
        plot_id = 'mlo_field_extensive_01',
        plot_type = 'extensive',
        state = 'fallow',
        soil_score = 60,
    },
}

local crops = {}
local quality_rows = {}
local next_crop_id = 1

Sonar.Farm.PlotService = {
    GetPlot = function(plot_id)
        return plots[plot_id]
    end,
    UpdatePlotState = function(plot_id, patch)
        local plot = plots[plot_id]
        if not plot then
            return false, 'missing plot'
        end
        for key, value in pairs(patch) do
            plot[key] = value
        end
        return true, plot
    end,
}

Sonar.Farm.DB = {
    row = function(query, params)
        local plot_id = params[1]
        if query:find('FROM `sonar_farm_crops`', 1, true) then
            return crops[plot_id]
        end
        if query:find('weather_match', 1, true) then
            return quality_rows[plot_id]
        end
        return nil
    end,
    execute = function(query, params)
        if query:find('INSERT INTO `sonar_farm_quality_tracking`', 1, true) then
            quality_rows[params[1]] = {
                weather_match = params[2],
            }
        end
        return true
    end,
    transaction = function(queries)
        for _, item in ipairs(queries) do
            if item.query:find('INSERT INTO `sonar_farm_crops`', 1, true) then
                local plot_id = item.values[1]
                crops[plot_id] = {
                    id = next_crop_id,
                    plot_id = plot_id,
                    crop_type = item.values[2],
                    player_cid = item.values[3],
                    stage = 0,
                    planted_ts = item.values[4],
                    next_stage_ts = item.values[5],
                    harvest_deadline_ts = item.values[6],
                }
                next_crop_id = next_crop_id + 1
            elseif item.query:find('INSERT INTO `sonar_farm_quality_tracking`', 1, true) then
                quality_rows[item.values[1]] = {
                    weather_match = item.values[5],
                }
            end
        end
        return true
    end,
}

dofile('sonar_farm_core/server/lifecycle/crop_lifecycle_service.lua')
dofile('sonar_farm_core/server/quality/factors/weather.lua')

local CropLifecycle = Sonar.Farm.CropLifecycle
local WeatherFactor = Sonar.Farm.Quality.Factors.Weather

local plant_policy, policy_err = CropLifecycle.GetPlantPolicy('mlo_greenhouse_01', 'tomato')
assert(plant_policy ~= nil, tostring(policy_err))
assert(plant_policy.greenhouse == true, 'greenhouse policy must mark greenhouse=true')
assert(plant_policy.weather_override == 70, 'greenhouse weather override must stay neutral at 70')
assert(plant_policy.maintenance_cost == 25.0, 'greenhouse maintenance cost must come from config')
assert(plant_policy.maintenance_account == 'bank', 'greenhouse maintenance account must come from config')

local ok, crop_or_error = CropLifecycle.Plant('mlo_greenhouse_01', 'citizen-7', 'tomato')
assert(ok == true, tostring(crop_or_error))
assert(crop_or_error.plot_id == 'mlo_greenhouse_01', 'greenhouse planting must create an active crop')
assert(plots.mlo_greenhouse_01.state == 'planted', 'greenhouse plot must transition to planted')
assert(quality_rows.mlo_greenhouse_01.weather_match == 70, 'greenhouse quality defaults must seed weather_match as neutral')

local denied_policy, denied_err = CropLifecycle.GetPlantPolicy('mlo_field_extensive_01', 'tomato')
assert(denied_policy == nil, 'tomato must reject extensive plots')
assert(type(denied_err) == 'string' and denied_err:find('cannot be planted on plot_type', 1, true), 'expected plot_type rejection for extensive plot')

local tracked_ok, tracked_score = WeatherFactor:track('mlo_greenhouse_01', 'external_weather', { score = 10 })
assert(tracked_ok == true, 'greenhouse weather track must succeed')
assert(tracked_score == 70, 'greenhouse weather track must clamp to neutral override')
assert(WeatherFactor:get('mlo_greenhouse_01') == 70, 'greenhouse weather get must always return neutral override')

print('greenhouse_spec.lua: OK (policy + weather override)')
