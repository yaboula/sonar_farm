Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}
Sonar.Farm.NPCs = Sonar.Farm.NPCs or {}

local function log_info(message)
    print(('[sonar_farm_core] %s'):format(message))
end

local function log_error(message)
    print(('[sonar_farm_core][ERROR] %s'):format(message))
end

function Sonar.Farm.NPCs.Boot()
    if not Sonar.Farm.NPCBuyerService or type(Sonar.Farm.NPCBuyerService.Boot) ~= 'function' then
        log_error(locale('npcs.boot.unavailable'))
        return false
    end

    local ok, result_or_error = pcall(Sonar.Farm.NPCBuyerService.Boot)
    if not ok then
        log_error(locale('npcs.boot.boot_failed'):format(tostring(result_or_error)))
        return false
    end

    if result_or_error ~= true then
        log_error(locale('npcs.boot.boot_failed'):format('unknown_error'))
        return false
    end

    local buyers = Config and Config.Farm and Config.Farm.NPCs and Config.Farm.NPCs.buyers or {}
    local count = 0
    for _, buyer in pairs(buyers) do
        if type(buyer) == 'table' then
            count = count + 1
        end
    end

    TriggerEvent('sonar:farm:npc:catalog_reloaded', {
        buyer_count = count,
    })

    log_info(locale('npcs.boot.ready'):format(count))
    return true
end
