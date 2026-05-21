-- ============================================================
-- Farm Sonar — Crop lifecycle FSM specs (S6).
-- ============================================================
--
-- Plain Lua spec (no busted/luaunit). Run with:
--     lua sonar_farm_core/tests/server/lifecycle_spec.lua
--
-- Mocks the bare minimum surface that crop_lifecycle_service.lua
-- needs: PlotService.GetPlot/UpdatePlotState, the DB row/execute/
-- transaction trio, the Quality.HarvestTiming factor, and the
-- PhysicalItem factory. We exercise the full happy path plus
-- the slice-specific DoD branches required by B1 §6.
--
-- Coverage matrix (6 cases):
--   1. Plant on `fallow` extensive plot succeeds.
--   2. Second plant on same plot rejects ("not fallow").
--   3. Harvest on a non-ready plot (stage 0) rejects.
--   4. AdvanceStage ×4 walks stages 1 → 2 → 3 → 4 and flips the
--      plot to `harvest_ready`.
--   5. Harvest on a `harvest_ready` plot produces a batch_id,
--      deletes the active crop + quality row, and transitions
--      the plot to `cooldown`.
--   6. Plant attempt during cooldown (immediately after harvest)
--      rejects with the cooldown still active.
-- ============================================================

Config = {
    Farm = {
        Crops = {
            wheat = {
                plot_types_allowed = { 'extensive' },
                stages = {
                    [0] = { duration_seconds = 0, state = 'planted' },
                    [1] = { duration_seconds = 0, state = 'germinating' },
                    [2] = { duration_seconds = 0, state = 'growing' },
                    [3] = { duration_seconds = 0, state = 'maturing' },
                    [4] = { duration_seconds = 0, state = 'harvest_ready' },
                },
                harvest_window_seconds = 10,
                harvest_yield_g = 2500,
                fallow_cooldown_seconds = 3600,
                seed_quality_default = 70,
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
    },
}

Sonar = { Farm = {} }

local plot = {
    plot_id = 'mlo_field_extensive_01',
    plot_type = 'extensive',
    state = 'fallow',
    soil_score = 50,
    planted_ts = nil,
    next_stage_ts = nil,
}

local crops = {}
local quality_rows = {}
local next_crop_id = 1

Sonar.Farm.PlotService = {
    GetPlot = function(plot_id)
        if plot.plot_id ~= plot_id then
            return nil
        end
        return plot
    end,
    UpdatePlotState = function(plot_id, patch)
        if plot.plot_id ~= plot_id then
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
        return nil
    end,
    execute = function(query, params)
        if query:find('UPDATE `sonar_farm_crops`', 1, true) then
            local stage = params[1]
            local next_stage_ts = params[2]
            local plot_id = params[3]
            crops[plot_id].stage = stage
            crops[plot_id].next_stage_ts = next_stage_ts
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
                quality_rows[item.values[1]] = true
            elseif item.query:find('DELETE FROM `sonar_farm_quality_tracking`', 1, true) then
                quality_rows[item.values[1]] = nil
            elseif item.query:find('DELETE FROM `sonar_farm_crops`', 1, true) then
                crops[item.values[1]] = nil
            end
        end
        return true
    end,
}

Sonar.Farm.Quality = {
    Factors = {
        HarvestTiming = {
            calculate = function()
                return 100
            end,
            track = function()
                return true
            end,
        },
    },
    Calculate = function()
        return { score = 76, grade = 'B', factors = {} }
    end,
}

Sonar.Farm.PhysicalItem = {
    CreateBatch = function(params)
        assert(params.lineage_chain ~= nil, 'lineage_chain must be provided')
        return 'sf-a1b2c3d4', {
            batch_id = 'sf-a1b2c3d4',
            lineage_chain = params.lineage_chain,
        }
    end,
    BuildBatchInsertQuery = function(params, batch_id, harvested_ts)
        return {
            query = 'INSERT INTO `sonar_farm_batches` (`batch_id`) VALUES (?)',
            values = { batch_id, params.plot_id, harvested_ts },
        }
    end,
    EmitCreated = function()
        return true
    end,
}

dofile('sonar_farm_core/server/lifecycle/crop_lifecycle_service.lua')

local CropLifecycle = Sonar.Farm.CropLifecycle
local PLOT_ID = 'mlo_field_extensive_01'

-- ------------------------------------------------------------
-- Case 1: Plant wheat on a fallow extensive plot.
-- ------------------------------------------------------------
local ok, result = CropLifecycle.Plant(PLOT_ID, 'citizen-1', 'wheat')
assert(ok, tostring(result))
assert(result.stage == 0, 'expected planted crop stage 0')
assert(plot.state == 'planted', 'expected plot state planted')
assert(crops[PLOT_ID] ~= nil, 'expected sonar_farm_crops row inserted')
assert(quality_rows[PLOT_ID] == true, 'expected sonar_farm_quality_tracking row inserted')

-- ------------------------------------------------------------
-- Case 2: Second plant on same plot rejects ("not fallow").
-- ------------------------------------------------------------
local second_ok, second_err = CropLifecycle.Plant(PLOT_ID, 'citizen-1', 'wheat')
assert(second_ok == false, 'second simultaneous plant attempt must fail')
assert(
    type(second_err) == 'string' and second_err:find('not fallow', 1, true),
    ('expected "not fallow" error, got %s'):format(tostring(second_err))
)

-- ------------------------------------------------------------
-- Case 3: Harvest before stage 4 rejects ("not harvest-ready").
-- ------------------------------------------------------------
local early_ok, early_err = CropLifecycle.Harvest(PLOT_ID, 'citizen-1')
assert(early_ok == false, 'harvest before stage 4 must fail')
assert(
    type(early_err) == 'string' and early_err:find('not harvest-ready', 1, true),
    ('expected "not harvest-ready" error, got %s'):format(tostring(early_err))
)

-- ------------------------------------------------------------
-- Case 4: AdvanceStage ×4 progresses 0 → 1 → 2 → 3 → 4 and sets
-- plot.state to 'harvest_ready' at the end.
-- ------------------------------------------------------------
for expected_stage = 1, 4 do
    ok, result = CropLifecycle.AdvanceStage(PLOT_ID)
    assert(ok, tostring(result))
    assert(
        result.stage == expected_stage,
        ('expected stage %d, got %d'):format(expected_stage, result.stage)
    )
end
assert(plot.state == 'harvest_ready', ('expected plot state harvest_ready, got %s'):format(tostring(plot.state)))

-- ------------------------------------------------------------
-- Case 5: Harvest on harvest_ready plot succeeds, cleans both
-- tables and flips the plot into cooldown.
-- ------------------------------------------------------------
ok, result = CropLifecycle.Harvest(PLOT_ID, 'citizen-1')
assert(ok, tostring(result))
assert(result.batch_id == 'sf-a1b2c3d4', 'expected harvested batch_id')
assert(crops[PLOT_ID] == nil, 'active crop must be deleted after harvest')
assert(quality_rows[PLOT_ID] == nil, 'quality row must be deleted after harvest')
assert(plot.state == 'cooldown', ('plot must enter cooldown after harvest, got %s'):format(tostring(plot.state)))
assert(
    type(plot.next_stage_ts) == 'number' and plot.next_stage_ts > os.time(),
    'cooldown next_stage_ts must be in the future'
)

-- ------------------------------------------------------------
-- Case 6: Plant during cooldown fails (state ~= 'fallow' until
-- the cooldown timer expires).
-- ------------------------------------------------------------
local cooldown_ok, cooldown_err = CropLifecycle.Plant(PLOT_ID, 'citizen-1', 'wheat')
assert(cooldown_ok == false, 'plant during cooldown must fail')
assert(
    type(cooldown_err) == 'string' and cooldown_err:find('not fallow', 1, true),
    ('expected "not fallow" error during cooldown, got %s'):format(tostring(cooldown_err))
)

print('lifecycle_spec.lua: OK (6 cases)')
