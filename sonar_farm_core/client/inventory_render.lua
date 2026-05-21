local QUALITY_COLORS = {
    S = '#B6FB63',
    A = '#B6FB63',
    B = '#FFFFFF',
    C = '#F59E0B',
    D = '#EF4444',
}

local metadata_labels_registered = false

local function get_quality_color(grade)
    return QUALITY_COLORS[tostring(grade or ''):upper()] or '#FFFFFF'
end

local function get_freshness_color(freshness)
    local value = math.max(0, math.min(100, tonumber(freshness) or 0))
    if value >= 70 then
        return '#22C55E'
    end

    if value >= 40 then
        return '#F59E0B'
    end

    return '#EF4444'
end

local function batch_suffix(batch_id)
    local value = tostring(batch_id or '')
    if value == '' then
        return '----'
    end

    return value:sub(-4):upper()
end

local function normalize_batch_metadata(metadata)
    if type(metadata) ~= 'table' then
        return nil
    end

    local item_name = tostring(metadata.item_name or '')
    if item_name == '' and type(metadata.crop_type) == 'string' and metadata.crop_type ~= '' then
        item_name = ('sonar_batch_%s'):format(metadata.crop_type)
    end

    if item_name == '' or not item_name:find('^sonar_batch_') then
        return nil
    end

    local quality = tostring(metadata.quality or ''):upper()
    local freshness = math.max(0, math.min(100, tonumber(metadata.freshness) or 0))

    return {
        item_name = item_name,
        batch_id = tostring(metadata.batch_id or ''),
        crop_type = tostring(metadata.crop_type or ''),
        weight_g = tonumber(metadata.weight_g) or 0,
        quality = quality,
        freshness = freshness,
        origin = {
            plot_id = metadata.origin and tostring(metadata.origin.plot_id or '') or '',
            player_cid = metadata.origin and tostring(metadata.origin.player_cid or '') or '',
            harvested_ts = metadata.origin and (tonumber(metadata.origin.harvested_ts) or 0) or 0,
        },
        lineage_chain = type(metadata.lineage_chain) == 'table' and metadata.lineage_chain or {},
        created_at = tonumber(metadata.created_at) or 0,
        render = {
            quality_badge = quality,
            quality_color = get_quality_color(quality),
            freshness_color = get_freshness_color(freshness),
            batch_suffix = batch_suffix(metadata.batch_id),
            batch_font = 'JetBrains Mono',
            batch_color = '#969C9C',
        },
    }
end

local function send_batch_tooltip(metadata)
    local payload = normalize_batch_metadata(metadata)
    if not payload then
        return
    end

    SendNUIMessage({
        action = 'sonar:farm:nui:batch_tooltip',
        payload = payload,
    })
end

local function is_inventory_open()
    return LocalPlayer and LocalPlayer.state and LocalPlayer.state.invOpen == true
end

local function register_metadata_labels()
    if type(exports) ~= 'table' or not exports.ox_inventory then
        return false
    end

    local ok = pcall(function()
        exports.ox_inventory:displayMetadata({
            quality_badge = locale('items.metadata.quality_badge'),
            freshness_percent = locale('items.metadata.freshness_percent'),
            batch_suffix = locale('items.metadata.batch_suffix'),
        })
    end)

    metadata_labels_registered = ok
    return ok
end

local function ensure_metadata_labels_registered()
    if metadata_labels_registered then
        return
    end

    CreateThread(function()
        for _ = 1, 10 do
            if register_metadata_labels() then
                return
            end

            Wait(1000)
        end
    end)
end

RegisterNetEvent('sonar:farm:inventory:batch_tooltip', function(metadata)
    send_batch_tooltip(metadata)
end)

CreateThread(function()
    local was_open = false

    while true do
        Wait(250)

        local is_open = is_inventory_open()
        if was_open and not is_open then
            SendNUIMessage({
                action = 'sonar:farm:nui:batch_tooltip',
                payload = nil,
            })
        end

        was_open = is_open
    end
end)

AddEventHandler('onClientResourceStart', function(resource_name)
    if resource_name == GetCurrentResourceName() or resource_name == 'ox_inventory' then
        metadata_labels_registered = false
        ensure_metadata_labels_registered()
    end
end)
