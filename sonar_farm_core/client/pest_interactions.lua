local plot_zones = {}
local plot_state = {}
local plot_coords = {}
local pest_status = {}
local pest_particles = {}
local active_plot_states = {
    planted = true,
    germinating = true,
    growing = true,
    maturing = true,
}
local PARTICLE_DICT = 'core'
local PARTICLE_EFFECT = 'exp_grd_bzgas_cloud'

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

local function refresh_plots(plots)
    plot_state = {}
    plot_coords = {}

    for index = 1, #plots do
        local plot = plots[index]
        plot_state[plot.plot_id] = plot.state
        plot_coords[plot.plot_id] = vec3(
            tonumber(plot.coords_x) or 0.0,
            tonumber(plot.coords_y) or 0.0,
            tonumber(plot.coords_z) or 0.0
        )
    end
end

local function get_plot_state(plot_id)
    return plot_state[plot_id]
end

local function has_pesticide()
    if type(exports) ~= 'table' or not exports.ox_inventory then
        return false
    end

    local ok, counts = pcall(function()
        return exports.ox_inventory:Search('count', {
            'sonar_pesticide_contact',
            'sonar_pesticide_systemic',
        })
    end)

    if not ok or type(counts) ~= 'table' then
        return false
    end

    return (tonumber(counts.sonar_pesticide_contact) or 0) > 0 or (tonumber(counts.sonar_pesticide_systemic) or 0) > 0
end

local function get_pesticide_options()
    if type(exports) ~= 'table' or not exports.ox_inventory then
        return nil
    end

    local ok, counts = pcall(function()
        return exports.ox_inventory:Search('count', {
            'sonar_pesticide_contact',
            'sonar_pesticide_systemic',
        })
    end)

    if not ok or type(counts) ~= 'table' then
        return nil
    end

    local options = {}
    if (tonumber(counts.sonar_pesticide_contact) or 0) > 0 then
        options[#options + 1] = {
            value = 'sonar_pesticide_contact',
            label = ('%s (%d)'):format(locale('items.sonar_pesticide_contact.label'), tonumber(counts.sonar_pesticide_contact) or 0),
        }
    end

    if (tonumber(counts.sonar_pesticide_systemic) or 0) > 0 then
        options[#options + 1] = {
            value = 'sonar_pesticide_systemic',
            label = ('%s (%d)'):format(locale('items.sonar_pesticide_systemic.label'), tonumber(counts.sonar_pesticide_systemic) or 0),
        }
    end

    if #options == 0 then
        return nil
    end

    if #options == 1 then
        return options[1].value
    end

    local result = lib.inputDialog(locale('pest.interaction.select_title'), {
        {
            type = 'select',
            label = locale('pest.interaction.select_label'),
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

local function get_error_message(reason)
    local key = 'pest.errors.' .. tostring(reason or 'unknown')
    local message = locale(key)
    if type(message) ~= 'string' or message == '' or message == key then
        return locale('pest.errors.unknown')
    end

    return message
end

local function ensure_particle_assets()
    RequestNamedPtfxAsset(PARTICLE_DICT)
    local ticks = 0
    while not HasNamedPtfxAssetLoaded(PARTICLE_DICT) do
        if ticks >= 5000 then
            return false
        end

        Wait(0)
        ticks = ticks + 1
    end

    return true
end

local function stop_particle(plot_id)
    local handle = pest_particles[plot_id]
    if handle then
        StopParticleFxLooped(handle, false)
        pest_particles[plot_id] = nil
    end
end

local function spawn_particle(plot_id)
    local coords = plot_coords[plot_id]
    if not coords or pest_particles[plot_id] then
        return
    end

    if not ensure_particle_assets() then
        return
    end

    UseParticleFxAssetNextCall(PARTICLE_DICT)
    pest_particles[plot_id] = StartParticleFxLoopedAtCoord(
        PARTICLE_EFFECT,
        coords.x,
        coords.y,
        coords.z + 0.2,
        0.0,
        0.0,
        0.0,
        0.8,
        false,
        false,
        false,
        false
    )
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

local function clear_all_particles()
    for plot_id, _ in pairs(pest_particles) do
        stop_particle(plot_id)
    end
end

local function sync_active_pests()
    local ok, active_pests = pcall(function()
        return lib.callback.await('sonar:farm:pest:get_active', false)
    end)

    if not ok or type(active_pests) ~= 'table' then
        return
    end

    for index = 1, #active_pests do
        local pest = active_pests[index]
        if type(pest) == 'table' and type(pest.plot_id) == 'string' and pest.plot_id ~= '' then
            pest_status[pest.plot_id] = {
                severity = pest.pest_severity,
                detected_ts = tonumber(pest.pest_detected_ts),
            }
            spawn_particle(pest.plot_id)
        end
    end
end

local function treat_pest(plot_id)
    local selected_item = get_pesticide_options()
    if type(selected_item) ~= 'string' or selected_item == '' then
        return
    end

    local status_ok, current_status = pcall(function()
        return lib.callback.await('sonar:farm:pest:get_status', false, plot_id)
    end)
    if not status_ok or type(current_status) ~= 'table' then
        lib.notify({
            description = locale('pest.notify.no_pest'),
            type = 'error',
        })
        return
    end

    if not play_action_progress('treat_pest', locale('pest.interaction.treating')) then
        return
    end

    local ok, response = pcall(function()
        return lib.callback.await('sonar:farm:plot:treat_pest', false, plot_id, selected_item)
    end)

    if not ok or type(response) ~= 'table' or response.ok ~= true then
        lib.notify({
            description = get_error_message(type(response) == 'table' and response.error or 'unknown'),
            type = 'error',
        })
        return
    end

    pest_status[plot_id] = nil
    stop_particle(plot_id)

    lib.notify({
        description = locale('pest.notify.treated'):gsub('{delta}', tostring(math.abs(tonumber(response.delta) or 0))),
        type = 'success',
    })
end

local function build_plot_zone_options(plot)
    local plot_id = plot.plot_id

    return {
        {
            name = ('sonar_farm_plot_treat_pest_%s'):format(plot_id),
            icon = 'fas fa-bug-slash',
            label = locale('pest.interaction.treat'),
            canInteract = function()
                return active_plot_states[get_plot_state(plot_id)] == true and pest_status[plot_id] ~= nil and has_pesticide()
            end,
            onSelect = function()
                treat_pest(plot_id)
            end,
        },
    }
end

local function register_plot_zones(plots)
    if type(exports) ~= 'table' or not exports.ox_target then
        return false
    end

    clear_plot_zones()

    for index = 1, #plots do
        local plot = plots[index]
        local zone_id = exports.ox_target:addSphereZone({
            coords = plot_coords[plot.plot_id],
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

    refresh_plots(plots)
    sync_active_pests()
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

RegisterNetEvent('sonar:farm:pest:appeared', function(payload)
    if type(payload) ~= 'table' or type(payload.plot_id) ~= 'string' or payload.plot_id == '' then
        return
    end

    pest_status[payload.plot_id] = {
        severity = payload.severity,
        detected_ts = tonumber(payload.detected_ts),
    }
    spawn_particle(payload.plot_id)
end)

RegisterNetEvent('sonar:farm:pest:treated', function(payload)
    if type(payload) ~= 'table' or type(payload.plot_id) ~= 'string' or payload.plot_id == '' then
        return
    end

    pest_status[payload.plot_id] = nil
    stop_particle(payload.plot_id)
end)

RegisterNetEvent('sonar:farm:pest:severe', function(payload)
    if type(payload) ~= 'table' or type(payload.plot_id) ~= 'string' or payload.plot_id == '' then
        return
    end

    pest_status[payload.plot_id] = pest_status[payload.plot_id] or {}
    pest_status[payload.plot_id].severity = 'severe'

    lib.notify({
        description = locale('pest.notify.severe'),
        type = 'warning',
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
    clear_all_particles()
end)
