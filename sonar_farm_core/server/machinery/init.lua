Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}
Sonar.Farm.Machinery = Sonar.Farm.Machinery or {}

local function log_info(message)
    print(('[sonar_farm_core] %s'):format(message))
end

local function log_error(message)
    print(('[sonar_farm_core][ERROR] %s'):format(message))
end

function Sonar.Farm.Machinery.Boot()
    if not Sonar.Farm.MachineryService or type(Sonar.Farm.MachineryService.Boot) ~= 'function' then
        log_error(locale('machinery.boot.unavailable'))
        return false
    end

    local ok, result_or_error = pcall(Sonar.Farm.MachineryService.Boot)
    if not ok then
        log_error(locale('machinery.boot.boot_failed'):format(tostring(result_or_error)))
        return false
    end

    if result_or_error ~= true then
        log_error(locale('machinery.boot.boot_failed'):format('unknown_error'))
        return false
    end

    local models = Config and Config.Farm and Config.Farm.Machinery and Config.Farm.Machinery.Models or {}
    local count = 0
    for _, model in pairs(models) do
        if type(model) == 'table' then
            count = count + 1
        end
    end

    log_info(locale('machinery.boot.ready'):format(count))
    return true
end
