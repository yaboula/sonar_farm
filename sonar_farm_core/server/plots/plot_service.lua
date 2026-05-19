-- ============================================================
-- Farm Sonar — PlotService (S5).
-- ============================================================
--
-- Server-authoritative registry for cultivable terrain units.
-- Bible §9.2 — DB is the single source of truth for plot state.
-- Bible §13.2 — every persisted mutation stamps `last_updated_ts`
-- so future delta-calc on boot (S6/S16) is trivial.
-- ADR-010 — `plot_id` is a stable natural key; seed sync never
-- resets gameplay-owned fields.
--
-- Public surface (`Sonar.Farm.PlotService`):
--   Boot()                                    -> boolean
--   SyncSeededPlots()                         -> result
--   ReloadSeededPlots(src)                    -> result
--   ListPlots()                               -> plot[]
--   GetPlot(plot_id)                          -> plot | nil
--   CreatePlot(plot, reason)                  -> ok, row_or_error
--   UpdatePlotState(plot_id, patch, reason)   -> ok, row_or_error
--
-- All persisted mutations publish:
--   TriggerEvent('sonar:farm:plot:state_changed', payload)
-- where payload includes: plot_id, previous_state, next_state,
-- changed_fields, reason, changed_at.

Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}

local PlotService = {}

local PLOT_EVENT = 'sonar:farm:plot:state_changed'
local STATE_CHANGED_DEFAULT_REASON = 'unspecified'
local CREATE_REASON = 'seed_create'
local UPDATE_CONFIG_REASON = 'seed_config_update'

-- Strict allowlist of fields a runtime caller may patch through
-- `UpdatePlotState`. Adding a key here is an explicit decision.
local ALLOWED_PATCH_FIELDS = {
    state = true,
    soil_score = true,
    planted_ts = true,
    next_stage_ts = true,
}

-- Config-owned columns are re-synced from `Config.Farm.Plots.Seed`
-- on every boot/reload, never written by gameplay code:
--   plot_type, display_name_key, coords_x, coords_y, coords_z, radius
-- The diff and update helpers below enumerate them inline.

local function log_info(message)
    print(('[sonar_farm_core][plots] %s'):format(message))
end

local function log_error(message)
    print(('[sonar_farm_core][plots][ERROR] %s'):format(message))
end

local function get_db()
    if not Sonar.Farm.DB then
        error('Sonar.Farm.DB is unavailable. Ensure server/db/db.lua loads before server/plots/plot_service.lua.', 3)
    end

    return Sonar.Farm.DB
end

local function get_plots_config()
    if type(Config) ~= 'table' or type(Config.Farm) ~= 'table' or type(Config.Farm.Plots) ~= 'table' then
        error('Config.Farm.Plots is unavailable. Ensure config/plots.lua loads before server/plots/plot_service.lua.', 3)
    end

    return Config.Farm.Plots
end

local function is_string_non_empty(value)
    return type(value) == 'string' and value ~= ''
end

local function is_number_finite(value)
    return type(value) == 'number' and value == value and value ~= math.huge and value ~= -math.huge
end

local function is_integer_in_range(value, min_value, max_value)
    if type(value) ~= 'number' then
        return false
    end

    if value ~= math.floor(value) then
        return false
    end

    return value >= min_value and value <= max_value
end

local function validate_plot_type(plot_type)
    local plots_config = get_plots_config()

    if not is_string_non_empty(plot_type) then
        return false, 'plot_type must be a non-empty string'
    end

    if not plots_config.AllowedTypes[plot_type] then
        return false, ('plot_type "%s" is not in Config.Farm.Plots.AllowedTypes'):format(plot_type)
    end

    return true
end

local function validate_state(state)
    if not is_string_non_empty(state) then
        return false, 'state must be a non-empty string'
    end

    if #state > 32 then
        return false, 'state exceeds 32 characters'
    end

    return true
end

local function validate_soil_score(soil_score)
    local plots_config = get_plots_config()
    local score_range = plots_config.SoilScore or { Min = 0, Max = 100 }

    if not is_integer_in_range(soil_score, score_range.Min, score_range.Max) then
        return false, ('soil_score must be an integer in [%d, %d]'):format(score_range.Min, score_range.Max)
    end

    return true
end

local function validate_optional_unix_ts(value, field_name)
    if value == nil then
        return true
    end

    if type(value) ~= 'number' or value < 0 or value ~= math.floor(value) then
        return false, ('%s must be a non-negative integer UNIX timestamp or nil'):format(field_name)
    end

    return true
end

local function validate_coords(coords_x, coords_y, coords_z, radius)
    if not is_number_finite(coords_x) then
        return false, 'coords_x must be a finite number'
    end

    if not is_number_finite(coords_y) then
        return false, 'coords_y must be a finite number'
    end

    if not is_number_finite(coords_z) then
        return false, 'coords_z must be a finite number'
    end

    if not is_number_finite(radius) or radius <= 0 then
        return false, 'radius must be a positive finite number'
    end

    return true
end

local function row_to_plot(row)
    if type(row) ~= 'table' then
        return nil
    end

    local planted_ts = row.planted_ts
    if planted_ts ~= nil then
        planted_ts = tonumber(planted_ts)
    end

    local next_stage_ts = row.next_stage_ts
    if next_stage_ts ~= nil then
        next_stage_ts = tonumber(next_stage_ts)
    end

    return {
        plot_id = row.plot_id,
        plot_type = row.plot_type,
        display_name_key = row.display_name_key,
        state = row.state,
        soil_score = tonumber(row.soil_score) or 0,
        coords_x = tonumber(row.coords_x) or 0,
        coords_y = tonumber(row.coords_y) or 0,
        coords_z = tonumber(row.coords_z) or 0,
        radius = tonumber(row.radius) or 0,
        last_updated_ts = tonumber(row.last_updated_ts) or 0,
        planted_ts = planted_ts,
        next_stage_ts = next_stage_ts,
    }
end

local function fetch_row(plot_id)
    return get_db().row([[
        SELECT
            `plot_id`,
            `plot_type`,
            `display_name_key`,
            `state`,
            `soil_score`,
            `coords_x`,
            `coords_y`,
            `coords_z`,
            `radius`,
            `last_updated_ts`,
            `planted_ts`,
            `next_stage_ts`
        FROM `sonar_farm_plots`
        WHERE `plot_id` = ?
        LIMIT 1
    ]], { plot_id })
end

local function fetch_all_rows()
    return get_db().rows([[
        SELECT
            `plot_id`,
            `plot_type`,
            `display_name_key`,
            `state`,
            `soil_score`,
            `coords_x`,
            `coords_y`,
            `coords_z`,
            `radius`,
            `last_updated_ts`,
            `planted_ts`,
            `next_stage_ts`
        FROM `sonar_farm_plots`
        ORDER BY `plot_id` ASC
    ]], {})
end

local function emit_state_changed(plot_id, previous_state, next_state, changed_fields, reason)
    TriggerEvent(PLOT_EVENT, {
        plot_id = plot_id,
        previous_state = previous_state,
        next_state = next_state,
        changed_fields = changed_fields,
        reason = reason or STATE_CHANGED_DEFAULT_REASON,
        changed_at = os.time(),
    })
end

local function insert_plot(plot, now_ts)
    get_db().execute([[
        INSERT INTO `sonar_farm_plots` (
            `plot_id`,
            `plot_type`,
            `display_name_key`,
            `state`,
            `soil_score`,
            `coords_x`,
            `coords_y`,
            `coords_z`,
            `radius`,
            `last_updated_ts`,
            `planted_ts`,
            `next_stage_ts`
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, NULL)
    ]], {
        plot.plot_id,
        plot.plot_type,
        plot.display_name_key,
        plot.state,
        plot.soil_score,
        plot.coords_x,
        plot.coords_y,
        plot.coords_z,
        plot.radius,
        now_ts,
    })
end

local function diff_config_owned(existing_row, seed_entry)
    local changed = {}

    if existing_row.plot_type ~= seed_entry.plot_type then
        changed[#changed + 1] = 'plot_type'
    end

    if existing_row.display_name_key ~= seed_entry.display_name_key then
        changed[#changed + 1] = 'display_name_key'
    end

    if (tonumber(existing_row.coords_x) or 0) ~= seed_entry.coords_x then
        changed[#changed + 1] = 'coords_x'
    end

    if (tonumber(existing_row.coords_y) or 0) ~= seed_entry.coords_y then
        changed[#changed + 1] = 'coords_y'
    end

    if (tonumber(existing_row.coords_z) or 0) ~= seed_entry.coords_z then
        changed[#changed + 1] = 'coords_z'
    end

    if (tonumber(existing_row.radius) or 0) ~= seed_entry.radius then
        changed[#changed + 1] = 'radius'
    end

    return changed
end

local function update_config_owned(plot_id, seed_entry, now_ts)
    get_db().execute([[
        UPDATE `sonar_farm_plots`
        SET
            `plot_type` = ?,
            `display_name_key` = ?,
            `coords_x` = ?,
            `coords_y` = ?,
            `coords_z` = ?,
            `radius` = ?,
            `last_updated_ts` = ?
        WHERE `plot_id` = ?
    ]], {
        seed_entry.plot_type,
        seed_entry.display_name_key,
        seed_entry.coords_x,
        seed_entry.coords_y,
        seed_entry.coords_z,
        seed_entry.radius,
        now_ts,
        plot_id,
    })
end

local function validate_seed_entry(entry)
    if type(entry) ~= 'table' then
        return false, 'seed entry must be a table'
    end

    if not is_string_non_empty(entry.plot_id) then
        return false, 'seed entry missing valid plot_id'
    end

    local ok, err = validate_plot_type(entry.plot_type)
    if not ok then
        return false, err
    end

    if not is_string_non_empty(entry.display_name_key) then
        return false, ('seed entry "%s" missing display_name_key'):format(entry.plot_id)
    end

    ok, err = validate_coords(entry.coords_x, entry.coords_y, entry.coords_z, entry.radius)
    if not ok then
        return false, ('seed entry "%s": %s'):format(entry.plot_id, err)
    end

    ok, err = validate_soil_score(entry.initial_soil_score)
    if not ok then
        return false, ('seed entry "%s": initial_%s'):format(entry.plot_id, err)
    end

    return true
end

-- ============================================================
-- Public API
-- ============================================================

function PlotService.ListPlots()
    local rows = fetch_all_rows() or {}
    local plots = {}

    for index = 1, #rows do
        plots[index] = row_to_plot(rows[index])
    end

    return plots
end

function PlotService.GetPlot(plot_id)
    if not is_string_non_empty(plot_id) then
        return nil
    end

    local row = fetch_row(plot_id)
    if not row then
        return nil
    end

    return row_to_plot(row)
end

function PlotService.CreatePlot(plot, reason)
    if type(plot) ~= 'table' then
        return false, 'plot must be a table'
    end

    if not is_string_non_empty(plot.plot_id) then
        return false, 'plot.plot_id must be a non-empty string'
    end

    local ok, err = validate_plot_type(plot.plot_type)
    if not ok then
        return false, err
    end

    if not is_string_non_empty(plot.display_name_key) then
        return false, 'plot.display_name_key must be a non-empty string'
    end

    ok, err = validate_coords(plot.coords_x, plot.coords_y, plot.coords_z, plot.radius)
    if not ok then
        return false, err
    end

    local plots_config = get_plots_config()
    local state = plot.state or plots_config.InitialState
    ok, err = validate_state(state)
    if not ok then
        return false, err
    end

    local soil_score = plot.soil_score
    ok, err = validate_soil_score(soil_score)
    if not ok then
        return false, err
    end

    if fetch_row(plot.plot_id) then
        return false, ('plot "%s" already exists'):format(plot.plot_id)
    end

    local now_ts = os.time()

    insert_plot({
        plot_id = plot.plot_id,
        plot_type = plot.plot_type,
        display_name_key = plot.display_name_key,
        state = state,
        soil_score = soil_score,
        coords_x = plot.coords_x,
        coords_y = plot.coords_y,
        coords_z = plot.coords_z,
        radius = plot.radius,
    }, now_ts)

    local stored = row_to_plot(fetch_row(plot.plot_id))
    emit_state_changed(plot.plot_id, nil, state, { 'created' }, reason or CREATE_REASON)

    return true, stored
end

function PlotService.UpdatePlotState(plot_id, state_patch, reason)
    if not is_string_non_empty(plot_id) then
        return false, 'plot_id must be a non-empty string'
    end

    if type(state_patch) ~= 'table' then
        return false, 'state_patch must be a table'
    end

    local existing = fetch_row(plot_id)
    if not existing then
        return false, ('plot "%s" not found'):format(plot_id)
    end

    -- Reject any patch field outside the strict allowlist before
    -- touching the DB. This keeps `UpdatePlotState` narrow and
    -- prevents accidental writes to config-owned columns.
    for key in pairs(state_patch) do
        if not ALLOWED_PATCH_FIELDS[key] then
            return false, ('field "%s" is not patchable via UpdatePlotState'):format(tostring(key))
        end
    end

    local set_clauses = {}
    local set_values = {}
    local changed_fields = {}
    local previous_state = existing.state
    local next_state = previous_state

    if state_patch.state ~= nil then
        local ok, err = validate_state(state_patch.state)
        if not ok then
            return false, err
        end

        if state_patch.state ~= existing.state then
            set_clauses[#set_clauses + 1] = '`state` = ?'
            set_values[#set_values + 1] = state_patch.state
            changed_fields[#changed_fields + 1] = 'state'
            next_state = state_patch.state
        end
    end

    if state_patch.soil_score ~= nil then
        local ok, err = validate_soil_score(state_patch.soil_score)
        if not ok then
            return false, err
        end

        if state_patch.soil_score ~= (tonumber(existing.soil_score) or 0) then
            set_clauses[#set_clauses + 1] = '`soil_score` = ?'
            set_values[#set_values + 1] = state_patch.soil_score
            changed_fields[#changed_fields + 1] = 'soil_score'
        end
    end

    -- Nil means "no change" for these timestamp fields. Lua tables
    -- cannot distinguish between an absent key and a key explicitly
    -- set to nil, so dedicated clearing semantics will be added in
    -- a follow-up slice when S6 needs to reset the lifecycle.
    if state_patch.planted_ts ~= nil then
        local ok, err = validate_optional_unix_ts(state_patch.planted_ts, 'planted_ts')
        if not ok then
            return false, err
        end

        local existing_planted_ts = existing.planted_ts ~= nil and tonumber(existing.planted_ts) or nil
        if state_patch.planted_ts ~= existing_planted_ts then
            set_clauses[#set_clauses + 1] = '`planted_ts` = ?'
            set_values[#set_values + 1] = state_patch.planted_ts
            changed_fields[#changed_fields + 1] = 'planted_ts'
        end
    end

    if state_patch.next_stage_ts ~= nil then
        local ok, err = validate_optional_unix_ts(state_patch.next_stage_ts, 'next_stage_ts')
        if not ok then
            return false, err
        end

        local existing_next_stage_ts = existing.next_stage_ts ~= nil and tonumber(existing.next_stage_ts) or nil
        if state_patch.next_stage_ts ~= existing_next_stage_ts then
            set_clauses[#set_clauses + 1] = '`next_stage_ts` = ?'
            set_values[#set_values + 1] = state_patch.next_stage_ts
            changed_fields[#changed_fields + 1] = 'next_stage_ts'
        end
    end

    if #set_clauses == 0 then
        return true, row_to_plot(existing)
    end

    local now_ts = os.time()
    set_clauses[#set_clauses + 1] = '`last_updated_ts` = ?'
    set_values[#set_values + 1] = now_ts
    set_values[#set_values + 1] = plot_id

    get_db().execute(([[
        UPDATE `sonar_farm_plots`
        SET %s
        WHERE `plot_id` = ?
    ]]):format(table.concat(set_clauses, ', ')), set_values)

    local stored = row_to_plot(fetch_row(plot_id))
    emit_state_changed(plot_id, previous_state, next_state, changed_fields, reason or STATE_CHANGED_DEFAULT_REASON)

    return true, stored
end

function PlotService.SyncSeededPlots()
    local plots_config = get_plots_config()
    local seed = plots_config.Seed or {}
    local now_ts = os.time()

    local result = {
        created = 0,
        updated = 0,
        unchanged = 0,
        skipped = 0,
        total = #seed,
    }

    for index = 1, #seed do
        local entry = seed[index]
        local ok, err = validate_seed_entry(entry)

        if not ok then
            result.skipped = result.skipped + 1
            log_error(('skipping invalid seed entry [%d]: %s'):format(index, tostring(err)))
        else
            local existing = fetch_row(entry.plot_id)

            if not existing then
                insert_plot({
                    plot_id = entry.plot_id,
                    plot_type = entry.plot_type,
                    display_name_key = entry.display_name_key,
                    state = plots_config.InitialState,
                    soil_score = entry.initial_soil_score,
                    coords_x = entry.coords_x,
                    coords_y = entry.coords_y,
                    coords_z = entry.coords_z,
                    radius = entry.radius,
                }, now_ts)

                result.created = result.created + 1
                emit_state_changed(
                    entry.plot_id,
                    nil,
                    plots_config.InitialState,
                    { 'created' },
                    CREATE_REASON
                )
            else
                local changed = diff_config_owned(existing, entry)

                if #changed == 0 then
                    result.unchanged = result.unchanged + 1
                else
                    update_config_owned(entry.plot_id, entry, now_ts)
                    result.updated = result.updated + 1
                    emit_state_changed(
                        entry.plot_id,
                        existing.state,
                        existing.state,
                        changed,
                        UPDATE_CONFIG_REASON
                    )
                end
            end
        end
    end

    return result
end

function PlotService.ReloadSeededPlots(_src)
    return PlotService.SyncSeededPlots()
end

function PlotService.Boot()
    local ok, result = pcall(PlotService.SyncSeededPlots)

    if not ok then
        log_error(('plot seed sync failed: %s'):format(tostring(result)))
        return false
    end

    log_info(('plot seed sync complete: created=%d, updated=%d, unchanged=%d, skipped=%d, total=%d'):format(
        result.created,
        result.updated,
        result.unchanged,
        result.skipped,
        result.total
    ))

    return result.skipped == 0
end

Sonar.Farm.PlotService = PlotService
