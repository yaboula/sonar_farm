-- ============================================================
-- Farm Sonar — Persistence/offline delta specs (S11).
-- ============================================================
--
-- Plain Lua spec. Run with:
--     lua sonar_farm_core/tests/server/persistence_spec.lua
--
-- Covers:
--   1. 1h offline → no cap, one stage advance, small factor decay.
--   2. 6h offline → no cap flag, penalties reach the configured floor.
--   3. 24h offline → cap applies, same factor floor as the 6h max.
--   4. 7d offline → factor floor remains capped identically.
--   5. Boot dry-run previews changes without mutating state.
--   6. Boot apply mutates crop/plot/quality state and emits the event.
-- ============================================================

local NOW_TS = 1700000000

Config = {
    Farm = {
        Persistence = {
            OfflineCapHours = 6,
            MaxFactorPenalty = 30,
            IrrigationPenaltyPerHour = 5,
            PestPenaltyPerHour = 5,
        },
        Quality = {
            NeutralDefaults = {
                irrigation = 70,
                pest_impact = 100,
            },
        },
        Crops = {
            wheat = {
                stages = {
                    [0] = { duration_seconds = 3600, state = 'planted' },
                    [1] = { duration_seconds = 3600, state = 'germinating' },
                    [2] = { duration_seconds = 3600, state = 'growing' },
                    [3] = { duration_seconds = 3600, state = 'maturing' },
                    [4] = { duration_seconds = 0, state = 'harvest_ready' },
                },
            },
        },
    },
}

local emitted_events = {}

Sonar = { Farm = {} }
Sonar.Farm.Persistence = {
    EmitReconciled = function(payload)
        emitted_events[#emitted_events + 1] = {
            name = 'sonar:farm:persistence:reconciled',
            payload = payload,
        }
    end,
}

dofile('sonar_farm_core/server/persistence/delta_calculator.lua')
dofile('sonar_farm_core/server/persistence/boot_reconciler.lua')

local DeltaCalculator = Sonar.Farm.Persistence.DeltaCalculator
local BootReconciler = Sonar.Farm.Persistence.BootReconciler

local function build_input(offline_seconds)
    local last_updated_ts = NOW_TS - offline_seconds
    return {
        now_ts = NOW_TS,
        plot = {
            plot_id = 'plot_01',
            state = 'planted',
            last_updated_ts = last_updated_ts,
            next_stage_ts = last_updated_ts + 3600,
        },
        crop = {
            id = 1,
            plot_id = 'plot_01',
            crop_type = 'wheat',
            stage = 0,
            next_stage_ts = last_updated_ts + 3600,
        },
        quality = {
            irrigation = 70,
            pest_impact = 100,
            next_irrigation_due_ts = last_updated_ts + 1,
            pest_detected_ts = last_updated_ts + 1,
        },
    }
end

local plan_1h, err_1h = DeltaCalculator.Calculate(build_input(3600))
assert(plan_1h ~= nil, tostring(err_1h))
assert(plan_1h.offline.capped == false, '1h offline must not be capped')
assert(plan_1h.crop.stage == 1, ('expected stage 1 after 1h, got %s'):format(tostring(plan_1h.crop.stage)))
assert(plan_1h.crop.stage_advances == 1, '1h offline must advance exactly one stage')
assert(plan_1h.quality.irrigation == 65, ('expected irrigation 65 after 1h, got %s'):format(tostring(plan_1h.quality.irrigation)))
assert(plan_1h.quality.pest_impact == 95, ('expected pest_impact 95 after 1h, got %s'):format(tostring(plan_1h.quality.pest_impact)))

local plan_6h, err_6h = DeltaCalculator.Calculate(build_input(21600))
assert(plan_6h ~= nil, tostring(err_6h))
assert(plan_6h.offline.capped == false, 'exactly 6h offline must not set capped=true')
assert(plan_6h.quality.irrigation == 40, ('expected irrigation floor 40 after 6h, got %s'):format(tostring(plan_6h.quality.irrigation)))
assert(plan_6h.quality.pest_impact == 70, ('expected pest floor 70 after 6h, got %s'):format(tostring(plan_6h.quality.pest_impact)))

local plan_24h, err_24h = DeltaCalculator.Calculate(build_input(86400))
assert(plan_24h ~= nil, tostring(err_24h))
assert(plan_24h.offline.capped == true, '24h offline must set capped=true')
assert(plan_24h.quality.irrigation == 40, '24h offline irrigation must remain at cap floor 40')
assert(plan_24h.quality.pest_impact == 70, '24h offline pest must remain at cap floor 70')

local plan_7d, err_7d = DeltaCalculator.Calculate(build_input(604800))
assert(plan_7d ~= nil, tostring(err_7d))
assert(plan_7d.offline.capped == true, '7d offline must set capped=true')
assert(plan_7d.quality.irrigation == plan_24h.quality.irrigation, '7d cap must match 24h capped irrigation')
assert(plan_7d.quality.pest_impact == plan_24h.quality.pest_impact, '7d cap must match 24h capped pest impact')

local active_rows = {
    {
        plot_id = 'plot_01',
        state = 'planted',
        last_updated_ts = NOW_TS - 86400,
        plot_next_stage_ts = NOW_TS - 82800,
        crop_id = 1,
        crop_type = 'wheat',
        stage = 0,
        next_stage_ts = NOW_TS - 82800,
        irrigation = 70,
        pest_impact = 100,
        next_irrigation_due_ts = NOW_TS - 86399,
        pest_detected_ts = NOW_TS - 86399,
        calculated_at = NOW_TS - 86400,
    },
}

local plot_row = {
    plot_id = 'plot_01',
    state = 'planted',
    next_stage_ts = NOW_TS - 82800,
    last_updated_ts = NOW_TS - 86400,
}

local crop_row = {
    plot_id = 'plot_01',
    stage = 0,
    next_stage_ts = NOW_TS - 82800,
}

local quality_row = {
    plot_id = 'plot_01',
    irrigation = 70,
    pest_impact = 100,
    calculated_at = NOW_TS - 86400,
}

Sonar.Farm.DB = {
    rows = function(query)
        if query:find('FROM `sonar_farm_plots` p', 1, true) then
            return active_rows
        end
        return {}
    end,
    transaction = function(queries)
        for index = 1, #queries do
            local item = queries[index]
            if item.query:find('UPDATE `sonar_farm_crops`', 1, true) then
                crop_row.stage = item.values[1]
                crop_row.next_stage_ts = item.values[2]
            elseif item.query:find('INSERT INTO `sonar_farm_quality_tracking`', 1, true) then
                quality_row.irrigation = item.values[2]
                quality_row.pest_impact = item.values[3]
                quality_row.calculated_at = item.values[4]
            end
        end
        return true
    end,
    execute = function(query, values)
        if query:find('UPDATE `sonar_farm_plots` SET `last_updated_ts`', 1, true) then
            plot_row.last_updated_ts = values[1]
        end
        return true
    end,
}

Sonar.Farm.PlotService = {
    UpdatePlotState = function(plot_id, patch)
        assert(plot_id == 'plot_01', 'unexpected plot id in UpdatePlotState')
        for key, value in pairs(patch) do
            plot_row[key] = value
        end
        plot_row.last_updated_ts = NOW_TS
        return true, plot_row
    end,
}

local dryrun_result = BootReconciler.Run({ dry_run = true, now_ts = NOW_TS })
assert(dryrun_result.reconciled == 1, ('dry run expected 1 preview, got %s'):format(tostring(dryrun_result.reconciled)))
assert(dryrun_result.capped == 1, 'dry run must report one capped plot')
assert(#dryrun_result.previews == 1, 'dry run must include one preview row')
assert(crop_row.stage == 0, 'dry run must not mutate crop stage')
assert(quality_row.irrigation == 70, 'dry run must not mutate quality rows')
assert(plot_row.state == 'planted', 'dry run must not mutate plot state')

local apply_result = BootReconciler.Run({ dry_run = false, now_ts = NOW_TS })
assert(apply_result.reconciled == 1, ('apply expected 1 reconciled row, got %s'):format(tostring(apply_result.reconciled)))
assert(crop_row.stage == 4, ('apply must advance crop to stage 4, got %s'):format(tostring(crop_row.stage)))
assert(plot_row.state == 'harvest_ready', ('plot state must become harvest_ready, got %s'):format(tostring(plot_row.state)))
assert(plot_row.last_updated_ts == NOW_TS, 'plot last_updated_ts must be refreshed on apply')
assert(quality_row.irrigation == 40, ('quality irrigation must be capped to 40, got %s'):format(tostring(quality_row.irrigation)))
assert(quality_row.pest_impact == 70, ('quality pest_impact must be capped to 70, got %s'):format(tostring(quality_row.pest_impact)))
assert(#emitted_events >= 1, 'expected reconciliation event to be emitted')
assert(emitted_events[#emitted_events].name == 'sonar:farm:persistence:reconciled', 'unexpected event emitted')

print('persistence_spec.lua: OK (6 cases)')
