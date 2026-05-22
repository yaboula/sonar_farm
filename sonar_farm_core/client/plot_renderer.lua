local CROP_TYPE = 'wheat'

local plot_entities = {}
local plot_coords = {}

local function get_render_config()
    return Config and Config.Farm and Config.Farm.Rendering or {}
end

local function get_crop_config()
    local crops = Config and Config.Farm and Config.Farm.Crops or nil
    return crops and crops[CROP_TYPE] or nil
end

local function get_stage_config(stage)
    local crop_config = get_crop_config()
    if not crop_config or type(crop_config.stages) ~= 'table' then
        return nil
    end

    return crop_config.stages[stage]
end

local function get_cooldown_config()
    local verified_props = Config and Config.Farm and Config.Farm.VerifiedProps or nil
    local wheat_props = verified_props and verified_props[CROP_TYPE] or nil
    return wheat_props and wheat_props.cooldown or nil
end

local function get_plot_coords(plot_id)
    return plot_coords[plot_id]
end

local function remember_plot_coords(plot)
    if type(plot) ~= 'table' or type(plot.plot_id) ~= 'string' or plot.plot_id == '' then
        return
    end

    local current = plot_coords[plot.plot_id] or {}

    plot_coords[plot.plot_id] = {
        x = tonumber(plot.coords_x) or 0.0,
        y = tonumber(plot.coords_y) or 0.0,
        z = tonumber(plot.coords_z) or 0.0,
        heading = tonumber(plot.heading) or tonumber(current.heading) or 0.0,
    }
end

local function load_model(model_hash)
    if type(model_hash) ~= 'number' then
        return false
    end

    RequestModel(model_hash)
    local ticks = 0
    local max_ticks = 5000

    while not HasModelLoaded(model_hash) do
        if ticks >= max_ticks then
            return false
        end

        Wait(0)
        ticks = ticks + 1
    end

    return true
end

local function despawn_plot_prop(plot_id)
    local entity = plot_entities[plot_id]
    if entity and DoesEntityExist(entity) then
        DeleteObject(entity)
    end

    plot_entities[plot_id] = nil
end

local function spawn_plot_prop(plot_id, stage)
    local stage_config = get_stage_config(stage)
    local coords = get_plot_coords(plot_id)
    if not stage_config or not coords then
        return false
    end

    local model_hash = tonumber(stage_config.prop_hash) or GetHashKey(stage_config.prop_name or '')
    if not load_model(model_hash) then
        return false
    end

    despawn_plot_prop(plot_id)

    local z_offset = tonumber(stage_config.prop_z_offset) or 0.0
    local entity = CreateObjectNoOffset(model_hash, coords.x, coords.y, coords.z + z_offset, false, false, false)
    if entity == 0 then
        SetModelAsNoLongerNeeded(model_hash)
        return false
    end

    -- SetEntityScale is not a native FiveM function - disabled for now
    -- if scale and scale > 0 then
    --     SetEntityScale(entity, scale)
    -- end

    SetEntityAsMissionEntity(entity, true, true)
    SetEntityHeading(entity, tonumber(coords.heading) or 0.0)
    FreezeEntityPosition(entity, true)

    -- SetEntityDistanceCullingRadius is not a native FiveM function - disabled
    -- local culling_radius = tonumber(get_render_config().PlotPropCullingRadius) or 250.0
    -- SetEntityDistanceCullingRadius(entity, culling_radius)

    plot_entities[plot_id] = entity
    SetModelAsNoLongerNeeded(model_hash)

    return true
end

local function spawn_cooldown_prop(plot_id)
    local stage_config = get_cooldown_config()
    local coords = get_plot_coords(plot_id)
    if not stage_config or not coords then
        return false
    end

    local model_hash = tonumber(stage_config.prop_hash) or GetHashKey(stage_config.prop_name or '')
    if not load_model(model_hash) then
        return false
    end

    despawn_plot_prop(plot_id)

    local z_offset = tonumber(stage_config.prop_z_offset) or 0.0
    local entity = CreateObjectNoOffset(model_hash, coords.x, coords.y, coords.z + z_offset, false, false, false)
    if entity == 0 then
        SetModelAsNoLongerNeeded(model_hash)
        return false
    end

    SetEntityAsMissionEntity(entity, true, true)
    SetEntityHeading(entity, tonumber(coords.heading) or 0.0)
    FreezeEntityPosition(entity, true)

    plot_entities[plot_id] = entity
    SetModelAsNoLongerNeeded(model_hash)

    return true
end

local function play_harvest_fx(plot_id)
    local coords = get_plot_coords(plot_id)
    if not coords then
        return
    end

    local fx_asset = 'core'
    local fx_name = 'ent_dst_wood_splinter'
    local fx_duration = tonumber(get_render_config().HarvestFxDurationMs) or 900

    RequestNamedPtfxAsset(fx_asset)
    local ticks = 0
    local max_ticks = 2500

    while not HasNamedPtfxAssetLoaded(fx_asset) do
        if ticks >= max_ticks then
            return
        end

        Wait(0)
        ticks = ticks + 1
    end

    UseParticleFxAssetNextCall(fx_asset)
    local handle = StartParticleFxLoopedAtCoord(fx_name, coords.x, coords.y, coords.z + 0.1, 0.0, 0.0, 0.0, 0.35, false, false, false, false)

    CreateThread(function()
        Wait(math.floor(fx_duration))
        if handle then
            StopParticleFxLooped(handle, false)
        end

        RemoveNamedPtfxAsset(fx_asset)
    end)
end

local function sync_plot_coords()
    local seed = Config and Config.Farm and Config.Farm.Plots and Config.Farm.Plots.Seed or {}
    for index = 1, #seed do
        remember_plot_coords(seed[index])
    end

    local ok, plots = pcall(function()
        return lib.callback.await('sonar:farm:plot:list', false)
    end)

    if not ok or type(plots) ~= 'table' then
        return
    end

    for index = 1, #plots do
        remember_plot_coords(plots[index])
    end
end

local function sync_active_props()
    local ok, active_crops = pcall(function()
        return lib.callback.await('sonar:farm:plot:active_crops', false)
    end)

    if not ok or type(active_crops) ~= 'table' then
        return
    end

    for index = 1, #active_crops do
        local crop = active_crops[index]
        if crop and crop.crop_type == CROP_TYPE then
            local stage = tonumber(crop.stage) or 0
            spawn_plot_prop(crop.plot_id, stage)
        end
    end
end

local function sync_cooldown_props()
    local ok, plots = pcall(function()
        return lib.callback.await('sonar:farm:plot:list', false)
    end)

    if not ok or type(plots) ~= 'table' then
        return
    end

    for index = 1, #plots do
        local plot = plots[index]
        if plot and plot.state == 'cooldown' then
            spawn_cooldown_prop(plot.plot_id)
        end
    end
end

local function clear_all_props()
    for plot_id, _ in pairs(plot_entities) do
        despawn_plot_prop(plot_id)
    end
end

RegisterNetEvent('sonar:farm:plot:planted', function(payload)
    if type(payload) ~= 'table' or payload.crop_type ~= CROP_TYPE then
        return
    end

    local stage = tonumber(payload.stage) or 0
    spawn_plot_prop(payload.plot_id, stage)
end)

RegisterNetEvent('sonar:farm:plot:stage_advanced', function(payload)
    if type(payload) ~= 'table' or payload.crop_type ~= CROP_TYPE then
        return
    end

    local next_stage = tonumber(payload.next_stage)
    if not next_stage then
        return
    end

    spawn_plot_prop(payload.plot_id, next_stage)
end)

RegisterNetEvent('sonar:farm:plot:harvested', function(payload)
    if type(payload) ~= 'table' then
        return
    end

    despawn_plot_prop(payload.plot_id)
    play_harvest_fx(payload.plot_id)
end)

RegisterNetEvent('sonar:farm:plot:state_changed', function(payload)
    if type(payload) ~= 'table' then
        return
    end

    if payload.next_state == 'cooldown' then
        spawn_cooldown_prop(payload.plot_id)
        return
    end

    if payload.next_state == 'fallow' then
        despawn_plot_prop(payload.plot_id)
    end
end)

AddEventHandler('onClientResourceStart', function(resource_name)
    if resource_name ~= GetCurrentResourceName() then
        return
    end

    sync_plot_coords()
    sync_active_props()
    sync_cooldown_props()
end)

AddEventHandler('onResourceStop', function(resource_name)
    if resource_name ~= GetCurrentResourceName() then
        return
    end

    clear_all_props()
end)
