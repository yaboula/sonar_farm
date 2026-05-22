local storage_zones = {}

local function get_storage_stash_prefix()
    return Config and Config.Farm and Config.Farm.Storage and Config.Farm.Storage.StashPrefix or 'sonar_farm_silo_'
end

local function get_storage_stash_id(storage_id)
    return get_storage_stash_prefix() .. tostring(storage_id)
end

local function get_unit_coords(unit)
    local coords = type(unit.coords) == 'table' and unit.coords or {}
    local x = tonumber(unit.coords_x) or tonumber(coords.x) or 0.0
    local y = tonumber(unit.coords_y) or tonumber(coords.y) or 0.0
    local z = tonumber(unit.coords_z) or tonumber(coords.z) or 0.0

    return vec3(x, y, z)
end

local function open_storage_stash(storage_id)
    if type(exports) ~= 'table' or not exports.ox_inventory then
        return
    end

    pcall(function()
        exports.ox_inventory:openInventory('stash', get_storage_stash_id(storage_id))
    end)
end

local function build_zone_options(unit)
    return {
        {
            name = ('sonar_farm_storage_deposit_%s'):format(unit.storage_id),
            icon = 'fas fa-box-arrow-in-down',
            label = locale('storage.interaction.deposit'),
            onSelect = function()
                open_storage_stash(unit.storage_id)
            end,
        },
        {
            name = ('sonar_farm_storage_check_%s'):format(unit.storage_id),
            icon = 'fas fa-warehouse',
            label = locale('storage.interaction.check'),
            onSelect = function()
                open_storage_stash(unit.storage_id)
            end,
        },
    }
end

local function clear_storage_zones()
    if type(exports) ~= 'table' or not exports.ox_target then
        storage_zones = {}
        return
    end

    for storage_id, zone_id in pairs(storage_zones) do
        if zone_id then
            exports.ox_target:removeZone(zone_id)
        end

        storage_zones[storage_id] = nil
    end
end

local function register_storage_zones(units)
    if type(exports) ~= 'table' or not exports.ox_target then
        return false
    end

    clear_storage_zones()

    for index = 1, #units do
        local unit = units[index]
        if type(unit) == 'table' and type(unit.storage_id) == 'string' and unit.storage_id ~= '' then
            local zone_id = exports.ox_target:addSphereZone({
                coords = get_unit_coords(unit),
                radius = tonumber(unit.radius) or 1.0,
                debug = false,
                drawSprite = false,
                options = build_zone_options(unit),
            })

            storage_zones[unit.storage_id] = zone_id
        end
    end

    return true
end

local function load_storage_units()
    local ok, units = pcall(function()
        return lib.callback.await('sonar:farm:storage:list_units', false)
    end)

    if not ok or type(units) ~= 'table' then
        return false
    end

    return register_storage_zones(units)
end

AddEventHandler('onClientResourceStart', function(resource_name)
    if resource_name ~= GetCurrentResourceName() then
        return
    end

    CreateThread(function()
        local retry_count = Config.Farm.Client.Startup.RetryCount or 10
        local retry_wait = Config.Farm.Client.Startup.RetryWaitMs or 1000
        for _ = 1, retry_count do
            if load_storage_units() then
                return
            end

            Wait(retry_wait)
        end
    end)
end)

AddEventHandler('onResourceStop', function(resource_name)
    if resource_name ~= GetCurrentResourceName() then
        return
    end

    clear_storage_zones()
end)
