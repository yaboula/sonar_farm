local plot_zones = {}
local plot_state = {}

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

local function has_seed_wheat()
    if type(exports) ~= 'table' or not exports.ox_inventory then
        return false
    end

    local ok, count_or_error = pcall(function()
        return exports.ox_inventory:Search('count', 'sonar_seed_wheat')
    end)

    if not ok then
        return false
    end

    return (tonumber(count_or_error) or 0) > 0
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

    local success = lib.progressBar({
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

    return success == true
end

local function refresh_plot_state(plots)
    plot_state = {}
    for index = 1, #plots do
        local plot = plots[index]
        plot_state[plot.plot_id] = plot.state
    end
end

local function get_plot_state(plot_id)
    return plot_state[plot_id]
end

local function plant_wheat(plot_id)
    if not play_action_progress('plant', locale('plots.interaction.plant_wheat')) then
        return
    end

    local ok, response = pcall(function()
        return lib.callback.await('sonar:farm:plot:plant', false, plot_id)
    end)

    if not ok or type(response) ~= 'table' then
        return
    end

    if response.ok == true then
        local crop = response.data
        local stage = crop and tonumber(crop.stage) or 0
        if stage == 0 then
            plot_state[plot_id] = 'planted'
        end
    end
end

local function harvest_plot(plot_id)
    if not play_action_progress('harvest', locale('plots.interaction.harvest')) then
        return
    end

    local ok, response = pcall(function()
        return lib.callback.await('sonar:farm:plot:harvest', false, plot_id)
    end)

    if not ok or type(response) ~= 'table' then
        return
    end

    if response.ok == true then
        plot_state[plot_id] = 'cooldown'

        if response.data and type(response.data.metadata) == 'table' then
            TriggerEvent('sonar:farm:inventory:batch_tooltip', response.data.metadata)
        end
    end
end

local function build_zone_options(plot_id)
    return {
        {
            name = ('sonar_farm_plot_plant_%s'):format(plot_id),
            icon = 'fas fa-seedling',
            label = locale('plots.interaction.plant_wheat'),
            canInteract = function()
                return get_plot_state(plot_id) == 'fallow' and has_seed_wheat()
            end,
            onSelect = function()
                plant_wheat(plot_id)
            end,
        },
        {
            name = ('sonar_farm_plot_harvest_%s'):format(plot_id),
            icon = 'fas fa-wheat-awn',
            label = locale('plots.interaction.harvest'),
            canInteract = function()
                return get_plot_state(plot_id) == 'harvest_ready'
            end,
            onSelect = function()
                harvest_plot(plot_id)
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

local function register_plot_zones(plots)
    if type(exports) ~= 'table' or not exports.ox_target then
        return false
    end

    clear_plot_zones()

    for index = 1, #plots do
        local plot = plots[index]
        local x = tonumber(plot.coords_x) or 0.0
        local y = tonumber(plot.coords_y) or 0.0
        local z = tonumber(plot.coords_z) or 0.0

        local zone_id = exports.ox_target:addSphereZone({
            coords = vec3(x, y, z),
            radius = tonumber(plot.radius) or 1.0,
            debug = false,
            options = build_zone_options(plot.plot_id),
        })

        plot_zones[plot.plot_id] = zone_id
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

AddEventHandler('onClientResourceStart', function(resource_name)
    if resource_name ~= GetCurrentResourceName() then
        return
    end

    CreateThread(function()
        for _ = 1, 10 do
            if load_plots() then
                return
            end

            Wait(1000)
        end
    end)
end)

AddEventHandler('onResourceStop', function(resource_name)
    if resource_name ~= GetCurrentResourceName() then
        return
    end

    clear_plot_zones()
end)
