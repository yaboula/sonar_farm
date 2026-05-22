Config = {
    Farm = {
        Quality = {
            NeutralDefaults = {
                fertilization = 70,
            },
        },
        Crops = {
            wheat = {
                fertilization = {
                    optimal_items = { 'sonar_fertilizer_npk', 'sonar_fertilizer_n' },
                    ceiling = 90,
                    wrong_penalty = -5,
                    overfertilize_floor = 40,
                    max_applications_per_stage = 1,
                    score_gain_correct = 15,
                },
            },
            corn = {
                fertilization = {
                    optimal_items = { 'sonar_fertilizer_npk', 'sonar_fertilizer_k' },
                    ceiling = 90,
                    wrong_penalty = -5,
                    overfertilize_floor = 40,
                    max_applications_per_stage = 1,
                    score_gain_correct = 15,
                },
            },
        },
    },
}

local quality_rows = {
    plot_wheat = { fertilization = 70 },
    plot_corn = { fertilization = 70 },
    plot_cap = { fertilization = 85 },
}

local event_handlers = {}
local emitted_events = {}

Sonar = { Farm = {} }

function AddEventHandler(event_name, handler)
    event_handlers[event_name] = event_handlers[event_name] or {}
    event_handlers[event_name][#event_handlers[event_name] + 1] = handler
end

function TriggerEvent(event_name, payload)
    emitted_events[#emitted_events + 1] = { name = event_name, payload = payload }
    local handlers = event_handlers[event_name] or {}
    for index = 1, #handlers do
        handlers[index](payload)
    end
end

Sonar.Farm.DB = {
    row = function(query, params)
        local plot_id = params[1]
        if query:find('SELECT `fertilization`', 1, true) then
            local row = quality_rows[plot_id]
            return row and { fertilization = row.fertilization } or nil
        end
        return nil
    end,
    execute = function(query, params)
        local plot_id = params[1]
        if query:find('INSERT INTO `sonar_farm_quality_tracking`', 1, true) then
            quality_rows[plot_id] = quality_rows[plot_id] or {}
            quality_rows[plot_id].fertilization = params[2]
            return true
        end
        return true
    end,
}

dofile('sonar_farm_core/server/quality/factors/fertilization.lua')

local FertilizationFactor = Sonar.Farm.Quality.Factors.Fertilization

local ok, score, err = FertilizationFactor.TrackApplication('plot_wheat', 'sonar_fertilizer_npk', 'wheat', 1)
assert(ok == true and err == nil, 'expected correct fertilizer on wheat to succeed')
assert(score == 85, ('expected wheat correct fertilizer score 85, got %s'):format(tostring(score)))

ok, score = FertilizationFactor.TrackApplication('plot_corn', 'sonar_fertilizer_n', 'corn', 1)
assert(ok == true, 'expected wrong fertilizer call to succeed')
assert(score == 65, ('expected wrong fertilizer penalty to 65, got %s'):format(tostring(score)))

ok, score = FertilizationFactor.TrackApplication('plot_wheat', 'sonar_fertilizer_n', 'wheat', 1)
assert(ok == true, 'expected second same-stage fertilization to succeed')
assert(score == 40, ('expected overfertilize floor 40, got %s'):format(tostring(score)))

TriggerEvent('sonar:farm:plot:stage_advanced', { plot_id = 'plot_wheat' })
ok, score = FertilizationFactor.TrackApplication('plot_wheat', 'sonar_fertilizer_n', 'wheat', 2)
assert(ok == true, 'expected stage reset for wheat fertilization cache')
assert(score == 55, ('expected post-reset wheat score 55, got %s'):format(tostring(score)))

ok, score = FertilizationFactor.TrackApplication('plot_cap', 'sonar_fertilizer_npk', 'corn', 0)
assert(ok == true and score == 90, 'expected fertilization score to clamp at ceiling 90')

local fertilized_event_count = 0
for index = 1, #emitted_events do
    if emitted_events[index].name == 'sonar:farm:plot:fertilized' then
        fertilized_event_count = fertilized_event_count + 1
    end
end
assert(fertilized_event_count == 5, ('expected 5 fertilized events, got %d'):format(fertilized_event_count))

print('fertilization_spec.lua: OK (5 cases)')
