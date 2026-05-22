Config = {
    Farm = {
        Quality = {
            NeutralDefaults = {
                irrigation = 70,
            },
        },
        Irrigation = {
            optimal_ceiling = 90,
            overwater_floor = 50,
            overwater_threshold = 3,
            score_gain_per_water = 10,
            score_loss_overwater = 15,
        },
    },
}

local quality_rows = {
    plot_alpha = { irrigation = 70, next_irrigation_due_ts = nil },
    plot_beta = { irrigation = 70, next_irrigation_due_ts = nil },
    plot_gamma = { irrigation = 85, next_irrigation_due_ts = nil },
}

local crop_rows = {
    plot_alpha = { next_stage_ts = 1000 },
    plot_beta = { next_stage_ts = 2000 },
    plot_gamma = { next_stage_ts = 3000 },
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
        if query:find('SELECT `irrigation`', 1, true) then
            local row = quality_rows[plot_id]
            return row and { irrigation = row.irrigation } or nil
        end
        if query:find('SELECT `next_stage_ts`', 1, true) then
            local row = crop_rows[plot_id]
            return row and { next_stage_ts = row.next_stage_ts } or nil
        end
        return nil
    end,
    execute = function(query, params)
        local plot_id = params[1]
        if query:find('INSERT INTO `sonar_farm_quality_tracking`', 1, true) then
            quality_rows[plot_id] = quality_rows[plot_id] or {}
            quality_rows[plot_id].irrigation = params[2]
            return true
        end
        if query:find('UPDATE `sonar_farm_quality_tracking` SET `next_irrigation_due_ts`', 1, true) then
            quality_rows[params[2]] = quality_rows[params[2]] or {}
            quality_rows[params[2]].next_irrigation_due_ts = params[1]
            return true
        end
        return true
    end,
}

dofile('sonar_farm_core/server/quality/factors/irrigation.lua')

local IrrigationFactor = Sonar.Farm.Quality.Factors.Irrigation

local ok, score, err = IrrigationFactor.TrackWatering('plot_alpha', 1, 1)
assert(ok == true and err == nil, 'expected first watering to succeed')
assert(score == 80, ('expected first watering score 80, got %s'):format(tostring(score)))
assert(quality_rows.plot_alpha.irrigation == 80, 'expected persisted irrigation score 80')
assert(quality_rows.plot_alpha.next_irrigation_due_ts == 1000, 'expected next irrigation due ts to mirror next stage ts')

ok, score = IrrigationFactor.TrackWatering('plot_alpha', 1, 1)
assert(ok == true, 'expected second watering to succeed')
assert(score == 90, ('expected second watering score 90, got %s'):format(tostring(score)))

ok, score = IrrigationFactor.TrackWatering('plot_alpha', 1, 1)
assert(ok == true, 'expected third watering to succeed')
assert(score == 75, ('expected overwater penalty to 75, got %s'):format(tostring(score)))

ok, score = IrrigationFactor.TrackWatering('plot_beta', 1, 2)
assert(ok == true and score == 80, 'expected fresh plot stage cache to start at 80')
TriggerEvent('sonar:farm:plot:stage_advanced', { plot_id = 'plot_beta' })
ok, score = IrrigationFactor.TrackWatering('plot_beta', 1, 3)
assert(ok == true and score == 90, 'expected cache reset on stage advance before overwater threshold')

ok, score = IrrigationFactor.TrackWatering('plot_gamma', 1, 0)
assert(ok == true and score == 90, 'expected score clamping at irrigation optimal ceiling')

local watered_event_count = 0
for index = 1, #emitted_events do
    if emitted_events[index].name == 'sonar:farm:plot:watered' then
        watered_event_count = watered_event_count + 1
    end
end
assert(watered_event_count == 6, ('expected 6 watered events, got %d'):format(watered_event_count))

print('irrigation_spec.lua: OK (5 cases)')
