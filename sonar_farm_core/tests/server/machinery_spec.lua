Config = {
    Farm = {
        Machinery = {
            DefaultDurability = 100,
            CriticalBreakThreshold = 30,
            Usage = {
                mode = 'reported_seconds',
                seconds_per_durability = 60,
                min_report_seconds = 60,
                max_report_seconds = 900,
            },
            Breakdown = {
                critical_chance_pct = 100,
            },
            Repair = {
                item_name = 'sonar_machinery_kit',
                restore_durability = 100,
            },
            Models = {
                tractor = {
                    wear_multiplier = 1.0,
                },
            },
        },
    },
}

Sonar = { Farm = {} }

local db_state = {}
local triggered_events = {}

function TriggerEvent(event_name, payload)
    triggered_events[#triggered_events + 1] = {
        event_name = event_name,
        payload = payload,
    }
end

Sonar.Farm.DB = {
    row = function(_query, params)
        local row = db_state[params[1]]
        if not row then
            return nil
        end

        return {
            plate = row.plate,
            model = row.model,
            durability = row.durability,
            is_broken = row.is_broken,
        }
    end,
    execute = function(query, params)
        if query:find('INSERT INTO `sonar_farm_machinery_state`', 1, true) then
            db_state[params[1]] = {
                plate = params[1],
                model = params[2],
                durability = params[3],
                is_broken = params[4],
            }
            return true
        end

        if query:find('UPDATE `sonar_farm_machinery_state`', 1, true) then
            local plate = params[4]
            local row = db_state[plate]
            if row then
                row.durability = params[1]
                row.is_broken = params[2]
                if params[3] ~= nil then
                    row.model = params[3]
                end
            end
            return true
        end

        return true
    end,
}

dofile('sonar_farm_core/server/machinery/machinery_service.lua')

local MachineryService = Sonar.Farm.MachineryService

math.randomseed(1)
local ok, state, err = MachineryService.RecordUsage('farm01', 60, 'tractor')
assert(ok == true and err == nil, 'expected first usage report to create machinery state')
assert(state.plate == 'FARM01', 'expected uppercase normalized plate')
assert(state.model == 'tractor', 'expected stored tractor model')
assert(state.durability == 99, ('expected durability 99, got %s'):format(tostring(state.durability)))
assert(state.is_broken == false, 'expected first usage not to break the vehicle')

local fetched_state, fetch_err = MachineryService.GetState('farm01')
assert(fetch_err == nil and fetched_state ~= nil, 'expected GetState to return the stored row')
assert(fetched_state.durability == 99, 'expected persisted durability to match the usage result')

ok, state, err = MachineryService.RecordUsage('farm01', 4200)
assert(ok == false, 'expected out-of-range usage amount to fail')
assert(err == 'invalid_usage_amount', ('expected invalid_usage_amount, got %s'):format(tostring(err)))

ok, state, err = MachineryService.RecordUsage('farm01', 900)
assert(ok == true and err == nil, 'expected large valid usage report to succeed')
assert(state.durability == 84, ('expected durability 84 after 15 points of wear, got %s'):format(tostring(state.durability)))

ok, state, err = MachineryService.RecordUsage('farm01', 900)
assert(ok == true and err == nil, 'expected second large usage report to succeed')
assert(state.durability == 69, ('expected durability 69 after repeated wear, got %s'):format(tostring(state.durability)))

ok, state, err = MachineryService.RecordUsage('farm01', 900)
assert(ok == true and err == nil, 'expected third large usage report to succeed')
assert(state.durability == 54, ('expected durability 54 after repeated wear, got %s'):format(tostring(state.durability)))

ok, state, err = MachineryService.RecordUsage('farm01', 900)
assert(ok == true and err == nil, 'expected fourth large usage report to succeed')
assert(state.durability == 39, ('expected durability 39 after repeated wear, got %s'):format(tostring(state.durability)))
assert(state.is_broken == false, 'expected durability above threshold to remain operational')

ok, state, err = MachineryService.RecordUsage('farm01', 900)
assert(ok == true and err == nil, 'expected threshold-crossing usage report to succeed')
assert(state.durability == 24, ('expected durability 24 after threshold-crossing wear, got %s'):format(tostring(state.durability)))
assert(state.is_broken == true, 'expected critical durability to mark machinery broken')
assert(triggered_events[#triggered_events].event_name == 'sonar:farm:machinery:broke_down', 'expected broke_down event to be emitted')
assert(triggered_events[#triggered_events].payload.plate == 'FARM01', 'expected broke_down payload to include normalized plate')

ok, state, err = MachineryService.Repair('farm01')
assert(ok == true and err == nil, 'expected repair to succeed for existing machinery')
assert(state.durability == 100, 'expected repair to restore durability to 100')
assert(state.is_broken == false, 'expected repair to clear broken state')
assert(triggered_events[#triggered_events].event_name == 'sonar:farm:machinery:repaired', 'expected repaired event to be emitted')

local repaired_state = assert(MachineryService.GetState('farm01'))
assert(repaired_state.durability == 100, 'expected persisted repair durability to be 100')
assert(repaired_state.is_broken == false, 'expected persisted repair state to be operational')

print('machinery_spec.lua: OK (usage, threshold breakdown, repair)')
