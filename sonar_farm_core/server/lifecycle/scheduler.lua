Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}
Sonar.Farm.Lifecycle = Sonar.Farm.Lifecycle or {}

local Scheduler = {}
local running = false

local function get_tick_seconds()
    local scheduler_config = Config and Config.Farm and Config.Farm.Scheduler or {}
    local tick_seconds = tonumber(scheduler_config.TickSeconds) or 30
    if tick_seconds < 1 then
        return 1
    end
    return math.floor(tick_seconds)
end

local function get_db()
    return Sonar and Sonar.Farm and Sonar.Farm.DB or nil
end

local function get_lifecycle()
    return Sonar and Sonar.Farm and Sonar.Farm.CropLifecycle or nil
end

local function run_tick()
    local db = get_db()
    local lifecycle = get_lifecycle()
    if not db or not lifecycle or type(lifecycle.AdvanceStage) ~= 'function' then
        return
    end

    local rows = db.rows([[
        SELECT `plot_id`
        FROM `sonar_farm_crops`
        WHERE `next_stage_ts` <= ? AND `stage` < 4
        ORDER BY `next_stage_ts` ASC
    ]], { os.time() }) or {}

    for index = 1, #rows do
        local ok, result = pcall(lifecycle.AdvanceStage, rows[index].plot_id)
        if not ok then
            print(('[sonar_farm_core][lifecycle][scheduler][ERROR] %s'):format(tostring(result)))
        end
    end
end

function Scheduler.Start()
    if running then
        return false
    end

    running = true
    CreateThread(function()
        while running do
            Wait(get_tick_seconds() * 1000)
            run_tick()
        end
    end)

    return true
end

function Scheduler.Stop()
    running = false
    return true
end

function Scheduler.IsRunning()
    return running
end

Sonar.Farm.Lifecycle.Scheduler = Scheduler
