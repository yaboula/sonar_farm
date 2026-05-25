local target_option_name = 'sonar_farm_machinery_repair'
local target_registered = false

local function get_machinery_config()
    return Config and Config.Farm and Config.Farm.Machinery or {}
end

local function get_repair_config()
    local machinery = get_machinery_config()
    local client = machinery.Client or {}
    return client.Repair or {}
end

local function sanitize_plate(plate)
    if type(plate) ~= 'string' then
        return nil
    end

    local trimmed = plate:match('^%s*(.-)%s*$')
    if trimmed == nil or trimmed == '' then
        return nil
    end

    if #trimmed > 16 then
        trimmed = trimmed:sub(1, 16)
    end

    return string.upper(trimmed)
end

local function get_vehicle_plate(vehicle)
    if type(vehicle) ~= 'number' or vehicle == 0 or not DoesEntityExist(vehicle) then
        return nil
    end

    return sanitize_plate(GetVehicleNumberPlateText(vehicle))
end

local function get_model_name(vehicle)
    if type(vehicle) ~= 'number' or vehicle == 0 or not DoesEntityExist(vehicle) then
        return nil
    end

    local display_name = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
    if type(display_name) ~= 'string' or display_name == '' then
        return nil
    end

    return string.lower(display_name)
end

local function is_valid_machinery(vehicle)
    local model_name = get_model_name(vehicle)
    local models = get_machinery_config().Models or {}
    if not model_name or type(models[model_name]) ~= 'table' then
        return false
    end

    return true
end

local function has_repair_kit()
    if type(exports) ~= 'table' or not exports.ox_inventory then
        return false
    end

    local item_name = get_machinery_config().Repair and get_machinery_config().Repair.item_name or 'sonar_machinery_kit'
    local ok, count = pcall(function()
        return exports.ox_inventory:Search('count', item_name)
    end)

    return ok and (tonumber(count) or 0) > 0
end

local function ensure_anim_dict(anim_dict)
    if type(anim_dict) ~= 'string' or anim_dict == '' then
        return false
    end

    local repair = get_repair_config()
    RequestAnimDict(anim_dict)
    local deadline = GetGameTimer() + math.max(tonumber(repair.anim_load_deadline_ms) or 0, 0)
    while not HasAnimDictLoaded(anim_dict) do
        if GetGameTimer() >= deadline then
            return false
        end

        Wait(0)
    end

    return true
end

local function release_anim_dict(anim_dict)
    if type(anim_dict) == 'string' and anim_dict ~= '' then
        RemoveAnimDict(anim_dict)
    end
end

local function request_entity_control(entity, timeout_ms)
    if type(entity) ~= 'number' or entity == 0 or not DoesEntityExist(entity) then
        return false
    end

    if NetworkHasControlOfEntity(entity) then
        return true
    end

    NetworkRequestControlOfEntity(entity)

    local deadline = GetGameTimer() + math.max(tonumber(timeout_ms) or 750, 0)
    while GetGameTimer() < deadline do
        if NetworkHasControlOfEntity(entity) then
            return true
        end

        Wait(0)
    end

    return NetworkHasControlOfEntity(entity)
end

local function get_error_message(reason)
    local key = 'machinery.errors.' .. tostring(reason or 'unknown')
    local message = locale(key)
    if type(message) ~= 'string' or message == '' or message == key then
        return locale('machinery.errors.unknown')
    end

    return message
end

local function notify_error(reason)
    lib.notify({
        description = get_error_message(reason),
        type = 'error',
    })
end

local function run_repair_progress(vehicle)
    local repair = get_repair_config()
    local anim_dict = repair.anim_dict or 'mini@repair'
    local anim_clip = repair.anim_clip or 'fixing_a_ped'

    if not ensure_anim_dict(anim_dict) then
        return false
    end

    request_entity_control(vehicle, repair.control_timeout_ms)
    SetVehicleDoorOpen(vehicle, tonumber(repair.hood_door_index) or 4, false, false)

    local completed = lib.progressBar({
        duration = math.floor(tonumber(repair.progress_duration_ms) or 10000),
        label = locale('machinery.interaction.repairing'),
        canCancel = true,
        useWhileDead = false,
        disable = {
            move = false,
            car = true,
            combat = true,
            sprint = true,
        },
        anim = {
            dict = anim_dict,
            clip = anim_clip,
            flag = tonumber(repair.anim_flag) or 49,
        },
    })

    ClearPedTasks(PlayerPedId())
    SetVehicleDoorShut(vehicle, tonumber(repair.hood_door_index) or 4, false)
    release_anim_dict(anim_dict)

    return completed == true
end

local function repair_vehicle(vehicle)
    local plate = get_vehicle_plate(vehicle)
    if not plate then
        notify_error('invalid_plate')
        return
    end

    if not run_repair_progress(vehicle) then
        return
    end

    local ok, response = pcall(function()
        return lib.callback.await('sonar:farm:server:repair_machinery', false, plate)
    end)

    if not ok or type(response) ~= 'table' or response.ok ~= true then
        notify_error(type(response) == 'table' and response.error or 'unknown')
        return
    end

    lib.notify({
        description = locale('machinery.notify.repaired'),
        type = 'success',
    })
end

local function register_global_vehicle_target()
    if target_registered or type(exports) ~= 'table' or not exports.ox_target then
        return false
    end

    local repair = get_repair_config()

    local ok = pcall(function()
        exports.ox_target:addGlobalVehicle({
            {
                name = target_option_name,
                icon = 'fas fa-screwdriver-wrench',
                label = locale('machinery.interaction.repair'),
                bones = repair.bones or { 'engine' },
                distance = tonumber(repair.target_distance) or 2.5,
                canInteract = function(entity)
                    return IsEntityAVehicle(entity)
                        and is_valid_machinery(entity)
                        and GetVehiclePedIsIn(PlayerPedId(), false) == 0
                        and has_repair_kit()
                end,
                onSelect = function(data)
                    local entity = type(data) == 'table' and data.entity or nil
                    if type(entity) ~= 'number' or entity == 0 or not DoesEntityExist(entity) then
                        notify_error('invalid_machinery')
                        return
                    end

                    repair_vehicle(entity)
                end,
            },
        })
    end)

    target_registered = ok == true
    return target_registered
end

local function unregister_global_vehicle_target()
    if not target_registered or type(exports) ~= 'table' or not exports.ox_target then
        target_registered = false
        return
    end

    pcall(function()
        exports.ox_target:removeGlobalVehicle(target_option_name)
    end)

    target_registered = false
end

AddEventHandler('onClientResourceStart', function(resource_name)
    if resource_name ~= GetCurrentResourceName() and resource_name ~= 'ox_target' then
        return
    end

    if resource_name == 'ox_target' then
        target_registered = false
    end

    CreateThread(function()
        local retry_count = Config.Farm.Client.Startup.RetryCount or 10
        local retry_wait = Config.Farm.Client.Startup.RetryWaitMs or 1000
        for _ = 1, retry_count do
            if register_global_vehicle_target() then
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

    unregister_global_vehicle_target()
end)
