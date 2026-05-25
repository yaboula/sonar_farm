-- ============================================================
-- Farm Sonar — Debug command to give batch items with metadata.
-- Usage: /sonarfarm:debug:give_batch <crop_type> <player_id>
-- ============================================================

local function get_db()
    return Sonar and Sonar.Farm and Sonar.Farm.DB or nil
end

RegisterCommand('sonarfarm:debug:give_batch', function(source, args)
    local caller_src = tonumber(source) or 0

    if caller_src > 0 and not IsPlayerAceAllowed(caller_src, 'sonar.farm.admin') then
        print('[sonar_farm_core][debug:give_batch] ACE permission required')
        return
    end

    local crop_type = args[1]
    local target_player = tonumber(args[2]) or caller_src

    if not crop_type or crop_type == '' then
        print('[sonar_farm_core][debug:give_batch] Usage: /sonarfarm:debug:give_batch <crop_type> [player_id]')
        return
    end

    local db = get_db()
    if not db then
        print('[sonar_farm_core][debug:give_batch] DB not available')
        return
    end

    -- Get player CID from bridge
    local player_cid = 'QQ4RRAV6'
    if Sonar.Farm.Bridge and Sonar.Farm.Bridge.GetPlayer then
        local player = Sonar.Farm.Bridge.GetPlayer(target_player)
        if player and player.citizen_id then
            player_cid = player.citizen_id
        end
    end

    -- Get a batch from DB for this crop type
    local batch = db.row([[
        SELECT batch_id, crop_type, quality, weight_g, plot_id, player_cid, harvested_ts
        FROM sonar_farm_batches
        WHERE crop_type = ? AND sold_ts IS NULL
        LIMIT 1
    ]], { crop_type })

    if not batch then
        print(('[sonar_farm_core][debug:give_batch] No unsold batch found for crop_type: %s'):format(crop_type))
        return
    end

    local item_name = 'sonar_batch_' .. crop_type
    local metadata = {
        batch_id = batch.batch_id,
        crop_type = batch.crop_type,
        quality = batch.quality,
        weight_g = batch.weight_g,
        freshness = 100,
        origin = {
            plot_id = batch.plot_id or 'debug_plot',
            player_cid = player_cid,
            harvested_ts = batch.harvested_ts or os.time(),
        },
        lineage_chain = {},
    }

    print(('[sonar_farm_core][debug:give_batch] Giving batch: %s, player_cid: %s'):format(batch.batch_id, player_cid))

    if type(exports) == 'table' and exports.ox_inventory then
        local added = exports.ox_inventory:AddItem(target_player, item_name, 1, metadata)
        if added then
            print(('[sonar_farm_core][debug:give_batch] Gave %s (batch_id: %s) to player %d'):format(item_name, batch.batch_id, target_player))
        else
            print(('[sonar_farm_core][debug:give_batch] Failed to add item %s to player %d'):format(item_name, target_player))
        end
    else
        print('[sonar_farm_core][debug:give_batch] ox_inventory not available')
    end
end, true)
