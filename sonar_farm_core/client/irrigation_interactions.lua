local plot_zones = {}
local well_zones = {}
local plot_state = {}
local active_plot_states = {
    planted = true,
    germinating = true,
    growing = true,
    maturing = true,
}

local function get_interaction_config()
    return Config and Config.Farm and Config.Farm.Interactions or {}
end

local function get_animation_config()
    local interactions = get_interaction_config()
    return interactions.Animations or {}
end

local function get_progress_config()
    local interactions = get_interaction_config()
    return interactions.Progress or {}
end

local function get_irrigation_config()
    return Config and Config.Farm and Config.Farm.Irrigation or {}
end

local function ensure_anim_dict(anim_dict)
    if type(anim_dict) ~= 'string' or anim_dict == '' then
        return false
    end

    RequestAnimDict(anim_dict)
    local ticks = 0
    local max_ticks = 5000

    while not HasAnimDictLoaded(anim_dict) do
        if ticks >= max_ticks then
            return false
        end

        Wait(0)
        ticks = ticks + 1
    end

    return true
end

local function release_anim_dict(anim_dict)
    if type(anim_dict) == 'string' and anim_dict ~= '' then
        RemoveAnimDict(anim_dict)
    end
end

local function play_action_progress(action, label)
    local progress_config = get_progress_config()
    local animation_config = get_animation_config()
    local action_duration = tonumber(progress_config[action])
    if not action_duration then
        return false
    end

    local animation = animation_config[action] or {}
    local anim_dict = animation.dict
    local anim_clip = animation.clip
    if not ensure_anim_dict(anim_dict) then
        return false
    end

    local completed = lib.progressBar({
        duration = math.floor(action_duration),
        label = label,
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
            flag = tonumber(animation.flag) or 49,
        },
    })

    ClearPedTasks(PlayerPedId())
    release_anim_dict(anim_dict)

    return completed == true
end

local function get_plot_state(plot_id)
    return plot_state[plot_id]
end

local function refresh_plot_state(plots)
    plot_state = {}

    for index = 1, #plots do
        local plot = plots[index]
        plot_state[plot.plot_id] = plot.state
    end
end

local function get_water_tank_slots()
    if type(exports) ~= 'table' or not exports.ox_inventory then
        return {}
    end

    local ok, slots = pcall(function()
        return exports.ox_inventory:Search('slots', 'sonar_water_tank')
    end)

    if not ok or type(slots) ~= 'table' then
        return {}
    end

    return slots
end

local function has_water_tank_with_charges()
    local slots = get_water_tank_slots()
    local max_charges = tonumber(get_irrigation_config().tank_max_charges) or 0

    for index = 1, #slots do
        local metadata = type(slots[index].metadata) == 'table' and slots[index].metadata or {}
        local charges = tonumber(metadata.charges)
        if charges == nil then
            charges = max_charges
        end

        if charges > 0 then
            return true
        end
    end

    return false
end

local function has_refillable_tank()
    local slots = get_water_tank_slots()
    local max_charges = tonumber(get_irrigation_config().tank_max_charges) or 0

    for index = 1, #slots do
        local metadata = type(slots[index].metadata) == 'table' and slots[index].metadata or {}
        local charges = tonumber(metadata.charges)
        if charges == nil then
            charges = max_charges
        end

        if charges < max_charges then
            return true
        end
    end

    return false
end

local function get_error_message(reason)
    local key = 'irrigation.errors.' .. tostring(reason or 'unknown')
    local message = locale(key)
    if type(message) ~= 'string' or message == '' or message == key then
        return locale('irrigation.errors.unknown')
    end

    return message
end

local function notify_error(reason)
    lib.notify({
        description = get_error_message(reason),
        type = 'error',
    })
end

local function notify_success(response)
    local delta = math.abs(tonumber(response and response.delta) or 0)
    local result = type(response) == 'table' and response.result or 'watered'
    local key = result == 'overwater' and 'irrigation.notify.overwater' or 'irrigation.notify.watered'

    lib.notify({
        description = locale(key):gsub('{delta}', tostring(delta)),
        type = result == 'overwater' and 'warning' or 'success',
    })
end

local function water_plot(plot_id)
    if not play_action_progress('water', locale('irrigation.interaction.watering')) then
        return
    end

    local ok, response = pcall(function()
        return lib.callback.await('sonar:farm:plot:water', false, plot_id, 1)
    end)

    if not ok or type(response) ~= 'table' or response.ok ~= true then
        notify_error(type(response) == 'table' and response.error or 'unknown')
        return
    end

    notify_success(response)
end

local function refill_tank()
    if not play_action_progress('refill', locale('irrigation.interaction.refilling')) then
        return
    end

    local ok, response = pcall(function()
        return lib.callback.await('sonar:farm:plot:refill_tank', false)
    end)

    if not ok or type(response) ~= 'table' or response.ok ~= true then
        notify_error(type(response) == 'table' and response.error or 'unknown')
        return
    end

    lib.notify({
        description = locale('irrigation.notify.refilled'),
        type = 'success',
    })
end

local function build_plot_zone_options(plot)
    local plot_id = plot.plot_id

    return {
        {
            name = ('sonar_farm_plot_water_%s'):format(plot_id),
            icon = 'fas fa-droplet',
            label = locale('irrigation.interaction.water'),
            canInteract = function()
                return active_plot_states[get_plot_state(plot_id)] == true and has_water_tank_with_charges()
            end,
            onSelect = function()
                water_plot(plot_id)
            end,
        },
    }
end

local function clear_plot_zones()
    if type(exports) ~= 'table' or not exports.ox_target then
        plot_zones = {}
        return
    end

    for plot_id, zone_id in pairs(plot_zones) do
        if zone_id then
            exports.ox_target:removeZone(zone_id)
        end
        plot_zones[plot_id] = nil
    end
end

local function clear_well_zones()
    if type(exports) ~= 'table' or not exports.ox_target then
        well_zones = {}
        return
    end

    for index, zone_id in pairs(well_zones) do
        if zone_id then
            exports.ox_target:removeZone(zone_id)
        end
        well_zones[index] = nil
    end
end

local function register_plot_zones(plots)
    if type(exports) ~= 'table' or not exports.ox_target then
        return false
    end

    clear_plot_zones()

    for index = 1, #plots do
        local plot = plots[index]
        local zone_id = exports.ox_target:addSphereZone({
            coords = vec3(tonumber(plot.coords_x) or 0.0, tonumber(plot.coords_y) or 0.0, tonumber(plot.coords_z) or 0.0),
            radius = tonumber(plot.radius) or 1.0,
            debug = false,
            options = build_plot_zone_options(plot),
        })

        plot_zones[plot.plot_id] = zone_id
    end

    return true
end

local function register_well_zones()
    if type(exports) ~= 'table' or not exports.ox_target then
        return false
    end

    clear_well_zones()

    local wells = get_irrigation_config().well_coords or {}
    for index = 1, #wells do
        local well = wells[index]
        well_zones[index] = exports.ox_target:addSphereZone({
            coords = vec3(tonumber(well.x) or 0.0, tonumber(well.y) or 0.0, tonumber(well.z) or 0.0),
            radius = tonumber(well.radius) or 2.0,
            debug = false,
            options = {
                {
                    name = ('sonar_farm_irrigation_refill_%s'):format(index),
                    icon = 'fas fa-fill-drip',
                    label = locale('irrigation.interaction.refill'),
                    canInteract = function()
                        return has_refillable_tank()
                    end,
                    onSelect = function()
                        refill_tank()
                    end,
                },
            },
        })
    end

    return true
end

local function load_plots()
    local ok, plots = pcall(function()
        return lib.callback.await('sonar:farm:plot:list', false)
    end)

    if not ok or type(plots) ~= 'table' then
        return false
    end

    refresh_plot_state(plots)
    register_well_zones()
    return register_plot_zones(plots)
end

RegisterNetEvent('sonar:farm:plot:state_changed', function(payload)
    if type(payload) ~= 'table' then
        return
    end

    if type(payload.plot_id) ~= 'string' or payload.plot_id == '' then
        return
    end

    if type(payload.next_state) == 'string' and payload.next_state ~= '' then
        plot_state[payload.plot_id] = payload.next_state
    end
end)

RegisterNetEvent('sonar:farm:plot:watered', function(payload)
    if type(payload) ~= 'table' or type(payload.plot_id) ~= 'string' or payload.plot_id == '' then
        return
    end

    lib.notify({
        description = locale('irrigation.interaction.watering'),
        type = 'inform',
        duration = 1000,
    })
end)

AddEventHandler('onClientResourceStart', function(resource_name)
    if resource_name ~= GetCurrentResourceName() then
        return
    end

    CreateThread(function()
        local retry_count = Config.Farm.Client.Startup.RetryCount or 10
        local retry_wait = Config.Farm.Client.Startup.RetryWaitMs or 1000
        for _ = 1, retry_count do
            if load_plots() then
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

    clear_plot_zones()
    clear_well_zones()
end)
