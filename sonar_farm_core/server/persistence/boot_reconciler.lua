Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}
Sonar.Farm.Persistence = Sonar.Farm.Persistence or {}

local BootReconciler = {}

local function log_info(message)
    print(('[sonar_farm_core][persistence] %s'):format(message))
end

local function log_error(message)
    print(('[sonar_farm_core][persistence][ERROR] %s'):format(message))
end

local function get_db()
    if not Sonar.Farm.DB then
        error('Sonar.Farm.DB is unavailable', 3)
    end

    return Sonar.Farm.DB
end

local function get_plot_service()
    if not Sonar.Farm.PlotService then
        error('Sonar.Farm.PlotService is unavailable', 3)
    end

    return Sonar.Farm.PlotService
end

local function get_delta_calculator()
    local persistence = Sonar.Farm.Persistence or {}
    if not persistence.DeltaCalculator or type(persistence.DeltaCalculator.Calculate) ~= 'function' then
        error('Sonar.Farm.Persistence.DeltaCalculator is unavailable', 3)
    end

    return persistence.DeltaCalculator
end

local function emit_reconciled(payload)
    local persistence = Sonar.Farm.Persistence or {}
    if type(persistence.EmitReconciled) == 'function' then
        persistence.EmitReconciled(payload)
        return
    end

    if type(TriggerEvent) == 'function' then
        TriggerEvent('sonar:farm:persistence:reconciled', payload)
    end
end

local function normalize_quality_row(row)
    if type(row) ~= 'table' then
        return {}
    end

    return {
        irrigation = tonumber(row.irrigation),
        pest_impact = tonumber(row.pest_impact),
        next_irrigation_due_ts = tonumber(row.next_irrigation_due_ts),
        pest_detected_ts = tonumber(row.pest_detected_ts),
        calculated_at = tonumber(row.calculated_at),
    }
end

local function fetch_active_rows()
    return get_db().rows([[ 
        SELECT
            p.`plot_id`,
            p.`state`,
            p.`last_updated_ts`,
            p.`next_stage_ts` AS `plot_next_stage_ts`,
            c.`id` AS `crop_id`,
            c.`crop_type`,
            c.`stage`,
            c.`next_stage_ts`,
            q.`irrigation`,
            q.`pest_impact`,
            q.`next_irrigation_due_ts`,
            q.`pest_detected_ts`,
            q.`calculated_at`
        FROM `sonar_farm_plots` p
        INNER JOIN `sonar_farm_crops` c
            ON c.`plot_id` = p.`plot_id`
        LEFT JOIN `sonar_farm_quality_tracking` q
            ON q.`plot_id` = p.`plot_id`
        ORDER BY p.`plot_id` ASC
    ]], {}) or {}
end

local function build_input(row, now_ts)
    return {
        now_ts = now_ts,
        plot = {
            plot_id = row.plot_id,
            state = row.state,
            last_updated_ts = tonumber(row.last_updated_ts) or 0,
            next_stage_ts = tonumber(row.plot_next_stage_ts),
        },
        crop = {
            id = tonumber(row.crop_id),
            plot_id = row.plot_id,
            crop_type = row.crop_type,
            stage = tonumber(row.stage) or 0,
            next_stage_ts = tonumber(row.next_stage_ts),
        },
        quality = normalize_quality_row(row),
    }
end

local function apply_plan(row, plan, now_ts)
    local queries = {}
    local changed = false

    if plan.crop.changed then
        changed = true
        queries[#queries + 1] = {
            query = [[
                UPDATE `sonar_farm_crops`
                SET `stage` = ?, `next_stage_ts` = ?
                WHERE `plot_id` = ?
            ]],
            values = { plan.crop.stage, plan.crop.next_stage_ts, row.plot_id },
        }
    end

    if plan.quality.changed then
        changed = true
        queries[#queries + 1] = {
            query = [[
                INSERT INTO `sonar_farm_quality_tracking` (
                    `plot_id`,
                    `irrigation`,
                    `pest_impact`,
                    `calculated_at`
                ) VALUES (?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE
                    `irrigation` = VALUES(`irrigation`),
                    `pest_impact` = VALUES(`pest_impact`),
                    `calculated_at` = VALUES(`calculated_at`)
            ]],
            values = {
                row.plot_id,
                plan.quality.irrigation,
                plan.quality.pest_impact,
                plan.quality.calculated_at,
            },
        }
    end

    if plan.plot.changed then
        changed = true
    end

    if not changed then
        return false
    end

    if #queries > 0 then
        get_db().transaction(queries)
    end

    local plot_patch = {}
    if plan.plot.state ~= row.state then
        plot_patch.state = plan.plot.state
    end
    if plan.plot.next_stage_ts ~= tonumber(row.plot_next_stage_ts) then
        plot_patch.next_stage_ts = plan.plot.next_stage_ts
    end

    if next(plot_patch) ~= nil then
        local ok, result_or_error = get_plot_service().UpdatePlotState(row.plot_id, plot_patch, 'offline_reconciled')
        if not ok then
            error(tostring(result_or_error), 2)
        end
    elseif plan.crop.changed or plan.quality.changed then
        get_db().execute('UPDATE `sonar_farm_plots` SET `last_updated_ts` = ? WHERE `plot_id` = ?', { now_ts, row.plot_id })
    end

    emit_reconciled({
        plot_id = row.plot_id,
        crop_type = row.crop_type,
        offline_seconds = plan.offline.seconds,
        capped = plan.offline.capped,
        stage_advances = plan.crop.stage_advances,
        irrigation_delta = plan.quality.irrigation_delta,
        pest_delta = plan.quality.pest_delta,
        reconciled_at = now_ts,
    })

    return true
end

function BootReconciler.Run(options)
    local dry_run = type(options) == 'table' and options.dry_run == true or false
    local now_ts = type(options) == 'table' and tonumber(options.now_ts) or os.time()
    local rows = fetch_active_rows()
    local delta_calculator = get_delta_calculator()

    local result = {
        total = #rows,
        reconciled = 0,
        unchanged = 0,
        capped = 0,
        stage_advances = 0,
        factor_caps = 0,
        skipped = 0,
        dry_run = dry_run,
        previews = {},
    }

    for index = 1, #rows do
        local row = rows[index]
        local ok, plan_or_error = pcall(delta_calculator.Calculate, build_input(row, now_ts))
        if not ok then
            result.skipped = result.skipped + 1
            log_error(('failed to calculate delta for %s: %s'):format(tostring(row.plot_id), tostring(plan_or_error)))
        elseif not plan_or_error then
            result.skipped = result.skipped + 1
        else
            local plan = plan_or_error
            local changed = plan.plot.changed or plan.crop.changed or plan.quality.changed
            if not changed then
                result.unchanged = result.unchanged + 1
            else
                result.stage_advances = result.stage_advances + (tonumber(plan.crop.stage_advances) or 0)
                if plan.offline.capped then
                    result.capped = result.capped + 1
                    result.factor_caps = result.factor_caps + #(plan.offline.capped_factors or {})
                end

                result.previews[#result.previews + 1] = {
                    plot_id = row.plot_id,
                    crop_type = row.crop_type,
                    offline_seconds = plan.offline.seconds,
                    capped = plan.offline.capped,
                    next_state = plan.plot.state,
                    stage = plan.crop.stage,
                    stage_advances = plan.crop.stage_advances,
                    irrigation = plan.quality.irrigation,
                    pest_impact = plan.quality.pest_impact,
                }

                if dry_run then
                    result.reconciled = result.reconciled + 1
                else
                    local applied_ok, applied_err = pcall(apply_plan, row, plan, now_ts)
                    if not applied_ok then
                        result.skipped = result.skipped + 1
                        log_error(('failed to apply delta for %s: %s'):format(tostring(row.plot_id), tostring(applied_err)))
                    else
                        result.reconciled = result.reconciled + 1
                    end
                end
            end
        end
    end

    return result
end

function BootReconciler.Boot()
    local ok, result_or_error = pcall(BootReconciler.Run, { dry_run = false })
    if not ok then
        log_error(('boot reconciliation failed: %s'):format(tostring(result_or_error)))
        return false
    end

    local result = result_or_error
    log_info(('boot reconciliation complete: reconciled=%d unchanged=%d capped=%d factor_caps=%d skipped=%d total=%d'):format(
        result.reconciled,
        result.unchanged,
        result.capped,
        result.factor_caps,
        result.skipped,
        result.total
    ))

    return result.skipped == 0
end

Sonar.Farm.Persistence.BootReconciler = BootReconciler
