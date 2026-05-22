local plot_zones = {}
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

local function get_item_tools()
    local items = Config and Config.Farm and Config.Farm.Items or {}
    return items.tools or {}
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

local function get_fertilizer_item_names()
    local tools = get_item_tools()
    local names = {}

    for item_name, _ in pairs(tools) do
        if type(item_name) == 'string' and item_name:match('^sonar_fertilizer_') then
            names[#names + 1] = item_name
        end
    end

    table.sort(names)
    return names
end

local function get_fertilizer_counts()
    if type(exports) ~= 'table' or not exports.ox_inventory then
        return {}
    end

    local item_names = get_fertilizer_item_names()
    local ok, counts = pcall(function()
        return exports.ox_inventory:Search('count', item_names)
    end)

    if not ok or type(counts) ~= 'table' then
        return {}
    end

    return counts
end

local function has_any_fertilizer()
    local counts = get_fertilizer_counts()
    for _, count in pairs(counts) do
        if (tonumber(count) or 0) > 0 then
            return true
        end
    end

    return false
end

local function get_error_message(reason)
    local key = 'fertilization.errors.' .. tostring(reason or 'unknown')
    local message = locale(key)
    if type(message) ~= 'string' or message == '' or message == key then
        return locale('fertilization.errors.unknown')
    end

    return message
end

local function notify_result(response)
    local result = type(response) == 'table' and response.result or 'wrong'
    local delta = math.abs(tonumber(response and response.delta) or 0)
    local key = 'fertilization.notify.' .. tostring(result)
    local message = locale(key)
    if type(message) ~= 'string' or message == '' or message == key then
        message = locale('fertilization.notify.wrong')
    end

    lib.notify({
        description = message:gsub('{delta}', tostring(delta)),
        type = result == 'wrong' and 'warning' or 'success',
    })
end

local function get_available_fertilizer_options()
    local counts = get_fertilizer_counts()
    local options = {}

    for _, item_name in ipairs(get_fertilizer_item_names()) do
        local count = tonumber(counts[item_name]) or 0
        if count > 0 then
            options[#options + 1] = {
                value = item_name,
                label = ('%s (%d)'):format(locale(('items.%s.label'):format(item_name)), count),
            }
        end
    end

    if #options == 1 then
        return options[1].value
    end

    if #options == 0 then
        return nil
    end

    local result = lib.inputDialog(locale('fertilization.interaction.select_title'), {
        {
            type = 'select',
            label = locale('fertilization.interaction.select_label'),
            required = true,
            options = options,
            default = options[1].value,
        },
    })

    if type(result) ~= 'table' then
        return nil
    end

    return result[1]
end

local function fertilize_plot(plot_id)
    local selected_item = get_available_fertilizer_options()
    if type(selected_item) ~= 'string' or selected_item == '' then
        return
    end

    if not play_action_progress('fertilize', locale('fertilization.interaction.applying')) then
        return
    end

    local ok, response = pcall(function()
        return lib.callback.await('sonar:farm:plot:fertilize', false, plot_id, selected_item)
    end)

    if not ok or type(response) ~= 'table' or response.ok ~= true then
        lib.notify({
            description = get_error_message(type(response) == 'table' and response.error or 'unknown'),
            type = 'error',
        })
        return
    end

    notify_result(response)
end

local function build_plot_zone_options(plot)
    local plot_id = plot.plot_id

    return {
        {
            name = ('sonar_farm_plot_fertilize_%s'):format(plot_id),
            icon = 'fas fa-seedling',
            label = locale('fertilization.interaction.apply'),
            canInteract = function()
                return active_plot_states[get_plot_state(plot_id)] == true and has_any_fertilizer()
            end,
            onSelect = function()
                fertilize_plot(plot_id)
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
end)
