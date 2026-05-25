Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}

local broken_plates = {}
local control_thread_running = false

local function get_client_breakdown_config()
    return Config
        and Config.Farm
        and Config.Farm.Machinery
        and Config.Farm.Machinery.Client
        and Config.Farm.Machinery.Client.Breakdown
        or {}
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

local function extract_plate(payload)
    if type(payload) == 'table' then
        return sanitize_plate(payload.plate)
    end

    return sanitize_plate(payload)
end

local function get_vehicle_plate(vehicle)
    if type(vehicle) ~= 'number' or vehicle == 0 or not DoesEntityExist(vehicle) then
        return nil
    end

    return sanitize_plate(GetVehicleNumberPlateText(vehicle))
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

local function apply_broken_state(vehicle)
    local breakdown = get_client_breakdown_config()
    request_entity_control(vehicle, breakdown.control_timeout_ms)
    SetVehicleEngineHealth(vehicle, tonumber(breakdown.engine_health_broken) or -4000.0)
    SetVehicleEngineOn(vehicle, false, true, true)
    SetVehicleUndriveable(vehicle, true)
end

local function apply_repaired_state(vehicle)
    local breakdown = get_client_breakdown_config()
    request_entity_control(vehicle, breakdown.control_timeout_ms)
    SetVehicleEngineHealth(vehicle, tonumber(breakdown.engine_health_repaired) or 1000.0)
    SetVehicleUndriveable(vehicle, false)

    if GetPedInVehicleSeat(vehicle, -1) == PlayerPedId() then
        SetVehicleEngineOn(vehicle, true, true, false)
    end
end

local function apply_plate_state(plate, is_broken)
    local vehicles = GetGamePool('CVehicle')
    for index = 1, #vehicles do
        local vehicle = vehicles[index]
        if get_vehicle_plate(vehicle) == plate then
            if is_broken then
                apply_broken_state(vehicle)
            else
                apply_repaired_state(vehicle)
            end
        end
    end
end

local function ensure_control_thread()
    if control_thread_running then
        return
    end

    control_thread_running = true

    CreateThread(function()
        while next(broken_plates) ~= nil do
            local breakdown = get_client_breakdown_config()
            local player_ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(player_ped, false)
            local plate = get_vehicle_plate(vehicle)

            if vehicle ~= 0 and plate and broken_plates[plate] == true then
                apply_broken_state(vehicle)
                DisableControlAction(0, 59, true)
                DisableControlAction(0, 60, true)
                DisableControlAction(0, 63, true)
                DisableControlAction(0, 64, true)
                DisableControlAction(0, 71, true)
                DisableControlAction(0, 72, true)
                Wait(math.max(tonumber(breakdown.control_active_tick_ms) or 0, 0))
            else
                Wait(math.max(tonumber(breakdown.control_idle_check_ms) or 1000, 100))
            end
        end

        control_thread_running = false
    end)
end

RegisterNetEvent('sonar:farm:machinery:broke_down', function(payload)
    local plate = extract_plate(payload)
    if not plate then
        return
    end

    broken_plates[plate] = true
    apply_plate_state(plate, true)
    ensure_control_thread()

    local player_vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if player_vehicle ~= 0 and get_vehicle_plate(player_vehicle) == plate then
        lib.notify({
            description = locale('machinery.notify.broken_down'),
            type = 'warning',
        })
    end
end)

RegisterNetEvent('sonar:farm:machinery:repaired', function(payload)
    local plate = extract_plate(payload)
    if not plate then
        return
    end

    broken_plates[plate] = nil
    apply_plate_state(plate, false)
end)

AddEventHandler('onResourceStop', function(resource_name)
    if resource_name ~= GetCurrentResourceName() then
        return
    end

    for plate in pairs(broken_plates) do
        apply_plate_state(plate, false)
        broken_plates[plate] = nil
    end
end)
