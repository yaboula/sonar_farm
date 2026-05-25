local spawned_buyers = {}

local function is_debug_enabled()
    return Config and Config.Farm and Config.Farm.Debug == true
end

local function log_debug(message)
    if is_debug_enabled() then
        print(('[sonar_farm_core][npc_spawner][DEBUG] %s'):format(message))
    end
end

local function log_error(message)
    print(('[sonar_farm_core][npc_spawner][ERROR] %s'):format(message))
end

local function format_locale_message(key, replacements)
    local message = locale(key)
    if type(message) ~= 'string' then
        return ''
    end

    if type(replacements) ~= 'table' then
        return message
    end

    for token, value in pairs(replacements) do
        message = message:gsub('{' .. token .. '}', tostring(value))
    end

    return message
end

local function format_money(amount)
    return ('%.2f'):format(tonumber(amount) or 0)
end

local function get_client_npc_config()
    return Config and Config.Farm and Config.Farm.Client and Config.Farm.Client.NPCVendor or {}
end

local function get_buyer_display_name(buyer)
    local display_name_key = type(buyer) == 'table' and buyer.display_name_key or nil
    local display_name = type(display_name_key) == 'string' and locale(display_name_key) or nil

    if type(display_name) ~= 'string' or display_name == '' or display_name == display_name_key then
        return tostring(display_name_key or '')
    end

    return display_name
end

local function normalize_buyer_coords(buyer)
    local coords = type(buyer) == 'table' and buyer.coords or nil
    if coords ~= nil and tonumber(coords.x) ~= nil and tonumber(coords.y) ~= nil and tonumber(coords.z) ~= nil then
        return {
            x = tonumber(coords.x) or 0.0,
            y = tonumber(coords.y) or 0.0,
            z = tonumber(coords.z) or 0.0,
            w = tonumber(coords.w) or tonumber(buyer.heading) or 0.0,
        }
    end

    local world_coords = type(buyer) == 'table' and buyer.world_coords or nil
    return {
        x = tonumber(world_coords and world_coords.x) or 0.0,
        y = tonumber(world_coords and world_coords.y) or 0.0,
        z = tonumber(world_coords and world_coords.z) or 0.0,
        w = tonumber(type(buyer) == 'table' and buyer.heading) or 0.0,
    }
end

local function ensure_model(model_name)
    if type(model_name) ~= 'string' or model_name == '' then
        return nil
    end

    local model_hash = joaat(model_name)
    if not IsModelInCdimage(model_hash) then
        return nil
    end

    RequestModel(model_hash)

    local deadline = GetGameTimer() + (tonumber(get_client_npc_config().ModelLoadDeadlineMs) or 5000)
    while not HasModelLoaded(model_hash) do
        if GetGameTimer() >= deadline then
            return nil
        end

        Wait(0)
    end

    return model_hash
end

local function get_player_batch_slots(item_name)
    if type(exports) ~= 'table' or not exports.ox_inventory then
        return {}
    end

    local ok, slots = pcall(function()
        return exports.ox_inventory:Search('slots', item_name)
    end)

    if not ok or type(slots) ~= 'table' then
        return {}
    end

    return slots
end

local function has_any_slots(slots)
    return type(slots) == 'table' and next(slots) ~= nil
end

local function has_sellable_batch(buyer)
    local accepted_crops = type(buyer) == 'table' and buyer.accepted_crops or {}

    for index = 1, #accepted_crops do
        local item_name = 'sonar_batch_' .. tostring(accepted_crops[index])
        local slots = get_player_batch_slots(item_name)
        if has_any_slots(slots) then
            return true
        end
    end

    return false
end

local function find_first_batch_id(buyer)
    local accepted_crops = type(buyer) == 'table' and buyer.accepted_crops or {}

    for index = 1, #accepted_crops do
        local item_name = 'sonar_batch_' .. tostring(accepted_crops[index])
        local slots = get_player_batch_slots(item_name)

        for _, slot in pairs(slots) do
            if type(slot) == 'table' and type(slot.metadata) == 'table' then
                local batch_id = tostring(slot.metadata.batch_id or '')
                if batch_id ~= '' then
                    return batch_id
                end
            end
        end
    end

    return nil
end

local function clear_spawned_buyers()
    if type(exports) == 'table' and exports.ox_target then
        for _, buyer_state in pairs(spawned_buyers) do
            if type(buyer_state) == 'table' and buyer_state.ped then
                exports.ox_target:removeLocalEntity(buyer_state.ped, buyer_state.option_names)
            end
        end
    end

    for buyer_id, buyer_state in pairs(spawned_buyers) do
        if type(buyer_state) == 'table' and buyer_state.blip and DoesBlipExist(buyer_state.blip) then
            RemoveBlip(buyer_state.blip)
        end

        if type(buyer_state) == 'table' and buyer_state.ped and DoesEntityExist(buyer_state.ped) then
            DeletePed(buyer_state.ped)
        end

        spawned_buyers[buyer_id] = nil
    end
end

local function get_sale_error_message(reason)
    local key = 'sale.errors.' .. tostring(reason or 'unknown')
    local message = locale(key)
    if type(message) ~= 'string' or message == '' or message == key then
        return locale('sale.errors.unknown')
    end

    return message
end

local function execute_sale(buyer_id, buyer)
    local batch_id = find_first_batch_id(buyer)
    if not batch_id then
        lib.notify({
            description = format_locale_message('sale.notify.error', { reason = get_sale_error_message('batch_not_in_inventory') }),
            type = 'error',
        })
        return
    end

    local completed = lib.progressBar({
        duration = tonumber(get_client_npc_config().SaleProgressDurationMs) or 3000,
        label = locale('sale.interaction.unloading'),
        canCancel = true,
        useWhileDead = false,
        disable = {
            move = false,
            car = true,
            combat = true,
            sprint = true,
        },
    })

    if completed ~= true then
        return
    end

    local ok, response = pcall(function()
        return lib.callback.await('sonar:farm:sale:sell', false, buyer_id, batch_id)
    end)

    if not ok or type(response) ~= 'table' or response.ok ~= true then
        local reason = type(response) == 'table' and tostring(response.error or 'sale_failed') or 'sale_failed'
        lib.notify({
            description = format_locale_message('sale.notify.error', { reason = get_sale_error_message(reason) }),
            type = 'error',
        })
        return
    end

    local payout = tonumber(response.payout or (type(response.data) == 'table' and response.data.payout) or 0) or 0

    lib.notify({
        description = format_locale_message('sale.notify.success', {
            amount = format_money(payout),
            buyer = get_buyer_display_name(buyer),
        }),
        type = 'success',
        duration = tonumber(get_client_npc_config().SuccessNotifyDurationMs) or 5000,
    })
end

local function create_buyer_blip(buyer)
    local blip_config = type(buyer) == 'table' and buyer.blip or nil
    if type(blip_config) ~= 'table' then
        return nil
    end

    local coords = normalize_buyer_coords(buyer)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    if not blip or blip == 0 then
        return nil
    end

    SetBlipSprite(blip, tonumber(blip_config.sprite) or 1)
    SetBlipColour(blip, tonumber(blip_config.color) or 0)
    SetBlipScale(blip, tonumber(blip_config.scale) or 0.8)
    SetBlipDisplay(blip, 4)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(get_buyer_display_name(buyer))
    EndTextCommandSetBlipName(blip)

    return blip
end

local function spawn_buyer_ped(buyer_id, buyer)
    local model_hash = ensure_model(buyer.ped_model)
    if not model_hash then
        log_error(('failed to load buyer model for %s (%s)'):format(tostring(buyer_id), tostring(buyer.ped_model)))
        return false
    end

    local coords = normalize_buyer_coords(buyer)
    local ped = CreatePed(4, model_hash, coords.x, coords.y, coords.z, coords.w, false, true)

    if not ped or ped == 0 or not DoesEntityExist(ped) then
        SetModelAsNoLongerNeeded(model_hash)
        log_error(('failed to create buyer ped for %s at %.2f %.2f %.2f'):format(tostring(buyer_id), coords.x, coords.y, coords.z))
        return false
    end

    SetEntityInvincible(ped, true)
    SetEntityHeading(ped, coords.w)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    SetEntityAsMissionEntity(ped, true, true)
    SetModelAsNoLongerNeeded(model_hash)

    local option_names = {
        ('sonar_farm_sale_%s'):format(buyer_id),
        ('sonar_farm_route_%s'):format(buyer_id),
    }

    local target_ok, target_error = pcall(function()
        exports.ox_target:addLocalEntity(ped, {
            {
                name = option_names[1],
                icon = 'fas fa-wheat-awn',
                label = locale('sale.interaction.sell_harvest'),
                distance = tonumber(buyer.interaction_radius) or tonumber(Config and Config.Farm and Config.Farm.NPCs and Config.Farm.NPCs.DefaultInteractionRadius) or 2.5,
                canInteract = function()
                    return has_sellable_batch(buyer)
                end,
                onSelect = function()
                    execute_sale(buyer_id, buyer)
                end,
            },
            {
                name = option_names[2],
                icon = 'fas fa-route',
                label = locale('market.cta.set_on_map'),
                distance = tonumber(buyer.interaction_radius) or tonumber(Config and Config.Farm and Config.Farm.NPCs and Config.Farm.NPCs.DefaultInteractionRadius) or 2.5,
                onSelect = function()
                    TriggerServerEvent('sonar:farm:market:request_waypoint', buyer_id)
                end,
            },
        })
    end)

    if not target_ok then
        DeletePed(ped)
        log_error(('failed to register buyer target for %s: %s'):format(tostring(buyer_id), tostring(target_error)))
        return false
    end

    spawned_buyers[buyer_id] = {
        ped = ped,
        blip = create_buyer_blip(buyer),
        option_names = option_names,
    }

    log_debug(('spawned buyer %s at %.2f %.2f %.2f heading %.2f'):format(tostring(buyer_id), coords.x, coords.y, coords.z, coords.w))

    return true
end

local function load_buyers_once()
    if type(exports) ~= 'table' or not exports.ox_target then
        log_debug('ox_target unavailable during buyer load')
        return false
    end

    clear_spawned_buyers()

    local buyers = Config and Config.Farm and Config.Farm.NPCs and Config.Farm.NPCs.buyers or {}
    local attempted = 0
    local spawned_count = 0

    for buyer_id, buyer in pairs(buyers) do
        if type(buyer) == 'table' then
            attempted = attempted + 1
            if spawn_buyer_ped(buyer_id, buyer) then
                spawned_count = spawned_count + 1
            end
        end
    end

    if attempted == 0 then
        log_error('buyer load failed: no buyer configs available on client')
        return false
    end

    if spawned_count == 0 then
        log_error('buyer load failed: no buyer ped was spawned')
        return false
    end

    log_debug(('buyer load ready: %d/%d buyers spawned'):format(spawned_count, attempted))

    return true
end

local function load_buyers_with_retry()
    local retry_count = tonumber(Config and Config.Farm and Config.Farm.Client and Config.Farm.Client.Startup and Config.Farm.Client.Startup.RetryCount) or 10
    local retry_wait = tonumber(Config and Config.Farm and Config.Farm.Client and Config.Farm.Client.Startup and Config.Farm.Client.Startup.RetryWaitMs) or 1000

    for _ = 1, retry_count do
        if load_buyers_once() then
            return true
        end

        Wait(retry_wait)
    end

    return false
end

RegisterNetEvent('sonar:farm:market:set_waypoint', function(payload)
    if type(payload) ~= 'table' then
        return
    end

    local coords = type(payload.coords) == 'table' and payload.coords or nil
    if coords == nil then
        return
    end

    local x = tonumber(coords.x)
    local y = tonumber(coords.y)
    if x == nil or y == nil then
        return
    end

    SetNewWaypoint(x, y)
end)

RegisterNetEvent('sonar:farm:npc:catalog_reloaded', function()
    CreateThread(function()
        load_buyers_with_retry()
    end)
end)

AddEventHandler('onClientResourceStart', function(resource_name)
    if resource_name ~= GetCurrentResourceName() and resource_name ~= 'ox_target' then
        return
    end

    CreateThread(function()
        load_buyers_with_retry()
    end)
end)

AddEventHandler('onResourceStop', function(resource_name)
    if resource_name ~= GetCurrentResourceName() then
        return
    end

    clear_spawned_buyers()
end)
