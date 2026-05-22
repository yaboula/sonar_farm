Config = {
    Farm = {
        Quality = {
            NeutralDefaults = {
                pest_impact = 100,
            },
        },
        Crops = {
            wheat = {
                pests = {
                    susceptible_to = { 'blight', 'aphid' },
                    spawn_probability_per_tick = 1.1,
                    min_stage = 1,
                    max_stage = 3,
                    severity_hours = 24,
                    treat_score_restore = 30,
                    severe_treat_ceiling = 60,
                },
            },
            barley = {
                pests = {
                    susceptible_to = { 'blight' },
                    spawn_probability_per_tick = 1.1,
                    min_stage = 1,
                    max_stage = 3,
                    severity_hours = 24,
                    treat_score_restore = 30,
                    severe_treat_ceiling = 60,
                },
            },
        },
    },
}

local now_ts = os.time()

local quality_rows = {
    plot_spawn = { pest_impact = 100, pest_detected_ts = nil, pest_severity = 'none' },
    plot_active = { pest_impact = 100, pest_detected_ts = nil, pest_severity = 'none' },
    plot_detected = { pest_impact = 20, pest_detected_ts = now_ts - 9000, pest_severity = 'detected' },
    plot_severe = { pest_impact = 10, pest_detected_ts = now_ts - 18000, pest_severity = 'severe' },
}

local crop_rows = {
    plot_spawn = { crop_type = 'barley', stage = 2 },
    plot_active = { crop_type = 'wheat', stage = 2 },
    plot_detected = { crop_type = 'wheat', stage = 2 },
    plot_severe = { crop_type = 'barley', stage = 2 },
}

local emitted_events = {}

Sonar = { Farm = { Quality = { Factors = {} } } }

function TriggerEvent(event_name, payload)
    emitted_events[#emitted_events + 1] = { name = event_name, payload = payload }
end

Sonar.Farm.DB = {
    row = function(query, params)
        local plot_id = params[1]
        if query:find('SELECT `pest_impact`', 1, true) then
            local row = quality_rows[plot_id]
            return row and { pest_impact = row.pest_impact } or nil
        end
        if query:find('SELECT `pest_detected_ts`, `pest_severity`', 1, true) then
            local row = quality_rows[plot_id]
            if not row then
                return nil
            end
            return {
                pest_detected_ts = row.pest_detected_ts,
                pest_severity = row.pest_severity,
            }
        end
        if query:find('SELECT `crop_type` FROM `sonar_farm_crops`', 1, true) then
            local row = crop_rows[plot_id]
            return row and { crop_type = row.crop_type } or nil
        end
        return nil
    end,
    rows = function(query)
        if query:find('FROM `sonar_farm_quality_tracking` q', 1, true) then
            local rows = {}
            for plot_id, row in pairs(quality_rows) do
                if row.pest_detected_ts ~= nil and row.pest_severity == 'detected' then
                    rows[#rows + 1] = {
                        plot_id = plot_id,
                        pest_detected_ts = row.pest_detected_ts,
                        crop_type = crop_rows[plot_id].crop_type,
                    }
                end
            end
            table.sort(rows, function(a, b)
                return a.plot_id < b.plot_id
            end)
            return rows
        end
        if query:find('FROM `sonar_farm_quality_tracking`', 1, true) then
            local rows = {}
            for plot_id, row in pairs(quality_rows) do
                if row.pest_severity ~= 'none' then
                    rows[#rows + 1] = {
                        plot_id = plot_id,
                        pest_detected_ts = row.pest_detected_ts,
                        pest_severity = row.pest_severity,
                    }
                end
            end
            table.sort(rows, function(a, b)
                return a.plot_id < b.plot_id
            end)
            return rows
        end
        return {}
    end,
    execute = function(query, params)
        if query:find('INSERT INTO `sonar_farm_quality_tracking`', 1, true) then
            local plot_id = params[1]
            quality_rows[plot_id] = quality_rows[plot_id] or { pest_detected_ts = nil, pest_severity = 'none' }
            quality_rows[plot_id].pest_impact = params[2]
            return true
        end
        if query:find('SET `pest_detected_ts` = ?, `pest_severity` = ?', 1, true) then
            local plot_id = params[3]
            quality_rows[plot_id].pest_detected_ts = params[1]
            quality_rows[plot_id].pest_severity = params[2]
            return true
        end
        if query:find('SET `pest_detected_ts` = NULL, `pest_severity` = ?', 1, true) then
            local plot_id = params[2]
            quality_rows[plot_id].pest_detected_ts = nil
            quality_rows[plot_id].pest_severity = params[1]
            return true
        end
        if query:find("SET `pest_severity` = 'severe'", 1, true) then
            local plot_id = params[1]
            quality_rows[plot_id].pest_severity = 'severe'
            return true
        end
        return true
    end,
}

dofile('sonar_farm_core/server/quality/factors/pest.lua')
dofile('sonar_farm_core/server/pests/pest_service.lua')

local PestFactor = Sonar.Farm.Quality.Factors.Pest
local PestService = Sonar.Farm.PestService
local local_score

local ok, err = PestFactor.Appear('plot_active', 'blight')
assert(ok == true and err == nil, 'expected pest appear to succeed on inactive plot')
assert(quality_rows.plot_active.pest_severity == 'detected', 'expected detected severity after appear')
assert(type(quality_rows.plot_active.pest_detected_ts) == 'number', 'expected detected ts stamped on appear')

ok, err = PestFactor.Appear('plot_active', 'aphid')
assert(ok == false and err == 'pest already active', 'expected duplicate appear to reject when pest is active')

local status = PestFactor.GetStatus('plot_active')
assert(status ~= nil and status.severity == 'detected', 'expected detected status for active pest')

ok, local_score, err = PestFactor.Treat('plot_detected', 'sonar_pesticide_contact')
assert(ok == true and err == nil, 'expected treating detected pest to succeed')
assert(local_score == 50, ('expected detected treatment to restore to 50, got %s'):format(tostring(local_score)))
assert(quality_rows.plot_detected.pest_severity == 'none', 'expected detected pest to clear severity')

ok, local_score, err = PestFactor.Treat('plot_severe', 'sonar_pesticide_systemic')
assert(ok == true and err == nil, 'expected treating severe pest to succeed')
assert(local_score == 60, ('expected severe treatment to restore to ceiling 60, got %s'):format(tostring(local_score)))
assert(quality_rows.plot_severe.pest_severity == 'none', 'expected severe pest to clear severity')

PestService.TickCrops({ { plot_id = 'plot_spawn', crop_type = 'barley', stage = 2 } })
assert(quality_rows.plot_spawn.pest_severity == 'detected', 'expected scheduler tick to spawn pest when probability hits')

quality_rows.plot_spawn.pest_detected_ts = os.time() - (25 * 3600)
quality_rows.plot_spawn.pest_severity = 'detected'
PestService.TickCrops({})
assert(quality_rows.plot_spawn.pest_severity == 'severe', 'expected scheduler tick to escalate detected pest to severe after threshold')

local active_pests = PestService.GetActivePests()
assert(#active_pests == 2, ('expected 2 active pests after escalation, got %d'):format(#active_pests))

print('pest_spec.lua: OK (6 cases)')
