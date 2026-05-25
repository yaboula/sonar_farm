local function get_machinery_config()
    return Config and Config.Farm and Config.Farm.Machinery or {}
end

local function get_tracking_config()
    local machinery = get_machinery_config()
    local client = machinery.Client or {}
    return client.Tracking or {}
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
        return false, nil
    end

    return true, model_name
end

local function flush_usage(plate, amount, model_name)
    local ok, response = pcall(function()
        return lib.callback.await('sonar:farm:machinery:report_usage', false, plate, amount, model_name)
    end)

    return ok and type(response) == 'table' and response.ok == true
end

local pending_usage = {}

local function get_pending_usage(plate, model_name)
    local pending = pending_usage[plate]
    if type(pending) ~= 'table' then
        pending = {
            seconds = 0,
            distance = 0.0,
            model_name = model_name,
        }
        pending_usage[plate] = pending
    end

    if type(model_name) == 'string' and model_name ~= '' then
        pending.model_name = model_name
    end

    return pending
end

CreateThread(function()
    local tracking = get_tracking_config()
    local sample_interval_ms = math.max(tonumber(tracking.sample_interval_ms) or 10000, 1000)
    local report_interval_seconds = math.max(tonumber(tracking.report_interval_seconds) or 60, 1)
    local min_movement_distance_m = math.max(tonumber(tracking.min_movement_distance_m) or 1.0, 0.0)

    local active_vehicle = nil
    local active_plate = nil
    local active_model = nil
    local last_coords = nil
    local active_usage = nil

    while true do
        local player_ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(player_ped, false)

        if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == player_ped then
            local valid, model_name = is_valid_machinery(vehicle)
            local plate = get_vehicle_plate(vehicle)

            if valid and plate then
                local coords = GetEntityCoords(vehicle)

                if vehicle ~= active_vehicle or plate ~= active_plate then
                    active_vehicle = vehicle
                    active_plate = plate
                    active_model = model_name
                    active_usage = get_pending_usage(plate, model_name)
                    last_coords = coords
                else
                    local moved_distance = #(coords - last_coords)
                    last_coords = coords

                    if moved_distance >= min_movement_distance_m then
                        active_usage.seconds = active_usage.seconds + math.floor(sample_interval_ms / 1000)
                        active_usage.distance = active_usage.distance + moved_distance
                    end

                    if active_usage.seconds >= report_interval_seconds and active_usage.distance >= min_movement_distance_m then
                        if flush_usage(active_plate, active_usage.seconds, active_usage.model_name or active_model) then
                            active_usage.seconds = 0
                            active_usage.distance = 0.0
                        end
                    end
                end

                Wait(sample_interval_ms)
            else
                active_vehicle = nil
                active_plate = nil
                active_model = nil
                last_coords = nil
                active_usage = nil
                Wait(sample_interval_ms)
            end
        else
            active_vehicle = nil
            active_plate = nil
            active_model = nil
            last_coords = nil
            active_usage = nil
            Wait(sample_interval_ms)
        end
    end
end)
